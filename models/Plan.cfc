<cfcomponent output="false">

    <cffunction name="getAll" returntype="query">
        <cfquery name="q" datasource="#application.dsn#">
            SELECT id, plan_name, description FROM plans WHERE is_active = 1 ORDER BY id
        </cfquery>
        <cfreturn q>
    </cffunction>

    <cffunction name="getVendorPlan" returntype="query">
        <cfargument name="vendor_id" required="true">
        <cfquery name="q" datasource="#application.dsn#">
            SELECT p.id, p.plan_name
            FROM vendor_plans vp
            JOIN plans p ON vp.plan_id = p.id
            WHERE vp.vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            ORDER BY vp.started_at DESC
            LIMIT 1
        </cfquery>
        <cfreturn q>
    </cffunction>

    <cffunction name="assignPlan" returntype="boolean">
        <cfargument name="vendor_id" required="true">
        <cfargument name="plan_id"   required="true">
        <cftry>
            <!--- Remove existing plan first --->
            <cfquery datasource="#application.dsn#">
                DELETE FROM vendor_plans
                WHERE vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfquery datasource="#application.dsn#">
                INSERT INTO vendor_plans (vendor_id, plan_id)
                VALUES (
                    <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#arguments.plan_id#"   cfsqltype="cf_sql_integer">
                )
            </cfquery>
            <cfreturn true>
        <cfcatch>
            <cfreturn false>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>