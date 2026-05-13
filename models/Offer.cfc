<cfcomponent output="false">

    <!--- GET ALL OFFERS FOR VENDOR --->
    <cffunction name="getAll" returntype="query" output="false">
        <cfargument name="vendor_id"   type="numeric" required="true">
        <cfargument name="offer_type"  type="string"  default="">

        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT
                o.id,
                o.offer_name,
                o.offer_type,
                o.discount_type,
                o.discount_value,
                o.start_date,
                o.end_date,
                o.is_active,
                o.created_at,
                o.category_id,
                o.product_id,
                COALESCE(c.category_name, '')  AS category_name,
                COALESCE(p.product_name,  '')  AS product_name,
                CASE
                    WHEN o.end_date < CURDATE() THEN 'expired'
                    WHEN o.start_date > CURDATE() THEN 'upcoming'
                    ELSE 'active'
                END AS offer_status,
                CASE
                    WHEN o.offer_type = 'seasonal' THEN (
                        SELECT COUNT(*) FROM products
                        WHERE category_id = o.category_id
                        AND   vendor_id   = o.vendor_id
                        AND   is_active   = 1
                    )
                    ELSE 1
                END AS affected_count
            FROM offers o
            LEFT JOIN categories c ON c.id = o.category_id
            LEFT JOIN products   p ON p.id = o.product_id
            WHERE o.vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            <cfif len(trim(arguments.offer_type))>
                AND o.offer_type = <cfqueryparam value="#arguments.offer_type#" cfsqltype="cf_sql_varchar">
            </cfif>
            ORDER BY o.created_at DESC
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <!--- GET SINGLE OFFER --->
    <cffunction name="getById" returntype="query" output="false">
        <cfargument name="id"        type="numeric" required="true">
        <cfargument name="vendor_id" type="numeric" required="true">

        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT * FROM offers
            WHERE id        = <cfqueryparam value="#arguments.id#"        cfsqltype="cf_sql_integer">
            AND   vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <cffunction name="add" returntype="struct" output="false">
        <cfargument name="vendor_id"      type="numeric" required="true">
        <cfargument name="offer_name"     type="string"  required="true">
        <cfargument name="offer_type"     type="string"  required="true">
        <cfargument name="category_id"    type="string"  default="">
        <cfargument name="product_id"     type="string"  default="">
        <cfargument name="discount_type"  type="string"  required="true">
        <cfargument name="discount_value" type="numeric" required="true">
        <cfargument name="start_date"     type="string"  required="true">
        <cfargument name="end_date"       type="string"  required="true">
        <cfargument name="is_active"      type="numeric" default="1">

        <cftry>
            <cfquery datasource="#application.dsn#">
                INSERT INTO offers (
                    vendor_id, offer_name, offer_type,
                    category_id, product_id,
                    discount_type, discount_value,
                    start_date, end_date, is_active
                ) VALUES (
                    <cfqueryparam value="#arguments.vendor_id#"      cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#arguments.offer_name#"     cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#arguments.offer_type#"     cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#arguments.category_id#"    cfsqltype="cf_sql_integer"
                                  null="#NOT isNumeric(arguments.category_id) OR val(arguments.category_id) EQ 0#">,
                    <cfqueryparam value="#arguments.product_id#"     cfsqltype="cf_sql_integer"
                                  null="#NOT isNumeric(arguments.product_id) OR val(arguments.product_id) EQ 0#">,
                    <cfqueryparam value="#arguments.discount_type#"  cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#arguments.discount_value#" cfsqltype="cf_sql_decimal">,
                    <cfqueryparam value="#arguments.start_date#"     cfsqltype="cf_sql_date">,
                    <cfqueryparam value="#arguments.end_date#"       cfsqltype="cf_sql_date">,
                    <cfqueryparam value="#arguments.is_active#"      cfsqltype="cf_sql_integer">
                )
            </cfquery>
            <cfreturn { success: true }>
        <cfcatch>
            <cfreturn { success: false, message: cfcatch.message }>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="update" returntype="struct" output="false">
        <cfargument name="id"             type="numeric" required="true">
        <cfargument name="vendor_id"      type="numeric" required="true">
        <cfargument name="offer_name"     type="string"  required="true">
        <cfargument name="offer_type"     type="string"  required="true">
        <cfargument name="category_id"    type="string"  default="">
        <cfargument name="product_id"     type="string"  default="">
        <cfargument name="discount_type"  type="string"  required="true">
        <cfargument name="discount_value" type="numeric" required="true">
        <cfargument name="start_date"     type="string"  required="true">
        <cfargument name="end_date"       type="string"  required="true">
        <cfargument name="is_active"      type="numeric" default="1">

        <cftry>
            <cfquery datasource="#application.dsn#">
                UPDATE offers SET
                    offer_name     = <cfqueryparam value="#arguments.offer_name#"     cfsqltype="cf_sql_varchar">,
                    offer_type     = <cfqueryparam value="#arguments.offer_type#"     cfsqltype="cf_sql_varchar">,
                    category_id    = <cfqueryparam value="#arguments.category_id#"    cfsqltype="cf_sql_integer"
                                      null="#NOT isNumeric(arguments.category_id) OR val(arguments.category_id) EQ 0#">,
                    product_id     = <cfqueryparam value="#arguments.product_id#"     cfsqltype="cf_sql_integer"
                                      null="#NOT isNumeric(arguments.product_id) OR val(arguments.product_id) EQ 0#">,
                    discount_type  = <cfqueryparam value="#arguments.discount_type#"  cfsqltype="cf_sql_varchar">,
                    discount_value = <cfqueryparam value="#arguments.discount_value#" cfsqltype="cf_sql_decimal">,
                    start_date     = <cfqueryparam value="#arguments.start_date#"     cfsqltype="cf_sql_date">,
                    end_date       = <cfqueryparam value="#arguments.end_date#"       cfsqltype="cf_sql_date">,
                    is_active      = <cfqueryparam value="#arguments.is_active#"      cfsqltype="cf_sql_integer">
                WHERE id        = <cfqueryparam value="#arguments.id#"        cfsqltype="cf_sql_integer">
                AND   vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfreturn { success: true }>
        <cfcatch>
            <cfreturn { success: false, message: cfcatch.message }>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="toggleStatus" returntype="struct" output="false">
        <cfargument name="id"        type="numeric" required="true">
        <cfargument name="vendor_id" type="numeric" required="true">

        <cftry>
            <cfquery datasource="#application.dsn#">
                UPDATE offers
                SET is_active = CASE WHEN is_active = 1 THEN 0 ELSE 1 END
                WHERE id        = <cfqueryparam value="#arguments.id#"        cfsqltype="cf_sql_integer">
                AND   vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfquery name="local.s" datasource="#application.dsn#">
                SELECT is_active FROM offers
                WHERE id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfreturn { success: true, is_active: local.s.is_active }>
        <cfcatch>
            <cfreturn { success: false, message: cfcatch.message }>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="delete" returntype="struct" output="false">
        <cfargument name="id"        type="numeric" required="true">
        <cfargument name="vendor_id" type="numeric" required="true">

        <cftry>
            <cfquery datasource="#application.dsn#">
                DELETE FROM offers
                WHERE id        = <cfqueryparam value="#arguments.id#"        cfsqltype="cf_sql_integer">
                AND   vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfreturn { success: true }>
        <cfcatch>
            <cfreturn { success: false, message: cfcatch.message }>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- GET ALL CUSTOMERS FOR EMAIL --->
   <cffunction name="getCustomerEmails" returntype="query" output="false">
    <cfquery name="local.q" datasource="#application.dsn#">
        SELECT u.id, u.first_name, u.last_name, u.email
        FROM users u
        JOIN roles r ON r.id = u.role_id
        WHERE r.role_name = 'Customer'
        AND u.email IS NOT NULL
        AND LENGTH(TRIM(u.email)) > 0
        ORDER BY u.first_name ASC
    </cfquery>
    <cfreturn local.q>
</cffunction>

    <!--- GET VENDOR NAME FOR EMAIL --->
    <cffunction name="getVendorName" returntype="string" output="false">
        <cfargument name="vendor_id" type="numeric" required="true">

        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT COALESCE(business_name, CONCAT(first_name,' ',last_name)) AS biz
            FROM users
            WHERE id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfreturn local.q.recordCount ? local.q.biz : "">
    </cffunction>


<cffunction name="getActiveOfferForProduct" returntype="struct" output="false">
    <cfargument name="product_id" type="numeric" required="true">

    <cfquery name="local.indiv" datasource="#application.dsn#">
        SELECT
            o.id,
            o.offer_name,
            o.discount_type,
            o.discount_value
        FROM offers o
        WHERE o.offer_type  = 'individual'
        AND   o.product_id  = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
        AND   o.is_active   = 1
        AND   o.start_date <= CURDATE()
        AND   o.end_date   >= CURDATE()
        ORDER BY o.discount_value DESC
        LIMIT 1
    </cfquery>

    <cfif local.indiv.recordCount GT 0>
        <cfreturn {
            hasOffer       : true,
            offer_name     : local.indiv.offer_name,
            discount_type  : local.indiv.discount_type,
            discount_value : local.indiv.discount_value
        }>
    </cfif>

    <cfquery name="local.seasonal" datasource="#application.dsn#">
        SELECT
            o.id,
            o.offer_name,
            o.discount_type,
            o.discount_value
        FROM offers o
        JOIN products p ON p.category_id = o.category_id
        WHERE o.offer_type  = 'seasonal'
        AND   p.id          = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
        AND   o.is_active   = 1
        AND   o.start_date <= CURDATE()
        AND   o.end_date   >= CURDATE()
        ORDER BY o.discount_value DESC
        LIMIT 1
    </cfquery>

    <cfif local.seasonal.recordCount GT 0>
        <cfreturn {
            hasOffer       : true,
            offer_name     : local.seasonal.offer_name,
            discount_type  : local.seasonal.discount_type,
            discount_value : local.seasonal.discount_value
        }>
    </cfif>

    <!--- No active offer --->
    <cfreturn {
        hasOffer       : false,
        offer_name     : "",
        discount_type  : "",
        discount_value : 0
    }>
</cffunction>

</cfcomponent>