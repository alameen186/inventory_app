<cfcomponent output="false">

    <!--- ADD TO WISHLIST --->
    <cffunction name="add" returntype="struct" output="false">
        <cfargument name="user_id"    type="numeric" required="true">
        <cfargument name="product_id" type="numeric" required="true">
        <cftry>
            <cfquery datasource="#application.dsn#">
                INSERT IGNORE INTO wishlists (user_id, product_id)
                VALUES (
                    <cfqueryparam value="#arguments.user_id#"    cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
                )
            </cfquery>
            <cfreturn { success: true }>
        <cfcatch>
            <cfreturn { success: false, message: cfcatch.message }>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- REMOVE FROM WISHLIST --->
    <cffunction name="remove" returntype="boolean" output="false">
        <cfargument name="user_id"    type="numeric" required="true">
        <cfargument name="product_id" type="numeric" required="true">
        <cftry>
            <cfquery datasource="#application.dsn#">
                DELETE FROM wishlists
                WHERE user_id    = <cfqueryparam value="#arguments.user_id#"    cfsqltype="cf_sql_integer">
                AND   product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfreturn true>
        <cfcatch>
            <cfreturn false>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- CHECK IF WISHLISTED --->
    <cffunction name="isWishlisted" returntype="boolean" output="false">
        <cfargument name="user_id"    type="numeric" required="true">
        <cfargument name="product_id" type="numeric" required="true">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT id FROM wishlists
            WHERE user_id    = <cfqueryparam value="#arguments.user_id#"    cfsqltype="cf_sql_integer">
            AND   product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfreturn local.q.recordCount GT 0>
    </cffunction>

    <!--- GET USER WISHLIST WITH PRODUCT DETAILS --->
    <cffunction name="getByUser" returntype="query" output="false">
        <cfargument name="user_id" type="numeric" required="true">
        <cfargument name="page"    type="numeric" default="1">
        <cfargument name="limit"   type="numeric" default="12">
        <cfset var offset = (arguments.page - 1) * arguments.limit>
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT
                w.id            AS wishlist_id,
                w.added_at,
                p.id            AS product_id,
                p.product_name,
                p.price,
                p.stock,
                p.is_active,
                c.category_name,
                (
                    SELECT pi.image FROM product_images pi
                    WHERE pi.product_id = p.id
                    ORDER BY pi.sort_order ASC LIMIT 1
                ) AS first_image
            FROM wishlists w
            JOIN products  p ON p.id = w.product_id
            JOIN categories c ON c.id = p.category_id
            WHERE w.user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
            ORDER BY w.added_at DESC
            LIMIT  <cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer">
            OFFSET <cfqueryparam value="#offset#"          cfsqltype="cf_sql_integer">
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <!--- COUNT USER WISHLIST --->
    <cffunction name="countByUser" returntype="numeric" output="false">
        <cfargument name="user_id" type="numeric" required="true">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT COUNT(*) AS total FROM wishlists
            WHERE user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfreturn local.q.total>
    </cffunction>

    <!--- GET ALL USERS WHO WISHLISTED A PRODUCT (for notifications) --->
    <cffunction name="getUsersByProduct" returntype="query" output="false">
        <cfargument name="product_id" type="numeric" required="true">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT DISTINCT w.user_id
            FROM wishlists w
            WHERE w.product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <!--- GET WISHLISTED PRODUCTS WITH LOW STOCK (stock <= threshold) --->
    <cffunction name="getWishlistUsersForLowStock" returntype="query" output="false">
        <cfargument name="product_id" type="numeric" required="true">
        <cfargument name="threshold"  type="numeric" default="5">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT DISTINCT
                w.user_id,
                p.product_name,
                p.stock
            FROM wishlists w
            JOIN products p ON p.id = w.product_id
            WHERE w.product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
              AND p.stock > 0
              AND p.stock <= <cfqueryparam value="#arguments.threshold#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <!--- GET WISHLISTED PRODUCTS THAT NOW HAVE AN ACTIVE OFFER --->
    <cffunction name="getWishlistUsersForOffer" returntype="query" output="false">
        <cfargument name="product_id" type="numeric" required="true">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT DISTINCT w.user_id
            FROM wishlists w
            WHERE w.product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <!--- TOGGLE: add if not present, remove if present --->
    <cffunction name="toggle" returntype="struct" output="false">
        <cfargument name="user_id"    type="numeric" required="true">
        <cfargument name="product_id" type="numeric" required="true">
        <cfset var already = isWishlisted(arguments.user_id, arguments.product_id)>
        <cfif already>
            <cfset remove(arguments.user_id, arguments.product_id)>
            <cfreturn { success: true, wishlisted: false, message: "Removed from wishlist" }>
        <cfelse>
            <cfset add(arguments.user_id, arguments.product_id)>
            <cfreturn { success: true, wishlisted: true, message: "Added to wishlist" }>
        </cfif>
    </cffunction>

</cfcomponent>