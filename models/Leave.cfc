<cfcomponent output="false">

    <cffunction name="getTypes" returntype="query" output="false">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT id, type_name, max_days FROM leave_types ORDER BY id
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <cffunction name="applyLeave" returntype="struct" output="false">
        <cfargument name="vendor_id"     type="numeric" required="true">
        <cfargument name="staff_id"      type="numeric" required="true">
        <cfargument name="leave_type_id" type="numeric" required="true">
        <cfargument name="from_date"     type="string"  required="true">
        <cfargument name="to_date"       type="string"  required="true">
        <cfargument name="total_days"    type="numeric" required="true">
        <cfargument name="reason"        type="string"  default="">

        <cftry>
            <cfquery datasource="#application.dsn#">
                INSERT INTO staff_leaves (
                    vendor_id, staff_id, leave_type_id,
                    from_date, to_date, total_days, reason
                ) VALUES (
                    <cfqueryparam value="#arguments.vendor_id#"     cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#arguments.staff_id#"      cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#arguments.leave_type_id#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#arguments.from_date#"     cfsqltype="cf_sql_date">,
                    <cfqueryparam value="#arguments.to_date#"       cfsqltype="cf_sql_date">,
                    <cfqueryparam value="#arguments.total_days#"    cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#arguments.reason#"        cfsqltype="cf_sql_varchar" null="#NOT len(trim(arguments.reason))#">
                )
            </cfquery>
            <cfreturn { success: true }>
        <cfcatch>
            <cfreturn { success: false, message: cfcatch.message }>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getLeaves" returntype="query" output="false">
        <cfargument name="vendor_id"  type="numeric" required="true">
        <cfargument name="staff_id"   type="string"  default="">
        <cfargument name="status"     type="string"  default="">
        <cfargument name="date_from"  type="string"  default="">
        <cfargument name="date_to"    type="string"  default="">

        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT
                sl.id,
                s.full_name      AS staff_name,
                s.position,
                s.department,
                lt.type_name     AS leave_type,
                sl.from_date,
                sl.to_date,
                sl.total_days,
                sl.reason,
                sl.status,
                sl.reject_reason,
                sl.created_at
            FROM staff_leaves sl
            JOIN staff       s  ON s.id  = sl.staff_id
            JOIN leave_types lt ON lt.id = sl.leave_type_id
            WHERE sl.vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            <cfif isNumeric(arguments.staff_id) AND val(arguments.staff_id) GT 0>
                AND sl.staff_id = <cfqueryparam value="#arguments.staff_id#" cfsqltype="cf_sql_integer">
            </cfif>
            <cfif len(trim(arguments.status))>
                AND sl.status = <cfqueryparam value="#arguments.status#" cfsqltype="cf_sql_varchar">
            </cfif>
            <cfif len(trim(arguments.date_from))>
                AND sl.from_date >= <cfqueryparam value="#arguments.date_from#" cfsqltype="cf_sql_date">
            </cfif>
            <cfif len(trim(arguments.date_to))>
                AND sl.to_date <= <cfqueryparam value="#arguments.date_to#" cfsqltype="cf_sql_date">
            </cfif>
            ORDER BY sl.created_at DESC
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <!--- approve or reject --->
    <cffunction name="updateStatus" returntype="struct" output="false">
        <cfargument name="id"            type="numeric" required="true">
        <cfargument name="vendor_id"     type="numeric" required="true">
        <cfargument name="status"        type="string"  required="true">
        <cfargument name="reject_reason" type="string"  default="">

        <cftry>
            <cfquery datasource="#application.dsn#">
                UPDATE staff_leaves
                SET status        = <cfqueryparam value="#arguments.status#"        cfsqltype="cf_sql_varchar">,
                    reject_reason = <cfqueryparam value="#arguments.reject_reason#" cfsqltype="cf_sql_varchar" null="#NOT len(trim(arguments.reject_reason))#">
                WHERE id        = <cfqueryparam value="#arguments.id#"        cfsqltype="cf_sql_integer">
                AND   vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfreturn { success: true }>
        <cfcatch>
            <cfreturn { success: false, message: cfcatch.message }>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- leave balance --->
    <cffunction name="getBalance" returntype="query" output="false">
        <cfargument name="staff_id"  type="numeric" required="true">
        <cfargument name="vendor_id" type="numeric" required="true">

        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT
                lt.type_name,
                lt.max_days,
                COALESCE(SUM(CASE WHEN sl.status = 'approved' THEN sl.total_days ELSE 0 END), 0) AS used_days,
                lt.max_days - COALESCE(SUM(CASE WHEN sl.status = 'approved' THEN sl.total_days ELSE 0 END), 0) AS remaining_days
            FROM leave_types lt
            LEFT JOIN staff_leaves sl
                ON sl.leave_type_id = lt.id
                AND sl.staff_id     = <cfqueryparam value="#arguments.staff_id#"  cfsqltype="cf_sql_integer">
                AND sl.vendor_id    = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
                AND YEAR(sl.from_date) = YEAR(CURDATE())
            GROUP BY lt.id, lt.type_name, lt.max_days
            ORDER BY lt.id
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <!--- Add this function to your existing Leave.cfc --->

<cffunction name="getDeptConflictInfo" returntype="struct" output="false">
    <cfargument name="leave_id"  type="numeric" required="true">
    <cfargument name="vendor_id" type="numeric" required="true">

    <!--- Get this leave request's staff department and dates --->
    <cfquery name="local.lq" datasource="#application.dsn#">
        SELECT sl.from_date, sl.to_date, s.department
        FROM staff_leaves sl
        JOIN staff s ON s.id = sl.staff_id
        WHERE sl.id       = <cfqueryparam value="#arguments.leave_id#"  cfsqltype="cf_sql_integer">
        AND   s.vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
    </cfquery>

    <!--- No dept assigned — skip conflict check entirely --->
    <cfif local.lq.recordCount EQ 0 OR NOT len(trim(local.lq.department))>
        <cfreturn { conflict_count: 0, names: "", department: "", max_on_leave: 0, triggered: false }>
    </cfif>

    <!--- Get this vendor's max_on_leave setting for this department --->
    <!--- Default to 1 if vendor hasn't created a departments record yet --->
    <cfquery name="local.dq" datasource="#application.dsn#">
        SELECT max_on_leave
        FROM departments
        WHERE vendor_id = <cfqueryparam value="#arguments.vendor_id#"      cfsqltype="cf_sql_integer">
        AND   name      = <cfqueryparam value="#trim(local.lq.department)#" cfsqltype="cf_sql_varchar">
        LIMIT 1
    </cfquery>

    <cfset var maxOnLeave = local.dq.recordCount ? local.dq.max_on_leave : 1>

    <!--- Count already approved overlapping leaves in same dept --->
    <cfquery name="local.cq" datasource="#application.dsn#">
        SELECT s.full_name
        FROM staff_leaves sl
        JOIN staff s ON s.id = sl.staff_id
        WHERE s.vendor_id  = <cfqueryparam value="#arguments.vendor_id#"      cfsqltype="cf_sql_integer">
        AND   s.department = <cfqueryparam value="#trim(local.lq.department)#" cfsqltype="cf_sql_varchar">
        AND   sl.status    = 'approved'
        AND   sl.from_date <= <cfqueryparam value="#local.lq.to_date#"         cfsqltype="cf_sql_date">
        AND   sl.to_date   >= <cfqueryparam value="#local.lq.from_date#"       cfsqltype="cf_sql_date">
        AND   sl.id        != <cfqueryparam value="#arguments.leave_id#"       cfsqltype="cf_sql_integer">
    </cfquery>

    <cfset var names = "">
    <cfloop query="local.cq">
        <cfset names = listAppend(names, local.cq.full_name)>
    </cfloop>

    <!--- triggered = true only when already-approved count hits the limit --->
    <cfreturn {
        conflict_count : local.cq.recordCount,
        names          : names,
        department     : local.lq.department,
        max_on_leave   : maxOnLeave,
        triggered      : local.cq.recordCount GTE maxOnLeave
    }>
</cffunction>

</cfcomponent>