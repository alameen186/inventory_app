<cfset couponModel = createObject("component","models.Coupon")>
<cfset coupons = couponModel.getActiveCoupons()>

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

<div id="ajaxMessage"></div>

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

<tr id="row_#pid#" data-price="#session.cart[pid].price#">
    <td>#session.cart[pid].name#</td>
    <td>#session.cart[pid].price#</td>

    <td>
        <form class="updateCartForm mb-3" method="post" >
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

    <td class="rowTotal">
        <cfset total = session.cart[pid].price * session.cart[pid].qty>
        #total#
    </td>

    <td>
        <button class="btn btn-danger btn-sm removeBtn" data-id="#pid#">
Remove
</button>
    </td>
</tr>

<cfset grandTotal += total>

</cfloop>
</cfoutput>

</table>

<!-- coupon apply -->
<h5>Apply Coupon</h5>

<form method="post"  id="couponForm" class="mb-3">

    <input type="hidden" name="action" value="applyCoupon">

    <select name="coupon_code" class="form-control mb-2" required>
        <option value="">Select Coupon</option>

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

    <button class="btn btn-primary btn-sm">Apply</button>
</form>

<!-- discount calc -->
<cfset discount = 0>

<cfif structKeyExists(session, "coupon")>

    <cfif session.coupon.type EQ "percent">
        <cfset discount = (grandTotal * session.coupon.value) / 100>
    <cfelse>
        <cfset discount = session.coupon.value>
    </cfif>

    <cfif discount GT session.coupon.max>
        <cfset discount = session.coupon.max>
    </cfif>

</cfif>

<cfset finalTotal = grandTotal - discount>

<div class="d-flex justify-content-between align-items-center mt-4 border-top pt-3">
    <cfoutput>
        <div>
            <h5>Total: <span id="grandTotal">#grandTotal#</span></h5>
            <h5>Discount: <span id="discount">#discount#</span></h5>
            <h4>Final: <strong id="finalTotal">#finalTotal#</strong></h4>
        </div>
    </cfoutput>

    <button class="btn btn-success btn-lg" id="checkoutBtn">
    Checkout
</button>
</div>

<script>
$(document).ready(function(){

let coupon = {
    type: null,
    value: 0,
    max: 0
};

function showMsg(res){
    $("#ajaxMessage").html(
    '<div id="msgBox" class="alert alert-' +
    (res.status==="success"?"success":"danger") +
    '">' + res.message + '</div>'
    );
    setTimeout(()=>$("#msgBox").fadeOut(),3000);
}


// CORE FUNCTION
function updateUI(){

    let grandTotal = 0;

    $("tr[id^='row_']").each(function(){

        let row = $(this);
        let price = parseFloat(row.data("price"));
        let qty = parseInt(row.find("input[name=qty]").val());

        let total = price * qty;

        row.find(".rowTotal").text(total);

        grandTotal += total;
    });

    // APPLY COUPON
    let discount = 0;

    if(coupon.type === "percent"){
        discount = (grandTotal * coupon.value) / 100;
    } else if(coupon.type === "flat"){
        discount = coupon.value;
    }

    if(discount > coupon.max){
        discount = coupon.max;
    }

    let finalTotal = grandTotal - discount;

    $("#grandTotal").text(grandTotal);
    $("#discount").text(discount);
    $("#finalTotal").text(finalTotal);
}


// UPDATE QTY
$(document).on("submit",".updateCartForm",function(e){
    e.preventDefault();

    let form = $(this);

    $.post("../../controllers/CartController.cfm",
    form.serialize(),
    function(res){

        showMsg(res);

        updateUI();

    },"json");
});


// REMOVE ITEM
$(document).on("click",".removeBtn",function(){

    let btn = $(this);
    let id = btn.data("id");

    $.get("../../controllers/CartController.cfm",{
        action:"remove",
        id:id
    },function(res){

        showMsg(res);

        // REMOVE ROW FROM DOM
        $("#row_"+id).remove();

        updateUI();

    },"json");

});


//APPLY COUPON
$("#couponForm").submit(function(e){
    e.preventDefault();

    $.post("../../controllers/CartController.cfm",
    $(this).serialize(),
    function(res){

        showMsg(res);

        if(res.status === "success"){

            coupon.type = res.type;
            coupon.value = parseFloat(res.value);
            coupon.max = parseFloat(res.max);

            updateUI(); // 🔥 IMPORTANT
        }

    },"json");
});

$("#checkoutBtn").click(function(){

    $.post("../../controllers/OrderController.cfm",{
        action: "checkout"
    }, function(res){

        if(res.status === "success"){
            alert(res.message);
            window.location.href = "../../index.cfm?page=dashboard&section=orders";
        }else{
            alert(res.message);
        }

    },"json")

    .fail(function(xhr){
        console.log("FULL ERROR:", xhr.responseText);
        alert("Server crashed. Check console.");
    });

});

});
</script>