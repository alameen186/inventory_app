<cfcomponent output="false">

<cffunction name="create_user" returntype="boolean">

    <cfargument name="first_name">
    <cfargument name="last_name">
    <cfargument name="email">
    <cfargument name="password">
    <cfargument name="role_id">
    <cfargument name="business_name" default="">
    <cfargument name="address" default="">

    <cftry>

        <cfquery datasource="#application.dsn#">
            INSERT INTO users (
                first_name,
                last_name,
                email,
                password,
                role_id,
                business_name,
                address
            )
            VALUES (
                <cfqueryparam value="#arguments.first_name#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.last_name#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.email#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.password#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.role_id#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#arguments.business_name#" cfsqltype="cf_sql_varchar" null="#NOT len(arguments.business_name)#">,
                <cfqueryparam value="#arguments.address#" cfsqltype="cf_sql_varchar" null="#NOT len(arguments.address)#">
            )
        </cfquery>

        <cfreturn true>

    <cfcatch>
        <cfdump var="#cfcatch#">
        <cfabort>
    </cfcatch>

    </cftry>

</cffunction>

<cffunction name="getUserByEmail" returntype="query">

    <cfargument name="email">

    <cfquery name="user" datasource="#application.dsn#">
        SELECT 
            u.id,
            u.first_name,
            u.last_name,
            u.email,
            u.password,
            u.role_id,
            r.role_name
        FROM users u
        JOIN roles r ON u.role_id = r.id
        WHERE u.email = 
        <cfqueryparam value="#arguments.email#" cfsqltype="cf_sql_varchar">
    </cfquery>

    <cfreturn user>

</cffunction>

<cffunction name="getUserWithRole" access="public" returnType="query" output="false">
      <cfargument name="user_id" type="numeric" rquired="true">
        <cfquery name="userData" datasource="#application.dsn#">
          SELECT 
    u.first_name,
    u.last_name,
    u.email,
    u.business_name,
    u.address,
    r.role_name,
    r.description
FROM users u
INNER JOIN roles r ON u.role_id = r.id
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

        AND u.role_id != 6

        <cfif len(searchValue)>
            AND (
                LOWER(u.first_name) LIKE 
                <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">
                OR LOWER(u.last_name) LIKE 
                <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">
                OR LOWER(u.email) LIKE 
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
INNER JOIN roles r ON u.role_id = r.id
WHERE 1=1

AND u.role_id != 6

<cfif len(searchValue)>
    AND (
        LOWER(u.first_name) LIKE <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">
        OR LOWER(u.last_name) LIKE <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">
        OR LOWER(u.email) LIKE <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">
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

   <cffunction name="getAllUsersSimple" returntype="query">
    <cfquery name="users" datasource="#application.dsn#">
        SELECT id, first_name, last_name
        FROM users
        WHERE role_id != 1
        ORDER BY first_name ASC
    </cfquery>
    <cfreturn users>
   </cffunction>


   <cffunction name="getAllVendors" returntype="query">

    <cfargument name="search" default="">
    <cfargument name="sort" default="">
    <cfargument name="page" default="1">
    <cfargument name="limit" default="5">

    <cfset var searchValue = trim(arguments.search)>
    <cfset var offset = (arguments.page - 1) * arguments.limit>

    <cfquery name="vendors" datasource="#application.dsn#">
        SELECT u.*, r.role_name
        FROM users u
        INNER JOIN roles r ON u.role_id = r.id
        WHERE r.role_name = 'vendor'

        <cfif len(searchValue)>
            AND (
                LOWER(u.first_name) LIKE 
                <cfqueryparam value="%#lcase(searchValue)#%">
                OR LOWER(u.last_name) LIKE 
                <cfqueryparam value="%#lcase(searchValue)#%">
                OR LOWER(u.email) LIKE 
                <cfqueryparam value="%#lcase(searchValue)#%">
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

    <cfreturn vendors>
</cffunction>

<cffunction name="getVendorCount" returntype="numeric">

    <cfargument name="search" default="">

    <cfset var searchValue = trim(arguments.search)>

    <cfquery name="q" datasource="#application.dsn#">
        SELECT COUNT(*) as total
        FROM users u
        INNER JOIN roles r ON u.role_id = r.id
        WHERE r.role_name = 'vendor'

        <cfif len(searchValue)>
            AND (
                LOWER(u.first_name) LIKE <cfqueryparam value="%#lcase(searchValue)#%">
                OR LOWER(u.last_name) LIKE <cfqueryparam value="%#lcase(searchValue)#%">
                OR LOWER(u.email) LIKE <cfqueryparam value="%#lcase(searchValue)#%">
            )
        </cfif>
    </cfquery>

    <cfreturn q.total>
</cffunction>

</cfcomponent>