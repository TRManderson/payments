<%inherit file="base.mako"/>

<div class="row" style="text-align:center">
  <div id="body" class="col-sm-12 col-md-6 col-md-offset-3">
    <img src="/static/logo.png" />
    <h1>2019 UQCS Registration</h1>
    <div class="flash">
      % for category, msg in get_msgs(with_categories=True):
      <div class="alert alert-${category} alert-dismissible" role="alert">
        <button
          type="button"
          class="close"
          data-dismiss="alert"
          aria-label="Close"
        >
          <span aria-hidden="true">&times;</span>
        </button>
        ${msg}
      </div>
      % endfor
    </div>
    <form method="POST" id="fullForm" action="/" name="payForm">
      <div class="form-group">
        <label for="fnameInput">First Name<span class="reqstar">*</span></label>
        <input
          type="text"
          class="form-control"
          id="fnameInput"
          placeholder="First Name"
          name="fname"
          required="true"
        />
      </div>
      <div class="form-group">
        <label for="lnameInput">Last Name<span class="reqstar">*</span></label>
        <input
          type="text"
          class="form-control"
          id="lnameInput"
          placeholder="Last Name"
          name="lname"
          required="true"
        />
      </div>
      <div class="form-group">
        <label for="emailInput"
          >Email address <span class="reqstar">*</span></label
        >
        <input
          name="email"
          type="email"
          class="form-control"
          id="emailInput"
          placeholder="Email"
          required="true"
        />
      </div>
      <div class="form-group">
        <label>Gender</label><br />
        <div style="text-align: left; display: inline-block">
          <div class="radio">
            <label> <input name="gender" type="radio" value="M" /> Male </label>
          </div>
          <div class="radio">
            <label>
              <input name="gender" type="radio" value="F" /> Female
            </label>
          </div>
          <div class="radio">
            <label>
              <input
                name="gender"
                type="radio"
                value="null"
                data-bind="checked: gender"
                checked
              />
              Other / Prefer not to disclose
            </label>
          </div>
        </div>
      </div>
      <div class="form-group">
        <label for="memberType"
          >Member Type <span class="reqstar">*</span></label
        >
        <div class="checkbox">
          <label>
            <input name="student" type="checkbox" id="studentCheckbox" /> Are
            you currently a student?
          </label>
        </div>
      </div>
      <div id="student-form-section" style="display:none;">
        <div class="form-group">
          <label for="student-no"
            >Student Number <span class="reqstar">*</span></label
          >
          <input
            type="number"
            name="student-no"
            class="form-control"
            id="studentNo"
            placeholder="43108765"
          />
          <p class="help-block">8 digits, no 's'</p>
        </div>
        <div class="form-group">
          <label>Domestic or International</label><br />
          <div style="text-align: left; display: inline-block">
            <div class="radio">
              <label>
                <input type="radio" value="domestic" name="domORint" /> Domestic
              </label>
            </div>
            <div class="radio">
              <label>
                <input type="radio" value="international" name="domORint" />
                International
              </label>
            </div>
          </div>
        </div>
        <div class="form-group">
          <label>Degree Type</label><br />
          <div id="ugpgrs" class="btn-group btn-group-toggle" data-toggle="buttons">
            <label class="btn btn-primary">
              <input
                type="radio"
                value="undergrad"
                name="degreeType"
                autocomplete="off"
              />
              Undergrad
            </label>
            <label class="btn btn-primary">
              <input
                type="radio"
                value="postgrad"
                name="degreeType"
                autocomplete="off"
              />
              Postgrad
            </label>
            <label class="btn btn-primary">
              <input
                type="radio"
                value="research"
                name="degreeType"
                autocomplete="off"
              />
              Research
            </label>
          </div>
        </div>
        <div class="form-group">
          <label for="inputProgram" class="control-label">Degree/Program</label
          ><br />
          <select
            id="inputProgram"
            name="program"
            class="form-control select2-single"
            style="width:100%"
          >
            <option></option>
          </select>
        </div>
        <div class="form-group">
          <label>Year</label> <br />
          <div class="btn-group btn-group-toggle" data-toggle="buttons">
            <label class="btn btn-primary">
              <input type="radio" name="year" value="1" /> 1
            </label>
            <label class="btn btn-primary">
              <input type="radio" name="year" value="2" /> 2
            </label>
            <label class="btn btn-primary">
              <input type="radio" name="year" value="3" /> 3
            </label>
            <label class="btn btn-primary">
              <input type="radio" name="year" value="4" /> 4
            </label>
            <label class="btn btn-primary">
              <input type="radio" name="year" value="5" /> 5+
            </label>
          </div>
        </div>
      </div>
      <input type="hidden" name="stripeToken" value="" id="stripeToken" />
      <input
        class="btn btn-primary"
        name="submit"
        type="submit"
        id="payonline_submit"
        value="Pay Online"
      />
      <input
        type="submit"
        name="submission"
        value="Pay Online"
        style="display:none;"
        id="submitbtn"
      />
      <input
        class="btn btn-success"
        name="submission"
        type="submit"
        value="Pay Cash"
      />
    </form>
    <div class="text-muted">
      <p></p>
      <p>Online payments have a 40c card surcharge.</p>
    </div>
    <h3>Want to register with QPAY?</h3>
    <p>
      As nearly all clubs and societies will be required to use QPAY for 2019,
      UQCS will offer QPAY signup as a secondary method. QPAY is not required
      for interacting with UQCS other than co-hosted events with clubs that
      choose to do ticketing with QPAY.
    </p>
    <div class="text-muted">
      <p></p>
      <p>
        UQCS does not endorse QPAY, you should do your own research to see if
        QPAY is right for you.
      </p>
    </div>
    <a role="button" class="btn btn-primary" href="https://joinuqcs.getqpay.com"
      >Signup with QPAY</a
    >
  </div>
</div>
<script src="https://checkout.stripe.com/checkout.js"></script>
<script type="text/javascript">
  var handler = StripeCheckout.configure({
    key: "${STRIPE_PUBLIC_KEY}",
    locale: "auto",
    token: function(token) {
      $("#stripeToken").val(token.id);
      $("#submitbtn").click();
    }
  });
  $("#payonline_submit").on("click", function(e) {
    e.preventDefault();
    if (!$("#fullForm")[0].checkValidity()) {
      return;
    }
    handler.open({
      name: "UQCS",
      description: "2019 Membership",
      currency: "aud",
      amount: 540,
      email: $("#emailInput").val()
    });
  });
  $(window).on("popstate", function() {
    handler.close();
  });
  $("#studentCheckbox").change(function(e) {
    if ($("#studentCheckbox")[0].checked) {
      $("#student-form-section").slideDown();
      $("#studentNo").attr("required", "true");
    } else {
      $("#student-form-section").slideUp();
      $("#studentNo").attr("required", null);
    }
  });
  function formatState (item) {
    opt = $(item.element);
    og = opt.closest("optgroup").attr("label");
    return ((og != null || og != "") ? og : "Degree") + " | " + item.text;
  };
  var ugpgrs;
  $("#ugpgrs :input").change(function() {
    switch(this.value) {
      case "undergrad":
        $.getJSON("/static/data-undergrad-select2.json", function(data) {
          $("#inputProgram").empty();
          $("#inputProgram").prop("disabled", false);
          $("#inputProgram").select2({
            templateSelection: formatState,
            data: data.results,
          });
        });
        break;
      case "postgrad":
        $.getJSON("/static/data-postgrad-select2.json", function(data) {
          $("#inputProgram").empty();
          $("#inputProgram").prop("disabled", false);
          $("#inputProgram").select2({
            templateSelection: formatState,
            data: data.results,
          });
        });
        break;
      case "research":
        $("#inputProgram").empty();
        $("#inputProgram").prop("disabled", true);
        break;
    }
  });
  $(document).ready(function() {
    $("#inputProgram").select2({
      theme: "bootstrap",
      placeholder: "Degree | Major"
    });
  }); 
</script>
