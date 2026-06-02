<cfcomponent output="false" displayname="Loyalty Controller">

    <!--- Minimum points needed to redeem --->
    <cfset REDEEM_THRESHOLD = 100>
    <!--- How many points = Rs.1 --->
    <cfset POINTS_PER_RUPEE = 10>

    <cffunction name="jsonRes" access="private" returntype="void" output="true">
        <cfargument name="success" type="boolean" required="true">
        <cfargument name="message" type="string"  default="">
        <cfargument name="data"    type="any"     default="">
        <cfcontent type="application/json; charset=utf-8" reset="true">
        <cfoutput>#serializeJSON({
            "success": arguments.success,
            "message": arguments.message,
            "data"   : arguments.data
        })#</cfoutput>
        <cfabort>
    </cffunction>

    <cffunction name="requireAuth" access="private" returntype="void" output="false">
        <cfif NOT structKeyExists(session, "user_id")>
            <cfset jsonRes(false, "Unauthorized")>
        </cfif>
    </cffunction>


    <!--- GET POINTS SUMMARY + HISTORY --->
    <cffunction name="getPoints" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireAuth()>
        <cftry>
            <cfquery name="local.totQ" datasource="#application.dsn#">
                SELECT COALESCE(SUM(points), 0) AS total_earned
                FROM loyalty_points
                WHERE user_id = <cfqueryparam value="#session.user_id#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfquery name="local.redQ" datasource="#application.dsn#">
                SELECT COALESCE(SUM(points_used), 0) AS total_redeemed
                FROM loyalty_redemptions
                WHERE user_id = <cfqueryparam value="#session.user_id#" cfsqltype="cf_sql_integer">
                AND   status  = 'active'
            </cfquery>

            <cfset var totalEarned   = val(local.totQ.total_earned)>
            <cfset var totalRedeemed = val(local.redQ.total_redeemed)>
            <cfset var available     = totalEarned - totalRedeemed>
            <cfset var worthRupees   = int(available / POINTS_PER_RUPEE)>

            <cfquery name="local.histQ" datasource="#application.dsn#">
                SELECT points, reason, order_group_id, created_at
                FROM loyalty_points
                WHERE user_id = <cfqueryparam value="#session.user_id#" cfsqltype="cf_sql_integer">
                ORDER BY created_at DESC
                LIMIT 20
            </cfquery>

            <cfset var history = []>
            <cfloop query="local.histQ">
                <cfset arrayAppend(history, {
                    "points"   : local.histQ.points,
                    "reason"   : local.histQ.reason,
                    "order_id" : local.histQ.order_group_id,
                    "date"     : dateTimeFormat(local.histQ.created_at, "dd-mmm-yyyy HH:mm")
                })>
            </cfloop>

            <cfquery name="local.redeemHistQ" datasource="#application.dsn#">
                SELECT points_used, coupon_code, created_at
                FROM loyalty_redemptions
                WHERE user_id = <cfqueryparam value="#session.user_id#" cfsqltype="cf_sql_integer">
                ORDER BY created_at DESC
                LIMIT 10
            </cfquery>

            <cfset var redeemHistory = []>
            <cfloop query="local.redeemHistQ">
                <cfset arrayAppend(redeemHistory, {
                    "points_used" : local.redeemHistQ.points_used,
                    "coupon_code" : local.redeemHistQ.coupon_code,
                    "date"        : dateTimeFormat(local.redeemHistQ.created_at, "dd-mmm-yyyy HH:mm")
                })>
            </cfloop>

            <cfset jsonRes(true, "", {
                "total_earned"     : totalEarned,
                "total_redeemed"   : totalRedeemed,
                "available"        : available,
                "worth_rupees"     : worthRupees,
                "can_redeem"       : (available GTE REDEEM_THRESHOLD),
                "threshold"        : REDEEM_THRESHOLD,
                "points_per_rupee" : POINTS_PER_RUPEE,
                "history"          : history,
                "redeem_history"   : redeemHistory
            })>
        <cfcatch>
            <cfset jsonRes(false, "Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>


    <!--- REDEEM POINTS - GENERATE COUPON --->
    <cffunction name="redeem" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireAuth()>
        <cftry>
            <cfquery name="local.totQ" datasource="#application.dsn#">
                SELECT COALESCE(SUM(points), 0) AS total_earned
                FROM loyalty_points
                WHERE user_id = <cfqueryparam value="#session.user_id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfquery name="local.redQ" datasource="#application.dsn#">
                SELECT COALESCE(SUM(points_used), 0) AS total_redeemed
                FROM loyalty_redemptions
                WHERE user_id = <cfqueryparam value="#session.user_id#" cfsqltype="cf_sql_integer">
                AND   status  = 'active'
            </cfquery>

            <cfset var available = val(local.totQ.total_earned) - val(local.redQ.total_redeemed)>

            <cfif available LT REDEEM_THRESHOLD>
                <cfset jsonRes(false, "You need at least " & REDEEM_THRESHOLD & " points to redeem. You have " & available & " points.")>
            </cfif>

            <cfset var pointsToUse = min(available, 500)>
            <cfset var discountAmt = int(pointsToUse / POINTS_PER_RUPEE)>
            <cfset var couponCode  = "LOYALTY" & session.user_id & dateFormat(now(), "yyyymmdd") & randRange(100,999)>

            <!--- Insert into your existing coupons table --->
            <cfquery datasource="#application.dsn#">
                INSERT INTO coupons
                    (coupon_code, discount_type, discount_value, min_order_amount,
                     max_uses, used_count, is_active, start_date, end_date, created_at)
                VALUES (
                    <cfqueryparam value="#couponCode#"  cfsqltype="cf_sql_varchar">,
                    'fixed',
                    <cfqueryparam value="#discountAmt#" cfsqltype="cf_sql_decimal">,
                    0,
                    1,
                    0,
                    1,
                    CURDATE(),
                    DATE_ADD(CURDATE(), INTERVAL 30 DAY),
                    NOW()
                )
            </cfquery>

            <cfquery datasource="#application.dsn#">
                INSERT INTO loyalty_redemptions (user_id, points_used, coupon_code)
                VALUES (
                    <cfqueryparam value="#session.user_id#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#pointsToUse#"     cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#couponCode#"       cfsqltype="cf_sql_varchar">
                )
            </cfquery>

            <cfset jsonRes(true, "Coupon generated successfully!", {
                "coupon_code"  : couponCode,
                "discount_amt" : discountAmt,
                "points_used"  : pointsToUse,
                "valid_until"  : dateFormat(dateAdd("d", 30, now()), "dd-mmm-yyyy")
            })>

        <cfcatch>
            <cfset jsonRes(false, "Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>
