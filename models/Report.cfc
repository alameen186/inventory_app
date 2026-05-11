<cfcomponent output="false">

    <cffunction name="getOrders" returntype="query" output="false">
    <cfargument name="vendor_id"  type="numeric" required="true">
    <cfargument name="date_from"  type="string"  required="false" default="">
    <cfargument name="date_to"    type="string"  required="false" default="">
    <cfargument name="status"     type="string"  required="false" default="">

    <cfquery name="local.q" datasource="#application.dsn#">
        SELECT
            o.id,
            o.order_group_id,
            CONCAT(u.first_name,' ',u.last_name) AS customer_name,
            p.product_name,
            o.quantity,
            o.price,
            o.total_amount,
            COALESCE(o.discount_amount, 0) AS discount_amount,
            COALESCE(o.final_amount, o.total_amount) AS final_amount,
            COALESCE(o.coupon_code, '') AS coupon_code,
            o.status,
            o.created_at
        FROM orders o
        JOIN products p ON p.id = o.product_id
        LEFT JOIN users u ON u.id = o.user_id  <!--- LEFT JOIN so guest orders still show --->
        WHERE p.vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
        <cfif len(trim(arguments.status))>
            AND o.status = <cfqueryparam value="#arguments.status#" cfsqltype="cf_sql_varchar">
        </cfif>
        <cfif len(trim(arguments.date_from))>
            AND DATE(o.created_at) >= <cfqueryparam value="#arguments.date_from#" cfsqltype="cf_sql_date">
        </cfif>
        <cfif len(trim(arguments.date_to))>
            AND DATE(o.created_at) <= <cfqueryparam value="#arguments.date_to#" cfsqltype="cf_sql_date">
        </cfif>
        ORDER BY o.created_at DESC
    </cfquery>

    <cfreturn local.q>
</cffunction>

    <cffunction name="getProducts" returntype="query" output="false">
        <cfargument name="vendor_id"  type="numeric" required="true">
        <cfargument name="date_from"  type="string"  required="false" default="">
        <cfargument name="date_to"    type="string"  required="false" default="">
        <cfargument name="category_id" type="string" required="false" default="">

        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT
                p.id,
                p.product_name,
                c.category_name,
                p.price,
                p.stock,
                p.expiry_date,
                p.is_active,
                p.created_at
            FROM products p
            JOIN categories c ON c.id = p.category_id
            WHERE p.vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            <cfif isNumeric(arguments.category_id) AND val(arguments.category_id) GT 0>
                AND p.category_id = <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_integer">
            </cfif>
            <cfif len(trim(arguments.date_from))>
                AND DATE(p.created_at) >= <cfqueryparam value="#arguments.date_from#" cfsqltype="cf_sql_date">
            </cfif>
            <cfif len(trim(arguments.date_to))>
                AND DATE(p.created_at) <= <cfqueryparam value="#arguments.date_to#" cfsqltype="cf_sql_date">
            </cfif>
            ORDER BY p.created_at DESC
        </cfquery>

        <cfreturn local.q>
    </cffunction>

    <cffunction name="getCategories" returntype="query" output="false">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfargument name="date_from" type="string"  required="false" default="">
        <cfargument name="date_to"   type="string"  required="false" default="">

        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT
                c.id,
                c.category_name,
                COALESCE(c.description,'') AS description,
                c.is_active,
                COUNT(p.id) AS product_count,
                c.created_at
            FROM categories c
            LEFT JOIN products p
                ON p.category_id = c.id
                AND p.vendor_id  = c.vendor_id
            WHERE c.vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            <cfif len(trim(arguments.date_from))>
                AND DATE(c.created_at) >= <cfqueryparam value="#arguments.date_from#" cfsqltype="cf_sql_date">
            </cfif>
            <cfif len(trim(arguments.date_to))>
                AND DATE(c.created_at) <= <cfqueryparam value="#arguments.date_to#" cfsqltype="cf_sql_date">
            </cfif>
            GROUP BY c.id
            ORDER BY c.created_at DESC
        </cfquery>

        <cfreturn local.q>
    </cffunction>

    <cffunction name="getScheduledOrders" returntype="query" output="false">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfargument name="date_from" type="string"  required="false" default="">
        <cfargument name="date_to"   type="string"  required="false" default="">

        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT
                so.id,
                CONCAT(u.first_name,' ',u.last_name) AS customer_name,
                p.product_name,
                so.quantity,
                so.reserved_qty,
                so.day_of_month,
                so.start_date,
                so.is_active,
                so.created_at
            FROM scheduled_orders so
            JOIN users    u ON u.id = so.customer_id
            JOIN products p ON p.id = so.product_id
            WHERE so.vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            <cfif len(trim(arguments.date_from))>
                AND DATE(so.created_at) >= <cfqueryparam value="#arguments.date_from#" cfsqltype="cf_sql_date">
            </cfif>
            <cfif len(trim(arguments.date_to))>
                AND DATE(so.created_at) <= <cfqueryparam value="#arguments.date_to#" cfsqltype="cf_sql_date">
            </cfif>
            ORDER BY so.created_at DESC
        </cfquery>

        <cfreturn local.q>
    </cffunction>

    <cffunction name="getCustomers" returntype="query" output="false">
     <cfargument name="vendor_id" type="numeric" required="true">
     <cfargument name="date_from" type="string"  required="false" default="">
     <cfargument name="date_to"   type="string"  required="false" default="">

     <cfquery name="local.q" datasource="#application.dsn#">
        SELECT
            u.id,
            CONCAT(u.first_name,' ',u.last_name)  AS customer_name,
            u.email,
            COALESCE(u.address,'')                AS address,
            COUNT(o.id)                           AS total_orders,
            COALESCE(SUM(o.final_amount), 0)      AS total_spent,
            MAX(o.created_at)                     AS last_order_date
        FROM orders o
        JOIN products p ON p.id = o.product_id
        LEFT JOIN users u ON u.id = o.user_id
        WHERE p.vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
        <cfif len(trim(arguments.date_from))>
            AND DATE(o.created_at) >= <cfqueryparam value="#arguments.date_from#" cfsqltype="cf_sql_date">
        </cfif>
        <cfif len(trim(arguments.date_to))>
            AND DATE(o.created_at) <= <cfqueryparam value="#arguments.date_to#" cfsqltype="cf_sql_date">
        </cfif>
        GROUP BY u.id, u.first_name, u.last_name, u.email, u.address
        ORDER BY total_spent DESC
     </cfquery>

     <cfreturn local.q>
    </cffunction>

    <cffunction name="getRevenue" returntype="query" output="false">
       <cfargument name="vendor_id" type="numeric" required="true">
       <cfargument name="date_from" type="string"  required="false" default="">
       <cfargument name="date_to"   type="string"  required="false" default="">
       <cfargument name="status"    type="string"  required="false" default="">
   
       <cfquery name="local.q" datasource="#application.dsn#">
           SELECT
               p.product_name,
               c.category_name,
               COUNT(o.id)                          AS total_orders,
               COALESCE(SUM(o.quantity), 0)         AS units_sold,
               COALESCE(SUM(o.total_amount), 0)     AS gross_revenue,
               COALESCE(SUM(o.discount_amount), 0)  AS total_discount,
               COALESCE(SUM(o.final_amount), 0)     AS net_revenue
           FROM orders o
           JOIN products   p ON p.id = o.product_id
           JOIN categories c ON c.id = p.category_id
           WHERE p.vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
           AND o.status != 'cancelled'
           <cfif len(trim(arguments.date_from))>
               AND DATE(o.created_at) >= <cfqueryparam value="#arguments.date_from#" cfsqltype="cf_sql_date">
           </cfif>
           <cfif len(trim(arguments.date_to))>
               AND DATE(o.created_at) <= <cfqueryparam value="#arguments.date_to#" cfsqltype="cf_sql_date">
           </cfif>
           GROUP BY p.id, p.product_name, c.category_name
           ORDER BY net_revenue DESC
       </cfquery>
   
       <cfreturn local.q>
    </cffunction>

    <cffunction name="getVendorName" returntype="string" output="false">
        <cfargument name="vendor_id" type="numeric" required="true">

        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT COALESCE(business_name, CONCAT(first_name,' ',last_name)) AS biz
            FROM users
            WHERE id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfreturn local.q.recordCount ? local.q.biz : "">
    </cffunction>

</cfcomponent>