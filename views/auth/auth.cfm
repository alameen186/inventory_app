<!DOCTYPE html>
<html>
<head>
    <title>Auth</title>

    <!-- Bootstrap -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>

<body class="bg-light">

<!---  active tab --->
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

                            <form method="post" action="../../index.cfm?page=auth">
                                <input type="hidden" name="action" value="signup">

                                <div class="mb-2">
                                    <input 
                                     type="text" 
                                     name="first_name" 
                                     class="form-control" 
                                     placeholder="First Name" 
                                     required
                                     value="<cfif structKeyExists(url,'first_name')><cfoutput>#url.first_name#</cfoutput></cfif>">
                                     
                                </div>

                                <div class="mb-2">
                                    <input type="text" 
                                    name="last_name" 
                                    class="form-control" 
                                    placeholder="Last Name" 
                                    required
                                    value="<cfif structKeyExists(url,'last_name')><cfoutput>#url.last_name#</cfoutput></cfif>">
                                    
                                </div>

                                <div class="mb-2">
                                    <input 
                                    type="email" 
                                    name="email" 
                                    class="form-control" 
                                    placeholder="Email" 
                                    required 
                                    value="<cfif structKeyExists(url,'email')><cfoutput>#url.email#</cfoutput></cfif>">
                                </div>

                                <div class="mb-2">
                                    <input 
                                    type="password" 
                                    name="password" 
                                    class="form-control" 
                                    placeholder="Password" 
                                    required>
                                </div>

                                <div class="mb-2">
                                    <input 
                                    type="password" 
                                    name="confirm_password" 
                                    class="form-control" 
                                    placeholder="Confirm Password" 
                                    required>
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

<!-- Bootstrap JS -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
    setTimeout(function () {
        var alertBox = document.getElementById("alertBox");
        if (alertBox) {
            alertBox.style.display = "none";
        }
    }, 5000);   
</script>
</body>
</html>