<cfcomponent output="false">

    <!--- Get all zones for a vendor --->
    <cffunction name="getByVendor" access="public" returntype="query">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT id, place_name, distance_km, km_price, delivery_fee, is_active, created_at
            FROM delivery_zones
            WHERE vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            ORDER BY place_name ASC
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <!--- Get only active zones  --->
    <cffunction name="getActiveByVendor" access="public" returntype="query">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT id, place_name, distance_km, km_price, delivery_fee
            FROM delivery_zones
            WHERE vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
              AND is_active = 1
            ORDER BY place_name ASC
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <!--- Get fee for a specific zone --->
    <cffunction name="getFee" access="public" returntype="numeric">
        <cfargument name="id"        type="numeric" required="true">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT delivery_fee
            FROM delivery_zones
            WHERE id        = <cfqueryparam value="#arguments.id#"        cfsqltype="cf_sql_integer">
              AND vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
              AND is_active = 1
        </cfquery>
        <cfif local.q.recordCount AND isNumeric(local.q.delivery_fee)>
            <cfreturn val(local.q.delivery_fee)>
        </cfif>
        <cfreturn -1>
    </cffunction>

    <!--- Get zone name by id --->
    <cffunction name="getById" access="public" returntype="query">
        <cfargument name="id"        type="numeric" required="true">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT id, place_name, distance_km, km_price, delivery_fee, is_active
            FROM delivery_zones
            WHERE id        = <cfqueryparam value="#arguments.id#"        cfsqltype="cf_sql_integer">
              AND vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <!--- Save (add or edit) a delivery zone --->
    <cffunction name="save" access="public" returntype="boolean">
        <cfargument name="vendor_id"   type="numeric" required="true">
        <cfargument name="place_name"  type="string"  required="true">
        <cfargument name="distance_km" type="numeric" required="true">
        <cfargument name="km_price"    type="numeric" required="true">
        <cfargument name="id"          type="numeric" default="0">

        <!--- Calculate fee from distance * km_price --->
        <cfset var fee = arguments.distance_km * arguments.km_price>

        <cftry>
            <cfif arguments.id GT 0>
                <cfquery datasource="#application.dsn#">
                    UPDATE delivery_zones
                    SET place_name  = <cfqueryparam value="#arguments.place_name#"  cfsqltype="cf_sql_varchar">,
                        distance_km = <cfqueryparam value="#arguments.distance_km#" cfsqltype="cf_sql_decimal">,
                        km_price    = <cfqueryparam value="#arguments.km_price#"    cfsqltype="cf_sql_decimal">,
                        delivery_fee= <cfqueryparam value="#fee#"                   cfsqltype="cf_sql_decimal">
                    WHERE id        = <cfqueryparam value="#arguments.id#"          cfsqltype="cf_sql_integer">
                      AND vendor_id = <cfqueryparam value="#arguments.vendor_id#"   cfsqltype="cf_sql_integer">
                </cfquery>
            <cfelse>
                <cfquery datasource="#application.dsn#">
                    INSERT INTO delivery_zones
                        (vendor_id, place_name, distance_km, km_price, delivery_fee, is_active)
                    VALUES (
                        <cfqueryparam value="#arguments.vendor_id#"   cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#arguments.place_name#"  cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#arguments.distance_km#" cfsqltype="cf_sql_decimal">,
                        <cfqueryparam value="#arguments.km_price#"    cfsqltype="cf_sql_decimal">,
                        <cfqueryparam value="#fee#"                   cfsqltype="cf_sql_decimal">,
                        1
                    )
                </cfquery>
            </cfif>
            <cfreturn true>
        <cfcatch>
            <cfreturn false>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- Toggle --->
    <cffunction name="toggle" access="public" returntype="boolean">
        <cfargument name="id"        type="numeric" required="true">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cftry>
            <cfquery datasource="#application.dsn#">
                UPDATE delivery_zones
                SET is_active = IF(is_active = 1, 0, 1)
                WHERE id        = <cfqueryparam value="#arguments.id#"        cfsqltype="cf_sql_integer">
                  AND vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfreturn true>
        <cfcatch>
            <cfreturn false>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- Delete a zone  --->
    <cffunction name="delete" access="public" returntype="boolean">
        <cfargument name="id"        type="numeric" required="true">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cftry>
            <cfquery datasource="#application.dsn#">
                DELETE FROM delivery_zones
                WHERE id        = <cfqueryparam value="#arguments.id#"        cfsqltype="cf_sql_integer">
                  AND vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfreturn true>
        <cfcatch>
            <cfreturn false>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>
