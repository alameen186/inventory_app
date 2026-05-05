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

<cfif dueTodayQ.recordCount EQ 0>
    <cfoutput>
    <br>No schedules due today (day #day(now())#).
    Check that your scheduled_orders have day_of_month = #day(now())#
    and start_date &lt;= today.
    </cfoutput>
    <cfabort>
</cfif>

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
            <!--- reduce stock --->
            <cfset prodModel.reduceStock(dueTodayQ.product_id, dueTodayQ.quantity)>

            <cfset schedModel.logRun(
                scheduled_order_id = dueTodayQ.id,
                order_id           = 0,
                status             = "success",
                notes              = "Auto-created. Group: #groupId#"
            )>
            <cfoutput>✓ Schedule ##dueTodayQ.id — Order #groupId# created.<br></cfoutput>
        <cfelse>
            <cfset schedModel.logRun(
                scheduled_order_id = dueTodayQ.id,
                order_id           = "",
                status             = "failed",
                notes              = result.message
            )>
            <cfoutput>✗ Schedule ##dueTodayQ.id — Failed: #result.message#<br></cfoutput>
        </cfif>

    <cfcatch>
        <cfset schedModel.logRun(
            scheduled_order_id = dueTodayQ.id,
            order_id           = "",
            status             = "failed",
            notes              = cfcatch.message
        )>
        <cfoutput>✗ Schedule ##dueTodayQ.id — Failed: #cfcatch.message#<br></cfoutput>
    </cfcatch>
    </cftry>
</cfloop>