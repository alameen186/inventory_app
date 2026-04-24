<cfcomponent output="false">
   <cffunction  name="jsonResponse" access="private" returntype="void" output="true">
        <cfargument name="success" type="boolean" required="true">
        <cfargument name="message" type="string" default="">
        <cfargument name="data" type="any" default="">
        <cfargument name="redirect" type="string" default="">

         <cfset var res = {
            "success"  : arguments.success,
            "message"  : arguments.message,
            "data"     : arguments.data,
            "redirect" : arguments.redirect
        }>

        <cfcontent type="application/json; charset=utf-8" reset="true">
        <cfoutput>#serializeJSON(res)#</cfoutput>
   </cffunction>

   <cffunction  name="signup" access="remote" returntype="void" output="true" httpMethod="POST">

        <cfset var userModel = createObject("component", "models.User")>

        <cftry>
            <cfset var first_name    = trim(form.first_name)>
            <cfset var last_name     = trim(form.last_name)>
            <cfset var email         = trim(form.email)>
            <cfset var password      = trim(form.password)>
            <cfset var confirm       = trim(form.confirm_password)>
            <cfset var role_id       = val(form.role_id)>
            <cfset var business_name = structKeyExists(form,"business_name") ? trim(form.business_name) : "">
            <cfset var address       = structKeyExists(form,"address") ? trim(form.address) : "">

            <!--- Validations --->
            <cfif NOT role_id>
                <cfreturn jsonResponse(false, "Please select a role")>
            </cfif>

            <cfif role_id EQ 3 AND business_name EQ "">
                <cfreturn jsonResponse(false, "Business name is required for vendors")>
            </cfif>

            <cfif password NEQ confirm>
                <cfreturn jsonResponse(false, "Passwords do not match")>
            </cfif>

            <!--- Email duplicate check --->
            <cfset var existing = userModel.getUserByEmail(email)>
            <cfif existing.recordCount GT 0>
                <cfreturn jsonResponse(false, "Email already registered")>
            </cfif>

            <!--- Hash & create --->
            <cfset var hashed = hash(password, "SHA-256")>
            <cfset var created = userModel.create_user(
                first_name, last_name, email,
                hashed, role_id, business_name, address
            )>

            <cfif created>
                <cfreturn jsonResponse(
                    true,
                    "Signup successful! Please login.",
                    "",
                    "index.cfm?page=auth&tab=login"
                )>
            <cfelse>
                <cfreturn jsonResponse(false, "Signup failed. Try again.")>
            </cfif>

        <cfcatch>
            <cfreturn jsonResponse(false, "Server error: #cfcatch.message#")>
        </cfcatch>
        </cftry>

   </cffunction>

   <cffunction name="login" access="remote" returntype="void" output="true" httpMethod="POST">

        <cfset var userModel = createObject("component", "models.User")>
        <cfset var authModel = createObject("component", "models.Auth")>

        <cftry>
            <cfset var email    = trim(form.email)>
            <cfset var password = trim(form.password)>

            <cfset var user   = userModel.getUserByEmail(email)>
            <cfset var result = authModel.loginUser(user, password)>

            <cfif result.success>
                <cfset session.user_id    = result.user.id>
                <cfset session.user_email = result.user.email>
                <cfset session.role_id    = result.user.role_id>
                <cfset session.role_name  = result.user.role_name>

                <cfreturn jsonResponse(
                    true,
                    "Login successful",
                    "",
                    "index.cfm?page=dashboard"
                )>
            <cfelse>
                <cfreturn jsonResponse(false, result.message)>
            </cfif>

        <cfcatch>
            <cfreturn jsonResponse(false, "Server error: #cfcatch.message#")>
        </cfcatch>
        </cftry>

    </cffunction>
</cfcomponent>