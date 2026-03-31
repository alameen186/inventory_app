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

   <cffunction name="getUserWithRole" access="public" returnType="query" output="false">
      <cfargument name="user_id" type="numeric" rquired="true">
        <cfquery name="userData" datasource="#application.dsn#">
           SELECT 
             u.first_name,
             u.last_name,
             u.email,
             r.role_name,
             r.description
           FROM users u
           INNER JOIN roles r ON u.role_id=r.id
           WHERE u.id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
        </cfquery>
      <cfreturn userData>   
   </cffunction>

</cfcomponent>