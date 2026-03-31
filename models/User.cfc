<cfcomponent output="false">

   <cffunction name="create_user" access="public" returntype="boolean" output="false">
     <cfargument name="first_name" type="string" required="true">
     <cfargument name="last_name" type="string" required="true">
     <cfargument name="email" type="string" required="true">
     <cfargument name="password" type="string" required="true">
     <cfargument name="role_id" type="numeric" required="true">

    <Cftry>
         <cfquery datasource="#application.dsn#">
           INSERT INTO users (first_name, last_name, email, password, role_id)
           VALUES(
             <cfqueryparam value="#arguments.first_name#" cfsqltype="cf_sql_varchar">,
             <cfqueryparam value="#arguments.last_name#" cfsqltype="cf_sql_varchar">,
             <cfqueryparam value="#arguments.email#" cfsqltype="cf_sql_varchar">,
             <cfqueryparam value="#arguments.password#" cfsqltype="cf_sql_varchar">,
             <cfqueryparam value="#arguments.role_id#" cfsqltype="cf_sql_integer">
           )   
         </cfquery>
           <cfreturn true>
    <cfcatch>
      <cfdump var="#cfcatch#">
      <cfabort>
    </cfcatch>      
    </Cftry> 
   </cffunction>

   <cffunction name="getUserByEmail" access="public" returntype="query" output="false">
     <cfargument name="email" type="string" required="true">
     <cfquery name="userQuery" datasource="#application.dsn#">
       SELECT * FROM users
       WHERE email = <cfqueryparam value="#arguments.email#" cfsqltype="cf_sql_varchar">
     </cfquery>

     <cfreturn userQuery>
   </cffunction>

</cfcomponent>