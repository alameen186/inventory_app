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

    <!-- new card  -->
    <cfif currentGroup NEQ order_group_id>

        <cfif currentGroup NEQ "">
           
            <tr class="table-secondary">
                <td colspan="4" class="text-end"><strong>Order Total:</strong></td>
                <td><strong>#gTotal#</strong></td>
            </tr>
            </table>
            </div>
            <cfset gTotal = 0>
        </cfif>

        <div class="card mb-4">
            <div class="card-header bg-dark text-white">
                Order ID: #order_group_id#
                <span class="float-end">Date: #dateFormat(created_at, "dd-mmm-yyyy")#</span>
            </div>

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

    <!--- order total --->
    <cfif currentRow EQ recordCount>
        <tr class="table-secondary">
            <td colspan="4" class="text-end"><strong>Order Total:</strong></td>
            <td><strong>#gTotal#</strong></td>
        </tr>
    </cfif>
</cfoutput>

</table>
</div>
</div>