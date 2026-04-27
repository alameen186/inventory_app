<cfif NOT structKeyExists(session, "user_id")>
    <cfabort>
</cfif>

<cfset userModel    = createObject("component","models.User")>
<cfset productModel = createObject("component","models.Product")>
<cfset couponModel  = createObject("component","models.Coupon")>

<cfset users    = userModel.getAllUsersSimple()>
<cfset products = productModel.getAllProductsSimple()>
<cfset coupons  = couponModel.getActiveCoupons()>

<div class="container mt-4">
<h3>Create Order</h3>

<div id="ajaxMessage"></div>

<form id="createOrderForm">
    <div class="mb-3">
        <label class="form-label">User</label>
        <select name="user_id" class="form-control" required>
            <option value="">Select User</option>
            <cfoutput query="users">
            <option value="#id#">#first_name# #last_name#</option>
            </cfoutput>
        </select>
    </div>

    <div class="mb-3">
        <label class="form-label">Product</label>
        <select name="product_id" class="form-control" required>
            <option value="">Select Product</option>
            <cfoutput query="products">
            <option value="#id#">
                #product_name# - Rs:#price# (Stock: #stock#)
            </option>
            </cfoutput>
        </select>
    </div>

    <div class="mb-3">
        <label class="form-label">Quantity</label>
        <input type="number" name="qty" min="1" max="3" class="form-control" required>
    </div>

    <div class="mb-3">
        <label class="form-label">Coupon</label>
        <select name="coupon_id" class="form-control">
            <option value="">No Coupon</option>
            <cfoutput query="coupons">
            <option value="#code#">
                #code# -
                <cfif discount_type EQ "percent">
                    #discount_value#% OFF
                <cfelse>
                    Rs:#discount_value# OFF
                </cfif>
                (Min: #min_amount#)
            </option>
            </cfoutput>
        </select>
    </div>

    <button type="submit" class="btn btn-success">Place Order</button>
</form>

</div>

<script>
$(function(){

    var CTRL = "../../controllers/AdminCreateOrderController.cfc";

    function showMsg(res){
        $("#ajaxMessage").html(
            '<div class="alert alert-'+(res.status==="success"?"success":"danger")+'">'+
            (res.message||"")+'</div>'
        );
        setTimeout(()=>$("#ajaxMessage").html(""), 5000);
    }

    $("#createOrderForm").submit(function(e){
        e.preventDefault();
        $.ajax({
            url      : CTRL + "?method=createOrder",
            type     : "POST",
            data     : $(this).serialize(),
            dataType : "json",
            success  : function(res){
                showMsg(res);
                if(res.status === "success"){
                    $("#createOrderForm")[0].reset();
                }
            },
            error : function(xhr){
    console.log("Order error:", xhr.responseText);
    console.log("Status:", xhr.status);
    console.log("Status Text:", xhr.statusText);
}
        });
    });

});
</script>