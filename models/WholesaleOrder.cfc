<cfcomponent output="false">


    <cffunction name="getDistricts" access="public" returntype="array" output="false">
        <cfset var districts = [
            { name: "Thiruvananthapuram", fee: 50  },
            { name: "Kollam",             fee: 110 },
            { name: "Alappuzha",          fee: 110 },
            { name: "Kottayam",           fee: 110 },
            { name: "Idukki",             fee: 170 },
            { name: "Ernakulam",          fee: 140 },
            { name: "Thrissur",           fee: 140 },
            { name: "Palakkad",           fee: 170 },
            { name: "Malappuram",         fee: 170 },
            { name: "Kozhikode",          fee: 170 },
            { name: "Wayanad",            fee: 170 },
            { name: "Kannur",             fee: 170 },
            { name: "Kasaragod",          fee: 170 },
            { name: "Pathanamthitta",     fee: 110 }
        ]>
        <cfreturn districts>
    </cffunction>

    <cffunction name="getDistrictFee" access="public" returntype="numeric" output="false">
        <cfargument name="district_name" type="string" required="true">
        <cfset var districts = getDistricts()>
        <cfloop array="#districts#" index="local.d">
            <cfif local.d.name EQ trim(arguments.district_name)>
                <cfreturn local.d.fee>
            </cfif>
        </cfloop>
        <cfreturn -1>
    </cffunction>

    <cffunction name="createOrder" access="public" returntype="struct">
        <cfargument name="vendor_id"         type="numeric" required="true">
        <cfargument name="temp_user_id"      type="numeric" required="true">
        <cfargument name="assigned_staff_id" type="numeric" required="true">
        <cfargument name="vehicle_id"        type="numeric" required="true">
        <cfargument name="district_name"     type="string"  required="true">
        <cfargument name="delivery_fee"      type="numeric" required="true">
        <cfargument name="notes"             type="string"  default="">
        <cfargument name="items"             type="array"   required="true">

        <cfset var result    = { success: false, message: "", group_id: "", order_id: 0 }>
        <cfset var group_id  = "WS-" & dateFormat(now(),"yyyymmdd") & "-" & randRange(10000,99999)>
        <cfset var grandTotal = 0>

        <cfloop array="#arguments.items#" index="local.item">
            <cfset grandTotal += local.item.total_price>
        </cfloop>

        <cfset var totalWithDelivery = grandTotal + arguments.delivery_fee>

        <cftry>
            <cfquery datasource="#application.dsn#">
                INSERT INTO wholesale_orders
                    (group_id, vendor_id, temp_user_id, assigned_staff_id, vehicle_id,
                     district_name, delivery_fee, total_amount, total_with_delivery,
                     notes, status)
                VALUES (
                    <cfqueryparam value="#group_id#"                    cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#arguments.vendor_id#"         cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#arguments.temp_user_id#"      cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#arguments.assigned_staff_id#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#arguments.vehicle_id#"        cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#arguments.district_name#"     cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#arguments.delivery_fee#"      cfsqltype="cf_sql_decimal">,
                    <cfqueryparam value="#grandTotal#"                  cfsqltype="cf_sql_decimal">,
                    <cfqueryparam value="#totalWithDelivery#"           cfsqltype="cf_sql_decimal">,
                    <cfqueryparam value="#arguments.notes#"             cfsqltype="cf_sql_longvarchar">,
                    'pending'
                )
            </cfquery>

            <cfquery name="local.lastId" datasource="#application.dsn#">
                SELECT LAST_INSERT_ID() AS new_id
            </cfquery>
            <cfset var orderId = local.lastId.new_id>

            <cfloop array="#arguments.items#" index="local.item">
                <cfquery datasource="#application.dsn#">
                    INSERT INTO wholesale_order_items
                        (wholesale_order_id, product_id, qty, unit_price, total_price)
                    VALUES (
                        <cfqueryparam value="#orderId#"                cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#local.item.product_id#"  cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#local.item.qty#"         cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#local.item.unit_price#"  cfsqltype="cf_sql_decimal">,
                        <cfqueryparam value="#local.item.total_price#" cfsqltype="cf_sql_decimal">
                    )
                </cfquery>

                <!--- Reduce stock immediately --->
                <cfquery datasource="#application.dsn#">
                    UPDATE products
                    SET stock = stock - <cfqueryparam value="#local.item.qty#"        cfsqltype="cf_sql_integer">
                    WHERE id  = <cfqueryparam value="#local.item.product_id#"         cfsqltype="cf_sql_integer">
                      AND stock >= <cfqueryparam value="#local.item.qty#"             cfsqltype="cf_sql_integer">
                </cfquery>
            </cfloop>

            <cfset result.success  = true>
            <cfset result.group_id = group_id>
            <cfset result.order_id = orderId>
            <cfset result.total_with_delivery = totalWithDelivery>

        <cfcatch>
            <cfset result.success = false>
            <cfset result.message = cfcatch.message>
        </cfcatch>
        </cftry>

        <cfreturn result>
    </cffunction>

    <!--- Get all orders for a vendor with pagination --->
    <cffunction name="getByVendor" access="public" returntype="query">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfargument name="search"    type="string"  default="">
        <cfargument name="status"    type="string"  default="">
        <cfargument name="page"      type="numeric" default="1">
        <cfargument name="limit"     type="numeric" default="10">

        <cfset var offset = (arguments.page - 1) * arguments.limit>

        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT
                wo.id,
                wo.group_id,
                wo.status,
                wo.total_amount,
                wo.delivery_fee,
                wo.total_with_delivery,
                wo.district_name,
                wo.notes,
                wo.created_at,
                CONCAT(tu.first_name, ' ', tu.last_name) AS customer_name,
                tu.email   AS customer_email,
                tu.phone   AS customer_phone,
                s.full_name AS staff_name,
                vv.vehicle_name,
                vv.vehicle_number,
                vv.capacity_units
            FROM wholesale_orders wo
            LEFT JOIN temp_users tu      ON tu.id  = wo.temp_user_id
            LEFT JOIN staff s            ON s.id   = wo.assigned_staff_id
            LEFT JOIN vendor_vehicles vv ON vv.id  = wo.vehicle_id
            WHERE wo.vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            <cfif len(trim(arguments.search))>
                AND (
                    wo.group_id      LIKE <cfqueryparam value="%#arguments.search#%" cfsqltype="cf_sql_varchar">
                    OR tu.first_name LIKE <cfqueryparam value="%#arguments.search#%" cfsqltype="cf_sql_varchar">
                    OR tu.last_name  LIKE <cfqueryparam value="%#arguments.search#%" cfsqltype="cf_sql_varchar">
                    OR tu.email      LIKE <cfqueryparam value="%#arguments.search#%" cfsqltype="cf_sql_varchar">
                    OR wo.district_name LIKE <cfqueryparam value="%#arguments.search#%" cfsqltype="cf_sql_varchar">
                )
            </cfif>
            <cfif len(trim(arguments.status))>
                AND wo.status = <cfqueryparam value="#arguments.status#" cfsqltype="cf_sql_varchar">
            </cfif>
            ORDER BY wo.created_at DESC
            LIMIT  <cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer">
            OFFSET <cfqueryparam value="#offset#"          cfsqltype="cf_sql_integer">
        </cfquery>
        <cfreturn local.q>
    </cffunction>


    <!--- Count for pagination --->
    <cffunction name="getByVendorCount" access="public" returntype="numeric">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfargument name="search"    type="string"  default="">
        <cfargument name="status"    type="string"  default="">

        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT COUNT(*) AS total
            FROM wholesale_orders wo
            LEFT JOIN temp_users tu ON tu.id = wo.temp_user_id
            WHERE wo.vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            <cfif len(trim(arguments.search))>
                AND (
                    wo.group_id      LIKE <cfqueryparam value="%#arguments.search#%" cfsqltype="cf_sql_varchar">
                    OR tu.first_name LIKE <cfqueryparam value="%#arguments.search#%" cfsqltype="cf_sql_varchar">
                    OR tu.last_name  LIKE <cfqueryparam value="%#arguments.search#%" cfsqltype="cf_sql_varchar">
                    OR tu.email      LIKE <cfqueryparam value="%#arguments.search#%" cfsqltype="cf_sql_varchar">
                    OR wo.district_name LIKE <cfqueryparam value="%#arguments.search#%" cfsqltype="cf_sql_varchar">
                )
            </cfif>
            <cfif len(trim(arguments.status))>
                AND wo.status = <cfqueryparam value="#arguments.status#" cfsqltype="cf_sql_varchar">
            </cfif>
        </cfquery>
        <cfreturn local.q.total>
    </cffunction>


    <!--- Get items for a single order --->
    <cffunction name="getById" access="public" returntype="query">
        <cfargument name="id"        type="numeric" required="true">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT
                wo.id,
                wo.group_id,
                wo.status,
                wo.total_amount,
                wo.delivery_fee,
                wo.total_with_delivery,
                wo.district_name,
                wo.notes,
                wo.created_at,
                tu.first_name AS customer_first_name,
                tu.last_name  AS customer_last_name,
                tu.email      AS customer_email,
                tu.phone      AS customer_phone,
                s.full_name   AS staff_name,
                vv.vehicle_name,
                vv.vehicle_number,
                vv.vehicle_type,
                vv.capacity_units
            FROM wholesale_orders wo
            LEFT JOIN temp_users tu      ON tu.id  = wo.temp_user_id
            LEFT JOIN staff s            ON s.id   = wo.assigned_staff_id
            LEFT JOIN vendor_vehicles vv ON vv.id  = wo.vehicle_id
            WHERE wo.id        = <cfqueryparam value="#arguments.id#"        cfsqltype="cf_sql_integer">
              AND wo.vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <cffunction name="getItems" access="public" returntype="query">
        <cfargument name="wholesale_order_id" type="numeric" required="true">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT
                woi.id,
                woi.product_id,
                woi.qty,
                woi.unit_price,
                woi.total_price,
                p.product_name
            FROM wholesale_order_items woi
            JOIN products p ON p.id = woi.product_id
            WHERE woi.wholesale_order_id =
                <cfqueryparam value="#arguments.wholesale_order_id#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfreturn local.q>
    </cffunction>

    <cffunction name="updateStatus" access="public" returntype="boolean">
        <cfargument name="id"        type="numeric" required="true">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfargument name="status"    type="string"  required="true">
        <cftry>
            <cfquery datasource="#application.dsn#">
                UPDATE wholesale_orders
                SET status     = <cfqueryparam value="#arguments.status#"    cfsqltype="cf_sql_varchar">,
                    updated_at = NOW()
                WHERE id        = <cfqueryparam value="#arguments.id#"        cfsqltype="cf_sql_integer">
                  AND vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfreturn true>
        <cfcatch>
            <cfreturn false>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getWholesaleProducts" access="public" returntype="query">
        <cfargument name="vendor_id" type="numeric" required="true">
        <cfargument name="keyword"   type="string"  default="">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT p.id, p.product_name, p.price, p.stock,
                   p.wholesale_price, p.min_wholesale_qty,
                   c.category_name
            FROM products p
            JOIN categories c ON c.id = p.category_id
            WHERE p.vendor_id         = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
              AND p.is_active         = 1
              AND p.wholesale_price   > 0
              AND p.min_wholesale_qty > 0
              AND p.stock             > 0
            <cfif len(trim(arguments.keyword))>
                AND p.product_name LIKE <cfqueryparam value="%#arguments.keyword#%" cfsqltype="cf_sql_varchar">
            </cfif>
            ORDER BY p.product_name ASC
        </cfquery>
        <cfreturn local.q>
    </cffunction>


</cfcomponent>
