<cfcomponent output="false">

    <cffunction name="getByVendor" access="public" returntype="query">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT id, vehicle_name, vehicle_number, vehicle_type,capacity_units, is_active, created_at
            FROM vendor_vehicles
            WHERE vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            ORDER BY created_at DESC
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <cffunction name="getActiveByVendor" access="public" returntype="query">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT id, vehicle_name, vehicle_number, vehicle_type, capacity_units
            FROM vendor_vehicles
            WHERE vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
              AND is_active = 1
            ORDER BY vehicle_name ASC
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <cffunction name="save" access="public" returntype="boolean">
        <cfargument name="vendor_id"      type="numeric" required="true">
        <cfargument name="vehicle_name"   type="string"  required="true">
        <cfargument name="vehicle_number" type="string"  required="true">
        <cfargument name="vehicle_type"   type="string"  required="true">
        <cfargument name="capacity_units" type="string"  default="">
        <cfargument name="id"             type="numeric" default="0">
        <cftry>
            <cfif arguments.id GT 0>
                <cfquery datasource="#application.dsn#">
                    UPDATE vendor_vehicles
                    SET vehicle_name   = <cfqueryparam value="#arguments.vehicle_name#"   cfsqltype="cf_sql_varchar">,
                        vehicle_number = <cfqueryparam value="#arguments.vehicle_number#" cfsqltype="cf_sql_varchar">,
                        vehicle_type   = <cfqueryparam value="#arguments.vehicle_type#"   cfsqltype="cf_sql_varchar">,
                        capacity_units = <cfqueryparam value="#arguments.capacity_units#" cfsqltype="cf_sql_integer"
                                            null="#NOT isNumeric(arguments.capacity_units) OR NOT val(arguments.capacity_units)#">
                    WHERE id        = <cfqueryparam value="#arguments.id#"        cfsqltype="cf_sql_integer">
                      AND vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
                </cfquery>
            <cfelse>
                <cfquery datasource="#application.dsn#">
                    INSERT INTO vendor_vehicles
                        (vendor_id, vehicle_name, vehicle_number, vehicle_type, capacity_units)
                    VALUES (
                        <cfqueryparam value="#arguments.vendor_id#"      cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#arguments.vehicle_name#"   cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#arguments.vehicle_number#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#arguments.vehicle_type#"   cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#arguments.capacity_units#" cfsqltype="cf_sql_integer"
                            null="#NOT isNumeric(arguments.capacity_units) OR NOT val(arguments.capacity_units)#">
                    )
                </cfquery>
            </cfif>
            <cfreturn true>
        <cfcatch>
            <cfreturn false>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="toggle" access="public" returntype="boolean">
        <cfargument name="id"        type="numeric" required="true">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cftry>
            <cfquery datasource="#application.dsn#">
                UPDATE vendor_vehicles
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

    <cffunction name="getById" access="public" returntype="query">
        <cfargument name="id"        type="numeric" required="true">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT id, vehicle_name, vehicle_number, vehicle_type,  capacity_units,is_active
            FROM vendor_vehicles
            WHERE id        = <cfqueryparam value="#arguments.id#"        cfsqltype="cf_sql_integer">
              AND vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <cffunction name="getCapacity" access="public" returntype="numeric">
        <cfargument name="id"        type="numeric" required="true">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT capacity_units
            FROM vendor_vehicles
            WHERE id        = <cfqueryparam value="#arguments.id#"        cfsqltype="cf_sql_integer">
              AND vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfif local.q.recordCount AND isNumeric(local.q.capacity_units)>
            <cfreturn val(local.q.capacity_units)>
        </cfif>
        <cfreturn 0>
    </cffunction>

</cfcomponent>
