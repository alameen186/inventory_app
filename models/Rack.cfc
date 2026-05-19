<cfcomponent output="false">

    <cffunction name="createRack" returntype="numeric" output="false">
    <cfargument name="vendor_id" type="numeric" required="true">
    <cfargument name="rack_code" type="string"  required="true">
    <cfargument name="rack_name" type="string"  required="false" default="">
    <cftry>
        <cfquery datasource="#application.dsn#" result="local.insertResult">
            INSERT INTO racks (vendor_id, rack_code, rack_name)
            VALUES (
                <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#arguments.rack_code#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.rack_name#" cfsqltype="cf_sql_varchar">
            )
        </cfquery>
        <cfreturn local.insertResult.GENERATED_KEY>
    <cfcatch>
        <cfreturn 0>
    </cfcatch>
    </cftry>
</cffunction>

   <cffunction name="saveFaces" returntype="boolean" output="false">
    <cfargument name="rack_id" type="numeric" required="true">
    <cfargument name="f1"      type="numeric" required="false" default="0">
    <cfargument name="f2"      type="numeric" required="false" default="0">
    <cfargument name="f3"      type="numeric" required="false" default="0">
    <cfargument name="f4"      type="numeric" required="false" default="0">

    <cfset var localRackId = arguments.rack_id>
    <cfset var localF1     = arguments.f1>
    <cfset var localF2     = arguments.f2>
    <cfset var localF3     = arguments.f3>
    <cfset var localF4     = arguments.f4>

    <cftry>
        <cfif localF1 GT 0>
            <cfquery datasource="#application.dsn#">
                INSERT INTO rack_faces (rack_id, face_code, capacity)
                VALUES (
                    <cfqueryparam value="#localRackId#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="F1"            cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#localF1#"     cfsqltype="cf_sql_integer">
                )
                ON DUPLICATE KEY UPDATE
                    capacity = <cfqueryparam value="#localF1#" cfsqltype="cf_sql_integer">
            </cfquery>
        </cfif>

        <cfif localF2 GT 0>
            <cfquery datasource="#application.dsn#">
                INSERT INTO rack_faces (rack_id, face_code, capacity)
                VALUES (
                    <cfqueryparam value="#localRackId#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="F2"            cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#localF2#"     cfsqltype="cf_sql_integer">
                )
                ON DUPLICATE KEY UPDATE
                    capacity = <cfqueryparam value="#localF2#" cfsqltype="cf_sql_integer">
            </cfquery>
        </cfif>

        <cfif localF3 GT 0>
            <cfquery datasource="#application.dsn#">
                INSERT INTO rack_faces (rack_id, face_code, capacity)
                VALUES (
                    <cfqueryparam value="#localRackId#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="F3"            cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#localF3#"     cfsqltype="cf_sql_integer">
                )
                ON DUPLICATE KEY UPDATE
                    capacity = <cfqueryparam value="#localF3#" cfsqltype="cf_sql_integer">
            </cfquery>
        </cfif>

        <cfif localF4 GT 0>
            <cfquery datasource="#application.dsn#">
                INSERT INTO rack_faces (rack_id, face_code, capacity)
                VALUES (
                    <cfqueryparam value="#localRackId#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="F4"            cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#localF4#"     cfsqltype="cf_sql_integer">
                )
                ON DUPLICATE KEY UPDATE
                    capacity = <cfqueryparam value="#localF4#" cfsqltype="cf_sql_integer">
            </cfquery>
        </cfif>

        <cfreturn true>
    <cfcatch>
        <cflog file="rack_debug"
               text="saveFaces ERROR: #cfcatch.message# | rack_id=#localRackId# f1=#localF1# f2=#localF2# f3=#localF3# f4=#localF4#">
        <cfreturn false>
    </cfcatch>
    </cftry>
</cffunction>

    <cffunction name="getAllRacks" returntype="query" output="false">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT r.id, r.rack_code, r.rack_name, r.is_active, r.vendor_id,
                   u.first_name, u.last_name, u.business_name
            FROM racks r
            JOIN users u ON u.id = r.vendor_id
            ORDER BY r.id DESC
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <cffunction name="getRacksByVendor" returntype="query" output="false">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT id, rack_code, rack_name
            FROM racks
            WHERE vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            AND   is_active = 1
            ORDER BY rack_code ASC
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <cffunction name="getRackFaces" returntype="query" output="false">
        <cfargument name="rack_id" type="numeric" required="true">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT rf.id, rf.face_code, rf.capacity,
                   COUNT(prp.id) AS used_slots
            FROM rack_faces rf
            LEFT JOIN product_rack_placement prp ON prp.rack_face_id = rf.id
            WHERE rf.rack_id = <cfqueryparam value="#arguments.rack_id#" cfsqltype="cf_sql_integer">
            GROUP BY rf.id, rf.face_code, rf.capacity
            ORDER BY rf.face_code ASC
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <cffunction name="getFaceProducts" returntype="query" output="false">
        <cfargument name="rack_face_id" type="numeric" required="true">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT p.id, p.product_name
            FROM product_rack_placement prp
            JOIN products p ON p.id = prp.product_id
            WHERE prp.rack_face_id = <cfqueryparam value="#arguments.rack_face_id#" cfsqltype="cf_sql_integer">
            ORDER BY p.product_name ASC
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <cffunction name="getFaceById" returntype="query" output="false">
        <cfargument name="rack_face_id" type="numeric" required="true">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT rf.id, rf.face_code, rf.capacity,
                   r.rack_code, r.rack_name, r.id AS rack_id,
                   COUNT(prp.id) AS used_slots
            FROM rack_faces rf
            JOIN racks r ON r.id = rf.rack_id
            LEFT JOIN product_rack_placement prp ON prp.rack_face_id = rf.id
            WHERE rf.id = <cfqueryparam value="#arguments.rack_face_id#" cfsqltype="cf_sql_integer">
            GROUP BY rf.id, rf.face_code, rf.capacity, r.rack_code, r.rack_name, r.id
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <cffunction name="toggleRack" returntype="boolean" output="false">
        <cfargument name="id"     type="numeric" required="true">
        <cfargument name="status" type="numeric" required="true">
        <cftry>
            <cfquery datasource="#application.dsn#">
                UPDATE racks
                SET is_active = <cfqueryparam value="#arguments.status#" cfsqltype="cf_sql_integer">
                WHERE id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfreturn true>
        <cfcatch>
            <cfreturn false>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getFaceWithUsage" returntype="query" output="false">
    <cfargument name="rack_face_id" type="numeric" required="true">

    <cfset var localFaceId = arguments.rack_face_id>

    <cfquery name="local.q" datasource="#application.dsn#">
        SELECT
            rf.id,
            rf.face_code,
            rf.capacity,
            r.rack_code,
            r.rack_name,
            r.id AS rack_id,
            COUNT(prp.id) AS used_slots
        FROM rack_faces rf
        JOIN racks r ON r.id = rf.rack_id
        LEFT JOIN product_rack_placement prp ON prp.rack_face_id = rf.id
        WHERE rf.id = <cfqueryparam value="#localFaceId#" cfsqltype="cf_sql_integer">
        GROUP BY rf.id, rf.face_code, rf.capacity, r.rack_code, r.rack_name, r.id
    </cfquery>

    <cfreturn local.q>
</cffunction>

<cffunction name="getFacesWithUsageByRack" returntype="query" output="false">
    <cfargument name="rack_id" type="numeric" required="true">

    <cfset var localRackId = arguments.rack_id>

    <cfquery name="local.q" datasource="#application.dsn#">
        SELECT
            rf.id,
            rf.face_code,
            rf.capacity,
            COUNT(prp.id) AS used_slots,
            (rf.capacity - COUNT(prp.id)) AS available
        FROM rack_faces rf
        LEFT JOIN product_rack_placement prp ON prp.rack_face_id = rf.id
        WHERE rf.rack_id = <cfqueryparam value="#localRackId#" cfsqltype="cf_sql_integer">
        GROUP BY rf.id, rf.face_code, rf.capacity
        ORDER BY rf.face_code ASC
    </cfquery>

    <cfreturn local.q>
</cffunction>
<cffunction name="getRacksByVendorAll" returntype="query" output="false">
    <cfargument name="vendor_id" type="numeric" required="true">
    <cfquery name="local.q" datasource="#application.dsn#">
        SELECT id, rack_code, rack_name, is_active
        FROM racks
        WHERE vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
        ORDER BY rack_code ASC
    </cfquery>
    <cfreturn local.q>
</cffunction>

<cffunction name="toggleRackByVendor" returntype="boolean" output="false">
    <cfargument name="id"        type="numeric" required="true">
    <cfargument name="vendor_id" type="numeric" required="true">
    <cfargument name="status"    type="numeric" required="true">
    <cftry>
        <cfquery name="local.q" datasource="#application.dsn#">
            UPDATE racks
            SET is_active = <cfqueryparam value="#arguments.status#"    cfsqltype="cf_sql_integer">
            WHERE id        = <cfqueryparam value="#arguments.id#"        cfsqltype="cf_sql_integer">
            AND   vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfreturn (local.q.recordCount GT 0)>
    <cfcatch>
        <cfreturn false>
    </cfcatch>
    </cftry>
</cffunction>

</cfcomponent>