<cfcomponent output="false">

    <cffunction name="sendJSON" access="private" returntype="void" output="true">
       <cfargument name="data" type="struct" required="true">
       <cfcontent type="application/json; charset=utf-8" reset="true">
       <cfset var map = createObject("java","java.util.LinkedHashMap").init()>
       <cfloop collection="#arguments.data#" item="k">
           <cfset map[lcase(k)] = arguments.data[k]>
       </cfloop>
       <cfset var jsonStr = serializeJSON(map)>
       <cfoutput>#jsonStr#</cfoutput>
       <cfabort>
    </cffunction>

<cffunction name="checkout" access="remote" returntype="void" output="true" httpmethod="POST">
    <cfset createObject("component","models.AuthGuard").checkAuth()>

    <cftry>
        <cfif NOT structKeyExists(session, "cart") OR structIsEmpty(session.cart)>
            <cfset sendJSON({status:"error", message:"Your cart is empty!"})>
        </cfif>

        <cfset var productModel = createObject("component","models.Product")>
        <cfset var orderModel   = createObject("component","models.Order")>
        <cfset var notifModel   = createObject("component","models.Notification")>
        
        <cfset var orderGroupId = "ORD-" & DateFormat(Now(),"yyyymmdd") & "-" & RandRange(10000,99999)>

        <!--- STOCK CHECK --->
        <cfloop collection="#session.cart#" item="pid">
            <cfset var item = session.cart[pid]>
            <cfset var availableStock = productModel.getStock(pid)>
            <cfif availableStock LT item.qty>
                <cfset sendJSON({status:"error", message:"Insufficient stock for #item.name#"})>
            </cfif>
        </cfloop>

        <!--- CALCULATE TOTALS --->
        <cfset var grandTotal = 0>
        <cfloop collection="#session.cart#" item="pid">
            <cfset grandTotal += session.cart[pid].price * session.cart[pid].qty>
        </cfloop>

        <cfset var discount = 0>
        <cfset var couponCode = "">
        <cfset var finalTotal = grandTotal>

        <cfif structKeyExists(session, "coupon")>
            <cfset couponCode = session.coupon.code>
            <cfif session.coupon.type EQ "percent">
                <cfset discount = (grandTotal * session.coupon.value) / 100>
            <cfelse>
                <cfset discount = session.coupon.value>
            </cfif>
            <cfif structKeyExists(session.coupon, "max") AND discount GT session.coupon.max>
                <cfset discount = session.coupon.max>
            </cfif>
            <cfset finalTotal = grandTotal - discount>
        </cfif>

        <!--- TEMP USER (for vendor orders) --->
        <cfset var tempUserId = "">
        <cfif session.role_name EQ "vendor">
            <cfset var tempUserModel = createObject("component","models.TempUser")>
            <cfset tempUserId = tempUserModel.getOrCreateTempUser(
                vendor_id  = session.user_id,
                first_name = structKeyExists(form,"first_name") ? form.first_name : "Walk-in",
                last_name  = structKeyExists(form,"last_name")  ? form.last_name  : "",
                email      = structKeyExists(form,"email")       ? form.email       : ""
            )>
        </cfif>

        <!--- SAVE ORDERS + SEND NOTIFICATIONS --->
        <cfloop collection="#session.cart#" item="pid">
            <cfset var item = session.cart[pid]>
            <cfset var itemTotal = item.price * item.qty>

            <!--- Get Vendor ID --->
            <cfset var vendorId = productModel.getVendorId(pid)>

            <!--- Save Order --->
            <cfset var result = orderModel.addOrder(
                user_id      = (session.role_name EQ "vendor" ? "" : session.user_id),
                temp_user_id = tempUserId,
                product_id   = pid,
                price        = item.price,
                quantity     = item.qty,
                total        = itemTotal,
                group_id     = orderGroupId,
                coupon_code  = couponCode,
                discount     = discount,
                final_total  = finalTotal
            )>

            <cfif isStruct(result) AND NOT result.success>
                <cfset sendJSON({status:"error", message:"Failed to save order item"})>
            </cfif>

            <!--- Reduce Stock --->
            <cfset productModel.reduceStock(pid, item.qty)>

            <!--- Send Notification to Vendor --->
            <cfif vendorId GT 0>
                <cfset notifModel.create(
                    user_id   = vendorId,
                    sender_id = session.user_id,
                    type      = "order_placed",
                    title     = "New Order Received",
                    message   = "#item.qty# x #item.name# has been ordered",
                    link      = "index.cfm?page=dashboard&section=allorders"
                )>
            </cfif>
        </cfloop>

        <!--- ── SWAP ALERT LOGIC ── --->
<cfset var cartProductIds = []>
<cfloop collection="#session.cart#" item="pid">
    <cfset arrayAppend(cartProductIds, val(pid))>
</cfloop>

<cfif arrayLen(cartProductIds) GTE 2>
    <cfset var placementModel = createObject("component","models.RackPlacement")>
    <cfloop from="1" to="#arrayLen(cartProductIds) - 1#" index="ci">
        <cfloop from="#ci + 1#" to="#arrayLen(cartProductIds)#" index="cj">
            <cfset var cPid1 = cartProductIds[ci]>
            <cfset var cPid2 = cartProductIds[cj]>
            <cfset var cV1   = productModel.getVendorId(cPid1)>
            <cfset var cV2   = productModel.getVendorId(cPid2)>
            <cfif cV1 EQ cV2 AND cV1 GT 0>
                <cfset var cLoc1 = placementModel.getProductPlacement(cPid1)>
                <cfset var cLoc2 = placementModel.getProductPlacement(cPid2)>
                <cfif cLoc1.recordCount GT 0 AND cLoc2.recordCount GT 0
                      AND cLoc1.rack_face_id NEQ cLoc2.rack_face_id>
                    <cfset placementModel.logSwapAlert(
                        vendor_id   = cV1,
                        product1_id = cPid1,
                        product2_id = cPid2
                    )>
                </cfif>
            </cfif>
        </cfloop>
    </cfloop>
</cfif>

        <!--- PDF Invoice Generation (Same style as vendorOrder) --->
        <cfset var invoiceDir  = expandPath("../../assets/invoices/")>
        <cfset var fileName    = "invoice_#orderGroupId#.pdf">
        <cfset var invoicePath = invoiceDir & fileName>

        <cfdocument format="pdf" filename="#invoicePath#" overwrite="true">
        <cfoutput>
        <style>
        body{font-family:Arial;font-size:12px;}
        .tc{text-align:center;} .tr{text-align:right;}
        .header{border-bottom:2px solid ##000;margin-bottom:15px;padding-bottom:10px;}
        .tbl{width:100%;border-collapse:collapse;margin-top:10px;}
        .tbl th{background:##f2f2f2;border:1px solid ##ccc;padding:8px;}
        .tbl td{border:1px solid ##ccc;padding:8px;}
        .total-box{width:40%;float:right;margin-top:10px;}
        .footer{margin-top:40px;font-size:10px;text-align:center;color:##777;}
        </style>
        <div>
            <div class="header tc"><h2>INVENTORY STORE</h2></div>
            <table width="100%">
            <tr>
                <td><strong>Invoice ID:</strong> #orderGroupId#<br>
                    <strong>Date:</strong> #dateFormat(now(),"dd-mmm-yyyy")#
                </td>
            </tr>
            </table>

            <table class="tbl">
            <tr><th>Product</th><th>Price</th><th>Qty</th><th>Total</th></tr>
            <cfset var pdfTotal = 0>
            <cfloop collection="#session.cart#" item="pid">
                <cfset var item = session.cart[pid]>
                <cfset var rowTotal = item.price * item.qty>
                <cfset pdfTotal += rowTotal>
                <tr>
                    <td>#item.name#</td>
                    <td>#item.price#</td>
                    <td>#item.qty#</td>
                    <td>#rowTotal#</td>
                </tr>
            </cfloop>
            </table>

            <table class="total-box">
            <tr><td>Subtotal</td><td class="tr">#pdfTotal#</td></tr>
            <tr><td>Discount</td><td class="tr">#discount#</td></tr>
            <tr><td><strong>Final Total</strong></td><td class="tr"><strong>#finalTotal#</strong></td></tr>
            </table>
            <div style="clear:both;"></div>
            <div class="footer"><p>System generated invoice. No signature required.</p></div>
        </div>
        </cfoutput>
        </cfdocument>

        <!--- Send Email --->
        <cftry>
            <cfmail to="#session.user_email#"
                    from="no-reply@yourdomain.com"
                    subject="Order Confirmation - #orderGroupId#"
                    type="html">
                <h3>Thank you for your order!</h3>
                <p>Order ID: <strong>#orderGroupId#</strong></p>
                <cfmailparam file="#invoicePath#" disposition="attachment">
            </cfmail>
            <cfcatch></cfcatch>
        </cftry>

        <!--- Clear Cart --->
        <cfset structDelete(session, "cart")>
        <cfset structDelete(session, "coupon")>

        <cfset sendJSON({
            status: "success",
            message: "Order placed successfully! Order ID: #orderGroupId#",
            order_group_id: orderGroupId
        })>

    <cfcatch>
        <cfset sendJSON({status:"error", message:"Checkout failed: #cfcatch.message#"})>
    </cfcatch>
    </cftry>
</cffunction>

    <!--- SEARCH ORDERS --->
    <cffunction name="searchOrders" access="remote" returntype="void" output="true" httpmethod="GET">
        <cfset createObject("component","models.AuthGuard").checkAuth()>
        <cftry>
            <cfset var orderModel  = createObject("component","models.Order")>
            <cfset var srch        = structKeyExists(url,"search") ? trim(url.search) : "">
            <cfset var currentPage = structKeyExists(url,"p") AND val(url.p) GT 0 ? val(url.p) : 1>
            <cfset var limit       = 5>

            <cfset var orders = orderModel.getUserOrdersWithPagination(
                user_id = session.user_id,
                search  = srch,
                page    = currentPage,
                limit   = limit
            )>
            <cfset var totalRecords = orderModel.getUserOrderCount(
                user_id = session.user_id,
                search  = srch
            )>
            <cfset var totalPages = ceiling(totalRecords / limit)>

            <!--- ORDER HTML --->
            <cfsavecontent variable="ordersHTML">
            <cfif orders.recordCount EQ 0>
                <div class="alert alert-info text-center">No orders found.</div>
            <cfelse>
                <cfset var tracker    = "">
                <cfset var groupTotal = 0>
                <cfoutput query="orders">

                    <cfif tracker NEQ order_group_id>
                        <cfif tracker NEQ "">
                            <tr class="table-light">
                                <td colspan="4" class="text-end"><strong>Total:</strong></td>
                                <td><strong>#groupTotal#</strong></td>
                            </tr>
                            </tbody></table></div></div>
                            <cfset groupTotal = 0>
                        </cfif>

                        <div class="card mb-4 shadow-sm">
                            <div class="card-header bg-dark text-white d-flex justify-content-between align-items-center flex-wrap">
                                <div>
                                    <strong>#order_group_id#</strong><br>
                                    <small>#dateFormat(created_at,"dd-mmm-yyyy")#</small>
                                </div>
                                <div class="d-flex gap-2 flex-wrap">
                                    <cfif status EQ "placed">
                                        <a href="../../assets/invoices/invoice_#order_group_id#.pdf"
                                           target="_blank" class="btn btn-success btn-sm">PDF</a>
                                        <button class="btn btn-danger btn-sm cancelBtn"
                                                data-id="#order_group_id#">Cancel</button>
                                    <cfelseif status EQ "cancel_requested">
                                        <span class="badge bg-warning">Requested</span>
                                    <cfelse>
                                        <span class="badge bg-secondary">Cancelled</span>
                                    </cfif>
                                </div>
                            </div>

                            <div class="p-3 border-top cancelBox d-none" id="cancelBox_#order_group_id#">
                                <textarea class="form-control mb-2 cancelReason"
                                          data-id="#order_group_id#"
                                          placeholder="Enter cancel reason" rows="3"></textarea>
                                <div class="d-flex gap-2">
                                    <button class="btn btn-danger btn-sm confirmCancel"
                                            data-id="#order_group_id#">Confirm</button>
                                    <button class="btn btn-secondary btn-sm closeCancel"
                                            data-id="#order_group_id#">Close</button>
                                </div>
                            </div>

                            <div class="table-responsive">
                            <table class="table mb-0">
                                <thead>
                                    <tr><th>Product</th><th>Image</th><th>Price</th><th>Qty</th><th>Total</th></tr>
                                </thead>
                                <tbody>
                        <cfset tracker = order_group_id>
                    </cfif>

                    <tr>
                        <td>#product_name#</td>
                        <td>
                            <cfif len(image)>
                                <img src="../../assets/images/products/#image#"
                                     class="img-fluid" style="max-width:50px;">
                            <cfelse>No Image</cfif>
                        </td>
                        <td>#price#</td>
                        <td>#quantity#</td>
                        <td>#total_amount#</td>
                    </tr>
                    <cfset groupTotal += total_amount>

                    <cfif currentRow EQ recordCount>
                                <tr class="table-light">
                                    <td colspan="4" class="text-end"><strong>Total:</strong></td>
                                    <td><strong>#groupTotal#</strong></td>
                                </tr>
                                </tbody></table></div>
                        </div>
                    </cfif>

                </cfoutput>
            </cfif>
            </cfsavecontent>

            <!--- PAGINATION HTML --->
            <cfsavecontent variable="paginationHTML">
            <cfoutput>
            <cfif totalPages GT 1>
                <cfset var groupSize = 4>
                <cfset var pageGroup = ceiling(currentPage / groupSize)>
                <cfset var startPage = (pageGroup - 1) * groupSize + 1>
                <cfset var endPage   = min(startPage + groupSize - 1, totalPages)>
                <cfif startPage GT 1>
                    <button class="btn btn-outline-primary btn-sm pageBtn"
                            data-page="#startPage - 1#">Prev</button>
                </cfif>
                <cfloop from="#startPage#" to="#endPage#" index="i">
                    <button class="btn btn-sm pageBtn <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
                            data-page="#i#">#i#</button>
                </cfloop>
                <cfif endPage LT totalPages>
                    <button class="btn btn-outline-primary btn-sm pageBtn"
                            data-page="#endPage + 1#">Next</button>
                </cfif>
            </cfif>
            </cfoutput>
            </cfsavecontent>

            <cfset sendJSON({status:"success", message:"",  html:ordersHTML, pagination:paginationHTML})>

        <cfcatch>
            <cfset sendJSON({
                status:"error",
                message:"#cfcatch.message#",
                html:"",
                pagination:""
            })>
        </cfcatch>
        </cftry>
    </cffunction>

<!--- CANCEL ORDER REQUEST --->
<cffunction name="cancelOrder" access="remote" returntype="void" output="true" httpmethod="POST">
    <cfset createObject("component","models.AuthGuard").checkAuth()>

    <cfif NOT structKeyExists(form,"order_group_id") OR NOT len(trim(form.order_group_id))>
        <cfset sendJSON({status:"error", message:"Order ID required"})>
    </cfif>

    <cfif NOT structKeyExists(form,"reason") OR NOT len(trim(form.reason))>
        <cfset sendJSON({status:"error", message:"Reason required"})>
    </cfif>

    <cftry>
        <cfset var orderModel = createObject("component","models.Order")>
        <cfset var result     = orderModel.cancelOrder(
            order_group_id = form.order_group_id,
            reason         = form.reason,
            user_id        = session.user_id
        )>

        <cfif result>
            
            <!--- Send Notification to Vendor --->
            <cfset var productModel = createObject("component","models.Product")>
            <cfset var notifModel   = createObject("component","models.Notification")>

            <cfset var orderItems = orderModel.getOrderItems(form.order_group_id)>
            
            <cfif orderItems.recordCount GT 0>
                <cfset var vendorId = productModel.getVendorId(orderItems.product_id)>
                
                <cfif vendorId GT 0>
                    <cfset notifModel.create(
                        user_id   = vendorId,
                        sender_id = session.user_id,
                        type      = "cancel_request_vendor",
                        title     = "Cancel Request Received",
                        message   = "Customer requested to cancel Order #form.order_group_id#",
                        link      = "index.cfm?page=dashboard&section=allorders"
                    )>
                </cfif>
            </cfif>

            <cfset sendJSON({
                status: "success",
                message: "Cancellation request submitted successfully"
            })>

        <cfelse>
            <cfset sendJSON({status:"error", message:"Could not submit request"})>
        </cfif>

    <cfcatch>
        <cfset sendJSON({
            status: "error",
            message: "Error: #cfcatch.message#"
        })>
    </cfcatch>
    </cftry>
</cffunction>

</cfcomponent>