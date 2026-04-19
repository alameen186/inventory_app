<cfset userModel = createObject("component","models.User")>
<cfset productModel = createObject("component","models.Product")>

<cfset users = userModel.getAllUsersSimple()>
<cfset products = productModel.getAllProductsSimple()>

<cfset couponModel = createObject("component","models.Coupon")>
<cfset coupons = couponModel.getActiveCoupons()>

<cfparam name="url.showForm" default="0">

<div class="container mt-4">
<h3>Create Order</h3>
<cfif structKeyExists(url, "message") AND url.showForm NEQ "1">
    <div id="alertBox" class="alert 
        <cfif structKeyExists(url, "type") AND url.type EQ "success">
            alert-success
        <cfelse>
            alert-danger
        </cfif>">
        <cfoutput>#url.message#</cfoutput>
    </div>
</cfif>
<div id="ajaxMessage"></div>
<form id="createOrderForm" method="post" >

<input type="hidden" name="action" value="createAdminOrder">

<label>User</label>
<select name="user_id" class="form-control mb-3" required>
<option value="">Select User</option>
<cfoutput query="users">
<option value="#id#">#first_name# #last_name#</option>
</cfoutput>
</select>

<label>Product</label>
<select name="product_id" class="form-control mb-3" required>
<option value="">Select Product</option>
<cfoutput query="products">
<option value="#id#">
#product_name# - rs:#price# (Stock: #stock#)
</option>
</cfoutput>
</select>

<label>Quantity</label>
<input type="number" name="qty" min="1" class="form-control mb-3" required>

<label>Coupon</label>
<select name="coupon_id" class="form-control mb-3">
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

<button class="btn btn-success">Place Order</button>

</form>
</div>

<script>
$(document).ready(function(){

$("#createOrderForm").submit(function(e){
    e.preventDefault();

    $.post("../../controllers/AdminOrderController.cfm",
        $(this).serialize(),
        function(res){

            $("#ajaxMessage").html(
                '<div id="msgBox" class="alert alert-' +
                (res.status === "success" ? "success" : "danger") +
                '">' + res.message + '</div>'
            );

            setTimeout(function(){
                $("#msgBox").fadeOut();
            }, 5000);

            if(res.status === "success"){
                $("#createOrderForm")[0].reset();
            }

        },
        "json"
    );
});

});
</script>