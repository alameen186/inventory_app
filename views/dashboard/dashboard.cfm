<cfif NOT structKeyExists(session, "user_id")>
   <cflocation url="../../index.cfm?page=auth&message=please login first&type=error&tab=login" addtoken="false">
   <cfabort>
</cfif>

<cfif structKeyExists(url, "section")>
     <cfset section = url.section>
<cfelse>
     <cfset section = "home">   
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

<div class="container-fluid">
    <div class="row">

        <!-- LEFT SIDEBAR -->
        <div class="col-md-2 bg-dark text-white vh-100 p-3">

            <h5 class="text-center">Menu</h5>
            <hr class="bg-light">

            <!-- Admin Only -->
            <cfif session.role_id EQ 1>
                <ul class="nav flex-column">
                    <li class="nav-item mb-2">
                        <a class="nav-link text-white" href="../../index.cfm?page=dashboard&section=users">Users</a>
                    </li>
                    <li class="nav-item mb-2">
                        <a class="nav-link text-white" href="../../index.cfm?page=dashboard&section=roles">Roles</a>
                    </li>
                </ul>
            </cfif>

            <!-- Logout -->
            <div class="mt-auto">
                <a href="../../controllers/LogoutController.cfm" class="btn btn-danger w-100 mt-4">
                    Logout
                </a>
            </div>

        </div>

        <!-- MAIN CONTENT -->
        <div class="col-md-10">

            <!-- TOP BAR -->
            <div class="d-flex justify-content-between align-items-center p-3 border-bottom shadow-sm">

                <h4 class="mb-0">Inventory Store</h4>

                <!-- PROFILE DROPDOWN -->
                <div class="dropdown">
                    <button class="btn btn-secondary dropdown-toggle" data-bs-toggle="dropdown">
                        Profile
                    </button>

                    <div class="dropdown-menu dropdown-menu-end p-3" style="min-width: 250px;">

                        <cfoutput>
                            <p><strong>#userData.first_name# #userData.last_name#</strong></p>
                            <p class="mb-1">#userData.email#</p>
                            <hr>
                            <p class="mb-1"><strong>#userData.role_name#</strong></p>
                            <small>#userData.description#</small>
                        </cfoutput>

                    </div>
                </div>

            </div>

            <!-- CENTER CONTENT -->
            <div class="p-4">

    <cfif section EQ "users">

        <cfinclude template="../admin/users.cfm">

    <cfelseif section EQ "roles">

        <cfinclude template="../admin/roles.cfm">

    <cfelse>

        <h3>Welcome to Inventory Store</h3>

    </cfif>

</div>

        </div>

    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>