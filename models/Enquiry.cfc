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
            WHERE pe.user_id = 
            <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
            ORDER BY pe.id DESC
       </cfquery>
       <cfreturn q>
</cffunction>

</cfcomponent>