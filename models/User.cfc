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

   <cffunction name="getAllUsers" access="public" returntype="query" output="false">
     <cfargument name="search" default="">
     <cfargument name="sort" default="">
     <cfargument name="page" default="1">
     <cfargument name="limit" default="2">

     <cfset var searchValue = trim(arguments.search)>
     <cfset var offset = (arguments.page - 1) * arguments.limit>
    
    <cfquery name="users" datasource="#application.dsn#">
        SELECT u.*, r.role_name
        FROM users u
        INNER JOIN roles r ON u.role_id = r.id
         WHERE 1=1

        <cfif len(searchValue)>
            AND (
                LOWER(u.first_name) LIKE 
                <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">

                OR LOWER(u.last_name) LIKE 
                <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">

                OR LOWER(u.email) LIKE 
                <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">

                OR LOWER(r.role_name) LIKE 
                <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">
            )
        </cfif>

        <cfif arguments.sort EQ "a_z">
            ORDER BY u.first_name ASC
        <cfelseif arguments.sort EQ "z_a">
            ORDER BY u.first_name DESC
        <cfelse>
            ORDER BY u.id DESC
        </cfif>

        LIMIT <cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer">
        OFFSET <cfqueryparam value="#offset#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfreturn users>
   </cffunction>

   <cffunction name="getUserCount" returntype="numeric">

    <cfargument name="search" default="">

    <cfset var searchValue = trim(arguments.search)>

    <cfquery name="result" datasource="#application.dsn#">
        SELECT COUNT(*) as total
        FROM users u
        WHERE 1=1

        <cfif len(searchValue)>
            AND (
                LOWER(u.first_name) LIKE 
                <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">

                OR LOWER(u.last_name) LIKE 
                <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">

                OR LOWER(u.email) LIKE 
                <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">

                OR LOWER(r.role_name) LIKE 
                <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">
            )
        </cfif>
    </cfquery>

    <cfreturn result.total>

</cffunction>

   <cffunction name="deleteUser" access="public" returntype="void" output="false">
       <cfargument name="id" type="numeric" required="true">
       <cfquery datasource="#application.dsn#">
       DELETE FROM users
       where id=<cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
       </cfquery>
   </cffunction>

   <cffunction name="updateUser" output="false">
       <cfargument name="id" type="numeric" required="true">
       <cfargument name="first_name" type="string" required="true">
       <cfargument name="last_name" type="string" required="true">
       <cfargument name="email" type="string" required="true">

       <cfquery datasource="#application.dsn#">
        UPDATE users
        SET first_name = <cfqueryparam value="#arguments.first_name#" cfsqltype="cf_sql_varchar">,
            last_name = <cfqueryparam value="#arguments.last_name#" cfsqltype="cf_sql_varchar">,
            email = <cfqueryparam value="#arguments.email#" cfsqltype="cf_sql_varchar">
        WHERE id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
    </cfquery>
   </cffunction>

</cfcomponent>