<cfcomponent output="false">
  
   <cffunction name="getAllRoles" access="public" returntype="query" output="false">
     <cfquery name="roles" datasource = "#application.dsn#">
       SELECT * FROM roles
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

</cfcomponent>