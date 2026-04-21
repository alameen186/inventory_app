<!DOCTYPE html>
<html>
<head>
    <title>Auth</title>

    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>

<body class="bg-light">

<cfset activeTab = structKeyExists(url, "tab") ? url.tab : "login">

<div class="container mt-5">
    <div class="row justify-content-center">
        <div class="col-md-6">

            <div class="card shadow">
                <div class="card-body">

                    <h3 class="text-center mb-4">Authentication</h3>

                    <!-- MESSAGE -->
                    <cfif structKeyExists(url, "message")>
                        <div id="alertBox" class="alert 
                            <cfif structKeyExists(url, "type") AND url.type EQ 'success'>
                                alert-success
                            <cfelse>
                                alert-danger
                            </cfif>">
                    
                            <cfoutput>#url.message#</cfoutput>
                        </div>
                    </cfif>

                    <!-- Tabs -->
                    <ul class="nav nav-tabs">
                        <li class="nav-item">
                            <button class="nav-link <cfif activeTab EQ 'login'>active</cfif>" 
                                data-bs-toggle="tab" data-bs-target="#login">
                                Login
                            </button>
                        </li>
                        <li class="nav-item">
                            <button class="nav-link <cfif activeTab EQ 'signup'>active</cfif>" 
                                data-bs-toggle="tab" data-bs-target="#signup">
                                Signup
                            </button>
                        </li>
                    </ul>

                    <div class="tab-content mt-3">

                        <!-- LOGIN -->
                        <div class="tab-pane fade <cfif activeTab EQ 'login'>show active</cfif>" id="login">

                            <form method="post" action="../../index.cfm?page=auth">
                                <input type="hidden" name="action" value="login">

                                <div class="mb-3">
                                    <label>Email</label>
                                    <input type="email" name="email" class="form-control" required>
                                </div>

                                <div class="mb-3">
                                    <label>Password</label>
                                    <input type="password" name="password" class="form-control" required>
                                </div>

                                <button class="btn btn-primary w-100">Login</button>
                            </form>

                        </div>

                        <!-- SIGNUP -->
                        <div class="tab-pane fade <cfif activeTab EQ 'signup'>show active</cfif>" id="signup">
<cfset roleModel = createObject("component","models.Role")>
<cfset roles = roleModel.getRolesForSignup()>
                            <form method="post" action="../../index.cfm?page=auth">
<input type="hidden" name="action" value="signup">

<input type="text" name="first_name" class="form-control mb-2" placeholder="First Name" required>
<input type="text" name="last_name" class="form-control mb-2" placeholder="Last Name" required>
<input type="email" name="email" class="form-control mb-2" placeholder="Email" required>
<input type="password" name="password" class="form-control mb-2" placeholder="Password" required>
<input type="password" name="confirm_password" class="form-control mb-2" placeholder="Confirm Password" required>

<!-- ROLE -->
<select name="role_id" id="roleSelect" class="form-control mb-2" required>
<option value="">Select Role</option>

<cfoutput query="roles">
<option value="#id#">#role_name#</option>
</cfoutput>

</select>

<!-- VENDOR FIELD -->
<div id="vendorFields" style="display:none;">
    <input type="text" name="business_name" class="form-control mb-2" placeholder="Business Name">
    <textarea name="address" class="form-control mb-2" placeholder="Address"></textarea>
</div>

<button class="btn btn-success w-100">Signup</button>
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
    setTimeout(function () {
        var alertBox = document.getElementById("alertBox");
        if (alertBox) {
            alertBox.style.display = "none";
        }
    }, 5000);   

   
document.getElementById("roleSelect").addEventListener("change", function(){

    let selectedText = this.options[this.selectedIndex].text.toLowerCase();

    if(selectedText === "vendor"){
        document.getElementById("vendorFields").style.display = "block";
    }else{
        document.getElementById("vendorFields").style.display = "none";
    }

});

</script>
</body>
</html>