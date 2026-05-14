<!DOCTYPE html>
<html>
<head>
    <title>Auth</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.min.css">
</head>
<body class="bg-light">

<cfset activeTab = structKeyExists(url, "tab") ? url.tab : "login">

<div class="container mt-5">
    <div class="row justify-content-center">
        <div class="col-md-6">
            <div class="card shadow">
                <div class="card-body">

                    <h3 class="text-center mb-4">Authentication</h3>

                    <!-- Shared alert — jQuery will fill this -->
                    <div id="alertBox" class="alert d-none"></div>

                    <ul class="nav nav-tabs">
                        <li class="nav-item">
                            <button class="nav-link <cfif activeTab EQ 'login'>active</cfif>"
                                data-bs-toggle="tab" data-bs-target="#login">Login</button>
                        </li>
                        <li class="nav-item">
                            <button class="nav-link <cfif activeTab EQ 'signup'>active</cfif>"
                                data-bs-toggle="tab" data-bs-target="#signup">Signup</button>
                        </li>
                    </ul>

                    <div class="tab-content mt-3">

                        <!-- LOGIN -->
                        <div class="tab-pane fade <cfif activeTab EQ 'login'>show active</cfif>" id="login">
                            <form id="loginForm">
                                <div class="mb-3">
                                    <label>Email</label>
                                    <input type="email" name="email" class="form-control" required>
                                </div>
                                <div class="mb-3">
                                    <label>Password</label>
                                    <input type="password" name="password" class="form-control" required>
                                </div>
                                <button type="submit" class="btn btn-primary w-100">
                                    <span class="spinner-border spinner-border-sm d-none" id="loginSpinner"></span>
                                    Login
                                </button>
                            </form>
                            <!-- Staff Login Toggle Link -->
                         <div class="text-center mt-3">
                             <hr>
                             <p class="text-muted small mb-2">Are you a staff member?</p>
                             <button class="btn btn-outline-secondary btn-sm" id="toggleStaffLogin">
                                 <i class="bi bi-person-badge me-1"></i> Staff Login
                             </button>
                         </div>
                         
                         <!-- Staff Login Panel (hidden by default) -->
                         <div id="staffLoginPanel" style="display:none;" class="mt-3">
                             <div class="card border-secondary">
                                 <div class="card-header bg-secondary text-white fw-semibold">
                                     <i class="bi bi-person-badge me-2"></i>Staff Login
                                 </div>
                                 <div class="card-body">
                                     <p class="text-muted small mb-3">
                                         Login with the email and password your employer set up for you.
                                     </p>
                                     <form id="staffLoginForm">
                                         <div class="mb-3">
                                             <label class="form-label">Staff Email</label>
                                             <input type="email" name="email" class="form-control" placeholder="your@email.com" required>
                                         </div>
                                         <div class="mb-3">
                                             <label class="form-label">Password</label>
                                             <input type="password" name="password" class="form-control" required>
                                         </div>
                                         <button type="submit" class="btn btn-secondary w-100">
                                             <span class="spinner-border spinner-border-sm d-none" id="staffSpinner"></span>
                                             Login as Staff
                                         </button>
                                     </form>
                                 </div>
                             </div>
                         </div>
                        </div>

                        <!-- SIGNUP -->
                        <div class="tab-pane fade <cfif activeTab EQ 'signup'>show active</cfif>" id="signup">
                            <cfset roleModel = createObject("component","models.Role")>
                            <cfset roles = roleModel.getRolesForSignup()>

                            <form id="signupForm">
                                <input type="text" name="first_name" class="form-control mb-2" placeholder="First Name" required>
                                <input type="text" name="last_name" class="form-control mb-2" placeholder="Last Name" required>
                                <input type="email" name="email" class="form-control mb-2" placeholder="Email" required>
                                <input type="password" name="password" class="form-control mb-2" placeholder="Password" required>
                                <input type="password" name="confirm_password" class="form-control mb-2" placeholder="Confirm Password" required>

                                <select name="role_id" id="roleSelect" class="form-control mb-2" required>
                                    <option value="">Select Role</option>
                                    <cfoutput query="roles">
                                        <option value="#id#">#role_name#</option>
                                    </cfoutput>
                                </select>

                                <div id="vendorFields" style="display:none;">
                                    <input type="text" name="business_name" class="form-control mb-2" placeholder="Business Name">
                                    <textarea name="address" class="form-control mb-2" placeholder="Address"></textarea>
                                </div>

                                <button type="submit" class="btn btn-success w-100">
                                    <span class="spinner-border spinner-border-sm d-none" id="signupSpinner"></span>
                                    Signup
                                </button>
                            </form>
                        </div>

                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

<script>

    function showAlert(message, type) {
        var box = $("#alertBox");
        box.removeClass().addClass("alert alert-" + (type || "danger"));
        box.text(message);
        setTimeout(function () { box.addClass("d-none"); }, 5000);
    }

    //   Generic AJAX submit to CFC  
    function submitToCFC(method, formId, spinnerId) {
        var spinner  = $("#" + spinnerId);
        var formData = $("#" + formId).serialize();

        spinner.removeClass("d-none");

        $.ajax({
            url      : "controllers/AuthController.cfc",
            type     : "POST",
            data     : formData + "&method=" + method,
            dataType : "json",

            success: function (res) {

                if (res.success) {

                    //   STORE TOKENS IN localStorage    
                    if (res.data && res.data.access_token) {
                        localStorage.setItem("access_token",  res.data.access_token);
                        localStorage.setItem("refresh_token", res.data.refresh_token);
                    }

                    showAlert(res.message, "success");

                    //   REDIRECT after short delay    
                    if (res.redirect) {
                        setTimeout(function () {
                            window.location.href = res.redirect;
                        }, 800);
                    }

                } else {
                    showAlert(res.message, "danger");
                }
            },

            error: function () {
                showAlert("Network error. Please try again.", "danger");
            },

            complete: function () {
                spinner.addClass("d-none");
            }
        });
    }

    //  Login form submit 
    $("#loginForm").on("submit", function (e) {
        e.preventDefault();
        submitToCFC("login", "loginForm", "loginSpinner");
    });

    //  Signup form submit 
    $("#signupForm").on("submit", function (e) {
        e.preventDefault();
        submitToCFC("signup", "signupForm", "signupSpinner");
    });

    //  Vendor field toggle 
    $("#roleSelect").on("change", function () {
        var selected = $(this).find("option:selected").text().toLowerCase();
        $("#vendorFields").toggle(selected === "vendor");
    });

    // Staff login toggle
$('#toggleStaffLogin').on('click', function () {
    var panel = $('#staffLoginPanel');
    var normalForm = $('#loginForm');
    var isHidden = !panel.is(':visible');

    panel.slideToggle(300, function () {
        var nowVisible = panel.is(':visible');
        normalForm.slideToggle(!nowVisible); 
        $('#toggleStaffLogin').text(nowVisible ? 'Hide Staff Login' : 'Staff Login');
    });
});

// Staff login submit
$('#staffLoginForm').on('submit', function(e){
    e.preventDefault();
    var spinner = $('#staffSpinner');
    spinner.removeClass('d-none');
    $.ajax({
        url      : 'controllers/StaffAuthController.cfc?method=login',
        type     : 'POST',
        data     : $(this).serialize(),
        dataType : 'json',
        success  : function(res){
            if(res.success){
                showAlert(res.message, 'success');
                setTimeout(function(){
                    window.location.href = res.data.redirect;
                }, 600);
            } else {
                showAlert(res.message, 'danger');
            }
        },
        error: function(){ showAlert('Network error. Try again.', 'danger'); },
        complete: function(){ spinner.addClass('d-none'); }
    });
});

</script>

</body>
</html>