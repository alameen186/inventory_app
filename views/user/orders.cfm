<!-- check login -->
<cfif NOT structKeyExists(session, "user_id")>
    <cfabort>
</cfif>

<cfset orderModel = createObject("component","models.Order")>

<!-- params -->
<cfparam name="url.search" default="">
<cfparam name="url.p" default="1">
<cfparam name="url.cancelId" default="">

<cfset searchValue = trim(url.search)>
<cfset currentPage = val(url.p)>
<cfif currentPage LT 1>
    <cfset currentPage = 1>
</cfif>

<cfset limit = 2>

<!-- fetch orders -->
<cfset orders = orderModel.getUserOrdersWithPagination(
    user_id = session.user_id,
    search = searchValue,
    page = currentPage,
    limit = limit
)>

<!-- count -->
<cfset totalRecords = orderModel.getUserOrderCount(
    user_id = session.user_id,
    search = searchValue
)>

<cfset totalPages = ceiling(totalRecords / limit)>

<div class="container mt-4">

<!-- SEARCH -->
<cfoutput>
<form method="get" action="" class="mb-3">
    <input type="hidden" name="page" value="dashboard">
    <input type="hidden" name="section" value="orders">

    <div class="input-group w-50">
        <input type="text" name="search" value="#encodeForHTMLAttribute(searchValue)#"
               placeholder="Search Order ID" class="form-control">

        <button class="btn btn-primary">Search</button>

        <cfif len(searchValue)>
            <a href="?page=dashboard&section=orders" class="btn btn-secondary">Clear</a>
        </cfif>
    </div>
</form>
</cfoutput>

<h3>Your Orders</h3>

<cfif orders.recordCount EQ 0>
    <div class="alert alert-info">No orders found</div>
<cfelse>

<cfset currentGroup = "">
<cfset gTotal = 0>

<cfoutput query="orders">

    <!-- NEW ORDER CARD -->
    <cfif currentGroup NEQ order_group_id>

        <!-- CLOSE PREVIOUS -->
        <cfif currentGroup NEQ "">
            <tr class="table-secondary">
                <td colspan="4" class="text-end"><strong>Total:</strong></td>
                <td><strong>#gTotal#</strong></td>
            </tr>
            </table>
            </div>
            <cfset gTotal = 0>
        </cfif>

        <div class="card mb-4">

            <!-- HEADER -->
            <div class="card-header bg-dark text-white d-flex justify-content-between align-items-center">

                <span>
                    Order ID: #order_group_id# |
                    #dateFormat(created_at, "dd-mmm-yyyy")#
                </span>

                <div>
                 <cfif status EQ "placed">
                    <a href="../../assets/invoices/invoice_#order_group_id#.pdf"
                       target="_blank"
                       class="btn btn-success btn-sm">
                        PDF
                    </a>
               </cfif>


                    <!-- CANCEL BUTTON -->
                    <cfif status EQ "placed">
                        <a href="?page=dashboard&section=orders&cancelId=#order_group_id#&p=#currentPage#&search=#urlEncodedFormat(searchValue)#"
                           class="btn btn-danger btn-sm">
                           Cancel
                    </a>

                    <cfelseif status EQ "cancel_requested">
                        <span class="badge bg-warning">Cancel Requested</span>

                    <cfelse>
                        <span class="badge bg-secondary">Cancelled</span>
                    </cfif>
                </div>

            </div>

            <!-- cancel form -->
            <cfif url.cancelId EQ order_group_id AND status EQ "placed">
                <div class="p-3 border-top">

                    <form method="post" action="../../controllers/OrderController.cfm">

                        <input type="hidden" name="action" value="cancel">
                        <input type="hidden" name="order_group_id" value="#order_group_id#">

                        <textarea name="reason" class="form-control mb-2"
                                  placeholder="Enter cancel reason" required></textarea>

                        <button class="btn btn-danger btn-sm">Confirm Cancel</button>

                        <a href="?page=dashboard&section=orders"
                           class="btn btn-secondary btn-sm">Close</a>

                    </form>

                </div>
            </cfif>

            <!-- TABLE -->
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

    <!-- ORDER ITEMS -->
    <tr>
        <td>#product_name#</td>

        <td>
            <cfif len(image)>
                <img src="../../assets/images/products/#image#" width="50">
            <cfelse>
                No Image
            </cfif>
        </td>

        <td>#price#</td>
        <td>#quantity#</td>
        <td>#total_amount#</td>
    </tr>

    <cfset gTotal += total_amount>

    <!-- LAST ROW -->
    <cfif currentRow EQ recordCount>
        <tr class="table-secondary">
            <td colspan="4" class="text-end"><strong>Total:</strong></td>
            <td><strong>#gTotal#</strong></td>
        </tr>
        </table>
        </div>
    </cfif>

</cfoutput>

</cfif>

<!-- PAGINATION -->
<cfoutput>
<div class="mt-4">

<cfloop from="1" to="#totalPages#" index="i">
    <a href="?page=dashboard&section=orders&p=#i#&search=#urlEncodedFormat(searchValue)#"
       class="btn btn-sm <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>">
        #i#
    </a>
</cfloop>

</div>
</cfoutput>

</div>