<cfif NOT structKeyExists(session, "user_id")>
   <cflocation url="../../index.cfm?page=auth&message=please login first&type=error&tab=login" addtoken="false">
   <cfabort>
</cfif>

<!DOCTYPE html>
<html>
<head>
    <title>Dashboard</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>

<body class="bg-light">

<div class="container mt-5">
    <div class="card shadow">
        <div class="card-body">

            <h3>Dashboard</h3>

            <hr>

            <cfoutput>
                <p><strong>Welcome:</strong> #session.user_email#</p>
                <p><strong>User ID:</strong> #session.user_id#</p>
                <p><strong>Role ID:</strong> #session.role_id#</p>
            </cfoutput>

            <hr>

            <a href="../../controllers/LogoutController.cfm" class="btn btn-danger">
                Logout
            </a>

        </div>
    </div>
</div>

</body>
</html>