<cfcomponent output="false">

    <cffunction name="sendJSON" access="private" returntype="void" output="true">
        <cfargument name="data" type="struct" required="true">
        <cfcontent type="application/json; charset=utf-8" reset="true">
        <cfset var map = createObject("java","java.util.LinkedHashMap").init()>
        <cfloop collection="#arguments.data#" item="k">
            <cfset map[lcase(k)] = arguments.data[k]>
        </cfloop>
        <cfoutput>#serializeJSON(map)#</cfoutput>
        <cfabort>
    </cffunction>

    <cffunction name="requireAuth" access="private" returntype="void" output="false">
        <cfif NOT structKeyExists(session,"user_id")>
            <cfset sendJSON({status:"error", message:"Unauthorized", html:"", pagination:""})>
        </cfif>
    </cffunction>

    <cffunction name="getVendorFilter" access="private" returntype="string" output="false">
        <cfif structKeyExists(session,"role_name") AND session.role_name EQ "vendor">
            <cfreturn session.user_id>
        </cfif>
        <cfreturn "">
    </cffunction>

    <!--- SEARCH ORDERS --->
    <cffunction name="searchOrders" access="remote" returntype="void" output="true" httpmethod="GET">
        <cfset requireAuth()>
        <cftry>
            <cfset var orderModel   = createObject("component","models.Order")>
            <cfset var vendorFilter = getVendorFilter()>
            <cfset var srch         = structKeyExists(url,"search")   ? trim(url.search)   : "">
            <cfset var fromDate     = structKeyExists(url,"fromDate") ? url.fromDate        : "">
            <cfset var toDate       = structKeyExists(url,"toDate")   ? url.toDate          : "">
            <cfset var currentPage  = structKeyExists(url,"p") AND val(url.p) GT 0 ? val(url.p) : 1>
            <cfset var limit        = 4>

            <cfset var orders = orderModel.getAllOrdersWithPagination(
                search    = srch,
                page      = currentPage,
                limit     = limit,
                vendor_id = vendorFilter,
                fromDate  = fromDate,
                toDate    = toDate
            )>
            <cfset var totalRecords = orderModel.getOrderCount(
                search    = srch,
                vendor_id = vendorFilter,
                fromDate  = fromDate,
                toDate    = toDate
            )>
            <cfset var totalPages = ceiling(totalRecords / limit)>

            <!--- ORDER HTML --->
            <cfsavecontent variable="ordersHTML">
            <cfif orders.recordCount EQ 0>
                <div class="alert alert-info">No orders found.</div>
            <cfelse>
                <cfset var currentGroup = "">
                <cfset var gTotal       = 0>
                <cfoutput query="orders">

                    <cfif currentGroup NEQ order_group_id>
                        <cfif currentGroup NEQ "">
                            <tr class="table-secondary">
                                <td colspan="4" class="text-end"><strong>Total:</strong></td>
                                <td><strong>#gTotal#</strong></td>
                            </tr>
                            </tbody></table></div>
                            <div class="card-footer text-end">
                                <strong>Order Total: #gTotal#</strong>
                            </div>
                            </div>
                            <cfset gTotal = 0>
                        </cfif>

                        <div class="card mb-4 shadow">
                            <div class="card-header bg-dark text-white">
                                <div class="d-flex flex-column flex-sm-row justify-content-between align-items-start align-items-sm-center gap-2">
                                    <span style="font-size:.9rem;">
                                        <strong>Order: #order_group_id#</strong>
                                        <span class="ms-sm-2">#dateFormat(created_at,"dd-mmm-yyyy")#</span>
                                        | <span>#user_name#</span>
                                    </span>
                                    <div class="d-flex align-items-center gap-2 flex-wrap">
                                        <a href="../../assets/invoices/invoice_#order_group_id#.pdf"
                                           target="_blank" class="btn btn-success btn-sm">PDF</a>
                                        <cfif status EQ "cancel_requested">
                                            <span class="badge bg-warning text-dark">Cancel Requested</span>
                                        <cfelseif status EQ "cancelled">
                                            <span class="badge bg-secondary">Cancelled</span>
                                        <cfelse>
                                            <span class="badge bg-success">Active</span>
                                        </cfif>
                                    </div>
                                </div>
                            </div>

                            <cfif status EQ "cancel_requested">
                            <div class="p-3 border-top bg-light">
                                <p><strong>Cancel Reason:</strong></p>
                                <div class="alert alert-warning">#cancel_reason#</div>
                                <button class="approveBtn btn btn-success btn-sm"
                                        data-id="#order_group_id#">Approve Cancel</button>
                            </div>
                            </cfif>

                            <div class="table-responsive">
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
                            <img src="../../assets/images/products/#image#"
                                 width="40" style="height:40px;object-fit:cover;"
                                 onerror="this.src='https://placehold.co/40'">
                        </td>
                        <td>#price#</td>
                        <td>#quantity#</td>
                        <td>#total_amount#</td>
                    </tr>
                    <cfset gTotal += total_amount>

                    <cfif currentRow EQ recordCount>
                                </tbody></table></div>
                            <div class="card-footer text-end">
                                <strong>Order Total: #gTotal#</strong>
                            </div>
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
                            data-page="#startPage - 1#">&laquo; Prev</button>
                </cfif>
                <cfloop from="#startPage#" to="#endPage#" index="i">
                    <button class="btn btn-sm pageBtn <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
                            data-page="#i#">#i#</button>
                </cfloop>
                <cfif endPage LT totalPages>
                    <button class="btn btn-outline-primary btn-sm pageBtn"
                            data-page="#endPage + 1#">Next &raquo;</button>
                </cfif>
            </cfif>
            </cfoutput>
            </cfsavecontent>

            <cfset sendJSON({status:"success", html:ordersHTML, pagination:paginationHTML})>

        <cfcatch>
            <cfset sendJSON({status:"error", message:"#cfcatch.message#", html:"", pagination:""})>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- APPROVE CANCEL --->
    <cffunction name="approveCancel" access="remote" returntype="void" output="true" httpmethod="POST">
        <cfset requireAuth()>
        <cfif NOT structKeyExists(form,"order_group_id") OR NOT len(trim(form.order_group_id))>
            <cfset sendJSON({status:"error", message:"Order ID required", html:"", pagination:""})>
        </cfif>
        <cftry>
            <cfset var orderModel = createObject("component","models.Order")>
            <cfset var result     = orderModel.approveCancel(order_group_id=form.order_group_id)>
            <cfif result>
                <cfset orderModel.restoreStock(order_group_id=form.order_group_id)>
                <cfset sendJSON({status:"success", message:"Order cancelled and stock restored", html:"", pagination:""})>
            <cfelse>
                <cfset sendJSON({status:"error", message:"Could not approve cancellation", html:"", pagination:""})>
            </cfif>
        <cfcatch>
            <cfset sendJSON({status:"error", message:"#cfcatch.message#", html:"", pagination:""})>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>