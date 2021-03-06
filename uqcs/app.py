import os
import re
import logging
import stripe
from datetime import date, timedelta
from .templates import lookup
from flask import Flask, request, session, flash, get_flashed_messages, redirect, jsonify
from werkzeug.datastructures import MultiDict
from . import models as m
from .admin import admin
from .base import needs_db
from .base import mailchimp_queue, mailer_queue
from .models import Member

logger = logging.getLogger(__name__)

app = Flask(__name__)
app.register_blueprint(admin, url_prefix='/admin')

stripe.api_key = os.environ.get("STRIPE_API_KEY")

STRIPE_PUBLIC_KEY = os.environ.get('STRIPE_PUBLIC_KEY')
STRIPE_PRICE_ID = os.environ.get('STRIPE_PRICE_ID')


def student_checksum(first_7, last_1):
    u = [int(d) for d in first_7]
    return int(last_1) == (9*u[0] + 7*u[1] + 3*u[2] + 9*u[3] + 7*u[4] + 3*u[5] + 9*u[6]) % 10


def user_from_request(form):
    info = {}
    if not form.get("fname", "").strip():
        return (None, "No first name given")
    else:
        info["first_name"] = form["fname"].strip()

    if not form.get("lname", "").strip():
        return (None, "No last name given")
    else:
        info["last_name"] = form["lname"].strip()

    if not form.get("email", "").strip():
        return (None, "No email given")
    else:
        info["email"] = form["email"].strip()

    if form.get("gender", '') not in ['', 'M', 'F', 'NB', 'O']:
        return (None, "Invalid option for gender")
    else:
        info["gender"] = form.get("gender", '') or None

    info["gender_text"] = form.get("gender_text", None)

    if form.get("student", False):
        info['student_no'] = form["student-no"]
        if re.match("[1-5][0-9]{7,7}", info['student_no']) is None:
            return None, "Invalid student number format"
        elif not student_checksum(info['student_no'][:7], info['student_no'][7]):
            return None, "Student number has valid format but is not a valid number"

        if form.get('year'):
            if form['year'] == "5+":
                info['year'] = 5
            else:
                try:
                    info['year'] = int(form['year'])
                except ValueError:
                    return None, "Invalid selection for year"
            if info['year'] not in range(1, 6):
                return None, "Invalid selection for year"
        if 'domORint' in form:
            if form['domORint'].lower() not in ['domestic', 'international']:
                return None, "Invalid domestic/international option"
            info["domestic"] = form['domORint'].lower() == 'domestic'
        if 'degreeType' in form:
            if form['degreeType'].lower() not in ['undergrad', 'postgrad']:
                return None, "Invalid degree type option"
            info["undergrad"] = form['degreeType'].lower() == 'undergrad'
        if 'degree' in form:
            info['program'] = form['degree']
        if 'majors' in form:
            info['majors'] = [x.strip() for x in form.getlist('majors') if x.strip()]
        return m.Student(**info), "Success"
    else:
        return m.Member(**info), "Success"


@app.route("/", methods=["GET"])
@needs_db
def form_get(s):
    def expiry():
        curr_year = date.today().year
        format_date = lambda d: d.strftime('%d').lstrip('0') + d.strftime(' %B %Y')
        # compute the last day of february as the day before march 1.
        expiry_today = date(curr_year + 1, 3, 1) - timedelta(days=1)
        start_future = date(curr_year + 1, 1, 1)
        expiry_future = date(curr_year + 2, 3, 1) - timedelta(days=1)
        return map(format_date, (expiry_today, start_future, expiry_future))

    if not STRIPE_PUBLIC_KEY or not STRIPE_PRICE_ID:
        logger.error(
            'missing Stripe environment variables may lead to unexpected failures.')

    template = lookup.get_template('form.mako')
    expiry_today, start_future, expiry_future = expiry()
    return template.render(request=request,
                            form=session.pop('form', None),
                            get_msgs=get_flashed_messages,
                            expiry_today=expiry_today,
                            start_future=start_future,
                            expiry_future=expiry_future,
                            STRIPE_PUBLIC_KEY=STRIPE_PUBLIC_KEY,
                            STRIPE_PRICE_ID=STRIPE_PRICE_ID), 200

def _check_form(s, form):
    errors = []

    if s.query(m.Member).filter(m.Member.email == form.get('email')).count() > 0:
        errors.append("That email has already been registered.")

    if form.get('student', False):
        if s.query(m.Student).filter(
                    m.Student.student_no == form.get('student-no')
                ).count() > 0:
            errors.append("That student number has already been registered.")

    user, msg = user_from_request(form)
    if user is None:
        errors.append(msg)

    if errors:
        return None, errors
    else:
        return user, []


@app.route("/", methods=["POST"])
@needs_db
def form_post(s):
    user, errors = _check_form(s, request.form)
    if errors:
        return jsonify(errors=errors)

    session['form'] = request.form.to_dict(flat=False)
    # store copy of form in session. user is not created until /complete is hit.
    return jsonify(success=True, email=user.email)


@app.route("/complete")
@needs_db
def complete(s):
    if 'form' not in session:
        logger.debug('rejecting attempt to access /complete without form.')
        flash('Invalid request to /complete (session is missing form).', 'danger')
        return redirect('/', 303)

    # need to convert serialised dict from session back to MultiDict.
    form = MultiDict(session['form'])
    user, errors = _check_form(s, form)
    if errors:
        logger.debug('errors while creating user on /complete: ' + str(errors))
        flash('Failed to create member after payment. '
              'Please contact UQCS if you have been charged twice.',
              'danger')
        flash('\n'.join(errors), 'danger')
        return redirect('/', 303)

    # if the user has paid via stripe, verify their payment and add them to
    # relevant queues.
    checkout_id = request.args.get('checkout')
    if checkout_id and not user.has_paid():
        try:
            checkout = stripe.checkout.Session.retrieve(
                checkout_id, expand=['payment_intent'])
            charge_id = checkout.payment_intent.charges.data[0].id
        except Exception as e:
            flash('Failed to verify Stripe payment.', 'danger')
            logger.exception('exception while verifying checkout session')
            return redirect('/', 303)

        user.paid = charge_id

    # if we get to this point, we are fairly sure the user has been created
    # successfully.
    s.add(user)
    s.flush()
    logger.info('added user: ' + user.email + '\nform: ' + str(form))
    s.expunge(user)

    if user.has_paid():
        mailer_queue.put(user)
        mailchimp_queue.put(user)

    return lookup.get_template("complete.mako").render(member=user)

@app.route("/cancel", methods=["GET"])
def cancel():
    return lookup.get_template("cancel.mako").render()