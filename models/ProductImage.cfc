<cfcomponent output="false">

    <cffunction name="getByProduct" returntype="query">
    <cfargument name="product_id" required="true">

    <cfquery name="q" datasource="#application.dsn#">
        SELECT id, image, sort_order
        FROM product_images
        WHERE product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
        ORDER BY sort_order ASC
    </cfquery>

    <!--- If no rows in product_images, pull legacy columns from products table --->
    <cfif q.recordCount EQ 0>
        <cfquery name="legacy" datasource="#application.dsn#">
            SELECT image, image2, image3
            FROM products
            WHERE id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfif legacy.recordCount>
            <!--- Build a query object manually from legacy columns --->
            <cfset var legacyQ = queryNew("id,image,sort_order","integer,varchar,integer")>
            <cfset var sort = 1>
            <cfloop list="image,image2,image3" index="col">
                <cfif len(trim(legacy[col][1]))>
                    <cfset queryAddRow(legacyQ)>
                    <cfset querySetCell(legacyQ, "id",         0)>
                    <cfset querySetCell(legacyQ, "image",      trim(legacy[col][1]))>
                    <cfset querySetCell(legacyQ, "sort_order", sort)>
                    <cfset sort++>
                </cfif>
            </cfloop>
            <cfreturn legacyQ>
        </cfif>
    </cfif>

    <cfreturn q>
</cffunction>

   <cffunction name="addImage" returntype="boolean">
    <cfargument name="product_id" required="true">
    <cfargument name="image" required="true">
    <cfargument name="sort_order" required="false" default="0">

    <cftry>
        <cfquery datasource="#application.dsn#">
            INSERT INTO product_images (product_id, image, sort_order)
            VALUES (
                <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#arguments.image#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.sort_order#" cfsqltype="cf_sql_integer">
            )
        </cfquery>
        <cfreturn true>
    <cfcatch>
        <cfreturn false>
    </cfcatch>
    </cftry>
</cffunction>

    <cffunction name="deleteImage" returntype="boolean">
        <cfargument name="id"         required="true">
        <cfargument name="product_id" required="true">
        <cftry>
            <cfquery name="imgQ" datasource="#application.dsn#">
                SELECT image FROM product_images
                WHERE id         = <cfqueryparam value="#arguments.id#"         cfsqltype="cf_sql_integer">
                AND   product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfif imgQ.recordCount AND len(imgQ.image)>
                <cfset var filePath = expandPath("../../assets/images/products/") & imgQ.image>
                <cfif fileExists(filePath)>
                    <cffile action="delete" file="#filePath#">
                </cfif>
            </cfif>
            <cfquery datasource="#application.dsn#">
                DELETE FROM product_images
                WHERE id         = <cfqueryparam value="#arguments.id#"         cfsqltype="cf_sql_integer">
                AND   product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfreturn true>
        <cfcatch>
            <cfreturn false>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="deleteAllForProduct" returntype="void">
        <cfargument name="product_id" required="true">
        <cfquery name="imgs" datasource="#application.dsn#">
            SELECT image FROM product_images
            WHERE product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfloop query="imgs">
            <cfif len(imgs.image)>
                <cfset var filePath = expandPath("../../assets/images/products/") & imgs.image>
                <cfif fileExists(filePath)><cffile action="delete" file="#filePath#"></cfif>
            </cfif>
        </cfloop>
        <cfquery datasource="#application.dsn#">
            DELETE FROM product_images
            WHERE product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
        </cfquery>
    </cffunction>

    <cffunction name="getCount" returntype="numeric">
        <cfargument name="product_id" required="true">
        <cfquery name="q" datasource="#application.dsn#">
            SELECT COUNT(*) AS total FROM product_images
            WHERE product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfreturn q.total>
    </cffunction>

</cfcomponent>