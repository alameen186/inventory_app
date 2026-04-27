<cfcomponent output="false">
<cffunction name="addEnquiry" returntype="boolean" output="false">
        <cfargument name="user_id" required="true">
        <cfargument name="product_id" required="true">

        <cftry>
            <cfquery datasource="#application.dsn#">
                INSERT INTO product_enquiries(
                        user_id,
                        product_id
                )
                VALUES(
                        <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
                )
            </cfquery>

            <cfreturn true>
            <cfcatch>
    <cfdump var="#cfcatch#">
    <cfabort>
</cfcatch>
        </cftry>
</cffunction>

<cffunction name="getUserEnquiries" returntype="query" output="false">
    <cfargument name="user_id" required="true">
    <cfargument name="page"    type="numeric" default="1">
    <cfargument name="limit"   type="numeric" default="5">
    <cfset var offset = (arguments.page - 1) * arguments.limit>
    <cfquery name="q" datasource="#application.dsn#">
        SELECT
            pe.id,
            pe.status,
            pe.created_at,
            p.product_name,
            p.price,
            p.image
        FROM product_enquiries pe
        INNER JOIN products p ON pe.product_id = p.id
        WHERE pe.user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
        ORDER BY pe.id DESC
        LIMIT  <cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer">
        OFFSET <cfqueryparam value="#offset#"          cfsqltype="cf_sql_integer">
    </cfquery>
    <cfreturn q>
</cffunction>

<cffunction name="getUserEnquiryCount" returntype="numeric" output="false">
    <cfargument name="user_id" required="true">
    <cfquery name="q" datasource="#application.dsn#">
        SELECT COUNT(*) AS total
        FROM   product_enquiries
        WHERE  user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfreturn q.total>
</cffunction>

<cffunction name="enquiryExists" returntype="boolean" output="false">
    <cfargument name="user_id"    required="true">
    <cfargument name="product_id" required="true">
    <cfquery name="q" datasource="#application.dsn#">
        SELECT COUNT(*) AS cnt
        FROM   product_enquiries
        WHERE  user_id    = <cfqueryparam value="#arguments.user_id#"    cfsqltype="cf_sql_integer">
        AND    product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
        AND    status     = 'pending'
    </cfquery>
    <cfreturn q.cnt GT 0>
</cffunction>


<cffunction name="getAllEnquiries" returntype="query" output="false">

    <cfargument name="search" default="">
    <cfargument name="status" default="">
    <cfargument name="page" default="1">
    <cfargument name="limit" default="5">
    <cfargument name="vendor_id" default="">
    <cfargument name="fromDate" default="">
    <cfargument name="toDate" default="">

    <cfset var offset = (arguments.page - 1) * arguments.limit>
    <cfset var searchValue = trim(arguments.search)>

    <cfquery name="q" datasource="#application.dsn#">
        SELECT 
            pe.id,
            pe.product_id,
            pe.user_id,
            pe.created_at,
            pe.status,
            p.product_name,
            p.price,
            p.stock,
            p.image,
            c.category_name,
            CONCAT(u.first_name,' ',u.last_name) AS user_name

        FROM product_enquiries pe
        INNER JOIN products p ON pe.product_id = p.id
        INNER JOIN users u ON pe.user_id = u.id
        LEFT JOIN categories c ON p.category_id = c.id

        WHERE 1=1

<cfif isNumeric(arguments.vendor_id)>
    AND p.vendor_id =
    <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
</cfif>

<cfif len(arguments.fromDate)>
    AND DATE(pe.created_at) >=
    <cfqueryparam value="#arguments.fromDate#" cfsqltype="cf_sql_date">
</cfif>

<cfif len(arguments.toDate)>
    AND DATE(pe.created_at) <=
    <cfqueryparam value="#arguments.toDate#" cfsqltype="cf_sql_date">
</cfif>

        <cfif len(searchValue)>
            AND (
                p.product_name LIKE 
                <cfqueryparam value="%#searchValue#%" cfsqltype="cf_sql_varchar">
                OR CONCAT(u.first_name,' ',u.last_name) LIKE
                <cfqueryparam value="%#searchValue#%" cfsqltype="cf_sql_varchar">
            )
        </cfif>

        <cfif len(arguments.status)>
            AND pe.status =
            <cfqueryparam value="#arguments.status#" cfsqltype="cf_sql_varchar">
        </cfif>

        ORDER BY pe.created_at DESC

        LIMIT <cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer">
        OFFSET <cfqueryparam value="#offset#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfreturn q>

</cffunction>

<cffunction name="restockProduct" returntype="boolean" output="false">
    <cfargument name="product_id" required="true">
    <cfargument name="add_stock"  type="numeric" required="true">
    <cftry>
        <!--- UPDATE PRODUCT STOCK --->
        <cfquery datasource="#application.dsn#">
            UPDATE products
            SET    stock = stock + <cfqueryparam value="#arguments.add_stock#" cfsqltype="cf_sql_integer">
            WHERE  id    = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfquery datasource="#application.dsn#">
            UPDATE product_enquiries
            SET    status = 'fulfilled'
            WHERE  product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
            AND    status     = 'pending'
        </cfquery>

        <cfreturn true>
    <cfcatch>
        <cfreturn false>
    </cfcatch>
    </cftry>
</cffunction>


<cffunction name="markFulfilled" returntype="boolean" output="false">
    <cfargument name="product_id" required="true">

    <cftry>
        <cfquery datasource="#application.dsn#">
            UPDATE product_enquiries
            SET status='fulfilled'
            WHERE product_id =
            <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
            AND status='pending'
        </cfquery>

        <cfreturn true>

        <cfcatch>
            <cfreturn false>
        </cfcatch>
    </cftry>
</cffunction>


<cffunction name="getEnquiryCount" returntype="numeric" output="false">

    <cfargument name="search" default="">
    <cfargument name="status" default="">
    <cfargument name="vendor_id" default="">
    <cfargument name="fromDate" default="">
    <cfargument name="toDate" default="">

    <cfset var searchValue = trim(arguments.search)>

    <cfquery name="q" datasource="#application.dsn#">
        SELECT COUNT(*) AS total

        FROM product_enquiries pe
        INNER JOIN products p ON pe.product_id = p.id
        INNER JOIN users u ON pe.user_id = u.id

        WHERE 1=1

        <cfif isNumeric(arguments.vendor_id)>
    AND p.vendor_id =
    <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
</cfif>

<cfif len(arguments.fromDate)>
    AND DATE(pe.created_at) >=
    <cfqueryparam value="#arguments.fromDate#" cfsqltype="cf_sql_date">
</cfif>

<cfif len(arguments.toDate)>
    AND DATE(pe.created_at) <=
    <cfqueryparam value="#arguments.toDate#" cfsqltype="cf_sql_date">
</cfif>

        <cfif len(searchValue)>
            AND (
                p.product_name LIKE 
                <cfqueryparam value="%#searchValue#%" cfsqltype="cf_sql_varchar">
                OR CONCAT(u.first_name,' ',u.last_name) LIKE
                <cfqueryparam value="%#searchValue#%" cfsqltype="cf_sql_varchar">
            )
        </cfif>

        <cfif len(arguments.status)>
            AND pe.status =
            <cfqueryparam value="#arguments.status#" cfsqltype="cf_sql_varchar">
        </cfif>
    </cfquery>

    <cfreturn q.total>

</cffunction>

</cfcomponent>