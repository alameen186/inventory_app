<cfcomponent output="false">

    <cffunction name="getAll" returntype="query" output="false">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT id, full_name, phone, email, gender,
                   position, join_date, profile_image, is_active, created_at
            FROM staff
            WHERE vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            ORDER BY created_at DESC
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <cffunction name="getById" returntype="query" output="false">
        <cfargument name="id"        type="numeric" required="true">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT * FROM staff
            WHERE id        = <cfqueryparam value="#arguments.id#"        cfsqltype="cf_sql_integer">
            AND   vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <cffunction name="add" returntype="struct" output="false">
        <cfargument name="vendor_id"      type="numeric" required="true">
        <cfargument name="full_name"      type="string"  required="true">
        <cfargument name="phone"          type="string"  required="true">
        <cfargument name="email"          type="string"  default="">
        <cfargument name="gender"         type="string"  default="">
        <cfargument name="date_of_birth"  type="string"  default="">
        <cfargument name="address"        type="string"  default="">
        <cfargument name="position"       type="string"  default="">
        <cfargument name="salary"         type="string"  default="">
        <cfargument name="join_date"      type="string"  default="">
        <cfargument name="profile_image"  type="string"  default="">
        <cfargument name="aadhaar_number" type="string"  default="">
        <cfargument name="aadhaar_image"  type="string"  default="">

        <cftry>
            <cfquery datasource="#application.dsn#">
                INSERT INTO staff (
                    vendor_id, full_name, phone, email, gender,
                    date_of_birth, address, position, salary,
                    join_date, profile_image, aadhaar_number, aadhaar_front
                ) VALUES (
                    <cfqueryparam value="#arguments.vendor_id#"      cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#arguments.full_name#"      cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#arguments.phone#"          cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#arguments.email#"          cfsqltype="cf_sql_varchar" null="#NOT len(trim(arguments.email))#">,
                    <cfqueryparam value="#arguments.gender#"         cfsqltype="cf_sql_varchar" null="#NOT len(trim(arguments.gender))#">,
                    <cfqueryparam value="#arguments.date_of_birth#"  cfsqltype="cf_sql_date"    null="#NOT len(trim(arguments.date_of_birth))#">,
                    <cfqueryparam value="#arguments.address#"        cfsqltype="cf_sql_varchar" null="#NOT len(trim(arguments.address))#">,
                    <cfqueryparam value="#arguments.position#"       cfsqltype="cf_sql_varchar" null="#NOT len(trim(arguments.position))#">,
                    <cfqueryparam value="#arguments.salary#"         cfsqltype="cf_sql_decimal" null="#NOT isNumeric(arguments.salary)#">,
                    <cfqueryparam value="#arguments.join_date#"      cfsqltype="cf_sql_date"    null="#NOT len(trim(arguments.join_date))#">,
                    <cfqueryparam value="#arguments.profile_image#"  cfsqltype="cf_sql_varchar" null="#NOT len(trim(arguments.profile_image))#">,
                    <cfqueryparam value="#arguments.aadhaar_number#" cfsqltype="cf_sql_varchar" null="#NOT len(trim(arguments.aadhaar_number))#">,
                    <cfqueryparam value="#arguments.aadhaar_image#"  cfsqltype="cf_sql_varchar" null="#NOT len(trim(arguments.aadhaar_image))#">
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
        <cfargument name="full_name"      type="string"  required="true">
        <cfargument name="phone"          type="string"  required="true">
        <cfargument name="email"          type="string"  default="">
        <cfargument name="gender"         type="string"  default="">
        <cfargument name="date_of_birth"  type="string"  default="">
        <cfargument name="address"        type="string"  default="">
        <cfargument name="position"       type="string"  default="">
        <cfargument name="salary"         type="string"  default="">
        <cfargument name="join_date"      type="string"  default="">
        <cfargument name="profile_image"  type="string"  default="">
        <cfargument name="aadhaar_number" type="string"  default="">
        <cfargument name="aadhaar_image"  type="string"  default="">

        <cftry>
            <cfquery datasource="#application.dsn#">
                UPDATE staff SET
                    full_name      = <cfqueryparam value="#arguments.full_name#"      cfsqltype="cf_sql_varchar">,
                    phone          = <cfqueryparam value="#arguments.phone#"          cfsqltype="cf_sql_varchar">,
                    email          = <cfqueryparam value="#arguments.email#"          cfsqltype="cf_sql_varchar" null="#NOT len(trim(arguments.email))#">,
                    gender         = <cfqueryparam value="#arguments.gender#"         cfsqltype="cf_sql_varchar" null="#NOT len(trim(arguments.gender))#">,
                    date_of_birth  = <cfqueryparam value="#arguments.date_of_birth#"  cfsqltype="cf_sql_date"    null="#NOT len(trim(arguments.date_of_birth))#">,
                    address        = <cfqueryparam value="#arguments.address#"        cfsqltype="cf_sql_varchar" null="#NOT len(trim(arguments.address))#">,
                    position       = <cfqueryparam value="#arguments.position#"       cfsqltype="cf_sql_varchar" null="#NOT len(trim(arguments.position))#">,
                    salary         = <cfqueryparam value="#arguments.salary#"         cfsqltype="cf_sql_decimal" null="#NOT isNumeric(arguments.salary)#">,
                    join_date      = <cfqueryparam value="#arguments.join_date#"      cfsqltype="cf_sql_date"    null="#NOT len(trim(arguments.join_date))#">,
                    aadhaar_number = <cfqueryparam value="#arguments.aadhaar_number#" cfsqltype="cf_sql_varchar" null="#NOT len(trim(arguments.aadhaar_number))#">
                    <!--- Only update image columns if a new file was uploaded --->
                    <cfif len(trim(arguments.profile_image))>
                        , profile_image = <cfqueryparam value="#arguments.profile_image#" cfsqltype="cf_sql_varchar">
                    </cfif>
                    <cfif len(trim(arguments.aadhaar_image))>
                        , aadhaar_front = <cfqueryparam value="#arguments.aadhaar_image#" cfsqltype="cf_sql_varchar">
                    </cfif>
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
                UPDATE staff
                SET is_active = CASE WHEN is_active = 1 THEN 0 ELSE 1 END
                WHERE id        = <cfqueryparam value="#arguments.id#"        cfsqltype="cf_sql_integer">
                AND   vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfquery name="local.s" datasource="#application.dsn#">
                SELECT is_active FROM staff
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
                DELETE FROM staff
                WHERE id        = <cfqueryparam value="#arguments.id#"        cfsqltype="cf_sql_integer">
                AND   vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfreturn { success: true }>
        <cfcatch>
            <cfreturn { success: false, message: cfcatch.message }>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getActiveStaff" returntype="query" output="false">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT id, full_name, position
            FROM staff
            WHERE vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            AND   is_active = 1
            ORDER BY full_name ASC
        </cfquery>
        <cfreturn local.q>
    </cffunction>

</cfcomponent>