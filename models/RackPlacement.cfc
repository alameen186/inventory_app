<cfcomponent output="false">

    <cffunction name="placeProduct" returntype="struct" output="false">
        <cfargument name="product_id"   type="numeric" required="true">
        <cfargument name="rack_face_id" type="numeric" required="true">
        <cftry>
            <cfquery name="local.face" datasource="#application.dsn#">
                SELECT rf.capacity, COUNT(prp.id) AS used_slots
                FROM rack_faces rf
                LEFT JOIN product_rack_placement prp ON prp.rack_face_id = rf.id
                WHERE rf.id = <cfqueryparam value="#arguments.rack_face_id#" cfsqltype="cf_sql_integer">
                GROUP BY rf.capacity
            </cfquery>
            <cfif local.face.recordCount EQ 0>
                <cfreturn {success:false, message:"Face not found"}>
            </cfif>
            <cfif local.face.used_slots GTE local.face.capacity>
                <cfreturn {success:false, message:"This face is full. No slots available."}>
            </cfif>
            <cfquery name="local.existing" datasource="#application.dsn#">
                SELECT id FROM product_rack_placement
                WHERE product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfif local.existing.recordCount GT 0>
                <cfreturn {success:false, message:"Product is already placed in a rack. Remove it first or use Swap."}>
            </cfif>
            <cfquery datasource="#application.dsn#">
                INSERT INTO product_rack_placement (product_id, rack_face_id)
                VALUES (
                    <cfqueryparam value="#arguments.product_id#"   cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#arguments.rack_face_id#" cfsqltype="cf_sql_integer">
                )
            </cfquery>
            <cfreturn {success:true}>
        <cfcatch>
            <cfreturn {success:false, message:cfcatch.message}>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="removeProduct" returntype="boolean" output="false">
        <cfargument name="product_id" type="numeric" required="true">
        <cftry>
            <cfquery datasource="#application.dsn#">
                DELETE FROM product_rack_placement
                WHERE product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfreturn true>
        <cfcatch>
            <cfreturn false>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- Check how many swaps vendor has done this calendar month --->
    <cffunction name="getMonthlySwapCount" returntype="numeric" output="false">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT COUNT(*) AS swap_count
            FROM swap_log
            WHERE vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            AND   YEAR(swapped_at)  = YEAR(NOW())
            AND   MONTH(swapped_at) = MONTH(NOW())
        </cfquery>
        <cfreturn local.q.swap_count>
    </cffunction>

    <!--- Log a swap --->
    <cffunction name="logSwap" returntype="void" output="false">
        <cfargument name="vendor_id"   type="numeric" required="true">
        <cfargument name="product1_id" type="numeric" required="true">
        <cfargument name="product2_id" type="numeric" required="true">
        <cftry>
            <cfquery datasource="#application.dsn#">
                INSERT INTO swap_log (vendor_id, product1_id, product2_id)
                VALUES (
                    <cfqueryparam value="#arguments.vendor_id#"   cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#arguments.product1_id#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#arguments.product2_id#" cfsqltype="cf_sql_integer">
                )
            </cfquery>
        <cfcatch></cfcatch>
        </cftry>
    </cffunction>

    <!--- Swap with monthly limit check --->
    <cffunction name="swapProducts" returntype="struct" output="false">
        <cfargument name="product1_id" type="numeric" required="true">
        <cfargument name="product2_id" type="numeric" required="true">
        <cfargument name="vendor_id"   type="numeric" required="true">
        <!--- Monthly swap limit --->
        <cfset var SWAP_LIMIT = 3>
        <cftry>
            <!--- Check monthly limit --->
            <cfset var usedThisMonth = getMonthlySwapCount(arguments.vendor_id)>
            <cfif usedThisMonth GTE SWAP_LIMIT>
                <cfreturn {
                    success : false,
                    message : "Monthly swap limit reached. You can only swap " & SWAP_LIMIT & " times per month. Resets on the 1st of next month.",
                    limit_reached : true,
                    swaps_used    : usedThisMonth,
                    swaps_allowed : SWAP_LIMIT
                }>
            </cfif>

            <!--- Get current placements --->
            <cfquery name="local.p1" datasource="#application.dsn#">
                SELECT id, rack_face_id FROM product_rack_placement
                WHERE product_id = <cfqueryparam value="#arguments.product1_id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfquery name="local.p2" datasource="#application.dsn#">
                SELECT id, rack_face_id FROM product_rack_placement
                WHERE product_id = <cfqueryparam value="#arguments.product2_id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfif local.p1.recordCount EQ 0 OR local.p2.recordCount EQ 0>
                <cfreturn {success:false, message:"Both products must be placed in a rack face to swap."}>
            </cfif>

            <!--- Do the swap --->
            <cfquery datasource="#application.dsn#">
                UPDATE product_rack_placement
                SET rack_face_id = <cfqueryparam value="#local.p2.rack_face_id#" cfsqltype="cf_sql_integer">
                WHERE product_id = <cfqueryparam value="#arguments.product1_id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfquery datasource="#application.dsn#">
                UPDATE product_rack_placement
                SET rack_face_id = <cfqueryparam value="#local.p1.rack_face_id#" cfsqltype="cf_sql_integer">
                WHERE product_id = <cfqueryparam value="#arguments.product2_id#" cfsqltype="cf_sql_integer">
            </cfquery>

            <!--- Log this swap --->
            <cfset logSwap(
                vendor_id   = arguments.vendor_id,
                product1_id = arguments.product1_id,
                product2_id = arguments.product2_id
            )>

            <cfset var remaining = SWAP_LIMIT - (usedThisMonth + 1)>
            <cfreturn {
                success       : true,
                swaps_used    : usedThisMonth + 1,
                swaps_allowed : SWAP_LIMIT,
                swaps_remaining : remaining
            }>
        <cfcatch>
            <cfreturn {success:false, message:cfcatch.message}>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getProductPlacement" returntype="query" output="false">
        <cfargument name="product_id" type="numeric" required="true">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT prp.rack_face_id, rf.face_code,
                   r.rack_code, r.rack_name, r.id AS rack_id
            FROM product_rack_placement prp
            JOIN rack_faces rf ON rf.id = prp.rack_face_id
            JOIN racks      r  ON r.id  = rf.rack_id
            WHERE prp.product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <cffunction name="getPlacedProducts" returntype="query" output="false">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT p.id, p.product_name,
                   r.rack_code, r.rack_name,
                   rf.face_code, prp.rack_face_id
            FROM product_rack_placement prp
            JOIN products   p  ON p.id  = prp.product_id
            JOIN rack_faces rf ON rf.id = prp.rack_face_id
            JOIN racks      r  ON r.id  = rf.rack_id
            WHERE p.vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            ORDER BY r.rack_code, rf.face_code, p.product_name
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <!--- Quick product search for vendor dashboard --->
    <cffunction name="searchVendorProducts" returntype="query" output="false">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfargument name="keyword"   type="string"  required="true">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT
                p.id,
                p.product_name,
                p.stock AS stock_quantity,
                r.rack_code,
                r.rack_name,
                rf.face_code,
                CASE
                    WHEN prp.id IS NOT NULL THEN 'Placed'
                    ELSE 'Not Placed'
                END AS placement_status
            FROM products p
            LEFT JOIN product_rack_placement prp ON prp.product_id = p.id
            LEFT JOIN rack_faces rf ON rf.id = prp.rack_face_id
            LEFT JOIN racks      r  ON r.id  = rf.rack_id
            WHERE p.vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            AND   p.product_name LIKE <cfqueryparam value="%#arguments.keyword#%" cfsqltype="cf_sql_varchar">
            ORDER BY p.product_name ASC
            LIMIT 20
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <cffunction name="logSwapAlert" returntype="void" output="false">
        <cfargument name="vendor_id"   type="numeric" required="true">
        <cfargument name="product1_id" type="numeric" required="true">
        <cfargument name="product2_id" type="numeric" required="true">
        <cfset var p1 = min(arguments.product1_id, arguments.product2_id)>
        <cfset var p2 = max(arguments.product1_id, arguments.product2_id)>
        <cftry>
            <cfquery datasource="#application.dsn#">
                INSERT INTO swap_alerts (vendor_id, product1_id, product2_id, alert_count)
                VALUES (
                    <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#p1#"                  cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#p2#"                  cfsqltype="cf_sql_integer">,
                    1
                )
                ON DUPLICATE KEY UPDATE
                    alert_count = alert_count + 1,
                    is_seen     = 0,
                    updated_at  = CURRENT_TIMESTAMP
            </cfquery>
        <cfcatch></cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getSwapAlerts" returntype="query" output="false">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfargument name="threshold" type="numeric" required="false" default="2">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT sa.id, sa.alert_count, sa.is_seen, sa.updated_at,
                   p1.product_name AS product1_name,
                   p2.product_name AS product2_name,
                   r1.rack_code    AS rack1_code,
                   rf1.face_code   AS face1_code,
                   r2.rack_code    AS rack2_code,
                   rf2.face_code   AS face2_code
            FROM swap_alerts sa
            JOIN products p1 ON p1.id = sa.product1_id
            JOIN products p2 ON p2.id = sa.product2_id
            LEFT JOIN product_rack_placement prp1 ON prp1.product_id = sa.product1_id
            LEFT JOIN rack_faces rf1 ON rf1.id = prp1.rack_face_id
            LEFT JOIN racks      r1  ON r1.id  = rf1.rack_id
            LEFT JOIN product_rack_placement prp2 ON prp2.product_id = sa.product2_id
            LEFT JOIN rack_faces rf2 ON rf2.id = prp2.rack_face_id
            LEFT JOIN racks      r2  ON r2.id  = rf2.rack_id
            WHERE sa.vendor_id   = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            AND   sa.alert_count >= <cfqueryparam value="#arguments.threshold#" cfsqltype="cf_sql_integer">
            AND   sa.is_seen     = 0
            ORDER BY sa.alert_count DESC
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <cffunction name="getAlertCount" returntype="numeric" output="false">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfargument name="threshold" type="numeric" required="false" default="2">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT COUNT(*) AS total
            FROM swap_alerts
            WHERE vendor_id   = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            AND   alert_count >= <cfqueryparam value="#arguments.threshold#" cfsqltype="cf_sql_integer">
            AND   is_seen     = 0
        </cfquery>
        <cfreturn local.q.total>
    </cffunction>

    <cffunction name="markAlertSeen" returntype="boolean" output="false">
        <cfargument name="id"        type="numeric" required="true">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cftry>
            <cfquery datasource="#application.dsn#">
                UPDATE swap_alerts
                SET is_seen = 1
                WHERE id        = <cfqueryparam value="#arguments.id#"        cfsqltype="cf_sql_integer">
                AND   vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfreturn true>
        <cfcatch>
            <cfreturn false>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>
