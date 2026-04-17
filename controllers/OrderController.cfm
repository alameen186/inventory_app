<!-- checkout-->
<cfif structKeyExists(form, "action") AND form.action EQ "checkout">

<cfif NOT structKeyExists(session, "cart") OR structIsEmpty(session.cart)>
    <cfcontent type="application/json" reset="true">
    <cfoutput>{"status":"error","message":"Cart empty"}</cfoutput>
    <cfabort>
</cfif>

<cfset productModel = createObject("component","models.Product")>
<cfset orderModel = createObject("component","models.Order")>
<cfset orderGroupId = createUUID()>

<!-- STOCK CHECK -->
<cfloop collection="#session.cart#" item="pid">
    <cfset item = session.cart[pid]>
    <cfset available = productModel.getStock(pid)>
    <cfif available LT item.qty>
        <cfcontent type="application/json" reset="true">
        <cfoutput>{"status":"error","message":"Not enough stock"}</cfoutput>
        <cfabort>
    </cfif>
</cfloop>

<!-- TOTAL -->
<cfset grandTotal = 0>
<cfloop collection="#session.cart#" item="pid">
    <cfset item = session.cart[pid]>
    <cfset grandTotal += item.price * item.qty>
</cfloop>

<!-- COUPON -->
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

<!-- SAVE ORDER -->
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
        <cfcontent type="application/json">
        <cfoutput>{"status":"error","message":"Order failed"}</cfoutput>
        <cfabort>
    </cfif>

    <cfset productModel.reduceStock(pid, item.qty)>
</cfloop>

<!-- pdf -->
<cfset invoiceDir = expandPath("../assets/invoices/")>
<cfset fileName = "invoice_#orderGroupId#.pdf">
<cfset invoicePath = invoiceDir & fileName>

<cfdocument format="pdf" filename="#invoicePath#" overwrite="true">
<cfoutput>
<h2>Invoice</h2>
<p>Order ID: #orderGroupId#</p>

<table border="1" width="100%">
<tr><th>Product</th><th>Price</th><th>Qty</th><th>Total</th></tr>

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

<!-- email -->
<cftry>
<cfmail to="#session.user_email#" from="no-reply@yourapp.com"
subject="Order Confirmation - #orderGroupId#" type="html">

<h3>Order Successful</h3>
<p>Order ID: #orderGroupId#</p>

<cfmailparam file="#invoicePath#" disposition="attachment">
</cfmail>
<cfcatch></cfcatch>
</cftry>

<!-- CLEAR -->
<cfset session.cart = structNew()>
<cfif structKeyExists(session,"coupon")>
<cfset structDelete(session,"coupon")>
</cfif>

<cfcontent type="application/json">
<cfoutput>{"status":"success","message":"Order placed successfully"}</cfoutput>
<cfabort>

</cfif>



<!-- cancel -->
<cfif structKeyExists(form,"action") AND form.action EQ "cancel">

<cfset orderModel = createObject("component","models.Order")>

<cfset result = orderModel.cancelOrder(
order_group_id=form.order_group_id,
reason=form.reason,
user_id=session.user_id
)>

<cfcontent type="application/json">
<cfoutput>
{"status":"#result ? 'success':'error'#","message":"#result ? 'Cancelled':'Error'#"}
</cfoutput>
<cfabort>

</cfif>



<!-- approve -->
<cfif structKeyExists(form,"action") AND form.action EQ "approveCancel">

<cfset orderModel = createObject("component","models.Order")>

<cfset result = orderModel.approveCancel(order_group_id=form.order_group_id)>

<cfif result>
<cfset orderModel.restoreStock(order_group_id=form.order_group_id)>
</cfif>

<cfcontent type="application/json">
<cfoutput>
{"status":"success","message":"Order Cancelled & Stock Restored"}
</cfoutput>
<cfabort>

</cfif>

<!-- ================= SEARCH + PAGINATION ================= -->
<cfif structKeyExists(url,"action") AND url.action EQ "search">

<cfset orderModel = createObject("component","models.Order")>

<cfparam name="url.search" default="">
<cfparam name="url.p" default="1">

<cfset searchValue = trim(url.search)>
<cfset currentPage = val(url.p) GT 0 ? val(url.p) : 1>
<cfset limit = 2>

<cfset orders = orderModel.getAllOrdersWithPagination(
    search=searchValue,
    page=currentPage,
    limit=limit
)>

<cfset totalRecords = orderModel.getOrderCount(search=searchValue)>
<cfset totalPages = ceiling(totalRecords / limit)>

<!-- RETURN ONLY INNER HTML -->
<cfif orders.recordCount EQ 0>

    <div class="alert alert-info">
        No orders found matching your criteria.
    </div>

<cfelse>

<cfset currentGroup = "">
<cfset gTotal = 0>

<cfoutput query="orders">

<cfif currentGroup NEQ order_group_id>

    <cfif currentGroup NEQ "">
        <tr class="table-secondary">
            <td colspan="4" class="text-end"><strong>Total:</strong></td>
            <td><strong>#gTotal#</strong></td>
        </tr>
        </table></div>
        <cfset gTotal = 0>
    </cfif>

    <div class="card mb-4 shadow">

    <div class="card-header bg-dark text-white d-flex justify-content-between">

        <span>
            <strong>Order: #order_group_id#</strong> |
            #dateFormat(created_at, "dd-mmm-yyyy")# |
            #user_name#
        </span>

        <div>

            <a href="../../assets/invoices/invoice_#order_group_id#.pdf"
               target="_blank"
               class="btn btn-success btn-sm">
               PDF
            </a>

            <cfif status EQ "cancel_requested">
                <span class="badge bg-warning text-dark ms-2">Cancel Requested</span>
            <cfelseif status EQ "cancelled">
                <span class="badge bg-secondary ms-2">Cancelled</span>
            <cfelse>
                <span class="badge bg-success ms-2">Active</span>
            </cfif>

        </div>

    </div>

    <cfif status EQ "cancel_requested">
    <div class="p-3 border-top bg-light">

        <p><strong>Cancel Reason:</strong></p>

        <div class="alert alert-warning">
            #cancel_reason#
        </div>

        <button class="approveBtn btn btn-success btn-sm"
                data-id="#order_group_id#">
            Approve Cancel
        </button>

    </div>
    </cfif>

    <table class="table mb-0">
    <tr>
        <th>Product</th>
        <th>Image</th>
        <th>Price</th>
        <th>Qty</th>
        <th>Total</th>
    </tr>

    <cfset currentGroup = order_group_id>
</cfif>

<tr>
    <td>#product_name#</td>
    <td>
        <img src="../../assets/images/products/#image#" width="40">
    </td>
    <td>#price#</td>
    <td>#quantity#</td>
    <td>#total_amount#</td>
</tr>

<cfset gTotal += total_amount>

<cfif currentRow EQ recordCount>
    <tr class="table-secondary">
        <td colspan="4" class="text-end"><strong>Total:</strong></td>
        <td><strong>#gTotal#</strong></td>
    </tr>
    </table></div>
</cfif>

</cfoutput>

<!-- PAGINATION -->
<nav class="mt-4">
<ul class="pagination">

<cfoutput>
<cfloop from="1" to="#totalPages#" index="i">

<li class="page-item # (i eq currentPage ? 'active' : '') #">

<button class="page-link pageBtn" data-page="#i#">
#i#
</button>

</li>

</cfloop>
</cfoutput>

</ul>
</nav>

</cfif>

<cfabort>

</cfif>