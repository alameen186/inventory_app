<cfif structKeyExists(form, "action") AND form.action EQ "checkout">

    <cfif NOT structKeyExists(session, "cart") OR structIsEmpty(session.cart)>
        <cflocation url="../index.cfm?page=dashboard&section=cart&message=Cart empty&type=error">
        <cfabort>
    </cfif>
     
    <cfset productModel = createObject("component","models.Product")>
    <cfset orderModel = createObject("component", "models.Order")>
    <cfset orderGroupId = createUUID()>

    <cfloop collection="#session.cart#" item="pid">
    <cfset item = session.cart[pid]>
    <cfset available = productModel.getStock(pid)>

    <cfif available LT item.qty>
        <cflocation url="../index.cfm?page=dashboard&section=cart&message=Not enough stock&type=error">
        <cfabort>
    </cfif>
    </cfloop>


       <cfset grandTotal = 0>
    <cfloop collection="#session.cart#" item="pid">
        <cfset item = session.cart[pid]>
        <cfset grandTotal += item.price * item.qty>
    </cfloop>

    <!-- coupon apply -->
    <cfset discount = 0>
    <cfset couponCode = "">

    <cfif structKeyExists(session, "coupon")>

        <cfset couponCode = session.coupon.code>

        <cfif session.coupon.type EQ "percent">
            <cfset discount = (grandTotal * session.coupon.value) / 100>
        <cfelse>
            <cfset discount = session.coupon.value>
        </cfif>

        <cfif discount GT session.coupon.max>
            <cfset discount = session.coupon.max>
        </cfif>

    </cfif>

    <cfset finalTotal = grandTotal - discount>

    <cfloop collection="#session.cart#" item="pid">
        <cfset item = session.cart[pid]>
        <cfset result = orderModel.addOrder(
    session.user_id,
    pid,
    item.price,
    item.qty,
    (item.price * item.qty),
    orderGroupId,
    couponCode,
    discount,
    finalTotal
)>

<cfif NOT result>
    <cflocation url="../index.cfm?page=dashboard&section=cart&message=Order failed&type=error">
    <cfabort>
</cfif>

        <cfset productModel.reduceStock(
        product_id = pid,
        qty = item.qty
        )>

    </cfloop>

    <cfset invoiceDir = expandPath("../assets/invoices/")>
    <cfset fileName = "invoice_#orderGroupId#.pdf">
    <cfset invoicePath = invoiceDir & fileName>

    <!--- create pdf --->
    <cfdocument format="pdf" filename="#invoicePath#" overwrite="true">
        <cfoutput>
            <h2>Invoice</h2>
            <p>Order ID: #orderGroupId#</p>

            <table border="1" width="100%">
                <tr>
                    <th>Product</th>
                    <th>Price</th>
                    <th>Qty</th>
                    <th>Total</th>
                </tr>

                <cfloop collection="#session.cart#" item="pid">
                    <cfset item = session.cart[pid]>
                    <tr>
                        <td>#item.name#</td>
                        <td>#item.price#</td>
                        <td>#item.qty#</td>
                        <td>#item.price * item.qty#</td>
                    </tr>
                </cfloop>
            </table>

            <p>Total: #grandTotal#</p>
            <p>Discount: #discount#</p>
            <h3>Final: #finalTotal#</h3>
        </cfoutput>
    </cfdocument>

    <!--- SEND EMAIL --->
    <cftry>
        <cfmail 
            to="#session.user_email#" 
            from="ameenalalameen8841@gmail.com" 
            subject="New Order Confirmation - #orderGroupId#" 
            type="html">
            
            <h2>Hello!</h2>
            <p>Thank you for your purchase. Please find your invoice attached to this email.</p>
            <p>Order ID: <strong>#orderGroupId#</strong></p>

            <!--- Attach the file --->
            <cfmailparam file="#invoicePath#" disposition="attachment">
        </cfmail>
        
        <cfcatch type="any">
            <!--- For debugging only - remove in production --->
            <cfdump var="#cfcatch#">
            <cfabort>
        </cfcatch>
    </cftry>

    <cfset session.cart = structNew()>
    <cfif structKeyExists(session,"coupon")>
    <cfset structDelete(session,"coupon")>
</cfif>

    <cflocation url="../index.cfm?page=dashboard&section=productList&message=Order successful! Invoice sent to your mail.&type=success" addtoken="false">
    <cfabort>
</cfif>

<cfif form.action EQ "cancel">

    <cfset orderModel = createObject("component","models.Order")>

    <cfset result = orderModel.cancelOrder(
    order_group_id = form.order_group_id,
    reason = form.reason,
    user_id = session.user_id
)>

    <cfif result>
        <cfset orderModel.sendCancelEmail(
            order_id = form.order_group_id,
            reason = form.reason
        )>

        <cflocation url="../index.cfm?page=dashboard&section=orders&message=Cancelled&type=success">
    <cfelse>
        <cflocation url="../index.cfm?page=dashboard&section=orders&message=Error&type=error">
    </cfif>

</cfif>


<cfif form.action EQ "approveCancel">

    <cfset orderModel = createObject("component","models.Order")>

    <cfset result = orderModel.approveCancel(
        order_group_id = form.order_group_id
    )>

    <cfif result>
        <cfset orderModel.restoreStock(
            order_group_id = form.order_group_id
        )>
    </cfif>

    <cflocation url="../index.cfm?page=dashboard&section=allorders&message=Order Cancelled and Stock Restored&type=success">

</cfif>