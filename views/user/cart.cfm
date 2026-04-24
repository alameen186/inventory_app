<cfset couponModel = createObject("component","models.Coupon")>
<cfset coupons = couponModel.getActiveCoupons()>

<!-- ALERT -->
<cfif structKeyExists(url, "message")>
<div id="alertBox" class="alert 
<cfif structKeyExists(url, "type") AND url.type EQ 'success'>
alert-success
<cfelse>
alert-danger
</cfif> text-center">
<cfoutput>#url.message#</cfoutput>
</div>
</cfif>

<script>
setTimeout(()=>$("#alertBox").fadeOut(),4000);
</script>

<!-- EMPTY -->
<cfif NOT structKeyExists(session, "cart") OR structIsEmpty(session.cart)>
    <div class="text-center mt-4">
        <h4>Your cart is empty</h4>
        <a href="../../index.cfm?page=dashboard&section=productList"
           class="btn btn-primary mt-2">
           Continue Shopping
        </a>
    </div>
    <cfreturn>
</cfif>

<div id="ajaxMessage"></div>

<!--  DESKTOP TABLE  -->
<div class="d-none d-md-block">
<div class="table-responsive">
<table class="table table-bordered align-middle text-center">

<thead class="table-dark">
<tr>
<th>Product</th>
<th>Price</th>
<th>Qty</th>
<th>Image</th>
<th>Total</th>
<th>Action</th>
</tr>
</thead>

<tbody>
<cfset grandTotal = 0>

<cfoutput>
<cfloop collection="#session.cart#" item="pid">

<tr id="row_#pid#" data-price="#session.cart[pid].price#">

<td class="text-start">#session.cart[pid].name#</td>
<td>#session.cart[pid].price#</td>

<td>
<form class="updateCartForm d-flex gap-2 justify-content-center">
<input type="hidden" name="action" value="update">
<input type="hidden" name="product_id" value="#pid#">

<input type="number" name="qty" max="3" min="1"
class="form-control form-control-sm"
style="max-width:80px;"
value="#session.cart[pid].qty#">

<button class="btn btn-primary btn-sm">Update</button>
</form>
</td>

<td>
<img src="../../assets/images/products/#session.cart[pid].image#"
class="img-fluid rounded" style="max-width:60px;">
</td>

<td class="rowTotal">
<cfset total = session.cart[pid].price * session.cart[pid].qty>
#total#
</td>

<td>
<button class="btn btn-danger btn-sm removeBtn" data-id="#pid#">Remove</button>
</td>

</tr>

<cfset grandTotal += total>
</cfloop>
</cfoutput>

</tbody>
</table>
</div>
</div>

<!--  MOBILE CARDS  -->
<div class="d-md-none">

<cfset grandTotal = 0>

<cfoutput>
<cfloop collection="#session.cart#" item="pid">

<cfset item = session.cart[pid]>
<cfset total = item.price * item.qty>
<cfset grandTotal += total>

<div class="card mb-3 shadow-sm" id="row_#pid#" data-price="#item.price#">

<div class="card-body">

<div class="d-flex gap-3">
<img src="../../assets/images/products/#item.image#"
class="rounded" style="width:70px;height:70px;object-fit:cover;">

<div class="flex-grow-1">
<h6 class="mb-1">#item.name#</h6>
<small>Price: #item.price#</small><br>
<strong class="rowTotal">Total: #total#</strong>
</div>
</div>

<form class="updateCartForm mt-2 d-flex gap-2">
<input type="hidden" name="action" value="update">
<input type="hidden" name="product_id" value="#pid#">

<input type="number" name="qty"
class="form-control form-control-sm"
value="#item.qty#">

<button class="btn btn-primary btn-sm">Update</button>
</form>

<button class="btn btn-danger btn-sm w-100 mt-2 removeBtn" data-id="#pid#">
Remove
</button>

</div>
</div>

</cfloop>
</cfoutput>

</div>

<!--  COUPON  -->
<div class="card mt-4 shadow-sm">
<div class="card-body">

<h6>Apply Coupon</h6>

<form id="couponForm" class="row g-2">

<input type="hidden" name="action" value="applyCoupon">

<div class="col-12">
<select name="coupon_code" class="form-select">
<option value="">Select Coupon</option>

<cfoutput query="coupons">
<option value="#code#">
#code# - 
<cfif discount_type EQ "percent">
#discount_value#% OFF
<cfelse>
Rs:#discount_value# OFF
</cfif>
</option>
</cfoutput>

</select>
</div>

<div class="col-12 d-grid">
<button class="btn btn-outline-primary">Apply Coupon</button>
</div>

</form>

</div>
</div>

<!--  TOTAL / CHECKOUT  -->
<cfset discount = 0>
<cfif structKeyExists(session, "coupon")>
<cfif session.coupon.type EQ "percent">
<cfset discount = (grandTotal * session.coupon.value) / 100>
<cfelse>
<cfset discount = session.coupon.value>
</cfif>
</cfif>

<cfset finalTotal = grandTotal - discount>

<div class="card mt-4 shadow">

<div class="card-body">

<cfoutput>
<div class="d-flex justify-content-between">
<span>Total</span>
<strong id="grandTotal">#grandTotal#</strong>
</div>

<div class="d-flex justify-content-between">
<span>Discount</span>
<strong id="discount">#discount#</strong>
</div>

<hr>

<div class="d-flex justify-content-between fs-5">
<strong>Final</strong>
<strong id="finalTotal">#finalTotal#</strong>
</div>
</cfoutput>

<button class="btn btn-success w-100 mt-3 py-2" id="checkoutBtn">
Proceed to Checkout
</button>

</div>
</div>

<script>
$(function(){

let coupon={type:null,value:0,max:0};
const CART_CTRL = "../../controllers/CartController.cfc";

function showMsg(res){
$("#ajaxMessage").html(
`<div class="alert alert-${res.status==="success"?"success":"danger"}">
${res.message}</div>`
);
 setTimeout(function(){ $("#ajaxMessage").fadeOut(); }, 3000);
}

// UPDATE UI
function updateUI(){
let grandTotal=0;

$("[id^='row_']").each(function(){
let price=parseFloat($(this).data("price"));
let qty=parseInt($(this).find("input[name=qty]").val());

let total=price*qty;
$(this).find(".rowTotal").text(total);

grandTotal+=total;
});

let discount=0;

if(coupon.type==="percent"){
discount=(grandTotal*coupon.value)/100;
}else if(coupon.type==="flat"){
discount=coupon.value;
}

if(discount>coupon.max) discount=coupon.max;

let finalTotal=grandTotal-discount;

$("#grandTotal").text(grandTotal);
$("#discount").text(discount);
$("#finalTotal").text(finalTotal);
}

// UPDATE
$(document).on("submit",".updateCartForm",function(e){
e.preventDefault();

$.post(CART_CTRL+"?method=update",
$(this).serialize(),
function(res){
showMsg(res);
location.reload();
updateUI();
},"json");

});

// REMOVE
$(document).on("click",".removeBtn",function(){
let id=$(this).data("id");

$.get(CART_CTRL+"?method=remove",
{id:id},
function(res){
showMsg(res);
 location.reload();
$("#row_"+id).remove();
updateUI();
},"json");
});

// COUPON
$("#couponForm").submit(function(e){
e.preventDefault();

$.post(CART_CTRL+"?method=applyCoupon",
$(this).serialize(),
function(res){
showMsg(res);
 location.reload();

if(res.status==="success"){
coupon.type=res.type;
coupon.value=parseFloat(res.value);
coupon.max=parseFloat(res.max);
updateUI();
}
},"json");
});

// CHECKOUT (unchanged)
$("#checkoutBtn").click(function(){
$.post("../../controllers/OrderController.cfm",{action:"checkout"},
function(res){
if(res.status==="success"){
alert(res.message);
window.location.href="../../index.cfm?page=dashboard&section=orders";
}else{
alert(res.message);
}
},"json");
});

});
</script>