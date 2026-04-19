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


<!-- UPDATE USER  -->
<cfif structKeyExists(form, "action") AND form.action EQ "update">

    <cfset first_name = trim(form.first_name)>
    <cfset last_name = trim(form.last_name)>
    <cfset email = trim(form.email)>

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


<!-- CREATE USER  -->
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

<!-- SEARCH -->
<cfif structKeyExists(url,"action") AND url.action EQ "search">

<cfset userModel = createObject("component","models.User")>

<cfparam name="url.search" default="">
<cfparam name="url.sort" default="">
<cfparam name="url.p" default="1">

<cfset users = userModel.getAllUsers(
    search = trim(url.search),
    sort = url.sort,
    page = val(url.p),
    limit = 2
)>

<cfoutput query="users">

<tr id="row_#id#">
<td>#id#</td>
<td>#first_name# #last_name#</td>
<td>#email#</td>
<td>#role_name#</td>

<td>
<button class="btn btn-warning btn-sm editBtn"
data-id="#id#"
data-first="#first_name#"
data-last="#last_name#"
data-email="#email#">Edit</button>

<button class="btn btn-danger btn-sm deleteBtn" data-id="#id#">Delete</button>
</td>
</tr>

</cfoutput>

<cfif users.recordCount EQ 0>
<tr><td colspan="5" class="text-center">No data</td></tr>
</cfif>

<cfabort>
</cfif>