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
        'cart_recovery','seasonal_test',
        'low_stock_alert','price_drop_alert','loyalty_points',
        'festival_offer'
    )
            ORDER BY created_at DESC
            LIMIT <cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfreturn local.q>
    </cffunction>
<!--- LOW STOCK & LAST CHANCE --->

<cffunction name="processLowStockAlerts" returntype="struct" output="false">

    <cfset var result          = { sent: 0, skipped: 0, errors: 0 }>
    <cfset var notifModel      = "">
    <cfset var STOCK_THRESHOLD = 5>

    <cfquery name="local.candidates" datasource="#application.dsn#">
        SELECT DISTINCT
            o.user_id,
            p.id           AS product_id,
            p.product_name,
            p.stock
        FROM orders o
        JOIN products p
            ON  p.id        = o.product_id
            AND p.is_active = 1
            AND p.stock     > 0
            AND p.stock    <= <cfqueryparam value="#STOCK_THRESHOLD#" cfsqltype="cf_sql_integer">
        JOIN customer_notification_preferences cnp
            ON  cnp.user_id       = o.user_id
            AND cnp.reorder_reminders = 1
        WHERE o.user_id IS NOT NULL
        AND   o.status  NOT IN ('cancelled', 'cancel_requested')
    </cfquery>

    <cfset notifModel = createObject("component", "models.Notification")>

    <cfloop query="local.candidates">
        <cftry>
            <cfif wasRecentlySent(
                    user_id           = local.candidates.user_id,
                    notification_type = "low_stock_alert",
                    reference_id      = local.candidates.product_id,
                    hours             = 72)>
                <cfset result.skipped = result.skipped + 1>
                <cfcontinue>
            </cfif>

            <cfset notifModel.create(
                user_id   = local.candidates.user_id,
                sender_id = 0,
                type      = "low_stock_alert",
                title     = "Last Chance - Almost Sold Out!",
                message   = "Your favourite """ & local.candidates.product_name
                          & """ is almost gone — only " & local.candidates.stock
                          & " left in stock. Order now before it runs out!",
                link      = "index.cfm?page=dashboard&section=productList"
            )>

            <cfset logSent(
                user_id           = local.candidates.user_id,
                notification_type = "low_stock_alert",
                reference_id      = local.candidates.product_id
            )>

            <cfset result.sent = result.sent + 1>
        <cfcatch>
            <cfoutput>
                <div style="color:red;padding:10px;border:1px solid red;margin:10px;">
                    <strong>ERROR:</strong> #cfcatch.message#<br>
                    <strong>DETAIL:</strong> #cfcatch.detail#
                </div>
            </cfoutput>
            <cfset result.errors = result.errors + 1>
        </cfcatch>
        </cftry>
    </cfloop>

    <cfreturn result>
</cffunction>


<!--- PRICE DROP ALERTS--->

<cffunction name="processPriceDropAlerts" returntype="struct" output="false">

    <cfset var result     = { sent: 0, skipped: 0, errors: 0 }>
    <cfset var notifModel = "">
    <cfset var savings    = 0>

    <cfquery name="local.candidates" datasource="#application.dsn#">
        SELECT
            o.user_id,
            o.product_id,
            p.product_name,
            p.price                AS current_price,
            MAX(o.price)           AS last_paid_price
        FROM orders o
        JOIN products p
            ON  p.id        = o.product_id
            AND p.is_active = 1
            AND p.stock     > 0
        JOIN customer_notification_preferences cnp
            ON  cnp.user_id             = o.user_id
            AND cnp.personalized_offers = 1
        WHERE o.user_id IS NOT NULL
        AND   o.status  NOT IN ('cancelled', 'cancel_requested')
        GROUP BY o.user_id, o.product_id, p.product_name, p.price
        HAVING p.price < MAX(o.price)
    </cfquery>

    <cfset notifModel = createObject("component", "models.Notification")>

    <cfloop query="local.candidates">
        <cftry>
            <cfif wasRecentlySent(
                    user_id           = local.candidates.user_id,
                    notification_type = "price_drop_alert",
                    reference_id      = local.candidates.product_id,
                    hours             = 48)>
                <cfset result.skipped = result.skipped + 1>
                <cfcontinue>
            </cfif>

            <cfset savings = local.candidates.last_paid_price - local.candidates.current_price>

            <cfset notifModel.create(
                user_id   = local.candidates.user_id,
                sender_id = 0,
                type      = "price_drop_alert",
                title     = "Price Drop on Your Favourite Product!",
                message   = "Good news! """ & local.candidates.product_name
                          & """ is now Rs." & numberFormat(local.candidates.current_price, "0.00")
                          & " — that's Rs." & numberFormat(savings, "0.00")
                          & " cheaper than last time. Grab it now!",
                link      = "index.cfm?page=dashboard&section=productList"
            )>

            <cfset logSent(
                user_id           = local.candidates.user_id,
                notification_type = "price_drop_alert",
                reference_id      = local.candidates.product_id
            )>

            <cfset result.sent = result.sent + 1>
        <cfcatch>
            <cfoutput>
                <div style="color:red;padding:10px;border:1px solid red;margin:10px;">
                    <strong>ERROR:</strong> #cfcatch.message#<br>
                    <strong>DETAIL:</strong> #cfcatch.detail#
                </div>
            </cfoutput>
            <cfset result.errors = result.errors + 1>
        </cfcatch>
        </cftry>
    </cfloop>

    <cfreturn result>
</cffunction>


<!---  LOYALTY REWARDS & POINTS --->
<cffunction name="processLoyaltyRewards" returntype="struct" output="false">

    <cfset var result       = { sent: 0, skipped: 0, errors: 0 }>
    <cfset var notifModel   = "">
    <cfset var pointsEarned = 0>
    <cfset var totalPoints  = 0>
    <cfset var milestoneMsg = "">

    <!--- Get users with unawarded orders, grouped by user (not per order) --->
    <cfquery name="local.users" datasource="#application.dsn#">
        SELECT
            o.user_id,
            COUNT(DISTINCT o.order_group_id) AS new_order_count,
            SUM(o.final_amount)              AS total_spent
        FROM orders o
        WHERE o.user_id IS NOT NULL
        AND   o.status  NOT IN ('cancelled', 'cancel_requested')
        AND   NOT EXISTS (
            SELECT 1 FROM loyalty_points lp
            WHERE lp.user_id        = o.user_id
            AND   lp.order_group_id = o.order_group_id
        )
        GROUP BY o.user_id
    </cfquery>

    <cfset notifModel = createObject("component", "models.Notification")>

    <cfloop query="local.users">
        <cftry>
            <!--- Skip if already sent loyalty notification today --->
            <cfif wasRecentlySent(
                    user_id           = local.users.user_id,
                    notification_type = "loyalty_points",
                    reference_id      = "",
                    hours             = 24)>
                <cfset result.skipped = result.skipped + 1>
                <cfcontinue>
            </cfif>

            <!--- Calculate total points for all new orders --->
            <cfset pointsEarned = int(local.users.total_spent / 10)>

            <cfif pointsEarned LT 1>
                <cfset result.skipped = result.skipped + 1>
                <cfcontinue>
            </cfif>

            <!--- Save one points row per unawarded order --->
            <cfquery name="local.unawardedOrders" datasource="#application.dsn#">
                SELECT DISTINCT o.order_group_id, SUM(o.final_amount) AS amt
                FROM orders o
                WHERE o.user_id IS NOT NULL
                AND   o.status  NOT IN ('cancelled', 'cancel_requested')
                AND   NOT EXISTS (
                    SELECT 1 FROM loyalty_points lp
                    WHERE lp.user_id        = o.user_id
                    AND   lp.order_group_id = o.order_group_id
                )
                AND o.user_id = <cfqueryparam value="#local.users.user_id#" cfsqltype="cf_sql_integer">
                GROUP BY o.order_group_id
            </cfquery>

            <cfloop query="local.unawardedOrders">
                <cfset var pts = int(local.unawardedOrders.amt / 10)>
                <cfif pts GTE 1>
                    <cfquery datasource="#application.dsn#">
                        INSERT IGNORE INTO loyalty_points
                            (user_id, points, reason, order_id)
                        VALUES (
                            <cfqueryparam value="#local.users.user_id#"               cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#pts#"                                cfsqltype="cf_sql_integer">,
                            'Order reward',
                            <cfqueryparam value="#local.unawardedOrders.order_group_id#" cfsqltype="cf_sql_varchar">
                        )
                    </cfquery>
                </cfif>
            </cfloop>

            <!--- Get updated total --->
            <cfquery name="local.totQ" datasource="#application.dsn#">
                SELECT SUM(points) AS total
                FROM loyalty_points
                WHERE user_id = <cfqueryparam value="#local.users.user_id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfset totalPoints = val(local.totQ.total)>

            <!--- Check milestone --->
            <cfset milestoneMsg = "">
            <cfset var prevTotal = totalPoints - pointsEarned>
            <cfif totalPoints GTE 500 AND prevTotal LT 500>
                <cfset milestoneMsg = " You have reached 500 points — enjoy a Rs.100 discount on your next order!">
            <cfelseif totalPoints GTE 250 AND prevTotal LT 250>
                <cfset milestoneMsg = " You have reached 250 points — keep going for bigger rewards!">
            <cfelseif totalPoints GTE 100 AND prevTotal LT 100>
                <cfset milestoneMsg = " You have hit 100 points — you are on a roll!">
            </cfif>

            <!--- One single notification summarising all new points --->
            <cfset notifModel.create(
                user_id   = local.users.user_id,
                sender_id = 0,
                type      = "loyalty_points",
                title     = "You Earned " & pointsEarned & " Reward Points!",
                message   = "You earned " & pointsEarned & " points from "
                          & local.users.new_order_count
                          & (local.users.new_order_count EQ 1 ? " order" : " orders")
                          & ". Your total is now " & totalPoints & " points." & milestoneMsg,
                link      = "index.cfm?page=dashboard&section=orders"
            )>

            <cfset logSent(
                user_id           = local.users.user_id,
                notification_type = "loyalty_points",
                reference_id      = ""
            )>

            <cfset result.sent = result.sent + 1>

        <cfcatch>
            <cfoutput>
                <div style="color:red;padding:10px;border:1px solid red;margin:10px;">
                    <strong>ERROR:</strong> #cfcatch.message#<br>
                    <strong>DETAIL:</strong> #cfcatch.detail#
                </div>
            </cfoutput>
            <cfset result.errors = result.errors + 1>
        </cfcatch>
        </cftry>
    </cfloop>

    <cfreturn result>
</cffunction>

<!---  SYNC SEASON TAGS → OFFERS TABLE --->
<cffunction name="syncSeasonOffers" returntype="struct" output="false">

    <cfset var result = { created: 0, deactivated: 0, errors: 0 }>

    <!--- Find all seasons active today --->
    <cfquery name="local.activeSeasons" datasource="#application.dsn#">
        SELECT id, season_key, season_name, start_date, end_date, discount_pct
        FROM   seasons
        WHERE  is_active   = 1
        AND    start_date <= CURDATE()
        AND    end_date   >= CURDATE()
    </cfquery>

    <cfloop query="local.activeSeasons">

        <!--- All products tagged for this season --->
        <cfquery name="local.taggedProducts" datasource="#application.dsn#">
            SELECT ps.product_id, p.vendor_id
            FROM   product_seasons ps
            JOIN   products p
                   ON  p.id        = ps.product_id
                   AND p.is_active = 1
                   AND p.stock     > 0
            WHERE  ps.season_id = <cfqueryparam value="#local.activeSeasons.id#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfloop query="local.taggedProducts">
            <cftry>
                <!--- Only create if not already there --->
                <cfquery name="local.existing" datasource="#application.dsn#">
                    SELECT id FROM offers
                    WHERE  offer_type = 'individual'
                    AND    product_id = <cfqueryparam value="#local.taggedProducts.product_id#" cfsqltype="cf_sql_integer">
                    AND    vendor_id  = <cfqueryparam value="#local.taggedProducts.vendor_id#"  cfsqltype="cf_sql_integer">
                    AND    offer_name LIKE <cfqueryparam value="[SEASON]#local.activeSeasons.season_key#%" cfsqltype="cf_sql_varchar">
                    LIMIT  1
                </cfquery>

                <cfif local.existing.recordCount EQ 0>
                    <cfquery datasource="#application.dsn#">
                        INSERT INTO offers
                            (vendor_id, offer_name, offer_type, product_id,
                             discount_type, discount_value,
                             start_date, end_date, is_active)
                        VALUES (
                            <cfqueryparam value="#local.taggedProducts.vendor_id#"    cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="[SEASON]#local.activeSeasons.season_key# - #local.activeSeasons.season_name#" cfsqltype="cf_sql_varchar">,
                            'individual',
                            <cfqueryparam value="#local.taggedProducts.product_id#"   cfsqltype="cf_sql_integer">,
                            'percentage',
                            <cfqueryparam value="#local.activeSeasons.discount_pct#"  cfsqltype="cf_sql_decimal">,
                            <cfqueryparam value="#local.activeSeasons.start_date#"    cfsqltype="cf_sql_date">,
                            <cfqueryparam value="#local.activeSeasons.end_date#"      cfsqltype="cf_sql_date">,
                            1
                        )
                    </cfquery>
                    <cfset result.created = result.created + 1>
                </cfif>

            <cfcatch>
                <cfset result.errors = result.errors + 1>
            </cfcatch>
            </cftry>
        </cfloop>

    </cfloop>

    <!--- Deactivate season offers whose season has now ended --->
    <cftry>
        <cfquery datasource="#application.dsn#">
            UPDATE offers
            SET    is_active = 0
            WHERE  offer_name LIKE '[SEASON]%'
            AND    end_date   < CURDATE()
            AND    is_active  = 1
        </cfquery>
        <cfset result.deactivated = 1>
    <cfcatch>
        <cfset result.errors = result.errors + 1>
    </cfcatch>
    </cftry>

    <cfreturn result>
</cffunction>


<!--- PERSONALIZED FESTIVAL NOTIFICATIONS --->

<cffunction name="processFestivalOffers" returntype="struct" output="false">

    <cfset var result      = { sent: 0, skipped: 0, errors: 0 }>
    <cfset var notifModel  = "">
    <cfset var productList = "">
    <cfset var discLabel   = "">
    <cfset var notifMsg    = "">

    <!--- Find all seasons active today --->
    <cfquery name="local.activeSeasons" datasource="#application.dsn#">
        SELECT id, season_key, season_name, discount_pct
        FROM   seasons
        WHERE  is_active   = 1
        AND    start_date <= CURDATE()
        AND    end_date   >= CURDATE()
        ORDER  BY start_date ASC
    </cfquery>

    <cfif local.activeSeasons.recordCount EQ 0>
        <cfreturn result>
    </cfif>

    <cfset notifModel = createObject("component","models.Notification")>

    <cfloop query="local.activeSeasons">

        <cfset var festKey  = local.activeSeasons.season_key>
        <cfset var festName = local.activeSeasons.season_name>
        <cfset var discPct  = local.activeSeasons.discount_pct>

        <!--- Build a friendly intro line --->
        <cfset var intro = "">
        <cfif festKey EQ "onam">
            <cfset intro = "Happy Onam!">
        <cfelseif festKey EQ "eid">
            <cfset intro = "Eid Mubarak!">
        <cfelseif festKey EQ "diwali">
            <cfset intro = "Happy Diwali!">
        <cfelseif festKey EQ "christmas">
            <cfset intro = "Merry Christmas!">
        <cfelseif festKey EQ "newyear">
            <cfset intro = "Happy New Year!">
        <cfelse>
            <cfset intro = "Festival season is here!">
        </cfif>

        <cfquery name="local.eligibleUsers" datasource="#application.dsn#">
            SELECT DISTINCT o.user_id
            FROM   orders o
            JOIN   customer_notification_preferences cnp
                   ON  cnp.user_id        = o.user_id
                   AND cnp.seasonal_predictions = 1
            WHERE  o.user_id IS NOT NULL
            AND    o.status  NOT IN ('cancelled','cancel_requested')
            AND    o.user_id NOT IN (
                SELECT user_id
                FROM   notification_send_log
                WHERE  notification_type = 'festival_offer'
                AND    reference_id      = <cfqueryparam value="#festKey#" cfsqltype="cf_sql_varchar">
                AND    sent_at          >= DATE_SUB(NOW(), INTERVAL 72 HOUR)
            )
        </cfquery>

        <cfloop query="local.eligibleUsers">
            <cftry>

                <cfquery name="local.userProducts" datasource="#application.dsn#">
                    SELECT
                        p.product_name,
                        ROUND(p.price * (1 - s.discount_pct / 100), 2) AS season_price,
                        s.discount_pct,
                        COUNT(o.id) AS buy_count
                    FROM   orders o
                    JOIN   products p
                           ON  p.id        = o.product_id
                           AND p.is_active = 1
                           AND p.stock     > 0
                    JOIN   product_seasons ps ON ps.product_id = p.id
                    JOIN   seasons s
                           ON  s.id        = ps.season_id
                           AND s.season_key = <cfqueryparam value="#festKey#" cfsqltype="cf_sql_varchar">
                           AND s.is_active  = 1
                           AND s.start_date <= CURDATE()
                           AND s.end_date   >= CURDATE()
                    WHERE  o.user_id = <cfqueryparam value="#local.eligibleUsers.user_id#" cfsqltype="cf_sql_integer">
                    AND    o.status  NOT IN ('cancelled','cancel_requested')
                    GROUP  BY p.id, p.product_name, s.discount_pct
                    ORDER  BY buy_count DESC
                    LIMIT  3
                </cfquery>

                <!--- Skip this user if none of their products are tagged for this season --->
                <cfif local.userProducts.recordCount EQ 0>
                    <cfset result.skipped = result.skipped + 1>
                    <cfcontinue>
                </cfif>

                <!--- Build "Rice, Coconut Oil & Banana Chips" --->
                <cfset productList = "">
                <cfset var pIdx = 0>
                <cfloop query="local.userProducts">
                    <cfset pIdx = pIdx + 1>
                    <cfif pIdx EQ 1>
                        <cfset productList = local.userProducts.product_name>
                    <cfelseif pIdx EQ local.userProducts.recordCount>
                        <cfset productList = productList & " & " & local.userProducts.product_name>
                    <cfelse>
                        <cfset productList = productList & ", " & local.userProducts.product_name>
                    </cfif>
                </cfloop>

                <cfset discLabel  = "up to " & numberFormat(discPct,"0") & "% OFF">
                <cfset notifMsg   = intro
                    & " Enjoy " & discLabel
                    & " on products you love: "
                    & productList
                    & ". Shop now before stocks run out!">

                <cfset notifModel.create(
                    user_id   = local.eligibleUsers.user_id,
                    sender_id = 0,
                    type      = "festival_offer",
                    title     = festName & "  Special Offers Just for You!",
                    message   = notifMsg,
                    link      = "index.cfm?page=dashboard&section=productList"
                )>

                <cfset logSent(
                    user_id           = local.eligibleUsers.user_id,
                    notification_type = "festival_offer",
                    reference_id      = festKey
                )>

                <cfset result.sent = result.sent + 1>

            <cfcatch>
                <cfoutput>
                    <div style="color:red;padding:10px;border:1px solid red;margin:10px;">
                        <strong>ERROR (Festival):</strong> #cfcatch.message#<br>
                        <strong>DETAIL:</strong> #cfcatch.detail#
                    </div>
                </cfoutput>
                <cfset result.errors = result.errors + 1>
            </cfcatch>
            </cftry>
        </cfloop>

    </cfloop>

    <cfreturn result>
</cffunction>
</cfcomponent>
