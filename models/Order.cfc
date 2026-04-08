<cfcomponent output="false">
   
    <cffunction name="addOrder" returntype="boolean" output="false">
        <cfargument name="user_id">
        <cfargument name="product_id">
        <cfargument name="price">
        <cfargument name="quantity">
        <cfargument name="total">
        <cfargument name="group_id">
        <cftry>
            <cfquery datasource="#application.dsn#">
                INSERT INTO orders (user_id, product_id, price, quantity, total_amount, order_group_id) 
                VALUES (
                    <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#arguments.price#" cfsqltype="cf_sql_decimal">,
                    <cfqueryparam value="#arguments.quantity#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#arguments.total#" cfsqltype="cf_sql_decimal">,
                    <cfqueryparam value="#arguments.group_id#" cfsqltype="cf_sql_varchar">
                )
            </cfquery>
            <cfreturn true>
            <cfcatch><cfreturn false></cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getAllOrdersWithPagination" returntype="query">
        <cfargument name="search" default="">
        <cfargument name="page" default="1">
        <cfargument name="limit" default="5">

        <cfset var searchValue = trim(arguments.search)>
        <cfset var offset = (max(val(arguments.page), 1) - 1) * arguments.limit>

        <cfquery name="orders" datasource="#application.dsn#">
            SELECT o.order_group_id, o.created_at, o.quantity, o.total_amount, 
                   p.product_name, p.image, p.price,
                   CONCAT(u.first_name, ' ', u.last_name) as user_name
            FROM orders o
            JOIN products p ON o.product_id = p.id
            LEFT JOIN users u ON o.user_id = u.id
            WHERE 1=1
            <cfif len(searchValue)>
    AND (
        o.order_group_id LIKE <cfqueryparam value="%#searchValue#%" cfsqltype="cf_sql_varchar">
        OR u.first_name LIKE <cfqueryparam value="%#searchValue#%" cfsqltype="cf_sql_varchar">
        OR u.last_name LIKE <cfqueryparam value="%#searchValue#%" cfsqltype="cf_sql_varchar">
        OR CONCAT(u.first_name, ' ', u.last_name) LIKE <cfqueryparam value="%#searchValue#%" cfsqltype="cf_sql_varchar">
    )
</cfif>
            ORDER BY o.id DESC
            LIMIT <cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer">
            OFFSET <cfqueryparam value="#offset#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfreturn orders>
    </cffunction>

    <cffunction name="getOrderCount" returntype="numeric">
        <cfargument name="search" default="">
        <cfset var searchValue = trim(arguments.search)>
        <cfquery name="result" datasource="#application.dsn#">
            SELECT COUNT(o.id) as total
            FROM orders o
            LEFT JOIN users u ON o.user_id = u.id
            WHERE 1=1
            <cfif len(searchValue)>
                AND (
                    o.order_group_id LIKE <cfqueryparam value="%#searchValue#%" cfsqltype="cf_sql_varchar">
                    OR u.first_name LIKE <cfqueryparam value="%#searchValue#%" cfsqltype="cf_sql_varchar">
                    OR u.last_name LIKE <cfqueryparam value="%#searchValue#%" cfsqltype="cf_sql_varchar">
                )
            </cfif>
        </cfquery>
        <cfreturn val(result.total)>
    </cffunction>


    <cffunction name="getUserOrders" returntype="query" output="false">
    <cfargument name="user_id" type="numeric" required="true">
    
    <cfquery name="userOrders" datasource="#application.dsn#">
        SELECT o.order_group_id, o.created_at, o.quantity, o.total_amount, 
               p.product_name, p.image, p.price
        FROM orders o
        JOIN products p ON o.product_id = p.id
        WHERE o.user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
        ORDER BY o.created_at DESC
    </cfquery>
    
    <cfreturn userOrders>
</cffunction>


<cffunction name="getUserOrdersWithPagination" returntype="query">

    <cfargument name="user_id" type="numeric" required="true">
    <cfargument name="search" default="">
    <cfargument name="page" default="1">
    <cfargument name="limit" default="5">

    <cfset var searchValue = trim(arguments.search)>
    <cfset var offset = (max(val(arguments.page),1) - 1) * arguments.limit>

    <cfquery name="orders" datasource="#application.dsn#">
        SELECT 
            o.order_group_id,
            o.created_at,
            o.quantity,
            o.total_amount,
            o.status,
            p.product_name,
            p.image,
            p.price
        FROM orders o
        JOIN products p ON o.product_id = p.id
        WHERE o.user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">

        <cfif len(searchValue)>
            AND o.order_group_id LIKE 
            <cfqueryparam value="%#searchValue#%" cfsqltype="cf_sql_varchar">
        </cfif>

        ORDER BY o.created_at DESC

        LIMIT <cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer">
        OFFSET <cfqueryparam value="#offset#" cfsqltype="cf_sql_integer">

    </cfquery>

    <cfreturn orders>

</cffunction>

<cffunction name="getUserOrderCount" returntype="numeric">

    <cfargument name="user_id" type="numeric" required="true">
    <cfargument name="search" default="">

    <cfset var searchValue = trim(arguments.search)>

    <cfquery name="result" datasource="#application.dsn#">
        SELECT COUNT(*) as total
        FROM orders o
        WHERE o.user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">

        <cfif len(searchValue)>
            AND o.order_group_id LIKE 
            <cfqueryparam value="%#searchValue#%" cfsqltype="cf_sql_varchar">
        </cfif>

    </cfquery>

    <cfreturn result.total>

</cffunction>

<cffunction name="cancelOrder" returntype="boolean">

    <cfargument name="order_group_id" required="true">
    <cfargument name="reason" required="true">
    <cfargument name="user_id" required="true">

    <cftry>

        <cfquery datasource="#application.dsn#">
            UPDATE orders
            SET 
                status = 'cancel_requested',
                cancel_reason = <cfqueryparam value="#arguments.reason#" cfsqltype="cf_sql_varchar">
            WHERE order_group_id = 
                <cfqueryparam value="#arguments.order_group_id#" cfsqltype="cf_sql_varchar">
            AND user_id =
                <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfreturn true>

    <cfcatch>
        <cfreturn false>
    </cfcatch>

    </cftry>
</cffunction>

<cffunction name="sendCancelEmail" returntype="void">

    <cfargument name="order_id">
    <cfargument name="reason">

    <cfmail 
        to="admin8841@gmail.com"
        from="noreply@yourcompany.com"
        subject="Order Cancel Request"
        type="html">

        <h3>Order Cancel Request</h3>
        <p><strong>Order ID:</strong> #arguments.order_id#</p>
        <p><strong>Reason:</strong> #arguments.reason#</p>

    </cfmail>

</cffunction>

</cfcomponent>
