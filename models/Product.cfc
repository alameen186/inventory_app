<cfcomponent output="false">
   <cffunction name="getAllProducts" access="public" returntype="query" output="false">
       <cfquery name="products" datasource="#application.dsn#">
          SELECT p.*, c.category_name
          FROM products p
          JOIN categories c ON p.category_id = c.id
       </cfquery>

       <cfreturn products>
   </cffunction>

   <cffunction name="getAllActiveProducts" access="public" returnType="query" output="false">
       <cfquery name="products" datasource="#application.dsn#">
         SELECT p.id, p.product_name
         FROM products p
         JOIN categories c ON p.category_id = c.id
         WHERE p.is_active = 1
         AND c.is_active = 1
       </cfquery>

       <cfreturn products>
   </cffunction>

   <cffunction name="addProduct" access="public" returntype="boolean" output="false">
     <cfargument name="product_name" type="string" required="true">
     <cfargument name="price" type="numeric" required="true">
     <cfargument name="category_id" type="numeric" required="true">
     <cfargument name="image" type="string" required="false" default="">
      <cftry>
        <cfquery datasource="#application.dsn#">
   INSERT INTO products(product_name, price, category_id, image)
   VALUES (
      <cfqueryparam value="#arguments.product_name#" cfsqltype="cf_sql_varchar">,
      <cfqueryparam value="#arguments.price#" cfsqltype="cf_sql_decimal">,
      <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_integer">,
      <cfqueryparam value="#arguments.image#" cfsqltype="cf_sql_varchar">
   )
</cfquery>

        <cfreturn true>
     <cfcatch>
    <cfdump var="#cfcatch#">
    <cfabort>
</cfcatch> 
      </cftry>     
   </cffunction>

  <cffunction name="updateProduct" access="public" returntype="boolean" output="false">
    <cfargument name="id" type="numeric" required="true">
    <cfargument name="product_name" type="string" required="true">
    <cfargument name="price" type="numeric" required="true">
    <cfargument name="category_id" type="numeric" required="true">
    <cfargument name="image" type="string" required="true">

    <cftry>
        <cfquery datasource="#application.dsn#">
            UPDATE products
            SET product_name = <cfqueryparam value="#arguments.product_name#" cfsqltype="cf_sql_varchar">,
                price = <cfqueryparam value="#arguments.price#" cfsqltype="cf_sql_decimal">,
                category_id = <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_integer">,
                image = <cfqueryparam value="#arguments.image#" cfsqltype="cf_sql_varchar">
            WHERE id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfreturn true>

    <cfcatch>
        <cfreturn false>
    </cfcatch>
    </cftry>
</cffunction>

   <cffunction name="toggleStatus" access="public" returntype="boolean" output="false">
        <cfargument name="id" type="numeric" required="true">
        <cfargument name="status" type="numeric" required="true">

        <cftry>
            <cfquery datasource="#application.dsn#">
                UPDATE products
                SET is_active = <cfqueryparam value="#arguments.status#" cfsqltype="cf_sql_bit">
                WHERE id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfreturn true>

            <cfcatch>
                <cfreturn false>
            </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getProductById" access="public" returntype="query" output="false">
       <cfargument name="id" type="numeric" required="true">

       <cfquery name="product" datasource="#application.dsn#">
       SELECT * from products
       WHERE id=<cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
       </cfquery>
       <cfreturn product>
    </cffunction>
</cfcomponent>