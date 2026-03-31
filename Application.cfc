<cfcomponent output="false">

      <cfset this.name = "inventory_app_v1">
      <cfset this.sessionManagement = true>
      <cfset this.sessionTimeout = createTimeSpan(0, 0, 30, 0)>

      <cfset this.dsn ="inventory_app">

    <cffunction name="onApplicationStart" returntype="boolean" output="false">
      <cfset application.dsn = this.dsn>
      <cfreturn true>
    </cffunction>

</cfcomponent>