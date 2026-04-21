<cfset userModel = createObject("component", "models.User")>
<cfset authModel = createObject("component", "models.Auth")>

<cfset message = "">
<cfset success = false>

<cfif structKeyExists(form, "action")>
  <cfset action = form.action>
<cfelse>
  <cfset action="" > 
</cfif>

<!--- SIGNUP --->
<cfif action EQ "signup">

<cfset first_name = trim(form.first_name)>
<cfset last_name = trim(form.last_name)>
<cfset email = trim(form.email)>
<cfset password = trim(form.password)>
<cfset confirm = trim(form.confirm_password)>
<cfset role_id = val(form.role_id)>
<cfset business_name = structKeyExists(form,"business_name") ? trim(form.business_name) : "">
<cfset address = structKeyExists(form,"address") ? trim(form.address) : "">

<!-- BASIC VALIDATION -->
<cfif NOT role_id>
    <cflocation url="../index.cfm?page=auth&message=Select role&type=error&tab=signup" addtoken="false">
    <cfabort>
</cfif>

<!-- VENDOR VALIDATION -->
<cfif business_name EQ "" AND role_id EQ 3>
    <cflocation url="../index.cfm?page=auth&message=Shop name required&type=error&tab=signup" addtoken="false">
    <cfabort>
</cfif>

<!-- EMAIL CHECK -->
<cfset existingUser = userModel.getUserByEmail(email)>

<cfif existingUser.recordCount GT 0>
    <cflocation url="../index.cfm?page=auth&message=Email already exists&type=error&tab=signup" addtoken="false">
    <cfabort>
</cfif>

<!-- PASSWORD -->
<cfif password NEQ confirm>
    <cflocation url="../index.cfm?page=auth&message=Password mismatch&type=error&tab=signup" addtoken="false">
    <cfabort>
</cfif>

<cfset hashedPassword = hash(password, "SHA-256")>

<!-- CREATE USER -->
<cfset isCreated = userModel.create_user(
    first_name,
    last_name,
    email,
    hashedPassword,
    role_id,
    business_name,
    address
)>

<cfif isCreated>

    <cfif role_id EQ 3>

        <cfquery datasource="#application.dsn#">
            INSERT INTO vendor_details (user_id, shop_name)
            VALUES (
                (SELECT id FROM users WHERE email = 
                    <cfqueryparam value="#email#" cfsqltype="cf_sql_varchar">
                ORDER BY id DESC LIMIT 1),
                <cfqueryparam value="#shop_name#" cfsqltype="cf_sql_varchar">
            )
        </cfquery>

    </cfif>

    <cflocation url="../index.cfm?page=auth&message=Signup successful&type=success&tab=login" addtoken="false">
    <cfabort>

<cfelse>

    <cflocation url="../index.cfm?page=auth&message=Signup failed&type=error" addtoken="false">
    <cfabort>

</cfif>

</cfif>

<!--- login --->

<cfif action EQ "login">

  <cfset email = trim(form.email)>
  <cfset password = trim(form.password)>

  <cfset user = userModel.getUserByEmail(email)>
  
  <cfset result = authModel.loginUser(user, password)>

  <cfif result.success>
    <cfset session.user_id = result.user.id>
    <cfset session.user_email = result.user.email>
    <cfset session.role_id = result.user.role_id>
    <cfset session.role_name = result.user.role_name>

    <cflocation url="../index.cfm?page=dashboard" addtoken="false">
    <cfabort>
  <cfelse>
     <cflocation url="../index.cfm?page=auth&message=#urlEncodedFormat(result.message)#&type=error" addtoken="false">
    <cfabort>  
  </cfif>
  
</cfif>