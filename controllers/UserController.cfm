<cfif NOT structKeyExists(session, "role_id") OR session.role_id NEQ 1>
<cfabort>
</cfif>

<cfif structKeyExists(url, "action") AND url.action EQ "delete">

    <cfset userModel = createObject("component", "models.User")>
    <cfset userModel.deleteUser(url.id)>

    <cflocation url="../index.cfm?page=dashboard&section=users&message=User deleted&type=success" addtoken="false">
    <cfabort>
</cfif> 

<cfif structKeyExists(form, "action") AND form.action EQ "update">

    <cfset first_name = trim(form.first_name)>
    <cfset last_name = trim(form.last_name)>
    <cfset email = trim(form.email)>

    <cfset baseUrl = "../index.cfm?page=dashboard&section=users">

    <cfif len(first_name) LT 3>
        <cflocation url="#baseUrl#&message=First name must be at least 3 characters&type=error&editId=#form.id#" addtoken="false">
        <cfabort>

    <cfelseif len(first_name) GT 100>
        <cflocation url="#baseUrl#&message=First name must be less than 100 characters&type=error&editId=#form.id#" addtoken="false">
        <cfabort>

    <cfelseif len(last_name) LT 1>
        <cflocation url="#baseUrl#&message=Last name must be at least 1 character&type=error&editId=#form.id#" addtoken="false">
        <cfabort>

    <cfelseif len(last_name) GT 100>
        <cflocation url="#baseUrl#&message=Last name must be less than 100 characters&type=error&editId=#form.id#" addtoken="false">
        <cfabort>

    <cfelseif NOT isValid("email", email)>
        <cflocation url="#baseUrl#&message=Invalid email format&type=error&editId=#form.id#" addtoken="false">
        <cfabort>

    <cfelseif len(email) GT 100>
        <cflocation url="#baseUrl#&message=Email too long&type=error&editId=#form.id#" addtoken="false">
        <cfabort>

    <cfelse>

        <cfset userModel = createObject("component","models.User")>

        <cfset userModel.updateUser(
            form.id,
            first_name,
            last_name,
            email
        )>

        <cflocation url="#baseUrl#&message=User updated successfully&type=success" addtoken="false">
        <cfabort>

    </cfif>

</cfif>

<!-- super admin create user -->
<cfif structKeyExists(form,"action") AND form.action EQ "create">

<cfset userModel = createObject("component","models.User")>

<cfset first_name = trim(form.first_name)>
<cfset last_name = trim(form.last_name)>
<cfset email = trim(form.email)>
<cfset password = trim(form.password)>
<cfset confirm = trim(form.confirm)>
<cfset role_id = val(form.role_id)>

<cfset baseUrl = "../index.cfm?page=dashboard&section=users">

<!-- validation -->
<cfif len(first_name) LT 3>
    <cflocation url="#baseUrl#&message=First name must be at least 3 characters&type=error&showForm=1" addtoken="false">
    <cfabort>

<cfelseif len(first_name) GT 100>
    <cflocation url="#baseUrl#&message=First name max 100 characters&type=error&showForm=1" addtoken="false">
    <cfabort>

<cfelseif len(last_name) LT 1>
    <cflocation url="#baseUrl#&message=Last name required&type=error&showForm=1" addtoken="false">
    <cfabort>

<cfelseif len(last_name) GT 100>
    <cflocation url="#baseUrl#&message=Last name max 100 characters&type=error&showForm=1" addtoken="false">
    <cfabort>

<cfelseif NOT isValid("email", email)>
    <cflocation url="#baseUrl#&message=Invalid email format&type=error&showForm=1" addtoken="false">
    <cfabort>

<cfelseif len(email) GT 100>
    <cflocation url="#baseUrl#&message=Email too long&type=error&showForm=1" addtoken="false">
    <cfabort>

<cfelseif len(password) LT 8 OR len(password) GT 20>
    <cflocation url="#baseUrl#&message=Password must be 8-20 characters&type=error&showForm=1" addtoken="false">
    <cfabort>

<cfelseif NOT reFind("^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])", password)>
    <cflocation url="#baseUrl#&message=Password must contain uppercase, lowercase, number and special character&type=error&showForm=1" addtoken="false">
    <cfabort>

<cfelseif password NEQ confirm>
    <cflocation url="#baseUrl#&message=Passwords do not match&type=error&showForm=1" addtoken="false">
    <cfabort>

</cfif>

<!-- create user -->
<cfset userModel.create_user(
    first_name,
    last_name,
    email,
    password,
    role_id
)>

<cflocation url="#baseUrl#&message=User created successfully&type=success" addtoken="false">
<cfabort>

</cfif>