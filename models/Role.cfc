<cfcomponent output="false">
  
   <cffunction name="getAllRoles" access="public" returntype="query" output="false">
     <cfargument name="search" default="">
     <cfargument name="sort" default="">
     <cfargument name="page" default="1">
     <cfargument name="limit" default="2">

     <cfset var searchValue = trim(arguments.search)>
     <cfset var offset = (arguments.page - 1) * arguments.limit>

     <cfquery name="roles" datasource = "#application.dsn#">
       SELECT r.* FROM roles r
       WHERE 1=1

        <cfif len(searchValue)>
            AND (
                LOWER(r.role_name) LIKE 
                <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">

                OR LOWER(r.description) LIKE 
                <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">
            )
        </cfif>

        <cfif arguments.sort EQ "a_z">
            ORDER BY r.role_name ASC
        <cfelseif arguments.sort EQ "z_a">
            ORDER BY r.role_name DESC
        <cfelse>
            ORDER BY r.id DESC
        </cfif>

        LIMIT <cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer">
        OFFSET <cfqueryparam value="#offset#" cfsqltype="cf_sql_integer">
     </cfquery>

   <cfreturn roles>  
   </cffunction>

   <cffunction name="deleteRole" access="public" returntype="void" output="false">
       <cfargument name="id" type="numeric" required="true">
       <cfquery datasource="#application.dsn#">
       DELETE FROM roles
       where id=<cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
       </cfquery>  
   </cffunction>

   <cffunction name="updateRole" output="false">
    <cfargument name="id" type="numeric">
    <cfargument name="name" type="string">
    <cfargument name="description" type="string">

    <cfquery datasource="#application.dsn#">
        UPDATE roles
        SET role_name = <cfqueryparam value="#arguments.name#" cfsqltype="cf_sql_varchar">,
            description = <cfqueryparam value="#arguments.description#" cfsqltype="cf_sql_varchar">
        WHERE id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
    </cfquery>
</cffunction>

<cffunction name="getRoleCount" returntype="numeric">

    <cfargument name="search" default="">

    <cfset var searchValue = trim(arguments.search)>

    <cfquery name="result" datasource="#application.dsn#">
        SELECT COUNT(*) as total
        FROM roles r
        WHERE 1=1

        <cfif len(searchValue)>
            AND (
                LOWER(r.role_name) LIKE 
                <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">

                OR LOWER(r.description) LIKE 
                <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">
            )
        </cfif>
    </cfquery>

    <cfreturn result.total>

</cffunction>

<cffunction name="getRolesForSignup" returntype="query">

    <cfquery name="roles" datasource="#application.dsn#">
        SELECT id, role_name
        FROM roles
        WHERE role_name IN ('customer','vendor')
        ORDER BY role_name ASC
    </cfquery>

    <cfreturn roles>

</cffunction>
<cffunction name="createRole" access="public" returntype="void" output="false">
    <cfargument name="name"        type="string" required="true">
    <cfargument name="description" type="string" required="true">
    <cfquery datasource="#application.dsn#">
        INSERT INTO roles (role_name, description)
        VALUES (
            <cfqueryparam value="#trim(arguments.name)#"        cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#trim(arguments.description)#" cfsqltype="cf_sql_varchar">
        )
    </cfquery>
</cffunction>


</cfcomponent>