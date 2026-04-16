<cfif NOT structKeyExists(session, "role_id") OR session.role_id NEQ 1>
    <cfabort>
</cfif>

<!-- DELETE USER -->
<cfif structKeyExists(url, "action") AND url.action EQ "delete">

    <cfset userModel = createObject("component", "models.User")>
    <cfset userModel.deleteUser(url.id)>

    <cfcontent type="application/json" reset="true">
       <cfoutput>
        {"status":"success", "message":"User Deleted"}
       </cfoutput>
    <cfabort>  

</cfif>


<!-- UPDATE USER (Normal Form Submit) -->
<cfif structKeyExists(form, "action") AND form.action EQ "update">

    <cfset first_name = trim(form.first_name)>
    <cfset last_name = trim(form.last_name)>
    <cfset email = trim(form.email)>

    <cfset baseUrl = "../index.cfm?page=dashboard&section=users">

    <cfif len(first_name) LT 3>
        <cfcontent type="application/json" reset="true">
          <cfoutput>
          {"status":"error","message":"First name must be at least 3 characters"}
          </cfoutput>
          <cfabort>

    <cfelseif len(first_name) GT 100>
        <cfcontent type="application/json" reset="true">
           <cfoutput>
           {"status":"error","message":"First name max 100 characters"}
           </cfoutput>
           <cfabort>

    <cfelseif len(last_name) LT 1>
        <cfcontent type="application/json" reset="true">
          <cfoutput>
          {"status":"error","message":"Last name required"}
          </cfoutput>
          <cfabort>
          
    <cfelseif len(last_name) GT 100>
        <cfcontent type="application/json" reset="true">
          <cfoutput>
          {"status":"error","message":"Last name max 100 characters"}
          </cfoutput>
          <cfabort>

    <cfelseif NOT isValid("email", email)>
        <cfcontent type="application/json" reset="true">
          <cfoutput>
          {"status":"error","message":"Invalid email format"}
          </cfoutput>
          <cfabort>

    <cfelseif len(email) GT 100>
        <cfcontent type="application/json" reset="true">
          <cfoutput>
          {"status":"error","message":"email too long"}
          </cfoutput>
          <cfabort>

    <cfelse>

        <cfset userModel = createObject("component","models.User")>
        <cfset userModel.updateUser(form.id, first_name, last_name, email)>

        <cfcontent type="application/json" reset="true">
          <cfoutput>
          {"status":"success","message":"User updated successfully"}
          </cfoutput>
          <cfabort>

    </cfif>

</cfif>


<!-- CREATE USER (AJAX ONLY) -->
<cfif structKeyExists(form,"action") AND form.action EQ "create">

    <cfset userModel = createObject("component","models.User")>

    <cfset first_name = trim(form.first_name)>
    <cfset last_name = trim(form.last_name)>
    <cfset email = trim(form.email)>
    <cfset password = trim(form.password)>
    <cfset confirm = trim(form.confirm)>
    <cfset role_id = val(form.role_id)>

    <!-- Validation -->
    <cfif len(first_name) LT 3>
        <cfcontent type="application/json" reset="true">
        <cfoutput>{"status":"error","message":"First name must be at least 3 characters"}</cfoutput>
        <cfabort>

    <cfelseif len(first_name) GT 100>
        <cfcontent type="application/json" reset="true">
        <cfoutput>{"status":"error","message":"First name max 100 characters"}</cfoutput>
        <cfabort>

    <cfelseif len(last_name) LT 1>
        <cfcontent type="application/json" reset="true">
        <cfoutput>{"status":"error","message":"Last name required"}</cfoutput>
        <cfabort>

    <cfelseif len(last_name) GT 100>
        <cfcontent type="application/json" reset="true">
        <cfoutput>{"status":"error","message":"Last name max 100 characters"}</cfoutput>
        <cfabort>

    <cfelseif NOT isValid("email", email)>
        <cfcontent type="application/json" reset="true">
        <cfoutput>{"status":"error","message":"Invalid email format"}</cfoutput>
        <cfabort>

    <cfelseif len(email) GT 100>
        <cfcontent type="application/json" reset="true">
        <cfoutput>{"status":"error","message":"Email too long"}</cfoutput>
        <cfabort>

    <cfelseif len(password) LT 8 OR len(password) GT 20>
        <cfcontent type="application/json" reset="true">
        <cfoutput>{"status":"error","message":"Password must be 8-20 characters"}</cfoutput>
        <cfabort>

    <cfelseif NOT reFind("^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])", password)>
        <cfcontent type="application/json" reset="true">
        <cfoutput>{"status":"error","message":"Password must contain uppercase, lowercase, number and special character"}</cfoutput>
        <cfabort>

    <cfelseif password NEQ confirm>
        <cfcontent type="application/json" reset="true">
        <cfoutput>{"status":"error","message":"Passwords do not match"}</cfoutput>
        <cfabort>
    </cfif>

    <!-- Create User -->
    <cfset userModel.create_user(
        first_name,
        last_name,
        email,
        password,
        role_id
    )>

    <!-- Success Response -->
    <cfcontent type="application/json" reset="true">
    <cfoutput>{"status":"success","message":"User created successfully"}</cfoutput>
    <cfabort>

</cfif>