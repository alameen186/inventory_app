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
             c.category_name,
             u.business_name
         FROM products p
         JOIN categories c ON p.category_id = c.id
         LEFT JOIN users u ON p.vendor_id = u.id
         WHERE p.is_active = 1
         AND c.is_active = 1
        </cfquery>
        <cfreturn products>
    </cffunction>


<cffunction name="addProduct" access="public" returntype="numeric" output="false">
    <cfargument name="product_name"      type="string"  required="true">
    <cfargument name="price"             type="numeric" required="true">
    <cfargument name="stock"             type="numeric" required="false" default="0">
    <cfargument name="category_id"       type="numeric" required="true">
    <cfargument name="image"             type="string"  required="false" default="">
    <cfargument name="image2"            type="string"  required="false" default="">
    <cfargument name="image3"            type="string"  required="false" default="">
    <cfargument name="vendor_id"         type="numeric" required="true">
    <cfargument name="expiry_date"       type="string"  required="false" default="">
    <cfargument name="wholesale_price"   type="string"  required="false" default="">
    <cfargument name="min_wholesale_qty" type="string"  required="false" default="">

    <cftry>
        <cfquery datasource="#application.dsn#">
            INSERT INTO products
                (product_name, price, stock, category_id, vendor_id, 
                 expiry_date, wholesale_price, min_wholesale_qty, is_active)
            VALUES (
                <cfqueryparam value="#arguments.product_name#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.price#" cfsqltype="cf_sql_decimal">,
                <cfqueryparam value="#arguments.stock#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#arguments.expiry_date#" cfsqltype="cf_sql_date" 
                    null="#NOT len(trim(arguments.expiry_date))#">,
                <cfqueryparam value="#arguments.wholesale_price#" cfsqltype="cf_sql_decimal"
                    null="#NOT isNumeric(arguments.wholesale_price) OR NOT val(arguments.wholesale_price)#">,
                <cfqueryparam value="#arguments.min_wholesale_qty#" cfsqltype="cf_sql_integer"
                    null="#NOT isNumeric(arguments.min_wholesale_qty) OR NOT val(arguments.min_wholesale_qty)#">,
                1
            )
        </cfquery>
        
        <cfquery name="lastId" datasource="#application.dsn#">
            SELECT LAST_INSERT_ID() AS new_id
        </cfquery>
        
        <cfreturn lastId.new_id>
        
    <cfcatch>
        <cfreturn 0>
    </cfcatch>
    </cftry>
</cffunction>

    <cffunction name="updateProduct" access="public" returntype="boolean" output="false">
    <cfargument name="id"                type="numeric" required="true">
    <cfargument name="product_name"      type="string"  required="true">
    <cfargument name="price"             type="numeric" required="true">
    <cfargument name="stock"             type="numeric">
    <cfargument name="category_id"       type="numeric" required="true">
    <cfargument name="image"             type="string"  required="true">
    <cfargument name="image2"            type="string"  required="false" default="">
    <cfargument name="image3"            type="string"  required="false" default="">
    <cfargument name="expiry_date"       type="string"  required="false" default="">
    <cfargument name="wholesale_price"   type="string"  required="false" default="">
    <cfargument name="min_wholesale_qty" type="string"  required="false" default="">

    <cftry>
        <cfquery datasource="#application.dsn#">
            UPDATE products
            SET product_name      = <cfqueryparam value="#arguments.product_name#" cfsqltype="cf_sql_varchar">,
                price             = <cfqueryparam value="#arguments.price#"        cfsqltype="cf_sql_decimal">,
                stock             = <cfqueryparam value="#arguments.stock#"        cfsqltype="cf_sql_integer">,
                category_id       = <cfqueryparam value="#arguments.category_id#"  cfsqltype="cf_sql_integer">,
                expiry_date       = <cfqueryparam value="#arguments.expiry_date#"  cfsqltype="cf_sql_date"
                                        null="#NOT len(trim(arguments.expiry_date))#">,
                wholesale_price   = <cfqueryparam value="#arguments.wholesale_price#"   cfsqltype="cf_sql_decimal"
                                        null="#NOT isNumeric(arguments.wholesale_price) OR NOT val(arguments.wholesale_price)#">,
                min_wholesale_qty = <cfqueryparam value="#arguments.min_wholesale_qty#" cfsqltype="cf_sql_integer"
                                        null="#NOT isNumeric(arguments.min_wholesale_qty) OR NOT val(arguments.min_wholesale_qty)#">
            WHERE id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfreturn true>
    <cfcatch>
        <cfreturn false>
    </cfcatch>
    </cftry>
</cffunction>

    <cffunction name="toggleStatus" access="public" returntype="boolean" output="false">
        <cfargument name="id"     type="numeric" required="true">
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

 
    <cffunction name="getProductById" returntype="query" output="false">
        <cfargument name="id" required="true">

        <cfquery name="q" datasource="#application.dsn#">
            SELECT
                p.id,
                p.vendor_id,
                p.product_name,
                p.price,
                p.stock,
                p.image,
                p.image2,
                p.image3,
                p.category_id,
                p.expiry_date,
                c.category_name,
                u.business_name,
                (
                    SELECT GROUP_CONCAT(pi.image ORDER BY pi.sort_order ASC SEPARATOR ',')
                    FROM product_images pi
                    WHERE pi.product_id = p.id
                ) AS grouped_images
            FROM products p
            LEFT JOIN categories c ON p.category_id = c.id
            LEFT JOIN users      u ON p.vendor_id   = u.id
            WHERE p.id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfreturn q>
    </cffunction>

    <cffunction name="searchProducts" returntype="query">
        <cfargument name="keyword"       type="string"  required="false" default="">
        <cfargument name="min_price"     required="false" default="">
        <cfargument name="max_price"     required="false" default="">
        <cfargument name="category_id"   required="false" default="">
        <cfargument name="sort"          type="string"  required="false" default="">
        <cfargument name="page"          type="numeric" required="false" default="1">
        <cfargument name="limit"         type="numeric" required="false" default="3">
        <cfargument name="expiry_months" type="string"  required="false" default="">

        <cfset safePage = arguments.page>
        <cfif safePage LT 1><cfset safePage = 1></cfif>
        <cfset offset = (safePage - 1) * arguments.limit>

        <cfquery name="products" datasource="#application.dsn#">
            SELECT
                p.*,
                c.category_name,
                u.business_name,
                ROUND(
                    (SELECT AVG(r.rating) FROM product_reviews r
                     WHERE r.product_id = p.id AND r.is_active = 1), 1
                ) AS avg_rating,
                (SELECT COUNT(*) FROM product_reviews r
                 WHERE r.product_id = p.id AND r.is_active = 1
                ) AS review_count,
                (SELECT pi.image FROM product_images pi
                 WHERE pi.product_id = p.id
                 ORDER BY pi.sort_order ASC LIMIT 1) AS first_image
            FROM products p
            JOIN categories c ON p.category_id = c.id
            LEFT JOIN users u ON p.vendor_id = u.id
            WHERE p.is_active = 1
            AND   c.is_active = 1

            <cfif structKeyExists(arguments,"expiry_months") AND isNumeric(arguments.expiry_months)>
                AND p.expiry_date IS NOT NULL
                AND p.expiry_date >= CURDATE()
                AND p.expiry_date <= DATE_ADD(CURDATE(), INTERVAL
                    <cfqueryparam value="#arguments.expiry_months#" cfsqltype="cf_sql_integer"> MONTH)
            </cfif>

            <cfif len(arguments.keyword)>
                AND (
                    p.product_name LIKE
                        <cfqueryparam value="%#arguments.keyword#%" cfsqltype="cf_sql_varchar">
                    OR c.category_name LIKE
                        <cfqueryparam value="%#arguments.keyword#%" cfsqltype="cf_sql_varchar">
                )
            </cfif>

            <cfif isNumeric(arguments.min_price)>
                AND p.price >= <cfqueryparam value="#arguments.min_price#" cfsqltype="cf_sql_decimal">
            </cfif>

            <cfif isNumeric(arguments.max_price)>
                AND p.price <= <cfqueryparam value="#arguments.max_price#" cfsqltype="cf_sql_decimal">
            </cfif>

            <cfif isNumeric(arguments.category_id)>
                AND p.category_id = <cfqueryparam value="#arguments.category_id#" cfsqltype="cf_sql_integer">
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
                p.expiry_date ASC
            </cfif>

            LIMIT  <cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer">
            OFFSET <cfqueryparam value="#offset#"          cfsqltype="cf_sql_integer">
        </cfquery>

        <cfreturn products>
    </cffunction>

    <cffunction name="getProductCount" returntype="numeric">
        <cfargument name="keyword"       default="">
        <cfargument name="category_id">
        <cfargument name="min_price">
        <cfargument name="max_price">
        <cfargument name="expiry_months" default="">

        <cfquery name="result" datasource="#application.dsn#">
            SELECT COUNT(*) as total
            FROM products p
            JOIN categories c ON p.category_id = c.id
            WHERE p.is_active = 1
            AND c.is_active = 1

            <cfif isNumeric(arguments.expiry_months)>
                AND p.expiry_date IS NOT NULL
                AND p.expiry_date >= CURDATE()
                AND p.expiry_date <= DATE_ADD(CURDATE(), INTERVAL
                    <cfqueryparam value="#arguments.expiry_months#" cfsqltype="cf_sql_integer"> MONTH)
            </cfif>

            <cfif len(arguments.keyword)>
                AND (
                    p.product_name LIKE <cfqueryparam value="%#arguments.keyword#%">
                    OR c.category_name LIKE <cfqueryparam value="%#arguments.keyword#%">
                )
            </cfif>

            <cfif isNumeric(arguments.category_id)>
                AND p.category_id = <cfqueryparam value="#arguments.category_id#">
            </cfif>

            <cfif isNumeric(arguments.min_price)>
                AND p.price >= <cfqueryparam value="#arguments.min_price#">
            </cfif>

            <cfif isNumeric(arguments.max_price)>
                AND p.price <= <cfqueryparam value="#arguments.max_price#">
            </cfif>
        </cfquery>

        <cfreturn result.total>
    </cffunction>

    <cffunction name="getAllProductsAdmin" returntype="query">
        <cfargument name="search"      default="">
        <cfargument name="sort"        default="">
        <cfargument name="page"        default="1">
        <cfargument name="limit"       default="10">
        <cfargument name="category_id" default="">
        <cfargument name="vendor_id"   default="">
        <cfargument name="season"   default="">

        <cfset var searchValue = trim(arguments.search)>
        <cfset var offset = (arguments.page - 1) * arguments.limit>

        <cfquery name="products" datasource="#application.dsn#">
            SELECT
                p.*,
                c.category_name,
                p.expiry_date,
                (SELECT pi.image FROM product_images pi
 WHERE pi.product_id = p.id
 ORDER BY pi.sort_order ASC LIMIT 1) AS first_image,
(
SELECT GROUP_CONCAT(s.season_name ORDER BY s.start_date SEPARATOR '|')
FROM   product_seasons ps
JOIN   seasons s ON s.id = ps.season_id AND s.is_active = 1
WHERE  ps.product_id = p.id
) AS season_tags
        FROM products p
            JOIN categories c ON p.category_id = c.id
            WHERE 1=1

            <cfif isNumeric(arguments.vendor_id)>
                AND p.vendor_id =
                <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            </cfif>

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
            <cfelse>
                ORDER BY p.expiry_date ASC
            </cfif>

            LIMIT  <cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer">
            OFFSET <cfqueryparam value="#offset#"          cfsqltype="cf_sql_integer">
        </cfquery>

        <cfreturn products>
    </cffunction>

    <cffunction name="getProductCountAdmin" returntype="numeric">
        <cfargument name="search"      default="">
        <cfargument name="category_id" default="">
        <cfargument name="vendor_id"   default="">

        <cfset var searchValue = trim(arguments.search)>

        <cfquery name="result" datasource="#application.dsn#">
            SELECT COUNT(*) as total
            FROM products p
            JOIN categories c ON p.category_id = c.id
            WHERE 1=1

            <cfif isNumeric(arguments.vendor_id)>
                AND p.vendor_id =
                <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            </cfif>

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
        <cfargument name="qty"        type="numeric" required="true">

        <cftry>
            <cfquery datasource="#application.dsn#">
                UPDATE products
                SET stock = stock - <cfqueryparam value="#arguments.qty#" cfsqltype="cf_sql_integer">
                WHERE id  = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
                AND stock >= <cfqueryparam value="#arguments.qty#" cfsqltype="cf_sql_integer">
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
            WHERE id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfreturn q.stock>
    </cffunction>

    <cffunction name="getAllProductsSimple" returntype="query">
        <cfquery name="products" datasource="#application.dsn#">
            SELECT id, product_name, price, stock
            FROM products
            WHERE stock > 0
            ORDER BY product_name ASC
        </cfquery>
        <cfreturn products>
    </cffunction>

    <cffunction name="addStock" returntype="boolean" output="false">
        <cfargument name="product_id" required="true">
        <cfargument name="qty"        required="true">

        <cftry>
            <cfquery datasource="#application.dsn#">
                UPDATE products
                SET stock = stock + <cfqueryparam value="#arguments.qty#" cfsqltype="cf_sql_integer">
                WHERE id  = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfreturn true>
        <cfcatch>
            <cfreturn false>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getProductsWithVendorByIds" returntype="query" output="false">
        <cfargument name="productIds" required="true">

        <cfquery name="q" datasource="#application.dsn#">
            SELECT
                p.id,
                p.product_name,
                p.price,
                u.business_name,
                u.address
            FROM products p
            JOIN users u ON p.vendor_id = u.id
            WHERE p.id IN (
                <cfqueryparam value="#arguments.productIds#" list="true" cfsqltype="cf_sql_integer">
            )
        </cfquery>

        <cfreturn q>
    </cffunction>

    <cffunction name="getByVendorSimple" returntype="query" output="false">
        <cfargument name="vendor_id" type="numeric" required="true">

        <cfquery name="q" datasource="#application.dsn#">
            SELECT id, product_name, price, stock
            FROM products
            WHERE vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            AND   is_active = 1
            AND   stock     > 0
            ORDER BY product_name ASC
        </cfquery>

        <cfreturn q>
    </cffunction>

    <cffunction name="getVendorProductsPaged" returntype="query" output="false">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfargument name="search"    type="string"  required="false" default="">
        <cfargument name="sort"      type="string"  required="false" default="">
        <cfargument name="page"      type="numeric" required="false" default="1">
        <cfargument name="limit"     type="numeric" required="false" default="10">

        <cfset var offset = (arguments.page - 1) * arguments.limit>

        <cfquery name="q" datasource="#application.dsn#">
            SELECT p.id, p.product_name, p.price, p.stock, p.image
            FROM products p
            WHERE p.vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            AND   p.is_active = 1

            <cfif len(trim(arguments.search))>
                AND p.product_name LIKE
                    <cfqueryparam value="%#trim(arguments.search)#%" cfsqltype="cf_sql_varchar">
            </cfif>

            <cfif arguments.sort EQ "price_low">
                ORDER BY p.price ASC
            <cfelseif arguments.sort EQ "price_high">
                ORDER BY p.price DESC
            <cfelseif arguments.sort EQ "z_a">
                ORDER BY p.product_name DESC
            <cfelse>
                ORDER BY p.product_name ASC
            </cfif>

            LIMIT  <cfqueryparam value="#arguments.limit#"  cfsqltype="cf_sql_integer">
            OFFSET <cfqueryparam value="#offset#"           cfsqltype="cf_sql_integer">
        </cfquery>

        <cfreturn q>
    </cffunction>

    <cffunction name="getVendorProductCount" returntype="numeric" output="false">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfargument name="search"    type="string"  required="false" default="">

        <cfquery name="q" datasource="#application.dsn#">
            SELECT COUNT(*) AS total
            FROM products
            WHERE vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            AND   is_active = 1

            <cfif len(trim(arguments.search))>
                AND product_name LIKE
                    <cfqueryparam value="%#trim(arguments.search)#%" cfsqltype="cf_sql_varchar">
            </cfif>
        </cfquery>

        <cfreturn q.total>
    </cffunction>

<cffunction name="getVendorId" returntype="numeric" output="false">
    <cfargument name="product_id" type="numeric" required="true">

    <cfquery name="q" datasource="#application.dsn#">
        SELECT vendor_id 
        FROM products 
        WHERE id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfreturn q.recordCount ? val(q.vendor_id) : 0>
</cffunction>

<cffunction name="getActiveOfferForProduct" returntype="struct" output="false">
    <cfargument name="product_id" type="numeric" required="true">

    <cfquery name="local.q" datasource="#application.dsn#">
        SELECT 
            o.offer_name,
            o.discount_type,
            o.discount_value,
            o.start_date,
            o.end_date
        FROM offers o
        WHERE o.product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
          AND o.offer_type = 'individual'
          AND o.is_active = 1
          AND o.start_date <= CURDATE()
          AND o.end_date >= CURDATE()
        ORDER BY o.discount_value DESC
        LIMIT 1
    </cfquery>

    <cfif local.q.recordCount GT 0>
        <cfreturn {
            hasOffer      : true,
            offer_name    : local.q.offer_name,
            discount_type : local.q.discount_type,
            discount_value: local.q.discount_value
        }>
    </cfif>

    <!--- No active offer --->
    <cfreturn { hasOffer: false }>
</cffunction>
<!--- Get all active seasons--->
<cffunction name="getAllSeasons" returntype="query" output="false">
    <cfquery name="local.q" datasource="#application.dsn#">
        SELECT id, season_key, season_name, start_date, end_date, discount_pct
        FROM   seasons
        WHERE  is_active = 1
        ORDER  BY start_date ASC
    </cfquery>
    <cfreturn local.q>
</cffunction>


<!--- Get season IDs already linked to a product --->
<cffunction name="getProductSeasonIds" returntype="array" output="false">
    <cfargument name="product_id" type="numeric" required="true">

    <cfquery name="local.q" datasource="#application.dsn#">
        SELECT season_id
        FROM   product_seasons
        WHERE  product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfset var ids = []>
    <cfloop query="local.q">
        <cfset arrayAppend(ids, local.q.season_id)>
    </cfloop>
    <cfreturn ids>
</cffunction>


<!--- Save  season links for a product --->
<cffunction name="saveProductSeasons" returntype="void" output="false">
    <cfargument name="product_id" type="numeric" required="true">
    <cfargument name="season_ids" type="array"   required="true">

    <cfquery datasource="#application.dsn#">
        DELETE FROM product_seasons
        WHERE product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfloop array="#arguments.season_ids#" index="sid">
        <cfif isNumeric(sid) AND val(sid) GT 0>
            <cfquery datasource="#application.dsn#">
                INSERT IGNORE INTO product_seasons (product_id, season_id)
                VALUES (
                    <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#val(sid)#"             cfsqltype="cf_sql_integer">
                )
            </cfquery>
        </cfif>
    </cfloop>
</cffunction>


<!--- Get products that are season-tagged AND have an active offer right now --->
<cffunction name="getActiveSeasonalProducts" returntype="query" output="false">
    <cfargument name="limit" type="numeric" default="12">

    <cfquery name="local.q" datasource="#application.dsn#">
        SELECT
            p.id,
            p.product_name,
            p.price                                         AS original_price,
            ROUND(p.price * (1 - s.discount_pct / 100), 2) AS season_price,
            s.discount_pct,
            s.season_name,
            s.season_key,
            s.end_date                                      AS offer_ends,
            p.stock,
            p.category_id,
            c.category_name,
            (
                SELECT pi.image FROM product_images pi
                WHERE  pi.product_id = p.id
                ORDER  BY pi.sort_order ASC LIMIT 1
            ) AS first_image
        FROM   products p
        JOIN   product_seasons ps ON ps.product_id = p.id
        JOIN   seasons s
               ON  s.id         = ps.season_id
               AND s.is_active  = 1
               AND s.start_date <= CURDATE()
               AND s.end_date   >= CURDATE()
        JOIN   categories c ON c.id = p.category_id AND c.is_active = 1
        WHERE  p.is_active = 1
        AND    p.stock     > 0
        ORDER  BY s.discount_pct DESC, p.product_name ASC
        LIMIT  <cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfreturn local.q>
</cffunction>


</cfcomponent>


