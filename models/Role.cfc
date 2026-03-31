<cfcomponent output="false">
   <cffunction name="getAllRoles" access="public" returntype="query" output="false">
     <cfquery name="roles" datasource = "#application.dsn#">
       SELECT * FROM roles
     </cfquery>

   <cfreturn roles>  
   </cffunction>

</cfcomponent>