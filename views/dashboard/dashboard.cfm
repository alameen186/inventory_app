<cfif NOT structKeyExists(session, "user_id")>
   <cflocation url="../../index.cfm?page=auth&message=please login first&type=error&tab=login" addtoken="false">
   <cfabort>
</cfif>

<cfset userModel = createObject("component","models.User")>
<cfset userData = userModel.getUserWithRole(session.user_id)>

<!DOCTYPE html>
<html>
<head>
    <title>Dashboard</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>

<body class="bg-light">

<div class="container mt-5">
    <div class="row justify-content-center">
        <div class="col-md-6">

            <div class="card shadow-lg border-0 rounded-3">

                <!-- Header -->
                <div class="card-header bg-dark text-white text-center">
                    <h4 class="mb-0">Inventory Management System</h4>
                </div>

                <!-- Body -->
                <div class="card-body">

                    <cfoutput>
                        <div class="text-center mb-4">
                            <h5 class="fw-bold">Welcome, #userData.first_name# #userData.last_name#</h5>
                            <p class="text-muted mb-0">#userData.email#</p>
                        </div>

                        <hr>

                        <!-- Role Info -->
                        <div class="p-3 bg-light rounded">
                            <h6 class="fw-bold text-primary mb-1">
                                #userData.role_name#
                            </h6>
                            <small class="text-muted">
                                #userData.description#
                            </small>
                        </div>
                    </cfoutput>

                    <hr>

                    <!-- Logout -->
                    <div class="d-grid">
                        <a href="../../controllers/LogoutController.cfm" class="btn btn-danger">
                            Logout
                        </a>
                    </div>

                </div>
            </div>

        </div>
    </div>
</div>

</body>
</html>