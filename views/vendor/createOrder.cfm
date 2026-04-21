<cfset productModel = createObject("component","models.Product")>
<cfset tempUserModel = createObject("component","models.TempUser")>

<cfset tempUsers = tempUserModel.getRecentTempUsers(
    vendor_id = session.user_id
)>
<!-- GET VENDOR PRODUCTS ONLY -->
<cfquery name="products" datasource="#application.dsn#">
    SELECT id, product_name, price, stock
    FROM products
    WHERE vendor_id = 
        <cfqueryparam value="#session.user_id#" cfsqltype="cf_sql_integer">
    AND is_active = 1
</cfquery>

<div class="container mt-4">

<h3>Create Order (Vendor)</h3>

<!-- CUSTOMER (TEMP USER) -->
<div class="card mb-3">
<div class="card-header bg-dark text-white">Customer Details</div>
<div class="card-body">
<select id="existingUser" class="form-control mb-2">
<option value="">Select Existing Customer</option>

<cfoutput query="tempUsers">
<option 
    data-fname="#first_name#"
    data-lname="#last_name#"
    data-email="#email#">
    #first_name# #last_name# (#email#)
</option>
</cfoutput>

</select>
<input type="text" id="first_name" class="form-control mb-2" placeholder="First Name">
<input type="text" id="last_name" class="form-control mb-2" placeholder="Last Name">
<input type="email" id="email" class="form-control mb-2" placeholder="Email">
<button class="btn btn-secondary btn-sm mt-2" id="clearUserBtn">
Clear Customer
</button>
</div>
</div>

<!-- PRODUCT ADD -->
<div class="card mb-3">
<div class="card-header bg-dark text-white">Add Products</div>
<div class="card-body">

<div class="row">

<div class="col-md-4">
<select id="productSelect" class="form-control">
<option value="">Select Product</option>
<cfoutput query="products">
<option value="#id#" data-price="#price#" data-name="#product_name#">
#product_name# (#price#)
</option>
</cfoutput>
</select>
</div>

<div class="col-md-3">
<input type="number" id="qty" class="form-control" placeholder="Qty">
</div>

<div class="col-md-2">
<button class="btn btn-primary" id="addBtn">Add</button>
</div>

</div>

</div>
</div>

<!-- CART TABLE -->
<div class="card">
<div class="card-header bg-dark text-white">Order Items</div>
<div class="card-body">

<table class="table">
<thead>
<tr>
<th>Product</th>
<th>Price</th>
<th>Qty</th>
<th>Total</th>
<th>Action</th>
</tr>
</thead>

<tbody id="cartTable"></tbody>

</table>

<h5>Total: <span id="grandTotal">0</span> /-</h5>

<button class="btn btn-success mt-2" id="placeOrderBtn">
Place Order
</button>

</div>
</div>

</div>

<script>
let cart = {};

function renderCart(){
    let html="";
    let total=0;

    for(let pid in cart){
        let item=cart[pid];
        let sub=item.price * item.qty;
        total+=sub;

        html+=`
        <tr>
            <td>${item.name}</td>
            <td>${item.price}</td>
            <td>${item.qty}</td>
            <td>${sub}</td>
            <td><button class="btn btn-danger btn-sm removeBtn" data-id="${pid}">X</button></td>
        </tr>`;
    }

    $("#cartTable").html(html);
    $("#grandTotal").text(total);
}

$("#addBtn").click(function(){
    let select=$("#productSelect option:selected");

    let pid=select.val();
    let name=select.data("name");
    let price=parseFloat(select.data("price"));
    let qty=parseInt($("#qty").val());

    if(!pid || !qty){
        alert("Select product & qty");
        return;
    }

    if(cart[pid]){
        cart[pid].qty += qty;
    }else{
        cart[pid]={name,price,qty};
    }

    renderCart();
});

$(document).on("click",".removeBtn",function(){
    let id=$(this).data("id");
    delete cart[id];
    renderCart();
});

$("#placeOrderBtn").click(function(){

    let first_name=$("#first_name").val();
    let last_name=$("#last_name").val();
    let email=$("#email").val();

    if(!first_name || !email){
        alert("Customer info required");
        return;
    }

    if(Object.keys(cart).length === 0){
        alert("Add products");
        return;
    }

    $.post("../../controllers/OrderController.cfm",{
        action:"vendorOrder",
        first_name:first_name,
        last_name:last_name,
        email:email,
        cart:JSON.stringify(cart)
    },function(res){

        console.log(res);

        if(res.status==="success"){
            alert("Order Created");
            location.reload();
        }else{
            alert(res.message);
        }

    },"json")
    .fail(function(xhr){
        console.log("FULL ERROR:", xhr.responseText);
        alert("Server error. Check console.");
    });

});

$("#existingUser").change(function(){
    let opt = $(this).find("option:selected");

    $("#first_name").val(opt.data("fname") || '');
    $("#last_name").val(opt.data("lname") || '');
    $("#email").val(opt.data("email") || '');
});

$("#clearUserBtn").click(function(){
    $("#first_name").val('');
    $("#last_name").val('');
    $("#email").val('');
    $("#existingUser").val('');
});
</script>