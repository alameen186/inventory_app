<cfcomponent output="false">

    <cffunction name="createSchedule" returntype="boolean">
        <cfargument name="vendor_id"    required="true">
        <cfargument name="customer_id"  required="true">
        <cfargument name="start_date"   required="true">
        <cfargument name="day_of_month" required="true">
        <cfargument name="items"        required="true">

        <cftry>
            <cfloop list="#arguments.items#" delimiters="|" index="item">
                <cfset var pid = val(listFirst(item,":"))>
                <cfset var qty = val(listLast(item,":"))>
                <cfif pid LTE 0 OR qty LTE 0><cfcontinue></cfif>

                <cfquery datasource="#application.dsn#">
                    INSERT INTO scheduled_orders
                        (vendor_id, product_id, quantity,
                         customer_id, start_date, day_of_month, is_active)
                    VALUES (
                        <cfqueryparam value="#arguments.vendor_id#"    cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#pid#"                     cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#qty#"                     cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#arguments.customer_id#"  cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#arguments.start_date#"   cfsqltype="cf_sql_date">,
                        <cfqueryparam value="#arguments.day_of_month#" cfsqltype="cf_sql_tinyint">,
                        1
                    )
                </cfquery>
            </cfloop>
            <cfreturn true>
        <cfcatch>
            <cfreturn false>
        </cfcatch>
        </cftry>
    </cffunction>


    <cffunction name="toggleSchedule" returntype="boolean">
        <cfargument name="id"        required="true">
        <cfargument name="vendor_id" required="true">
        <cfargument name="status"    required="true">
        <cftry>
            <cfquery datasource="#application.dsn#">
                UPDATE scheduled_orders
                SET is_active = <cfqueryparam value="#arguments.status#" cfsqltype="cf_sql_tinyint">
                WHERE id        = <cfqueryparam value="#arguments.id#"        cfsqltype="cf_sql_integer">
                AND   vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfreturn true>
        <cfcatch>
            <cfreturn false>
        </cfcatch>
        </cftry>
    </cffunction>


    <!--- PRODUCTION: runs once per day, no time check needed --->
    <cffunction name="getSchedulesDueToday" returntype="query">
        <cfquery name="q" datasource="#application.dsn#">
            SELECT s.*
            FROM scheduled_orders s
            WHERE s.is_active    = 1
            AND   DAY(CURDATE()) = s.day_of_month
            AND   s.start_date  <= CURDATE()
            AND NOT EXISTS (
                SELECT 1 FROM scheduled_order_log l
                WHERE l.scheduled_order_id = s.id
                AND   l.run_date           = CURDATE()
                AND   l.status             = 'success'
            )
        </cfquery>
        <cfreturn q>
    </cffunction>


    <!--- TESTING: bypass already-ran check --->
    <cffunction name="getSchedulesDueTodayForTesting" returntype="query">
        <cfquery name="q" datasource="#application.dsn#">
            SELECT s.*
            FROM scheduled_orders s
            WHERE s.is_active    = 1
            AND   DAY(CURDATE()) = s.day_of_month
            AND   s.start_date  <= CURDATE()
        </cfquery>
        <cfreturn q>
    </cffunction>


    <cffunction name="logRun" returntype="void">
        <cfargument name="scheduled_order_id" required="true">
        <cfargument name="order_id"           required="false" default="">
        <cfargument name="status"             required="true">
        <cfargument name="notes"              required="false" default="">

        <cfquery datasource="#application.dsn#">
            INSERT INTO scheduled_order_log
                (scheduled_order_id, order_id, run_date, status, notes)
            VALUES (
                <cfqueryparam value="#arguments.scheduled_order_id#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#arguments.order_id#"           cfsqltype="cf_sql_integer"
                    null="#NOT isNumeric(arguments.order_id)#">,
                CURDATE(),
                <cfqueryparam value="#arguments.status#"  cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.notes#"   cfsqltype="cf_sql_varchar">
            )
        </cfquery>
    </cffunction>


    <cffunction name="getByVendor" returntype="query">
        <cfargument name="vendor_id" required="true">
        <cfargument name="search"    required="false" default="">
        <cfargument name="sort"      required="false" default="">
        <cfargument name="page"      required="false" default="1">
        <cfargument name="limit"     required="false" default="10">

        <cfset var offset = (arguments.page - 1) * arguments.limit>

        <cfquery name="q" datasource="#application.dsn#">
            SELECT
                s.id,
                s.product_id,
                s.quantity,
                s.start_date,
                s.day_of_month,
                s.is_active,
                s.created_at,
                p.product_name,
                CONCAT(u.first_name,' ',u.last_name) AS customer_name
            FROM scheduled_orders s
            JOIN products p ON s.product_id  = p.id
            JOIN users    u ON s.customer_id = u.id
            WHERE s.vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">

            <cfif len(trim(arguments.search))>
                AND (
                    p.product_name LIKE
                        <cfqueryparam value="%#trim(arguments.search)#%" cfsqltype="cf_sql_varchar">
                    OR CONCAT(u.first_name,' ',u.last_name) LIKE
                        <cfqueryparam value="%#trim(arguments.search)#%" cfsqltype="cf_sql_varchar">
                )
            </cfif>

            <cfif arguments.sort EQ "product_az">
                ORDER BY p.product_name ASC
            <cfelseif arguments.sort EQ "product_za">
                ORDER BY p.product_name DESC
            <cfelseif arguments.sort EQ "qty_low">
                ORDER BY s.quantity ASC
            <cfelseif arguments.sort EQ "qty_high">
                ORDER BY s.quantity DESC
            <cfelseif arguments.sort EQ "day_asc">
                ORDER BY s.day_of_month ASC
            <cfelse>
                ORDER BY s.created_at DESC
            </cfif>

            LIMIT  <cfqueryparam value="#arguments.limit#"  cfsqltype="cf_sql_integer">
            OFFSET <cfqueryparam value="#offset#"           cfsqltype="cf_sql_integer">
        </cfquery>

        <cfreturn q>
    </cffunction>


    <cffunction name="getByVendorCount" returntype="numeric">
        <cfargument name="vendor_id" required="true">
        <cfargument name="search"    required="false" default="">

        <cfquery name="q" datasource="#application.dsn#">
            SELECT COUNT(*) AS total
            FROM scheduled_orders s
            JOIN products p ON s.product_id  = p.id
            JOIN users    u ON s.customer_id = u.id
            WHERE s.vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">

            <cfif len(trim(arguments.search))>
                AND (
                    p.product_name LIKE
                        <cfqueryparam value="%#trim(arguments.search)#%" cfsqltype="cf_sql_varchar">
                    OR CONCAT(u.first_name,' ',u.last_name) LIKE
                        <cfqueryparam value="%#trim(arguments.search)#%" cfsqltype="cf_sql_varchar">
                )
            </cfif>
        </cfquery>

        <cfreturn q.total>
    </cffunction>

</cfcomponent>