<cfcomponent output="false">

    <cfset this.name = "inventory_app_v1">
    <cfset this.sessionManagement = true>
    <cfset this.sessionTimeout = createTimeSpan(0, 0, 30, 0)>
    <cfset this.dsn = "inventory_app">

    <cffunction name="onApplicationStart" returntype="boolean" output="false">
        <cfset application.dsn = this.dsn>
        <cfset application.jwtSecret = "inv@App$SecretKey!2025XyZ">
        <cfreturn true>
    </cffunction>

    <!--- ADD THIS — runs on every request, fills gap if app already running --->
    <cffunction name="onRequestStart" returntype="boolean" output="false">
        <cfif NOT structKeyExists(application, "jwtSecret")>
            <cfset application.jwtSecret = "inv@App$SecretKey!2025XyZ">
        </cfif>
        <cfif NOT structKeyExists(application, "dsn")>
            <cfset application.dsn = this.dsn>
        </cfif>
        <cfreturn true>
    </cffunction>

</cfcomponent>