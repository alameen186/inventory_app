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

    <cffunction name="requireAuth" access="private" returntype="void" output="false">
        <cfif NOT structKeyExists(session,"user_id")>
            <cfset sendJSON({
                status:"error",
                message:"Unauthorized",
                html:"",
                pagination:""
            })>
        </cfif>
    </cffunction>

    <!--- SEARCH ORDERS --->
    <cffunction name="searchOrders" access="remote" returntype="void" output="true" httpmethod="GET">
        <cfset requireAuth()>
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

    <!--- CANCEL ORDER --->
    <cffunction name="cancelOrder" access="remote" returntype="void" output="true" httpmethod="POST">
        <cfset requireAuth()>
        <cfif NOT structKeyExists(form,"order_group_id") OR NOT len(trim(form.order_group_id))>
            <cfset sendJSON({status:"error", message:"Order ID required",html:"",pagination:""})>
        </cfif>
        <cfif NOT structKeyExists(form,"reason") OR NOT len(trim(form.reason))>
            <cfset sendJSON({status:"error", message:"Reason required",html:"",pagination:""})>
        </cfif>
        <cftry>
            <cfset var orderModel = createObject("component","models.Order")>
            <cfset var result     = orderModel.cancelOrder(
                order_group_id = form.order_group_id,
                reason         = form.reason,
                user_id        = session.user_id
            )>
            <cfif result>
                <cfset sendJSON({
                    status:"success",
                    message:"Cancellation request submitted",
                    html:"",
                    pagination:""
                })>
            <cfelse>
                <cfset sendJSON({status:"error", message:"Could not submit request",html:"", pagination:""})>
            </cfif>
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

</cfcomponent>