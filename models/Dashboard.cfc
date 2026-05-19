    <cfcomponent output="false">

    <cffunction name="getTotalUsers" returntype="numeric">
        <cfquery name="q" datasource="#application.dsn#">
            SELECT COUNT(*) as total FROM users
        </cfquery>
        <cfreturn q.total>
    </cffunction>

    <cffunction name="getTotalCoupons" returntype="numeric">
        <cfquery name="q" datasource="#application.dsn#">
            SELECT COUNT(*) as total FROM coupons
        </cfquery>
        <cfreturn q.total>
    </cffunction>

    <cffunction name="getTotalVendors" returntype="numeric">
        <cfquery name="q" datasource="#application.dsn#">
            SELECT COUNT(*) as total
            FROM users
            WHERE role_id = 6 
        </cfquery>
        <cfreturn q.total>
    </cffunction>




    <!-- VENDOR TOTAL PRODUCTS -->
    <cffunction name="getVendorTotalProducts" returntype="numeric">
        <cfargument name="vendor_id">

        <cfquery name="q" datasource="#application.dsn#">
            SELECT COUNT(*) as total
            FROM products
            WHERE vendor_id =
            <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfreturn q.total>
    </cffunction>

    <!-- VENDOR ORDERS -->
    <cffunction name="getVendorOrdersCount" returntype="numeric">
        <cfargument name="vendor_id">

        <cfquery name="q" datasource="#application.dsn#">
            SELECT COUNT(DISTINCT o.order_group_id) as total
            FROM orders o
            JOIN products p ON o.product_id = p.id
            WHERE p.vendor_id =
            <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfreturn q.total>
    </cffunction>


    <cffunction name="getVendorRevenue" returntype="numeric">
        <cfargument name="vendor_id">

        <cfquery name="q" datasource="#application.dsn#">
            SELECT SUM(o.total_amount) as total
            FROM orders o
            JOIN products p ON o.product_id = p.id
            WHERE p.vendor_id =
            <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfreturn val(q.total)>
    </cffunction>

    <cffunction name="getSlowMovingProducts" returntype="query" output="false">
        <cfargument name="vendor_id"  type="numeric" required="true">
        <cfargument name="days"       type="numeric" required="false" default="30">
        <cfargument name="threshold"  type="numeric" required="false" default="3">

        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT
                p.id,
                p.product_name,
                p.stock,
                COALESCE(r.rack_code, '') AS rack_code,
                COALESCE(rf.face_code, '') AS face_code,
                COALESCE(s.sale_count, 0) AS sale_count,
                CASE
                    WHEN prp.id IS NULL THEN 'not_placed'
                    WHEN COALESCE(s.sale_count, 0) = 0 THEN 'no_sales'
                    ELSE 'low_sales'
                END AS movement_status
            FROM products p
            LEFT JOIN product_rack_placement prp ON prp.product_id = p.id
            LEFT JOIN rack_faces rf ON rf.id = prp.rack_face_id
            LEFT JOIN racks r ON r.id = rf.rack_id
            LEFT JOIN (
                SELECT 
                    o.product_id, 
                    COUNT(*) AS sale_count
                FROM orders o
                WHERE o.created_at >= DATE_SUB(NOW(), INTERVAL 
                        <cfqueryparam value="#arguments.days#" cfsqltype="cf_sql_integer"> DAY)
                AND o.status NOT IN ('cancelled', 'refunded')
                GROUP BY o.product_id
            ) s ON s.product_id = p.id
            WHERE p.vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            AND COALESCE(s.sale_count, 0) <= <cfqueryparam value="#arguments.threshold#" cfsqltype="cf_sql_integer">
            ORDER BY sale_count ASC, p.product_name ASC
            LIMIT 10
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <cffunction name="getSwapResults" returntype="query" output="false">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfargument name="limit"     type="numeric" required="false" default="5">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT
                sl.id,
                sl.swapped_at,
                sl.sales_before_p1,
                sl.sales_before_p2,
                sl.sales_after_p1,
                sl.sales_after_p2,
                sl.evaluated_at,
                (sl.sales_before_p1 + sl.sales_before_p2) AS total_before,
                (COALESCE(sl.sales_after_p1, 0) + COALESCE(sl.sales_after_p2, 0)) AS total_after,
                p1.product_name AS product1_name,
                p2.product_name AS product2_name
            FROM swap_log sl
            JOIN products p1 ON p1.id = sl.product1_id
            JOIN products p2 ON p2.id = sl.product2_id
            WHERE sl.vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            ORDER BY sl.swapped_at DESC
            LIMIT <cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <cffunction name="evaluatePendingSwaps" returntype="void" output="false">
        <cfargument name="vendor_id" type="numeric" required="true">

        <cfquery name="local.pending" datasource="#application.dsn#">
            SELECT id, product1_id, product2_id, swapped_at
            FROM swap_log
            WHERE vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            AND evaluated_at IS NULL
            AND swapped_at <= DATE_SUB(NOW(), INTERVAL 1 DAY)
        </cfquery>

        <cfloop query="local.pending">
            <cfquery name="local.after1" datasource="#application.dsn#">
                SELECT COUNT(*) AS cnt
                FROM orders o
                WHERE o.product_id = <cfqueryparam value="#local.pending.product1_id#" cfsqltype="cf_sql_integer">
                AND o.created_at BETWEEN <cfqueryparam value="#local.pending.swapped_at#" cfsqltype="cf_sql_timestamp">
                                        AND DATE_ADD(<cfqueryparam value="#local.pending.swapped_at#" cfsqltype="cf_sql_timestamp">, INTERVAL 1 DAY)
                AND o.status NOT IN ('cancelled', 'refunded')
            </cfquery>

            <cfquery name="local.after2" datasource="#application.dsn#">
                SELECT COUNT(*) AS cnt
                FROM orders o
                WHERE o.product_id = <cfqueryparam value="#local.pending.product2_id#" cfsqltype="cf_sql_integer">
                AND o.created_at BETWEEN <cfqueryparam value="#local.pending.swapped_at#" cfsqltype="cf_sql_timestamp">
                                        AND DATE_ADD(<cfqueryparam value="#local.pending.swapped_at#" cfsqltype="cf_sql_timestamp">, INTERVAL 1 DAY)
                AND o.status NOT IN ('cancelled', 'refunded')
            </cfquery>

            <cfquery datasource="#application.dsn#">
                UPDATE swap_log
                SET sales_after_p1 = <cfqueryparam value="#local.after1.cnt#" cfsqltype="cf_sql_integer">,
                    sales_after_p2 = <cfqueryparam value="#local.after2.cnt#" cfsqltype="cf_sql_integer">,
                    evaluated_at = NOW()
                WHERE id = <cfqueryparam value="#local.pending.id#" cfsqltype="cf_sql_integer">
            </cfquery>
        </cfloop>
    </cffunction>   
    </cfcomponent>