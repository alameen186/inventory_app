<cfcomponent output="false" displayname="Customer Notification Engine">

    <!--- PREFERENCES--->

    <cffunction name="getPreferences" returntype="query" output="false">
        <cfargument name="user_id" type="numeric" required="true">

        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT * FROM customer_notification_preferences
            WHERE user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfif local.q.recordCount EQ 0>
            <cfquery datasource="#application.dsn#">
                INSERT IGNORE INTO customer_notification_preferences (user_id)
                VALUES (<cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">)
            </cfquery>
            <cfquery name="local.q" datasource="#application.dsn#">
                SELECT * FROM customer_notification_preferences
                WHERE user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
            </cfquery>
        </cfif>

        <cfreturn local.q>
    </cffunction>


    <cffunction name="savePreferences" returntype="boolean" output="false">
        <cfargument name="user_id"               type="numeric" required="true">
        <cfargument name="reorder_reminders"     type="numeric" default="0">
        <cfargument name="personalized_offers"   type="numeric" default="0">
        <cfargument name="smart_recommendations" type="numeric" default="0">
        <cfargument name="seasonal_predictions"  type="numeric" default="0">
        <cfargument name="cart_recovery"         type="numeric" default="0">

        <cftry>
            <cfquery datasource="#application.dsn#">
                INSERT INTO customer_notification_preferences
                    (user_id, reorder_reminders, personalized_offers,
                     smart_recommendations, seasonal_predictions, cart_recovery)
                VALUES (
                    <cfqueryparam value="#arguments.user_id#"               cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#arguments.reorder_reminders#"     cfsqltype="cf_sql_tinyint">,
                    <cfqueryparam value="#arguments.personalized_offers#"   cfsqltype="cf_sql_tinyint">,
                    <cfqueryparam value="#arguments.smart_recommendations#" cfsqltype="cf_sql_tinyint">,
                    <cfqueryparam value="#arguments.seasonal_predictions#"  cfsqltype="cf_sql_tinyint">,
                    <cfqueryparam value="#arguments.cart_recovery#"         cfsqltype="cf_sql_tinyint">
                )
                ON DUPLICATE KEY UPDATE
                    reorder_reminders      = VALUES(reorder_reminders),
                    personalized_offers    = VALUES(personalized_offers),
                    smart_recommendations  = VALUES(smart_recommendations),
                    seasonal_predictions   = VALUES(seasonal_predictions),
                    cart_recovery          = VALUES(cart_recovery),
                    updated_at             = NOW()
            </cfquery>
            <cfreturn true>
        <cfcatch>
            <cfreturn false>
        </cfcatch>
        </cftry>
    </cffunction>


    <!--- HELPERS --->

    <cffunction name="wasRecentlySent" returntype="boolean" output="false">
        <cfargument name="user_id"           type="numeric" required="true">
        <cfargument name="notification_type" type="string"  required="true">
        <cfargument name="reference_id"      type="string"  default="">
        <cfargument name="hours"             type="numeric" default="24">

        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT id FROM notification_send_log
            WHERE user_id           = <cfqueryparam value="#arguments.user_id#"           cfsqltype="cf_sql_integer">
            AND   notification_type = <cfqueryparam value="#arguments.notification_type#" cfsqltype="cf_sql_varchar">
            AND   sent_at           >= DATE_SUB(NOW(), INTERVAL
                  <cfqueryparam value="#arguments.hours#" cfsqltype="cf_sql_integer"> HOUR)
            <cfif len(trim(arguments.reference_id))>
            AND   reference_id = <cfqueryparam value="#arguments.reference_id#" cfsqltype="cf_sql_varchar">
            </cfif>
            LIMIT 1
        </cfquery>

        <cfreturn local.q.recordCount GT 0>
    </cffunction>


    <cffunction name="logSent" returntype="void" output="false">
        <cfargument name="user_id"           type="numeric" required="true">
        <cfargument name="notification_type" type="string"  required="true">
        <cfargument name="reference_id"      type="string"  default="">

        <cftry>
            <cfquery datasource="#application.dsn#">
                INSERT INTO notification_send_log (user_id, notification_type, reference_id)
                VALUES (
                    <cfqueryparam value="#arguments.user_id#"           cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#arguments.notification_type#" cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#arguments.reference_id#"      cfsqltype="cf_sql_varchar">
                )
            </cfquery>
        <cfcatch></cfcatch>
        </cftry>
    </cffunction>


    <!--- REORDER REMINDERS--->

    <cffunction name="processReorderReminders" returntype="struct" output="false">

        <!--- declare ALL local vars at the top of the function --->
        <cfset var result      = { sent: 0, skipped: 0, errors: 0 }>
        <cfset var notifModel  = "">
        <cfset var avgDays     = 0>

        <cfquery name="local.candidates" datasource="#application.dsn#">
            SELECT
                o.user_id,
                o.product_id,
                p.product_name,
                p.stock,
                COUNT(*)                                              AS purchase_count,
                MIN(o.created_at)                                     AS first_purchase,
                MAX(o.created_at)                                     AS last_purchase,
                DATEDIFF(MAX(o.created_at), MIN(o.created_at))
                    / NULLIF(COUNT(*) - 1, 0)                         AS avg_days_between,
                DATEDIFF(NOW(), MAX(o.created_at))                    AS days_since_last
            FROM orders o
            JOIN products p ON p.id = o.product_id
            JOIN customer_notification_preferences cnp
                ON  cnp.user_id           = o.user_id
                AND cnp.reorder_reminders = 1
            WHERE o.user_id IS NOT NULL
            AND   o.status NOT IN ('cancelled','cancel_requested')
            AND   p.stock > 0
            GROUP BY o.user_id, o.product_id, p.product_name, p.stock
            HAVING purchase_count >= 1
        </cfquery>

        <cfset notifModel = createObject("component","models.Notification")>

        <cfloop query="local.candidates">
            <cftry>
                <cfif wasRecentlySent(
                        user_id           = local.candidates.user_id,
                        notification_type = "reorder_reminder",
                        reference_id      = local.candidates.product_id,
                        hours             = 48)>
                    <cfset result.skipped = result.skipped + 1>
                    <cfcontinue>
                </cfif>

                <cfset avgDays = isNumeric(local.candidates.avg_days_between)
    ? round(local.candidates.avg_days_between)
    : 7>

                <cfset notifModel.create(
                    user_id   = local.candidates.user_id,
                    sender_id = 0,
                    type      = "reorder_reminder",
                    title     = "Time to Restock!",
                    message   = "You usually buy """ & local.candidates.product_name
                              & """ every " & avgDays & " day(s). Would you like to reorder now?",
                    link      = "index.cfm?page=dashboard&section=productList"
                )>

                <cfset logSent(
                    user_id           = local.candidates.user_id,
                    notification_type = "reorder_reminder",
                    reference_id      = local.candidates.product_id
                )>

                <cfset result.sent = result.sent + 1>
            <cfcatch>
    <cfoutput>
        <div style="color:red;padding:10px;border:1px solid red;margin:10px;">
            <strong>ERROR:</strong> #cfcatch.message#<br>
            <strong>DETAIL:</strong> #cfcatch.detail#<br>
            <strong>TYPE:</strong> #cfcatch.type#
        </div>
    </cfoutput>

    <cfset result.errors = result.errors + 1>
</cfcatch>
            </cftry>
        </cfloop>

        <cfreturn result>
    </cffunction>


    <!--- PERSONALIZED OFFERS--->

    <cffunction name="processPersonalizedOffers" returntype="struct" output="false">

        <cfset var result        = { sent: 0, skipped: 0, errors: 0 }>
        <cfset var notifModel    = "">
        <cfset var discountLabel = "">

        <cfquery name="local.offerTargets" datasource="#application.dsn#">
    SELECT DISTINCT
        o.user_id,
        p.id AS product_id,
        p.product_name,
        off.offer_name,
        off.discount_type,
        off.discount_value,
        off.end_date
    FROM orders o

    JOIN products p
        ON p.id = o.product_id

    JOIN offers off
        ON (
            (off.offer_type = 'individual' AND off.product_id = p.id)
            OR
            (off.offer_type = 'seasonal' AND off.category_id = p.category_id)
        )

    JOIN customer_notification_preferences cnp
        ON cnp.user_id = o.user_id
        AND cnp.personalized_offers = 1

    WHERE o.user_id IS NOT NULL
    AND o.status NOT IN ('cancelled','cancel_requested')
    AND off.is_active = 1
    AND off.start_date <= CURDATE()
    AND off.end_date >= CURDATE()
    AND p.stock > 0
</cfquery>

        <cfset notifModel = createObject("component","models.Notification")>

        <cfloop query="local.offerTargets">
            <cftry>
                <cfif wasRecentlySent(
                        user_id           = local.offerTargets.user_id,
                        notification_type = "personalized_offer",
                        reference_id      = local.offerTargets.product_id,
                        hours             = 72)>
                    <cfset result.skipped = result.skipped + 1>
                    <cfcontinue>
                </cfif>

                <cfif local.offerTargets.discount_type EQ "percentage">
                    <cfset discountLabel = local.offerTargets.discount_value & "% OFF">
                <cfelse>
                    <cfset discountLabel = "Rs." & numberFormat(local.offerTargets.discount_value,"0.00") & " OFF">
                </cfif>

                <cfset notifModel.create(
                    user_id   = local.offerTargets.user_id,
                    sender_id = 0,
                    type      = "personalized_offer",
                    title     = "Special Offer on Your Favorite Product!",
                    message   = "Your favorite """ & local.offerTargets.product_name
                              & """ is now " & discountLabel
                              & "! Offer: """ & local.offerTargets.offer_name
                              & """ - valid until " & dateFormat(local.offerTargets.end_date,"dd-mmm-yyyy") & ".",
                    link      = "index.cfm?page=dashboard&section=productList"
                )>

                <cfset logSent(
                    user_id           = local.offerTargets.user_id,
                    notification_type = "personalized_offer",
                    reference_id      = local.offerTargets.product_id
                )>

                <cfset result.sent = result.sent + 1>
          <cfcatch>
    <cfoutput>
        <div style="color:red;padding:10px;border:1px solid red;margin:10px;">
            <strong>ERROR:</strong> #cfcatch.message#<br>
            <strong>DETAIL:</strong> #cfcatch.detail#<br>
            <strong>TYPE:</strong> #cfcatch.type#
        </div>
    </cfoutput>

    <cfset result.errors = result.errors + 1>
</cfcatch>
            </cftry>
        </cfloop>

        <cfreturn result>
    </cffunction>


    <!---  SMART RECOMMENDATIONS--->

    <cffunction name="processSmartRecommendations" returntype="struct" output="false">

        <cfset var result     = { sent: 0, skipped: 0, errors: 0 }>
        <cfset var notifModel = "">
        <cfset var refId      = "">

        <cfquery name="local.coPairs" datasource="#application.dsn#">
            SELECT
                o1.product_id                     AS product_a_id,
                o2.product_id                     AS product_b_id,
                pa.product_name                   AS product_a_name,
                pb.product_name                   AS product_b_name,
                COUNT(DISTINCT o1.order_group_id) AS pair_count
            FROM orders o1
            JOIN orders o2
                ON  o1.order_group_id = o2.order_group_id
                AND o1.product_id     < o2.product_id
            JOIN products pa ON pa.id = o1.product_id AND pa.stock > 0
            JOIN products pb ON pb.id = o2.product_id AND pb.stock > 0
            WHERE o1.status NOT IN ('cancelled','cancel_requested')
            AND   o2.status NOT IN ('cancelled','cancel_requested')
            GROUP BY o1.product_id, o2.product_id, pa.product_name, pb.product_name
            HAVING pair_count >= 1
            ORDER BY pair_count DESC
            LIMIT 50
        </cfquery>

        <cfset notifModel = createObject("component","models.Notification")>

        <cfloop query="local.coPairs">

            <cfquery name="local.buyers" datasource="#application.dsn#">
                SELECT DISTINCT o.user_id
                FROM orders o
                JOIN customer_notification_preferences cnp
                    ON  cnp.user_id              = o.user_id
                    AND cnp.smart_recommendations = 1
                WHERE o.product_id = <cfqueryparam value="#local.coPairs.product_a_id#" cfsqltype="cf_sql_integer">
                AND   o.user_id IS NOT NULL
                AND   o.status NOT IN ('cancelled','cancel_requested')
                AND   o.user_id NOT IN (
                    SELECT DISTINCT user_id FROM orders
                    WHERE  product_id = <cfqueryparam value="#local.coPairs.product_b_id#" cfsqltype="cf_sql_integer">
                    AND    status NOT IN ('cancelled','cancel_requested')
                    AND    user_id IS NOT NULL
                )
                LIMIT 20
            </cfquery>

            <cfloop query="local.buyers">
                <cftry>
                    <cfset refId = local.coPairs.product_a_id & "_" & local.coPairs.product_b_id>

                    <cfif wasRecentlySent(
                            user_id           = local.buyers.user_id,
                            notification_type = "smart_recommendation",
                            reference_id      = refId,
                            hours             = 96)>
                        <cfset result.skipped = result.skipped + 1>
                        <cfcontinue>
                    </cfif>

                    <cfset notifModel.create(
                        user_id   = local.buyers.user_id,
                        sender_id = 0,
                        type      = "smart_recommendation",
                        title     = "Customers Also Buy This!",
                        message   = "People who buy """ & local.coPairs.product_a_name
                                  & """ often also buy """ & local.coPairs.product_b_name
                                  & """. Try it today!",
                        link      = "index.cfm?page=dashboard&section=productList"
                    )>

                    <cfset logSent(
                        user_id           = local.buyers.user_id,
                        notification_type = "smart_recommendation",
                        reference_id      = refId
                    )>

                    <cfset result.sent = result.sent + 1>
                <cfcatch>
    <cfoutput>
        <div style="color:red;padding:10px;border:1px solid red;margin:10px;">
            <strong>ERROR:</strong> #cfcatch.message#<br>
            <strong>DETAIL:</strong> #cfcatch.detail#<br>
            <strong>TYPE:</strong> #cfcatch.type#
        </div>
    </cfoutput>

    <cfset result.errors = result.errors + 1>
</cfcatch>
                </cftry>
            </cfloop>

        </cfloop>

        <cfreturn result>
    </cffunction>


    <!--- SEASONAL PREDICTIONS--->

    <cffunction name="processSeasonalPredictions" returntype="struct" output="false">

        <cfset var result     = { sent: 0, skipped: 0, errors: 0 }>
        <cfset var today      = now()>
        <cfset var dayOfWeek  = dayOfWeek(today)>
        <cfset var dayOfMonth = day(today)>
        <cfset var monthNum   = month(today)>
        <cfset var ctx        = { active: false, label: "", sqlMonth: 0, notifType: "" }>
        <cfset var notifModel = "">
        <cfset var seasonMsg  = "">

        <!--- Weekend (Fri=6, Sat=7) --->
        <cfif dayOfWeek EQ 6 OR dayOfWeek EQ 7>
            <cfset ctx.active    = true>
            <cfset ctx.label     = "Weekend Special">
            <cfset ctx.notifType = "seasonal_weekend">
            <cfset ctx.sqlMonth  = 0>
        </cfif>

        <!--- Month-end (day 28+) --->
        <cfif NOT ctx.active AND dayOfMonth GTE 1>
            <cfset ctx.active    = true>
            <cfset ctx.label     = "Month-End Shopping">
            <cfset ctx.notifType = "seasonal_monthend">
            <cfset ctx.sqlMonth  = 0>
        </cfif>

        <!--- Ramadan (March-April) --->
        <cfif NOT ctx.active AND (monthNum EQ 3 OR monthNum EQ 4)>
            <cfset ctx.active    = true>
            <cfset ctx.label     = "Ramadan Season">
            <cfset ctx.notifType = "seasonal_ramadan">
            <cfset ctx.sqlMonth  = monthNum>
        </cfif>

        <!--- Christmas/New Year (December) --->
        <cfif NOT ctx.active AND monthNum EQ 12>
            <cfset ctx.active    = true>
            <cfset ctx.label     = "Christmas & New Year">
            <cfset ctx.notifType = "seasonal_christmas">
            <cfset ctx.sqlMonth  = 12>
        </cfif>

        <!--- Onam/Diwali (Sep-Nov) --->
        <cfif NOT ctx.active AND (monthNum GTE 9 AND monthNum LTE 11)>
            <cfset ctx.active    = true>
            <cfset ctx.label     = "Festival Season">
            <cfset ctx.notifType = "seasonal_festival">
            <cfset ctx.sqlMonth  = monthNum>
        </cfif>


        <cfquery name="local.seasonalBuyers" datasource="#application.dsn#">
            SELECT DISTINCT
                o.user_id,
                COUNT(DISTINCT o.order_group_id) AS seasonal_orders
            FROM orders o
            JOIN customer_notification_preferences cnp
                ON  cnp.user_id             = o.user_id
                AND cnp.seasonal_predictions = 1
            WHERE o.user_id IS NOT NULL
            AND   o.status NOT IN ('cancelled','cancel_requested')
            <!--- TEST MODE: NO DATE FILTER 
            <cfif ctx.sqlMonth GT 0>
                AND MONTH(o.created_at) = <cfqueryparam value="#ctx.sqlMonth#" cfsqltype="cf_sql_integer">
            <cfelse>
                <cfif dayOfWeek EQ 6 OR dayOfWeek EQ 7>
                    AND DAYOFWEEK(o.created_at) IN (6, 7)
                <cfelse>
                    AND DAY(o.created_at) >= 28
                </cfif>
            </cfif>--->
            AND o.created_at < DATE_SUB(NOW(), INTERVAL 7 DAY)
            GROUP BY o.user_id
            HAVING seasonal_orders >= 1
        </cfquery>

        <cfset notifModel = createObject("component","models.Notification")>

        <cfloop query="local.seasonalBuyers">
            <cftry>
                <cfif wasRecentlySent(
                        user_id           = local.seasonalBuyers.user_id,
                        notification_type = ctx.notifType,
                        hours             = 168)>
                    <cfset result.skipped = result.skipped + 1>
                    <cfcontinue>
                </cfif>

                <cfset seasonMsg = "">
                <cfif ctx.notifType EQ "seasonal_weekend">
                    <cfset seasonMsg = "It's the weekend! Check out fresh deals and stock up on your favourites.">
                <cfelseif ctx.notifType EQ "seasonal_monthend">
                    <cfset seasonMsg = "Month-end is here! Great deals available on your favourite products.">
                <cfelseif ctx.notifType EQ "seasonal_ramadan">
                    <cfset seasonMsg = "Ramadan Mubarak! Special grocery combos and discounts are available for you.">
                <cfelseif ctx.notifType EQ "seasonal_christmas">
                    <cfset seasonMsg = "Merry Christmas & Happy New Year! Enjoy festive deals on all your favourites.">
                <cfelse>
                    <cfset seasonMsg = "Festival season is here! Explore special offers curated just for you.">
                </cfif>

                <cfset notifModel.create(
                    user_id   = local.seasonalBuyers.user_id,
                    sender_id = 0,
                    type      = ctx.notifType,
                    title     = ctx.label & " - Shop Now!",
                    message   = seasonMsg,
                    link      = "index.cfm?page=dashboard&section=productList"
                )>

                <cfset logSent(
                    user_id           = local.seasonalBuyers.user_id,
                    notification_type = ctx.notifType
                )>

                <cfset result.sent = result.sent + 1>
          <cfcatch>
    <cfoutput>
        <div style="color:red;padding:10px;border:1px solid red;margin:10px;">
            <strong>ERROR:</strong> #cfcatch.message#<br>
            <strong>DETAIL:</strong> #cfcatch.detail#<br>
            <strong>TYPE:</strong> #cfcatch.type#
        </div>
    </cfoutput>

    <cfset result.errors = result.errors + 1>
</cfcatch>
            </cftry>
        </cfloop>

        <cfreturn result>
    </cffunction>


    <!---  CART RECOVERY --->

    <cffunction name="saveCartSnapshot" returntype="void" output="false">
        <cfargument name="user_id" type="numeric" required="true">
        <cfargument name="cart"    type="struct"  required="true">

        <cfset var pid  = "">
        <cfset var item = "">

        <cftry>
            <cfquery datasource="#application.dsn#">
                DELETE FROM cart_abandonment_log
                WHERE user_id   = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
                AND   recovered = 0
            </cfquery>

            <cfloop collection="#arguments.cart#" item="pid">
                <cfset item = arguments.cart[pid]>
                <cfquery datasource="#application.dsn#">
                    INSERT INTO cart_abandonment_log
                        (user_id, product_id, product_name, price, quantity)
                    VALUES (
                        <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#pid#"               cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#item.name#"         cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#item.price#"        cfsqltype="cf_sql_decimal">,
                        <cfqueryparam value="#item.qty#"          cfsqltype="cf_sql_integer">
                    )
                </cfquery>
            </cfloop>
        <cfcatch></cfcatch>
        </cftry>
    </cffunction>


    <cffunction name="markCartRecovered" returntype="void" output="false">
        <cfargument name="user_id" type="numeric" required="true">

        <cftry>
            <cfquery datasource="#application.dsn#">
                UPDATE cart_abandonment_log
                SET    recovered = 1
                WHERE  user_id   = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
                AND    recovered = 0
            </cfquery>
        <cfcatch></cfcatch>
        </cftry>
    </cffunction>


    <cffunction name="processCartRecovery" returntype="struct" output="false">

        <cfset var result    = { sent: 0, skipped: 0, errors: 0 }>
        <cfset var notifModel = "">
        <cfset var itemLabel  = "">
        <cfset var cartMsg    = "">

        <cfquery name="local.abandoned" datasource="#application.dsn#">
            SELECT
                cal.user_id,
                GROUP_CONCAT(cal.product_name ORDER BY cal.product_name SEPARATOR ', ') AS product_names,
                COUNT(*)                      AS item_count,
                SUM(cal.price * cal.quantity) AS cart_total,
                MIN(cal.cart_saved_at)        AS abandoned_at
            FROM cart_abandonment_log cal
            JOIN customer_notification_preferences cnp
                ON  cnp.user_id      = cal.user_id
                AND cnp.cart_recovery = 1
            WHERE cal.recovered    = 0
            AND   cal.notified     = 0
            AND   cal.cart_saved_at <= DATE_SUB(NOW(), INTERVAL 1 MINUTE)
            GROUP BY cal.user_id
        </cfquery>

        <cfset notifModel = createObject("component","models.Notification")>

        <cfloop query="local.abandoned">
            <cftry>
                <cfif wasRecentlySent(
                        user_id           = local.abandoned.user_id,
                        notification_type = "cart_recovery",
                        hours             = 24)>
                    <cfset result.skipped = result.skipped + 1>
                    <cfcontinue>
                </cfif>

                <cfset itemLabel = local.abandoned.item_count EQ 1 ? "item" : "items">
                <cfset cartMsg   = "You left " & local.abandoned.item_count & " " & itemLabel
                                 & " (""" & left(local.abandoned.product_names, 80)
                                 & (len(local.abandoned.product_names) GT 80 ? "..." : "")
                                 & """) in your cart worth Rs."
                                 & numberFormat(local.abandoned.cart_total, "0.00")
                                 & ". Complete your order before they sell out!">

                <cfset notifModel.create(
                    user_id   = local.abandoned.user_id,
                    sender_id = 0,
                    type      = "cart_recovery",
                    title     = "You Left Something Behind!",
                    message   = cartMsg,
                    link      = "index.cfm?page=dashboard&section=cart"
                )>

                <cfquery datasource="#application.dsn#">
                    UPDATE cart_abandonment_log
                    SET    notified    = 1,
                           notified_at = NOW()
                    WHERE  user_id     = <cfqueryparam value="#local.abandoned.user_id#" cfsqltype="cf_sql_integer">
                    AND    recovered   = 0
                </cfquery>

                <cfset logSent(
                    user_id           = local.abandoned.user_id,
                    notification_type = "cart_recovery"
                )>

                <cfset result.sent = result.sent + 1>
         <cfcatch>
    <cfoutput>
        <div style="color:red;padding:10px;border:1px solid red;margin:10px;">
            <strong>ERROR:</strong> #cfcatch.message#<br>
            <strong>DETAIL:</strong> #cfcatch.detail#<br>
            <strong>TYPE:</strong> #cfcatch.type#
        </div>
    </cfoutput>

    <cfset result.errors = result.errors + 1>
</cfcatch>
            </cftry>
        </cfloop>

        <cfreturn result>
    </cffunction>


    <!---  ANALYTICS --->

    <cffunction name="getCustomerStats" returntype="struct" output="false">
        <cfargument name="user_id" type="numeric" required="true">

        <cfset var stats = {
            total_orders    : 0,
            unique_products : 0,
            top_product     : "",
            avg_order_days  : 0,
            last_order_days : 0
        }>

        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT
                COUNT(DISTINCT order_group_id)                              AS total_orders,
                COUNT(DISTINCT product_id)                                  AS unique_products,
                DATEDIFF(NOW(), MAX(created_at))                            AS last_order_days,
                DATEDIFF(MAX(created_at), MIN(created_at))
                    / NULLIF(COUNT(DISTINCT order_group_id) - 1, 0)         AS avg_order_days
            FROM orders
            WHERE user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
            AND   status  NOT IN ('cancelled','cancel_requested')
        </cfquery>

        <cfif local.q.recordCount>
            <cfset stats.total_orders    = val(local.q.total_orders)>
            <cfset stats.unique_products = val(local.q.unique_products)>
            <cfset stats.last_order_days = val(local.q.last_order_days)>
            <cfset stats.avg_order_days  = round(val(local.q.avg_order_days))>
        </cfif>

        <cfquery name="local.topP" datasource="#application.dsn#">
            SELECT p.product_name, COUNT(*) AS cnt
            FROM   orders o
            JOIN   products p ON p.id = o.product_id
            WHERE  o.user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
            AND    o.status  NOT IN ('cancelled','cancel_requested')
            GROUP BY p.product_name
            ORDER BY cnt DESC
            LIMIT 1
        </cfquery>

        <cfif local.topP.recordCount>
            <cfset stats.top_product = local.topP.product_name>
        </cfif>

        <cfreturn stats>
    </cffunction>


    <cffunction name="getNotificationHistory" returntype="query" output="false">
        <cfargument name="user_id" type="numeric" required="true">
        <cfargument name="limit"   type="numeric" default="10">

        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT id, type, title, message, is_read, created_at
            FROM   notifications
            WHERE  user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
            AND    type IN (
                'reorder_reminder','personalized_offer',
                'smart_recommendation','seasonal_weekend',
                'seasonal_monthend','seasonal_ramadan',
                'seasonal_christmas','seasonal_festival',
                'cart_recovery','seasonal_test'
            )
            ORDER BY created_at DESC
            LIMIT <cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfreturn local.q>
    </cffunction>

</cfcomponent>
