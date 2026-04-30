<cfcomponent output="false">

    <!--- CHECK IF USER PURCHASED PRODUCT AT LEAST 2 TIMES --->
    <cffunction name="canUserReview" returntype="boolean" output="false">
        <cfargument name="user_id"    type="numeric" required="true">
        <cfargument name="product_id" type="numeric" required="true">

        <cfquery name="q" datasource="#application.dsn#">
            SELECT COUNT(*) AS purchase_count
            FROM orders
            WHERE user_id    = <cfqueryparam value="#arguments.user_id#"    cfsqltype="cf_sql_integer">
            AND   product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
            AND   status     != 'cancelled'
        </cfquery>

        <cfreturn q.purchase_count GTE 2>
    </cffunction>


    <!--- CHECK IF USER ALREADY REVIEWED THIS PRODUCT --->
    <cffunction name="hasUserReviewed" returntype="boolean" output="false">
        <cfargument name="user_id"    type="numeric" required="true">
        <cfargument name="product_id" type="numeric" required="true">

        <cfquery name="q" datasource="#application.dsn#">
            SELECT COUNT(*) AS cnt
            FROM product_reviews
            WHERE user_id    = <cfqueryparam value="#arguments.user_id#"    cfsqltype="cf_sql_integer">
            AND   product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfreturn q.cnt GT 0>
    </cffunction>


    <!--- ADD REVIEW --->
    <cffunction name="addReview" returntype="boolean" output="false">
        <cfargument name="user_id"    type="numeric" required="true">
        <cfargument name="product_id" type="numeric" required="true">
        <cfargument name="rating"     type="numeric" required="true">
        <cfargument name="comment"    type="string"  required="true">

        <cftry>
            <cfquery datasource="#application.dsn#">
                INSERT INTO product_reviews (user_id, product_id, rating, comment)
                VALUES (
                    <cfqueryparam value="#arguments.user_id#"    cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#arguments.rating#"     cfsqltype="cf_sql_tinyint">,
                    <cfqueryparam value="#arguments.comment#"    cfsqltype="cf_sql_varchar">
                )
            </cfquery>
            <cfreturn true>
        <cfcatch>
            <cfreturn false>
        </cfcatch>
        </cftry>
    </cffunction>


    <!--- GET REVIEWS FOR A PRODUCT --->
    <cffunction name="getProductReviews" returntype="query" output="false">
        <cfargument name="product_id" type="numeric" required="true">
        <cfargument name="page"       type="numeric" default="1">
        <cfargument name="limit"      type="numeric" default="5">

        <cfset var offset = (arguments.page - 1) * arguments.limit>

        <cfquery name="q" datasource="#application.dsn#">
            SELECT
                r.id,
                r.rating,
                r.comment,
                r.created_at,
                CONCAT(u.first_name, ' ', u.last_name) AS reviewer_name
            FROM product_reviews r
            JOIN users u ON r.user_id = u.id
            WHERE r.product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
            AND   r.is_active  = 1
            ORDER BY r.created_at DESC
            LIMIT  <cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer">
            OFFSET <cfqueryparam value="#offset#"          cfsqltype="cf_sql_integer">
        </cfquery>

        <cfreturn q>
    </cffunction>


    <!--- GET REVIEW COUNT FOR A PRODUCT --->
    <cffunction name="getProductReviewCount" returntype="numeric" output="false">
        <cfargument name="product_id" type="numeric" required="true">

        <cfquery name="q" datasource="#application.dsn#">
            SELECT COUNT(*) AS total
            FROM product_reviews
            WHERE product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
            AND   is_active  = 1
        </cfquery>

        <cfreturn q.total>
    </cffunction>


    <!--- GET AVERAGE RATING FOR A PRODUCT --->
    <cffunction name="getAverageRating" returntype="struct">
    <cfquery name="q" datasource="#application.dsn#">
        SELECT 
            ROUND(AVG(rating), 1) AS avg_rating,
            COUNT(*) AS total_reviews
        FROM product_reviews
        WHERE product_id = <cfqueryparam value="#arguments.product_id#">
        AND is_active = 1
    </cfquery>

    <cfreturn {
        avg_rating    = val(q.avg_rating),
        total_reviews = q.total_reviews
    }>
</cffunction>

    <!--- GET RATING SUMMARY --->
    <cffunction name="getRatingSummary" returntype="query" output="false">
        <cfargument name="product_id" type="numeric" required="true">

        <cfquery name="q" datasource="#application.dsn#">
            SELECT
                rating,
                COUNT(*) AS cnt
            FROM product_reviews
            WHERE product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
            AND   is_active  = 1
            GROUP BY rating
            ORDER BY rating DESC
        </cfquery>

        <cfreturn q>
    </cffunction>


    <!--- ADMIN FUNCTIONS --->

    <!--- GET ALL REVIEWS WITH SEARCH + PAGINATION  --->
    <cffunction name="getAllReviews" returntype="query" output="false">
        <cfargument name="search"  type="string"  default="">
        <cfargument name="rating"  type="string"  default="">
        <cfargument name="status"  type="string"  default="">
        <cfargument name="page"    type="numeric" default="1">
        <cfargument name="limit"   type="numeric" default="10">

        <cfset var offset      = (arguments.page - 1) * arguments.limit>
        <cfset var searchValue = trim(arguments.search)>

        <cfquery name="q" datasource="#application.dsn#">
            SELECT
                r.id,
                r.rating,
                r.comment,
                r.is_active,
                r.created_at,
                p.product_name,
                CONCAT(u.first_name, ' ', u.last_name) AS user_name
            FROM product_reviews r
            JOIN products p ON r.product_id = p.id
            JOIN users    u ON r.user_id    = u.id
            WHERE 1=1

            <cfif len(searchValue)>
                AND (
                    p.product_name LIKE
                        <cfqueryparam value="%#searchValue#%" cfsqltype="cf_sql_varchar">
                    OR CONCAT(u.first_name,' ',u.last_name) LIKE
                        <cfqueryparam value="%#searchValue#%" cfsqltype="cf_sql_varchar">
                    OR r.comment LIKE
                        <cfqueryparam value="%#searchValue#%" cfsqltype="cf_sql_varchar">
                )
            </cfif>

            <cfif isNumeric(arguments.rating) AND arguments.rating GTE 1 AND arguments.rating LTE 5>
                AND r.rating = <cfqueryparam value="#arguments.rating#" cfsqltype="cf_sql_tinyint">
            </cfif>

            <cfif arguments.status EQ "active">
                AND r.is_active = 1
            <cfelseif arguments.status EQ "removed">
                AND r.is_active = 0
            </cfif>

            ORDER BY r.created_at DESC

            LIMIT  <cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer">
            OFFSET <cfqueryparam value="#offset#"          cfsqltype="cf_sql_integer">
        </cfquery>

        <cfreturn q>
    </cffunction>


    <!--- GET TOTAL COUNT --->
    <cffunction name="getAllReviewCount" returntype="numeric" output="false">
        <cfargument name="search" type="string" default="">
        <cfargument name="rating" type="string" default="">
        <cfargument name="status" type="string" default="">

        <cfset var searchValue = trim(arguments.search)>

        <cfquery name="q" datasource="#application.dsn#">
            SELECT COUNT(*) AS total
            FROM product_reviews r
            JOIN products p ON r.product_id = p.id
            JOIN users    u ON r.user_id    = u.id
            WHERE 1=1

            <cfif len(searchValue)>
                AND (
                    p.product_name LIKE
                        <cfqueryparam value="%#searchValue#%" cfsqltype="cf_sql_varchar">
                    OR CONCAT(u.first_name,' ',u.last_name) LIKE
                        <cfqueryparam value="%#searchValue#%" cfsqltype="cf_sql_varchar">
                    OR r.comment LIKE
                        <cfqueryparam value="%#searchValue#%" cfsqltype="cf_sql_varchar">
                )
            </cfif>

            <cfif isNumeric(arguments.rating) AND arguments.rating GTE 1 AND arguments.rating LTE 5>
                AND r.rating = <cfqueryparam value="#arguments.rating#" cfsqltype="cf_sql_tinyint">
            </cfif>

            <cfif arguments.status EQ "active">
                AND r.is_active = 1
            <cfelseif arguments.status EQ "removed">
                AND r.is_active = 0
            </cfif>
        </cfquery>

        <cfreturn q.total>
    </cffunction>


    <!--- TOGGLE REVIEW VISIBILITY --->
    <cffunction name="toggleReview" returntype="boolean" output="false">
        <cfargument name="id" type="numeric" required="true">

        <cftry>
            <cfquery datasource="#application.dsn#">
                UPDATE product_reviews
                SET is_active = IF(is_active = 1, 0, 1)
                WHERE id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfreturn true>
        <cfcatch>
            <cfreturn false>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>