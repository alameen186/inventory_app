<cfcomponent output="false">

    <cfset this.name            = "inventory_app_v1">
    <cfset this.sessionManagement = true>
    <cfset this.sessionTimeout  = createTimeSpan(0, 0, 30, 0)>
    <cfset this.dsn             = "inventory_app">

    <cffunction name="onApplicationStart" returntype="boolean" output="false">
        <cfset application.dsn             = this.dsn>
        <cfset application.jwtSecret       = "inv@App$SecretKey!2025XyZ">
        <cfset application.schedulerSecret = "Sch3d$ecr3t!Key99">

        <cfschedule
            action    = "update"
            task      = "DailyOrderScheduler"
            operation = "HTTPRequest"
            url       = "http://inventory.local:8081/tasks/runScheduler.cfm?token=Sch3d$ecr3t!Key99"
            startDate = "#dateFormat(now(),'yyyy-mm-dd')#"
            startTime = "00:00:00"
            interval  = "daily">

        <cfreturn true>
    </cffunction>

    <cffunction name="onRequestStart" returntype="boolean" output="false">
        <cfif NOT structKeyExists(application, "jwtSecret")>
            <cfset application.jwtSecret = "inv@App$SecretKey!2025XyZ">
        </cfif>
        <cfif NOT structKeyExists(application, "dsn")>
            <cfset application.dsn = this.dsn>
        </cfif>
        <cfif NOT structKeyExists(application, "schedulerSecret")>
            <cfset application.schedulerSecret = "Sch3d$ecr3t!Key99">
        </cfif>
        <cfreturn true>
    </cffunction>

</cfcomponent>