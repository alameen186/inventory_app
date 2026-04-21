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

<!-- VENDOR REVENUE -->
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
</cfcomponent>