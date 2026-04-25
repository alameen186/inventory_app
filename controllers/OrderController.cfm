<!---

<!---ADMIN--->
<cfif structKeyExists(form, "action") AND form.action EQ "checkout">

<cfif structKeyExists(session,"role_name") AND session.role_name EQ "vendor">
    <cfset vendorFilter = session.user_id>
<cfelse>
    <cfset vendorFilter = "">
</cfif>

<cfif NOT structKeyExists(session, "cart") OR structIsEmpty(session.cart)>
    <cfcontent type="application/json" reset="true">
    <cfoutput>{"status":"error","message":"Cart empty"}</cfoutput>
    <cfabort>
</cfif>

<cfset productModel = createObject("component","models.Product")>
<cfset orderModel   = createObject("component","models.Order")>
<cfset orderGroupId = createUUID()>

<!--- STOCK CHECK --->
<cfloop collection="#session.cart#" item="pid">
    <cfset item      = session.cart[pid]>
    <cfset available = productModel.getStock(pid)>
    <cfif available LT item.qty>
        <cfcontent type="application/json" reset="true">
        <cfoutput>{"status":"error","message":"Not enough stock"}</cfoutput>
        <cfabort>
    </cfif>
</cfloop>

<!--- CALCULATE GRAND TOTAL --->
<cfset grandTotal = 0>
<cfloop collection="#session.cart#" item="pid">
    <cfset item = session.cart[pid]>
    <cfset grandTotal += item.price * item.qty>
</cfloop>

<!--- APPLY COUPON IF EXISTS --->
<cfset discount   = 0>
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

<!--- TEMP USER LOGIC --->
<cfif session.role_name EQ "vendor">
    <cfset tempUserModel = createObject("component","models.TempUser")>
    <cfset tempUserId = tempUserModel.getOrCreateTempUser(
        vendor_id  = session.user_id,
        first_name = form.first_name,
        last_name  = form.last_name,
        email      = form.email
    )>
<cfelse>
    <cfset tempUserId = "">
</cfif>

<!--- SAVE ORDER ITEMS --->
<cfloop collection="#session.cart#" item="pid">
    <cfset item = session.cart[pid]>
    <cfset result = orderModel.addOrder(
        user_id      = (session.role_name EQ "vendor" ? "" : session.user_id),
        temp_user_id = tempUserId,
        product_id   = pid,
        price        = item.price,
        quantity     = item.qty,
        total        = (item.price * item.qty),
        group_id     = orderGroupId,
        coupon_code  = couponCode,
        discount     = discount,
        final_total  = finalTotal
    )>

    <cfif NOT result.success>
        <cfcontent type="application/json">
        <cfoutput>{"status":"error","message":"Order failed"}</cfoutput>
        <cfabort>
    </cfif>

    <cfset productModel.reduceStock(pid, item.qty)>
</cfloop>

<!--- GENERATE PDF INVOICE --->
<cfset invoiceDir  = expandPath("../assets/invoices/")>
<cfset fileName    = "invoice_#orderGroupId#.pdf">
<cfset invoicePath = invoiceDir & fileName>

<cfset userModel    = createObject("component","models.User")>
<cfset productIds   = structKeyList(session.cart)>
<cfset vendorData   = userModel.getUserWithRole(session.user_id)>
<cfset productData  = productModel.getProductsWithVendorByIds(productIds)>

<cfdocument format="pdf" filename="#invoicePath#" overwrite="true">
<cfoutput>
<style>
body { font-family: Arial; font-size: 12px; }
.text-center { text-align: center; }
.text-right  { text-align: right; }
.header      { border-bottom: 2px solid ##000; margin-bottom: 15px; padding-bottom: 10px; }
.table       { width: 100%; border-collapse: collapse; margin-top: 10px; }
.table th    { background: ##f2f2f2; border: 1px solid ##ccc; padding: 8px; }
.table td    { border: 1px solid ##ccc; padding: 8px; }
.total-box   { width: 40%; float: right; margin-top: 10px; }
.footer      { margin-top: 40px; font-size: 10px; text-align: center; color: ##777; }
</style>

<div>
    <div class="header text-center">
        <h2>INVENTORY STORE</h2>
    </div>

    <table width="100%">
    <tr>
        <td>
            <strong>Invoice ID:</strong> #orderGroupId#<br>
            <strong>Date:</strong> #dateFormat(now(),"dd-mmm-yyyy")#
        </td>
    </tr>
    </table>

    <table class="table">
    <tr>
        <th>Product</th>
        <th>Price</th>
        <th>Qty</th>
        <th>Vendor</th>
        <th>Total</th>
    </tr>

    <cfset grandTotal = 0>
    <cfloop collection="#session.cart#" item="pid">
        <cfset item         = session.cart[pid]>
        <cfset vendorName   = "Unknown Vendor">
        <cfset vendorAddress = "">

        <cfloop query="productData">
            <cfif productData.id EQ pid>
                <cfset vendorName    = productData.business_name>
                <cfset vendorAddress = productData.address>
            </cfif>
        </cfloop>

        <cfset rowTotal    = item.price * item.qty>
        <cfset grandTotal += rowTotal>

        <tr>
            <td>#item.name#</td>
            <td>#item.price#</td>
            <td>#item.qty#</td>
            <td><strong>#vendorName#</strong><br><small>#vendorAddress#</small></td>
            <td>#rowTotal#</td>
        </tr>
    </cfloop>
    </table>

    <table class="total-box">
    <tr><td>Subtotal</td>         <td class="text-right">#grandTotal#</td></tr>
    <tr><td>GST (0%)</td>         <td class="text-right">0</td></tr>
    <tr><td><strong>Final Total</strong></td><td class="text-right"><strong>#finalTotal#</strong></td></tr>
    </table>

    <div style="clear:both;"></div>

    <div class="footer">
        <p>This is a system generated invoice.</p>
        <p>No signature required.</p>
    </div>
</div>
</cfoutput>
</cfdocument>

<!--- SEND CONFIRMATION EMAIL WITH INVOICE --->
<cftry>
    <cfmail to="#session.user_email#"
            from="no-reply@yourapp.com"
            subject="Order Confirmation - #orderGroupId#"
            type="html">
        <h3>Order Successful</h3>
        <p>Order ID: #orderGroupId#</p>
        <cfmailparam file="#invoicePath#" disposition="attachment">
    </cfmail>
    <cfcatch></cfcatch>
</cftry>

<!--- CLEAR CART AND COUPON --->
<cfset session.cart = structNew()>
<cfif structKeyExists(session,"coupon")>
    <cfset structDelete(session,"coupon")>
</cfif>

<cfcontent type="application/json">
<cfoutput>{"status":"success","message":"Order placed successfully"}</cfoutput>
<cfabort>

</cfif>


<!--- ADMIN: APPROVE CANCEL REQUEST --->
<cfif structKeyExists(form,"action") AND form.action EQ "approveCancel">
 
<cfset orderModel = createObject("component","models.Order")>
<cfset result     = orderModel.approveCancel(order_group_id=form.order_group_id)>

<cfif result>
    <cfset orderModel.restoreStock(order_group_id=form.order_group_id)>
</cfif>

<cfcontent type="application/json">
<cfoutput>{"status":"success","message":"Order Cancelled & Stock Restored"}</cfoutput>
<cfabort>

</cfif>


<!--- ADMIN: SEARCH & PAGINATE ORDERS --->
<cfif structKeyExists(url,"action") AND url.action EQ "search">

<cfset orderModel = createObject("component","models.Order")>

<cfparam name="url.search"   default="">
<cfparam name="url.p"        default="1">
<cfparam name="url.fromDate" default="">
<cfparam name="url.toDate"   default="">

<cfset searchValue  = trim(url.search)>
<cfset currentPage  = val(url.p) GT 0 ? val(url.p) : 1>
<cfset limit        = 2>

<cfif structKeyExists(session,"role_name") AND session.role_name EQ "vendor">
    <cfset vendorFilter = session.user_id>
<cfelse>
    <cfset vendorFilter = "">
</cfif>

<cfset orders = orderModel.getAllOrdersWithPagination(
    search    = searchValue,
    page      = currentPage,
    limit     = limit,
    vendor_id = vendorFilter,
    fromDate  = url.fromDate,
    toDate    = url.toDate
)>

<cfset totalRecords = orderModel.getOrderCount(
    search    = searchValue,
    vendor_id = vendorFilter,
    fromDate  = url.fromDate,
    toDate    = url.toDate
)>
<cfset totalPages = ceiling(totalRecords / limit)>

<cfif orders.recordCount EQ 0>

    <div class="alert alert-info">No orders found matching your criteria.</div>

<cfelse>

    <cfset currentGroup = "">
    <cfset gTotal       = 0>

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
                           class="btn btn-success btn-sm">PDF</a>

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
                    <div class="alert alert-warning">#cancel_reason#</div>
                    <button class="approveBtn btn btn-success btn-sm" data-id="#order_group_id#">
                        Approve Cancel
                    </button>
                </div>
                </cfif>

                <table class="table mb-0">
                <thead class="table-dark">
                <tr>
                    <th>Product</th>
                    <th>Image</th>
                    <th>Price</th>
                    <th>Qty</th>
                    <th>Total</th>
                </tr>
                </thead>
                <tbody>

            <cfset currentGroup = order_group_id>
        </cfif>

        <tr>
            <td>#product_name#</td>
            <td>
                <img src="../../assets/images/products/#image#" width="40"
                     style="height:40px;object-fit:cover;"
                     onerror="this.src='https://placehold.co/40'">
            </td>
            <td>#price#</td>
            <td>#quantity#</td>
            <td>#total_amount#</td>
        </tr>

        <cfset gTotal += total_amount>

        <cfif currentRow EQ recordCount>
                </tbody>
                </table>
                <div class="card-footer text-end">
                    <strong>Order Total: #gTotal#</strong>
                </div>
            </div>
        </cfif>

    </cfoutput>

</cfif>

<!--- PAGINATION --->
<cfif totalPages GT 1>
    <cfset groupSize  = 4>
    <cfset pageGroup  = ceiling(currentPage / groupSize)>
    <cfset startPage  = (pageGroup - 1) * groupSize + 1>
    <cfset endPage    = min(startPage + groupSize - 1, totalPages)>

    <cfoutput>
    <div class="mt-4 d-flex justify-content-center flex-wrap gap-2">

        <cfif startPage GT 1>
            <button class="btn btn-outline-primary btn-sm pageBtn"
                    data-page="#startPage - 1#">Prev</button>
        </cfif>

        <cfloop from="#startPage#" to="#endPage#" index="i">
            <button class="btn btn-sm pageBtn
                <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
                data-page="#i#">#i#</button>
        </cfloop>

        <cfif endPage LT totalPages>
            <button class="btn btn-outline-primary btn-sm pageBtn"
                    data-page="#endPage + 1#">Next</button>
        </cfif>

    </div>
    </cfoutput>
</cfif>

<cfabort>

</cfif>


<!--- ADMIN --->
<cfif structKeyExists(form,"action") AND form.action EQ "vendorOrder">

<cftry>

    <cfset tempUserModel = createObject("component","models.TempUser")>
    <cfset orderModel    = createObject("component","models.Order")>
    <cfset productModel  = createObject("component","models.Product")>

    <!--- VALIDATE CART EXISTS --->
    <cfif NOT structKeyExists(form,"cart")>
        <cfthrow message="Cart missing">
    </cfif>

    <!--- PARSE CART FROM JSON --->
    <cfset cartData = deserializeJSON(form.cart)>

    <cfif structIsEmpty(cartData)>
        <cfthrow message="Cart is empty after parse">
    </cfif>

    <!--- CREATE OR FETCH TEMP USER --->
    <cfset tempUserId = tempUserModel.getOrCreateTempUser(
        vendor_id  = session.user_id,
        first_name = form.first_name,
        last_name  = form.last_name,
        email      = form.email
    )>

    <cfset orderGroupId = createUUID()>

    <!--- LOAD VENDOR DATA FOR PDF --->
    <cfset userModel  = createObject("component","models.User")>
    <cfset vendorData = userModel.getUserWithRole(session.user_id)>

    <!--- SAVE EACH CART ITEM AS ORDER --->
    <cfloop collection="#cartData#" item="pid">
        <cfset item = cartData[pid]>

        <cfif NOT structKeyExists(item,"price") OR NOT structKeyExists(item,"qty")>
            <cfthrow message="Cart item structure invalid">
        </cfif>

        <cfset result = orderModel.addOrder(
            user_id      = "",
            temp_user_id = tempUserId,
            product_id   = pid,
            price        = item.price,
            quantity     = item.qty,
            total        = item.price * item.qty,
            group_id     = orderGroupId,
            coupon_code  = "",
            discount     = 0,
            final_total  = item.price * item.qty
        )>

        <cfif isStruct(result) AND NOT result.success>
            <cfthrow message="#result.message#" detail="#result.detail#">
        </cfif>

        <cfset productModel.reduceStock(pid, item.qty)>
    </cfloop>

    <!--- GENERATE PDF INVOICE FOR VENDOR ORDER --->
    <cfset invoiceDir  = expandPath("../assets/invoices/")>
    <cfset fileName    = "invoice_#orderGroupId#.pdf">
    <cfset invoicePath = invoiceDir & fileName>

    <cfdocument format="pdf" filename="#invoicePath#" overwrite="true">
    <cfoutput>
    <style>
    body { font-family: Arial; font-size: 12px; }
    .text-center { text-align: center; }
    .text-right  { text-align: right; }
    .header      { border-bottom: 2px solid ##000; margin-bottom: 15px; padding-bottom: 10px; }
    .table       { width: 100%; border-collapse: collapse; margin-top: 10px; }
    .table th    { background: ##f2f2f2; border: 1px solid ##ccc; padding: 8px; }
    .table td    { border: 1px solid ##ccc; padding: 8px; }
    .total-box   { width: 40%; float: right; margin-top: 10px; }
    .footer      { margin-top: 40px; font-size: 10px; text-align: center; color: ##777; }
    </style>

    <div>
        <div class="header text-center">
            <h2>INVENTORY STORE</h2>
        </div>

        <table width="100%">
        <tr>
            <td>
                <strong>Invoice ID:</strong> #orderGroupId#<br>
                <strong>Date:</strong> #dateFormat(now(),"dd-mmm-yyyy")#
            </td>
            <td class="text-right">
                <strong>Vendor:</strong><br>
                #vendorData.business_name#
            </td>
        </tr>
        </table>

        <table class="table">
        <tr>
            <th>Product</th>
            <th>Price</th>
            <th>Qty</th>
            <th>Total</th>
        </tr>

        <cfset grandTotal = 0>
        <cfloop collection="#cartData#" item="pid">
            <cfset item     = cartData[pid]>
            <cfset rowTotal = item.price * item.qty>
            <cfset grandTotal += rowTotal>
            <tr>
                <td>#item.name#</td>
                <td>#item.price#</td>
                <td>#item.qty#</td>
                <td>#rowTotal#</td>
            </tr>
        </cfloop>
        </table>

        <table class="total-box">
        <tr><td>Subtotal</td>                  <td class="text-right">#grandTotal#</td></tr>
        <tr><td>GST (0%)</td>                  <td class="text-right">0</td></tr>
        <tr><td><strong>Final Total</strong></td><td class="text-right"><strong>#grandTotal#</strong></td></tr>
        </table>

        <div style="clear:both;"></div>

        <div class="footer">
            <p>This is a system generated invoice.</p>
            <p>No signature required.</p>
        </div>
    </div>
    </cfoutput>
    </cfdocument>

    <cfcontent type="application/json">
    <cfoutput>{"status":"success"}</cfoutput>
    <cfabort>

<cfcatch>
    <cfcontent type="application/json">
    <cfoutput>{"status":"error","message":"#cfcatch.message#","detail":"#cfcatch.detail#"}</cfoutput>
    <cfabort>
</cfcatch>

</cftry>

</cfif>


<!---  USER: CANCEL ORDER REQUEST --->
<cfif structKeyExists(form,"action") AND form.action EQ "cancel">

<cfset orderModel = createObject("component","models.Order")>

<cfset result = orderModel.cancelOrder(
    order_group_id = form.order_group_id,
    reason         = form.reason,
    user_id        = session.user_id
)>

<cfcontent type="application/json">
<cfoutput>
{"status":"#result ? 'success' : 'error'#","message":"#result ? 'Cancelled' : 'Error'#"}
</cfoutput>
<cfabort>

</cfif>

--->