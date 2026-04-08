<cfset orderModel = createObject("component","models.Order")>
<cfparam name="url.search" default="">
<cfparam name="url.p" default="1">

<cfset searchValue = trim(url.search)>
<cfset currentPage = val(url.p) GT 0 ? val(url.p) : 1>
<cfset limit = 2>

<!--- Get Data --->
<cfset orders = orderModel.getAllOrdersWithPagination(search=searchValue, page=currentPage, limit=limit)>
<cfset totalRecords = orderModel.getOrderCount(search=searchValue)>
<cfset totalPages = ceiling(totalRecords / limit)>

<div class="container mt-4">
    <!--- Search Form: Note the empty action to submit to current page --->
    <cfoutput>
    <form method="get" action="" class="mb-3">
        <input type="hidden" name="page" value="dashboard">
        <input type="hidden" name="section" value="allorders">
        <div class="input-group w-50">
            <input type="text" name="search" value="#encodeForHTMLAttribute(searchValue)#" 
                   placeholder="Search Order ID or Username" class="form-control">
            <button type="submit" class="btn btn-primary">Search</button>
            <cfif len(searchValue)>
                <a href="?page=dashboard&section=allorders" class="btn btn-outline-secondary">Clear</a>
            </cfif>
        </div>
    </form>
    </cfoutput>

    <h3>All Orders</h3>

    <cfif orders.recordCount EQ 0>
        <div class="alert alert-info">No orders found matching your criteria.</div>
    <cfelse>
        <cfset currentGroup = "">
        <cfset gTotal = 0>

        <cfoutput query="orders">
            <!--- Grouping Header Logic --->
            <cfif currentGroup NEQ order_group_id>
                <cfif currentGroup NEQ "">
                    <tr class="table-secondary"><td colspan="4" class="text-end"><strong>Total:</strong></td><td><strong>#gTotal#</strong></td></tr>
                    </table></div>
                    <cfset gTotal = 0>
                </cfif>

                <div class="card mb-4 shadow">
                    <div class="card-header bg-dark text-white d-flex justify-content-between align-items-center">
                        <span><strong>Order: #order_group_id#</strong> | #dateFormat(created_at, "dd-mmm-yyyy")# | #user_name#</span>
                        <a href="../../assets/invoices/invoice_#order_group_id#.pdf" target="_blank" class="btn btn-success btn-sm">PDF</a>
                    </div>
                    <table class="table mb-0">
                        <tr><th>Product</th><th>Image</th><th>Price</th><th>Qty</th><th>Total</th></tr>
                <cfset currentGroup = order_group_id>
            </cfif>

            <tr>
                <td>#product_name#</td>
                <td><img src="../../assets/images/products/#image#" width="40" onerror="this.src='https://placehold.co'"></td>
                <td>#price#</td>
                <td>#quantity#</td>
                <td>#total_amount#</td>
            </tr>
            <cfset gTotal += total_amount>

            <!--- Final Group Footer --->
            <cfif currentRow EQ recordCount>
                <tr class="table-secondary"><td colspan="4" class="text-end"><strong>Total:</strong></td><td><strong>#gTotal#</strong></td></tr>
                </table></div>
            </cfif>
        </cfoutput>

        <!--- Pagination Links --->
        <nav class="mt-4">
            <ul class="pagination">
                <cfoutput>
                <cfloop from="1" to="#totalPages#" index="i">
                    <li class="page-item # (i eq currentPage) ? 'active' : '' #">
                        <a class="page-link" href="?page=dashboard&section=allorders&p=#i#&search=#urlEncodedFormat(searchValue)#">#i#</a>
                    </li>
                </cfloop>
                </cfoutput>
            </ul>
        </nav>
    </cfif>
</div>
