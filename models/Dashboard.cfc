<cfcomponent output="false">

<!-- total orders -->
<cffunction name="getTotalOrders" returntype="numeric">
    <cfquery name="q" datasource="#application.dsn#">
        SELECT COUNT(*) as total FROM orders
    </cfquery>
    <cfreturn q.total>
</cffunction>

<!-- total revenue -->
<cffunction name="getTotalRevenue" returntype="numeric">
    <cfquery name="q" datasource="#application.dsn#">
        SELECT SUM(final_amount) as total FROM orders
    </cfquery>
    <cfreturn val(q.total)>
</cffunction>

<!-- total users -->
<cffunction name="getTotalUsers" returntype="numeric">
    <cfquery name="q" datasource="#application.dsn#">
        SELECT COUNT(*) as total FROM users
    </cfquery>
    <cfreturn q.total>
</cffunction>

<!-- total products -->
<cffunction name="getTotalProducts" returntype="numeric">
    <cfquery name="q" datasource="#application.dsn#">
        SELECT COUNT(*) as total FROM products
    </cfquery>
    <cfreturn q.total>
</cffunction>

<!-- low stock -->
<cffunction name="getLowStockProducts" returntype="query">
    <cfquery name="q" datasource="#application.dsn#">
        SELECT product_name, stock
        FROM products
        WHERE stock < 5
        ORDER BY stock ASC
    </cfquery>
    <cfreturn q>
</cffunction>

<!-- total coupons -->
<cffunction name="getTotalCoupons" returntype="numeric">
    <cfquery name="q" datasource="#application.dsn#">
        SELECT COUNT(*) as total FROM coupons
    </cfquery>
    <cfreturn q.total>
</cffunction>

<!-- latest orders -->
<cffunction name="getLatestOrders" returntype="query">
    <cfquery name="q" datasource="#application.dsn#">
        SELECT order_group_id, final_amount, created_at
        FROM orders
        ORDER BY created_at DESC
        LIMIT 5
    </cfquery>
    <cfreturn q>
</cffunction>

</cfcomponent>