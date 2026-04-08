    <cfcomponent output="false">
    <cffunction name="getAllProducts" access="public" returntype="query" output="false">
        <cfquery name="products" datasource="#application.dsn#">
            SELECT p.*, c.category_name
            FROM products p
            JOIN categories c ON p.category_id = c.id
        </cfquery>

        <cfreturn products>
    </cffunction>

    <cffunction name="getAllActiveProducts" returntype="query" output="false">

        <cfquery name="products" datasource="#application.dsn#">
            SELECT 
                p.id,
                p.product_name,
                p.price,
                p.stock,
                p.image,   
                c.category_name
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
        <cfargument name="stock" type="numeric">
        <cfargument name="category_id" type="numeric" required="true">
        <cfargument name="image" type="string" required="false" default="">
        <cftry>
            <cfquery datasource="#application.dsn#">
    INSERT INTO products(product_name, price, stock, category_id, image)
    VALUES (
        <cfqueryparam value="#arguments.product_name#" cfsqltype="cf_sql_varchar">,
        <cfqueryparam value="#arguments.price#" cfsqltype="cf_sql_decimal">,
        <cfqueryparam value="#arguments.stock#" cfsqltype="cf_sql_decimal">,
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
        <cfargument name="stock" type="numeric" >
        <cfargument name="category_id" type="numeric" required="true">
        <cfargument name="image" type="string" required="true">

        <cftry>
            <cfquery datasource="#application.dsn#">
                UPDATE products
                SET product_name = <cfqueryparam value="#arguments.product_name#" cfsqltype="cf_sql_varchar">,
                    price = <cfqueryparam value="#arguments.price#" cfsqltype="cf_sql_decimal">,
                    stock = <cfqueryparam value="#arguments.stock#" cfsqltype="cf_sql_decimal">,
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

     <cffunction name="searchProducts" returntype="query">
    <cfargument name="keyword" type="string" required="false" default="">
    <cfargument name="min_price" type="numeric" required="false">
    <cfargument name="max_price" type="numeric" required="false">
    <cfargument name="category_id" type="numeric" required="false">
    <cfargument name="sort" type="string" required="false" default="">
    <cfargument name="page" type="numeric" required="false" default="1">
    <cfargument name="limit" type="numeric" required="false" default="2">

    <cfset safePage = arguments.page>

<cfif safePage LT 1>
    <cfset safePage = 1>
</cfif>

<cfset offset = (safePage - 1) * arguments.limit>

    <cfquery name="products" datasource="#application.dsn#">
        SELECT P.*, c.category_name
        FROM products P
        JOIN categories c ON p.category_id = c.id
        WHERE p.is_active = 1
        AND c.is_active = 1

         <cfif len(arguments.keyword)>
            AND (
                p.product_name LIKE 
                <cfqueryparam value="%#arguments.keyword#%" cfsqltype="cf_sql_varchar">
                OR c.category_name LIKE 
                <cfqueryparam value="%#arguments.keyword#%" cfsqltype="cf_sql_varchar">
            )
        </cfif>

         <cfif structKeyExists(arguments, "min_price") AND arguments.min_price NEQ "">
            AND p.price >= 
            <cfqueryparam value="#arguments.min_price#" cfsqltype="cf_sql_decimal">
        </cfif>

        <cfif structKeyExists(arguments, "max_price") AND arguments.max_price NEQ "">
            AND p.price <= 
            <cfqueryparam value="#arguments.max_price#" cfsqltype="cf_sql_decimal">
        </cfif>

         <cfif structKeyExists(arguments, "category_id") AND arguments.category_id NEQ "">
            AND p.category_id = 
            <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_integer">
        </cfif>

         ORDER BY
        <cfif arguments.sort EQ "price_low">
            p.price ASC
        <cfelseif arguments.sort EQ "price_high">
            p.price DESC
        <cfelseif arguments.sort EQ "a_z">
            p.product_name ASC
        <cfelseif arguments.sort EQ "z_a">
            p.product_name DESC
        <cfelse>
            p.id DESC
        </cfif>

         LIMIT <cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer">
        OFFSET <cfqueryparam value="#offset#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfreturn products>
</cffunction>


         <cffunction name="getProductCount" returntype="numeric">
    <cfargument name="keyword" default="">
    <cfargument name="category_id">
    <cfargument name="min_price">
    <cfargument name="max_price">

    <cfquery name="result" datasource="#application.dsn#">
        SELECT COUNT(*) as total
        FROM products P
        JOIN categories c ON p.category_id = c.id
        WHERE p.is_active = 1
        AND c.is_active = 1
    </cfquery>

    <cfreturn result.total>
</cffunction>



<cffunction name="getAllProductsAdmin" returntype="query">

    <cfargument name="search" default="">
    <cfargument name="sort" default="">
    <cfargument name="page" default="1">
    <cfargument name="limit" default="10">
    <cfargument name="category_id" default="">

    <cfset var searchValue = trim(arguments.search)>
    <cfset var offset = (arguments.page - 1) * arguments.limit>

    <cfquery name="products" datasource="#application.dsn#">
        SELECT p.*, c.category_name
        FROM products p
        JOIN categories c ON p.category_id = c.id
        WHERE 1=1

        <cfif len(searchValue)>
            AND (
                LOWER(p.product_name) LIKE 
                <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">

                OR LOWER(c.category_name) LIKE 
                <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">
            )
        </cfif>

        <cfif isNumeric(arguments.category_id)>
           AND p.category_id = 
            <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_integer">
        </cfif>

        <cfif arguments.sort EQ "a_z">
            ORDER BY p.product_name ASC
        <cfelseif arguments.sort EQ "z_a">
            ORDER BY p.product_name DESC
        <cfelseif arguments.sort EQ "price_low">
            ORDER BY p.price ASC
        <cfelseif arguments.sort EQ "price_high">
            ORDER BY p.price DESC
        <cfelseif arguments.sort EQ "category_a_z">
            ORDER BY c.category_name ASC
        <cfelseif arguments.sort EQ "category_z_a">
            ORDER BY c.category_name DESC
        <cfelse>
            ORDER BY p.id DESC
        </cfif>

        LIMIT <cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer">
        OFFSET <cfqueryparam value="#offset#" cfsqltype="cf_sql_integer">

    </cfquery>

    <cfreturn products>

</cffunction>


<cffunction name="getProductCountAdmin" returntype="numeric">

    <cfargument name="search" default="">
     <cfargument name="category_id" default=""> 

    <cfset var searchValue = trim(arguments.search)>

    <cfquery name="result" datasource="#application.dsn#">
        SELECT COUNT(*) as total
        FROM products p
        JOIN categories c ON p.category_id = c.id
        WHERE 1=1

        <cfif len(searchValue)>
            AND (
                LOWER(p.product_name) LIKE 
                <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">

                OR LOWER(c.category_name) LIKE 
                <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">
            )
        </cfif>
        <cfif isNumeric(arguments.category_id)>
           AND p.category_id = 
        <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_integer">
        </cfif>
    </cfquery>

    <cfreturn result.total>

</cffunction>

<cffunction name="reduceStock" returntype="boolean" output="false">
    <cfargument name="product_id" type="numeric" required="true">
    <cfargument name="qty" type="numeric" required="true">

    <cftry>

        <cfquery datasource="#application.dsn#">
            UPDATE products
            SET stock = stock - 
                <cfqueryparam value="#arguments.qty#" cfsqltype="cf_sql_integer">
            WHERE id = 
                <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
            AND stock >= 
                <cfqueryparam value="#arguments.qty#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfreturn true>

    <cfcatch>
        <cfreturn false>
    </cfcatch>

    </cftry>
</cffunction>


<cffunction name="getStock" returntype="numeric">

    <cfargument name="product_id" required="true">

    <cfquery name="q" datasource="#application.dsn#">
        SELECT stock FROM products
        WHERE id = 
        <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfreturn q.stock>

</cffunction>

</cfcomponent>