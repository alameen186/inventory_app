<cfcomponent output="false">

    <cffunction name="getOrCreateTempUser" returntype="numeric">

        <cfargument name="vendor_id" required="true">
        <cfargument name="first_name" required="true">
        <cfargument name="last_name" required="true">
        <cfargument name="email" required="true">

        <!-- CHECK EXISTING -->
        <cfquery name="qTemp" datasource="#application.dsn#">
            SELECT id 
            FROM temp_users
            WHERE vendor_id = 
                <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            AND email = 
                <cfqueryparam value="#arguments.email#" cfsqltype="cf_sql_varchar">
        </cfquery>

        <cfif qTemp.recordCount GT 0>
            <cfreturn qTemp.id>
        </cfif>

        <!-- INSERT NEW -->
        <cfquery datasource="#application.dsn#">
            INSERT INTO temp_users (
                vendor_id, first_name, last_name, email
            )
            VALUES (
                <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#arguments.first_name#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.last_name#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.email#" cfsqltype="cf_sql_varchar">
            )
        </cfquery>

        <!-- GET NEW ID -->
        <cfquery name="newUser" datasource="#application.dsn#">
            SELECT id FROM temp_users
            WHERE vendor_id = 
                <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            AND email = 
                <cfqueryparam value="#arguments.email#" cfsqltype="cf_sql_varchar">
            ORDER BY id DESC LIMIT 1
        </cfquery>

        <cfreturn newUser.id>

    </cffunction>

    <cffunction name="getRecentTempUsers" returntype="query">

    <cfargument name="vendor_id" required="true">

    <cfquery name="q" datasource="#application.dsn#">
        SELECT id, first_name, last_name, email
        FROM temp_users
        WHERE vendor_id = 
            <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
        ORDER BY id DESC
        LIMIT 10
    </cfquery>

    <cfreturn q>

</cffunction>

</cfcomponent>