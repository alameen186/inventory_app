<cfif NOT structKeyExists(session, "user_id")>
    <cfabort>
</cfif>

<cfset orderModel = createObject("component","models.Order")>
<cfset orders = orderModel.getUserOrders(session.user_id)>

<cfif orders.recordCount EQ 0>
    <h4>No orders found</h4>
    <cfabort>
</cfif>

<div class="container mt-4">
    <h3>Your Orders</h3>

<cfset currentGroup = "">
<cfset gTotal = 0> 

<cfoutput query="orders">

    <!-- NEW ORDER CARD -->
    <cfif currentGroup NEQ order_group_id>

        <!-- CLOSE PREVIOUS -->
        <cfif currentGroup NEQ "">
            <tr class="table-secondary">
                <td colspan="4" class="text-end"><strong>Order Total:</strong></td>
                <td><strong>#gTotal#</strong></td>
            </tr>
            </table>
            </div>
            <cfset gTotal = 0>
        </cfif>

        <!-- CARD START -->
        <div class="card mb-4">

            <!-- HEADER WITH DOWNLOAD BUTTON -->
            <div class="card-header bg-dark text-white d-flex justify-content-between align-items-center">

                <span>
                    Order ID: #order_group_id#
                    | Date: #dateFormat(created_at, "dd-mmm-yyyy")#
                </span>

                <a href="../../assets/invoices/invoice_#order_group_id#.pdf" 
                   target="_blank"
                   class="btn btn-success btn-sm">
                    Download PDF
                </a>

            </div>

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
            <td colspan="4" class="text-end"><strong>Order Total:</strong></td>
            <td><strong>#gTotal#</strong></td>
        </tr>
        </table>
        </div>
    </cfif>

</cfoutput>

</div>