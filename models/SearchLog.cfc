<cfcomponent output="false">

    <cffunction name="logSearch" returntype="void" output="false">
        <cfargument name="keyword" required="true">
        <cfargument name="user_id" default="">
        <cfargument name="result_count" type="numeric" default="0">
        <cfargument name="matched_product_id" default="">

        <cfif NOT len(trim(arguments.keyword))><cfreturn></cfif>

        <cftry>
            <!--- Log the search --->
            <cfquery datasource="#application.dsn#">
                INSERT INTO search_logs (user_id, search_keyword, matched_product_id)
                VALUES (
                    <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer" 
                                  null="#NOT isNumeric(arguments.user_id)#">,
                    <cfqueryparam value="#lcase(trim(arguments.keyword))#" cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#arguments.matched_product_id#" cfsqltype="cf_sql_integer"
                                  null="#NOT isNumeric(arguments.matched_product_id)#">
                )
            </cfquery>

            <!--- If no products found, track as unmatched demand --->
            <cfif arguments.result_count EQ 0 AND len(trim(arguments.keyword))>
                <cfquery datasource="#application.dsn#">
                    INSERT INTO unmatched_searches (keyword, search_count)
                    VALUES (
                        <cfqueryparam value="#lcase(trim(arguments.keyword))#" cfsqltype="cf_sql_varchar">,
                        1
                    )
                    ON DUPLICATE KEY UPDATE 
                        search_count = search_count + 1,
                        last_searched_at = NOW()
                </cfquery>
            </cfif>
        <cfcatch></cfcatch>
        </cftry>
    </cffunction>

    <!--- How many times did a product appear in searches --->
    <cffunction name="getProductSearchCount" returntype="numeric" output="false">
        <cfargument name="product_id" required="true">
        <cfquery name="q" datasource="#application.dsn#">
            SELECT COUNT(*) as total FROM search_logs
            WHERE matched_product_id = 
            <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfreturn q.total>
    </cffunction>

    <!--- searches where their products appeared --->
    <cffunction name="getVendorSearchStats" returntype="query" output="false">
        <cfargument name="vendor_id" required="true">
        <cfquery name="q" datasource="#application.dsn#">
            SELECT 
                p.id, p.product_name,
                COUNT(sl.id) as search_appearances,
                MAX(sl.created_at) as last_appeared
            FROM products p
            LEFT JOIN search_logs sl ON sl.matched_product_id = p.id
            WHERE p.vendor_id = 
                <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            GROUP BY p.id, p.product_name
            ORDER BY search_appearances DESC
        </cfquery>
        <cfreturn q>
    </cffunction>

    <!--- Admin/Vendor: unmatched searches (demand for non-existing products) --->
    <cffunction name="getUnmatchedSearches" returntype="query" output="false">
        <cfargument name="limit" type="numeric" default="20">
        <cfquery name="q" datasource="#application.dsn#">
            SELECT keyword, search_count, last_searched_at
            FROM unmatched_searches
            ORDER BY search_count DESC
            LIMIT <cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfreturn q>
    </cffunction>

</cfcomponent>