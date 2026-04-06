           <cfif structKeyExists(url, "message")>
                <div id="alertBox" class="alert 
                <cfif structKeyExists(url, "type") AND url.type EQ 'success'>
                     alert-success
                <cfelse>
                     alert-danger
                </cfif>">
                     <cfoutput>#url.message#</cfoutput> 
                </div>
           </cfif>
           <script>
    setTimeout(function () {
        var alertBox = document.getElementById("alertBox");
        if (alertBox) {
            alertBox.style.display = "none";
        }
    }, 5000);   
</script>

<cfif NOT structKeyExists(session, "cart") OR structIsEmpty(session.cart)>
    <h4>Your cart is empty</h4>
    <cfabort>
</cfif>

<table class="table">
    <tr>
        <th>Product</th>
        <th>Price</th>
        <th>Qty</th>
        <th>Image</th>
        <th>Total</th>
        <th>Action</th>
    </tr>

<cfset grandTotal = 0>

<cfoutput>
<cfloop collection="#session.cart#" item="pid">

<tr>
    <td>#session.cart[pid].name#</td>
    <td>#session.cart[pid].price#</td>

    <td>
        <form method="post" action="../../controllers/CartController.cfm">
            <input type="hidden" name="action" value="update">
            <input type="hidden" name="product_id" value="#pid#">

            <input type="number" name="qty" value="#session.cart[pid].qty#" min="1" max="3">

            <button class="btn btn-sm btn-primary">Update</button>
        </form>
    </td>

    <td>
        <cfif len(session.cart[pid].image)>
                    <img src="../../assets/images/products/#session.cart[pid].image#" 
                         class="img-thumbnail" 
                         style="width: 60px; height: 60px; object-fit: cover;">
        </cfif>
    </td>
    <td>
        <cfset total = session.cart[pid].price * session.cart[pid].qty>
        #total#
    </td>

    <td>
        <a href="../../controllers/CartController.cfm?action=remove&id=#pid#" 
           class="btn btn-danger btn-sm">Remove</a>
    </td>
</tr>

<cfset grandTotal += total>

</cfloop>
</cfoutput>

</table>
<div class="d-flex justify-content-between align-items-center mt-4 border-top pt-3">
    <cfoutput>
        <h4 class="mb-0">Total: <strong>#grandTotal#</strong></h4>
    </cfoutput>

    <form method="post" action="../../controllers/OrderController.cfm" class="mb-0">
        <input type="hidden" name="action" value="checkout">
        <button class="btn btn-success btn-lg">Checkout</button>
    </form>
</div>
