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
            INSERT INTO orders (
                user_id,
                product_id,
                price,
                quantity,
                total_amount,
                order_group_id
            ) VALUES (
                <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#arguments.price#" cfsqltype="cf_sql_decimal">,
                <cfqueryparam value="#arguments.quantity#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#arguments.total#" cfsqltype="cf_sql_decimal">,
                <cfqueryparam value="#arguments.group_id#" cfsqltype="cf_sql_varchar">
            )
        </cfquery>

        <cfreturn true>

    <cfcatch>
        <cfreturn false>
    </cfcatch>

    </cftry>

  </cffunction>

  <cffunction name="getUserOrders" returntype="query">
     <cfargument name="user_id" type="numeric" required="true">
     <cfquery name="orders" datasource="#application.dsn#">
     SELECT o.*, p.product_name, p.image
     FROM orders o
     join products p ON o.product_id = p.id
     WHERE o.user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
     ORDER BY o.order_group_id DESC, o.id DESC
     </cfquery>
  <cfreturn orders> 
  </cffunction>

</cfcomponent>