<!--- Initialize Models --->
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

<!--- Validation --->
  <cfif len(first_name) LT 3>
    <cflocation url="../index.cfm?page=auth&message=First name must be at least 3 characters&type=error&tab=signup&first_name=#urlEncodedFormat(first_name)#&last_name=#urlEncodedFormat(last_name)#&email=#urlEncodedFormat(email)#"addtoken="false">
    <cfabort>
    <cfelseif len(first_name) GT 100>
      <cflocation url="../index.cfm?page=auth&message=First name only less than 100 charecters&type=error&tab=signup&first_name=#urlEncodedFormat(first_name)#&last_name=#urlEncodedFormat(last_name)#&email=#urlEncodedFormat(email)#" addtoken="false">
      <cfabort>  
    <cfelseif len(last_name) LT 1>
    <cflocation url="../index.cfm?page=auth&message=Last name must be at least 1 charecters&type=error&tab=signup&first_name=#urlEncodedFormat(first_name)#&last_name=#urlEncodedFormat(last_name)#&email=#urlEncodedFormat(email)#" addtoken="false">
    <cfabort>
    <cfelseif len(last_name) GT 100>  
    <cflocation url="../index.cfm?page=auth&message=Last name only less than 100 charecters&type=error&tab=signup&first_name=#urlEncodedFormat(first_name)#&last_name=#urlEncodedFormat(last_name)#&email=#urlEncodedFormat(email)#" addtoken="false">
    <cfabort>
    <cfelseif NOT isValid("email", email)>
    <cflocation url="../index.cfm?page=auth&message=Invalid email format&type=error&tab=signup&first_name=#urlEncodedFormat(first_name)#&last_name=#urlEncodedFormat(last_name)#&email=#urlEncodedFormat(email)#" addtoken="false">
    <cfabort>
    <cfelseif len(email) GT 100>
    <cflocation url="../index.cfm?page=auth&message=mail too long!!&type=error&tab=signup&first_name=#urlEncodedFormat(first_name)#&last_name=#urlEncodedFormat(last_name)#&email=#urlEncodedFormat(email)#" addtoken="false">
    <cfabort>
    <cfelseif len(password) LT 8 OR len(password) GT 20>
    <cflocation url="../index.cfm?page=auth&message=Invalid email&type=error&tab=signup&first_name=#urlEncodedFormat(first_name)#&last_name=#urlEncodedFormat(last_name)#&email=#urlEncodedFormat(email)#" addtoken="false">
    <cfabort>
    <cfelseif NOT reFind("^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])", password)>
    <cflocation url="../index.cfm?page=auth&message=Password must contain uppercase, lowercase, number, and special character&type=error&tab=signup&first_name=#urlEncodedFormat(first_name)#&last_name=#urlEncodedFormat(last_name)#&email=#urlEncodedFormat(email)#" addtoken="false">
    <cfabort>
    <cfelseif password NEQ confirm>
    <cflocation url="../index.cfm?page=auth&message=password do not match&type=error&tab=signup&first_name=#urlEncodedFormat(first_name)#&last_name=#urlEncodedFormat(last_name)#&email=#urlEncodedFormat(email)#" addtoken="false">
    <cfabort>
      <cfset message = "">

    <cfelse>
      <cfset existingUser = userModel.getUserByEmail(email)>   

      <cfif existingUser.recordCount GT 0>
        <cflocation url="../index.cfm?page=auth&message=Email already exists&type=error&tab=signup" addtoken="false">
        <cfabort>

      <cfelse>
        
       <cfset hashedPassword = hash(password, "SHA-256")>

       <cfset isCreated = userModel.create_user(
        first_name,
        last_name,
        email,
        hashedPassword,
        2
       )>

       <cfif isCreated>
           <cfset success = true>
           <cflocation url="../index.cfm?page=auth&message=Signup successful&type=success&tab=login" addtoken="false">
    <cfabort>
       <cfelse>
           <cflocation url="../index.cfm?page=auth&message=Something went wrong&type=error" addtoken="false">
    <cfabort>    
       </cfif>
    
    </cfif>

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