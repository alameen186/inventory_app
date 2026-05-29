<cfset testMode = false>

<cfparam name="url.token" default="">
<cfif url.token NEQ application.schedulerSecret>
    <cfoutput>Unauthorized</cfoutput>
    <cfabort>
</cfif>

<cfset schedModel = createObject("component","models.ScheduledOrder")>
<cfset orderModel = createObject("component","models.Order")>
<cfset prodModel  = createObject("component","models.Product")>

<cfif testMode>
    <cfset dueTodayQ = schedModel.getSchedulesDueTodayForTesting()>
<cfelse>
    <cfset dueTodayQ = schedModel.getSchedulesDueToday()>
</cfif>

<cfoutput>
Running scheduler [#testMode ? 'TEST MODE' : 'PRODUCTION'#]
— #timeFormat(now(),"HH:mm:ss")#
— #dueTodayQ.recordCount# schedule(s) due.<br>
</cfoutput>
<!--- ═══════════════════════════════════════════
   SCHEDULED ORDERS PROCESSING
════════════════════════════════════════════════ --->

<cfif dueTodayQ.recordCount EQ 0>

    <cfoutput>
    <br>
    No schedules due today (day #day(now())#).
    Check that your scheduled_orders have day_of_month = #day(now())#
    and start_date &lt;= today.
    <br>
    </cfoutput>

<cfelse>

    <cfloop query="dueTodayQ">

        <cftry>

            <!--- get product price to calculate totals --->
            <cfset prodQ = prodModel.getProductById(dueTodayQ.product_id)>
            <cfset unitPrice  = prodQ.price>
            <cfset totalAmt   = unitPrice * dueTodayQ.quantity>
            <cfset groupId    = "SCHED-" & dueTodayQ.id & "-" & dateFormat(now(),"yyyymmdd")>

            <cfset result = orderModel.addOrder(
                user_id     = dueTodayQ.customer_id,
                product_id  = dueTodayQ.product_id,
                price       = unitPrice,
                quantity    = dueTodayQ.quantity,
                total       = totalAmt,
                group_id    = groupId,
                coupon_code = "",
                discount    = 0,
                final_total = totalAmt
            )>

            <cfif result.success>

                <!--- Stock already reduced at reservation time --->

                <!--- Reserve stock for NEXT cycle --->

                <cfquery name="nextStockCheck" datasource="#application.dsn#">
                    SELECT stock
                    FROM products
                    WHERE id = <cfqueryparam
                        value="#dueTodayQ.product_id#"
                        cfsqltype="cf_sql_integer">
                </cfquery>

                <cfif nextStockCheck.stock GTE dueTodayQ.quantity>

                    <!--- Enough stock: reserve for next month --->

                    <cfquery datasource="#application.dsn#">
                        UPDATE products
                        SET stock = stock - <cfqueryparam
                            value="#dueTodayQ.quantity#"
                            cfsqltype="cf_sql_integer">
                        WHERE id = <cfqueryparam
                            value="#dueTodayQ.product_id#"
                            cfsqltype="cf_sql_integer">
                        AND stock >= <cfqueryparam
                            value="#dueTodayQ.quantity#"
                            cfsqltype="cf_sql_integer">
                    </cfquery>

                    <cfquery datasource="#application.dsn#">
                        UPDATE scheduled_orders
                        SET reserved_qty = <cfqueryparam
                            value="#dueTodayQ.quantity#"
                            cfsqltype="cf_sql_integer">
                        WHERE id = <cfqueryparam
                            value="#dueTodayQ.id#"
                            cfsqltype="cf_sql_integer">
                    </cfquery>

                    <cfset notes = "Auto-created. Group: #groupId#. Next cycle reserved.">

                <cfelse>

                    <!--- Not enough stock for next cycle --->

                    <cfquery datasource="#application.dsn#">
                        UPDATE scheduled_orders
                        SET is_active = 0,
                            reserved_qty = 0
                        WHERE id = <cfqueryparam
                            value="#dueTodayQ.id#"
                            cfsqltype="cf_sql_integer">
                    </cfquery>

                    <cfset notes = "Auto-created. Group: #groupId#. WARNING: Schedule auto-paused — insufficient stock for next cycle.">

                    <cfoutput>
                        ⚠ Schedule ##dueTodayQ.id — paused, stock too low for next cycle.<br>
                    </cfoutput>

                </cfif>

                <cfset schedModel.logRun(
                    scheduled_order_id = dueTodayQ.id,
                    order_id           = 0,
                    status             = "success",
                    notes              = notes
                )>

                <cfoutput>
                    ✓ Schedule ##dueTodayQ.id — Order #groupId# created.<br>
                </cfoutput>

            <cfelse>

                <cfset schedModel.logRun(
                    scheduled_order_id = dueTodayQ.id,
                    order_id           = "",
                    status             = "failed",
                    notes              = result.message
                )>

                <cfoutput>
                    ✗ Schedule ##dueTodayQ.id — Failed: #result.message#<br>
                </cfoutput>

            </cfif>

        <cfcatch>

            <cfset schedModel.logRun(
                scheduled_order_id = dueTodayQ.id,
                order_id           = "",
                status             = "failed",
                notes              = cfcatch.message
            )>

            <cfoutput>
                ✗ Schedule ##dueTodayQ.id — Failed: #cfcatch.message#<br>
            </cfoutput>

        </cfcatch>

        </cftry>

    </cfloop>

</cfif>


<!--- ═══════════════════════════════════════════
   PERSONALIZED CUSTOMER NOTIFICATIONS
════════════════════════════════════════════════ --->

<cftry>

    <cfset notifEngine = createObject(
        "component",
        "models.CustomerNotificationEngine"
    )>

    <!--- 1. Reorder Reminders --->

    <cfset reorderResult = notifEngine.processReorderReminders()>

    <cfoutput>
        <br>
        <strong>Reorder Reminders:</strong>
        Sent: #reorderResult.sent#
        |
        Skipped: #reorderResult.skipped#
        |
        Errors: #reorderResult.errors#
    </cfoutput>


    <!--- 2. Personalized Offer Notifications --->

    <cfset offerResult = notifEngine.processPersonalizedOffers()>

    <cfoutput>
        <br>
        <strong>Personalized Offers:</strong>
        Sent: #offerResult.sent#
        |
        Skipped: #offerResult.skipped#
        |
        Errors: #offerResult.errors#
    </cfoutput>


    <!--- 3. Smart Recommendations --->

    <cfset recoResult = notifEngine.processSmartRecommendations()>

    <cfoutput>
        <br>
        <strong>Smart Recommendations:</strong>
        Sent: #recoResult.sent#
        |
        Skipped: #recoResult.skipped#
        |
        Errors: #recoResult.errors#
    </cfoutput>


    <!--- 4. Seasonal Predictions --->

    <cfset seasonResult = notifEngine.processSeasonalPredictions()>

    <cfoutput>
        <br>
        <strong>Seasonal Predictions:</strong>
        Sent: #seasonResult.sent#
        |
        Skipped: #seasonResult.skipped#
        |
        Errors: #seasonResult.errors#
    </cfoutput>


    <!--- 5. Cart Recovery --->

    <cfset cartResult = notifEngine.processCartRecovery()>

    <cfoutput>
        <br>
        <strong>Cart Recovery:</strong>
        Sent: #cartResult.sent#
        |
        Skipped: #cartResult.skipped#
        |
        Errors: #cartResult.errors#
    </cfoutput>

<cfcatch>

    <cfoutput>
        <br>
        <span style="color:red">
            Notification Engine Error:
            #cfcatch.message#
        </span>
    </cfoutput>

</cfcatch>

</cftry>