<cfcomponent output="false">
 
      <cffunction name="verifyPassword" access="public" returntype="boolean" output="false">
            <cfargument name="inputPassword" type="string" required="true">
            <cfargument name="storedPassword" type="string" required="true">

            <cfset hashedInput = hash(arguments.inputPassword, "SHA-256")>

            <cfif hashedInput EQ storedPassword>
                <cfreturn true>
            <cfelse>
                <cfreturn false>
            </cfif>
      </cffunction>

      <cffunction name="loginUser" access="public" returntype="struct" output="false">
        <cfargument name="userQuery" type="query" required="true">
        <cfargument name="password" type="string" required="true">

        <cfset result={success=false, message="",user={}}>

        <cfif arguments.userQuery.recordCount EQ 0>
           <cfset result.message = "Email Not Found">
           <cfreturn result>
        </cfif>

        <cfset var dbPassword = arguments.userQuery.password[1]>
        <cfif verifyPassword(arguments.password,dbPassword)>
           <cfset result.success = true>
           <cfset result.user = {
                id = arguments.userQuery.id[1],
                email = arguments.userQuery.email[1],
                role_id = arguments.userQuery.role_id[1]
            }>        
        <cfelse>
         <cfset result.message = "Invalid password">   
        </cfif>

      <cfreturn result>  

      </cffunction>

</cfcomponent>