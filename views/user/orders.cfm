<!-- check login -->
<cfif NOT structKeyExists(session, "user_id")>
    <cfabort>
</cfif>

<cfset orderModel = createObject("component","models.Order")>

<!-- params -->
<cfparam name="url.search" default="">
<cfparam name="url.p" default="1">

<cfset searchValue = trim(url.search)>
<cfset currentPage = val(url.p)>
<cfif currentPage LT 1>
    <cfset currentPage = 1>
</cfif>

<cfset limit = 5>

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

<h3 class="mb-3">Your Orders</h3>

<div id="ajaxMessage"></div>

<!-- SEARCH -->
<cfoutput>
<form id="searchForm" class="mb-3">
<div class="row g-2">

    <div class="col-12 col-md-6">
        <input type="text" name="search"
        value="#encodeForHTMLAttribute(searchValue)#"
        placeholder="Search Order ID"
        class="form-control">
    </div>

    <div class="col-6 col-md-3 d-grid">
        <button type="submit" class="btn btn-primary">Search</button>
    </div>

    <div class="col-6 col-md-3 d-grid">
        <button type="button" id="clearSearch" class="btn btn-secondary">Clear</button>
    </div>

</div>
</form>
</cfoutput>


<div id="orderContainer">

<cfif orders.recordCount EQ 0>
    <div class="alert alert-info text-center">No orders found</div>
<cfelse>

<cfset currentGroup = "">
<cfset gTotal = 0>

<cfoutput query="orders">

<cfif currentGroup NEQ order_group_id>

<cfif currentGroup NEQ "">
<div class="text-end p-2 border-top bg-light">
<strong>Total: #gTotal#</strong>
</div>
</table>
</div>
<cfset gTotal = 0>
</cfif>

<div class="card mb-4 shadow-sm">

<!-- HEADER -->
<div class="card-header bg-dark text-white">

<div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center">

    <div class="mb-2 mb-md-0">
        <strong>#order_group_id#</strong><br class="d-md-none">
        <small>#dateFormat(created_at, "dd-mmm-yyyy")#</small>
    </div>

    <div class="d-flex flex-wrap gap-2">

        <cfif status EQ "placed">
            <a href="../../assets/invoices/invoice_#order_group_id#.pdf"
            target="_blank"
            class="btn btn-success btn-sm">PDF</a>

            <button class="btn btn-danger btn-sm cancelBtn"
            data-id="#order_group_id#">Cancel</button>

        <cfelseif status EQ "cancel_requested">
            <span class="badge bg-warning">Requested</span>

        <cfelse>
            <span class="badge bg-secondary">Cancelled</span>
        </cfif>

    </div>

</div>

</div>

<!-- CANCEL BOX -->
<div class="p-3 border-top cancelBox"
id="cancelBox_#order_group_id#"
style="display:none;">

<textarea class="form-control mb-2 cancelReason"
data-id="#order_group_id#"
placeholder="Reason"></textarea>

<div class="d-flex gap-2">
<button class="btn btn-danger btn-sm confirmCancel"
data-id="#order_group_id#">Confirm</button>

<button class="btn btn-secondary btn-sm closeCancel"
data-id="#order_group_id#">Close</button>
</div>

</div>

<!-- TABLE -->
<div class="table-responsive">
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

<tr>
<td>#product_name#</td>
<td>
<cfif len(image)>
<img src="../../assets/images/products/#image#" class="img-fluid" style="max-width:50px;">
<cfelse>
No Image
</cfif>
</td>
<td>#price#</td>
<td>#quantity#</td>
<td>#total_amount#</td>
</tr>

<cfset gTotal += total_amount>

<cfif currentRow EQ recordCount>
<tr class="table-light">
<td colspan="4" class="text-end"><strong>Total:</strong></td>
<td><strong>#gTotal#</strong></td>
</tr>
</table>
</div>
</div>
</cfif>

</cfoutput>

</cfif>

<!-- PAGINATION -->

<cfset groupSize = 4>
<cfset currentGroup = ceiling(currentPage / groupSize)>

<cfset startPage = (currentGroup - 1) * groupSize + 1>
<cfset endPage = startPage + groupSize - 1>

<cfif endPage GT totalPages>
    <cfset endPage = totalPages>
</cfif>

<div class="mt-4 d-flex justify-content-center flex-wrap gap-2">

<!-- PREV -->
<cfif startPage GT 1>
    <cfoutput>
    <button class="btn btn-outline-primary btn-sm pageBtn"
        data-page="#startPage - 1#">Prev</button>
    </cfoutput>
</cfif>

<!-- NUMBERS -->
<cfloop from="#startPage#" to="#endPage#" index="i">
    <cfoutput>
    <button class="btn btn-sm pageBtn 
        #i EQ currentPage ? 'btn-primary' : 'btn-outline-primary'#"
        data-page="#i#">#i#</button>
    </cfoutput>
</cfloop>

<!-- NEXT -->
<cfif endPage LT totalPages>
    <cfoutput>
    <button class="btn btn-outline-primary btn-sm pageBtn"
        data-page="#endPage + 1#">Next</button>
    </cfoutput>
</cfif>

</div>


</div> 
</div>


<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>

<script>
$(document).ready(function(){

function showMsg(res){
$("#ajaxMessage").html(
'<div class="alert alert-' +
(res.status==="success"?"success":"danger") +
'">'+res.message+'</div>'
);
}

// SEARCH
$("#searchForm").submit(function(e){
e.preventDefault();

$.get("../../controllers/OrderController.cfm",
"action=search&"+$(this).serialize(),
function(res){
$("#orderContainer").html(res);
});
});

// CLEAR
$("#clearSearch").click(function(){
$("#searchForm")[0].reset();
$("#searchForm").submit();
});


// CANCEL UI
$(document).on("click",".cancelBtn",function(){
let id=$(this).data("id");
$(".cancelBox").hide();
$("#cancelBox_"+id).show();
});

$(document).on("click",".closeCancel",function(){
let id=$(this).data("id");
$("#cancelBox_"+id).hide();
});

// CONFIRM CANCEL
$(document).on("click",".confirmCancel",function(){

let id=$(this).data("id");
let reason = $(".cancelReason[data-id='"+id+"']").val();

$.post("../../controllers/OrderController.cfm",{
action:"cancel",
order_group_id:id,
reason:reason
},function(res){

showMsg(res);
$("#searchForm").submit();

},"json");

});

$(document).on("click",".pageBtn",function(){
    let page=$(this).data("page");

    let data=$("#searchForm").serialize().replace(/(&|^)p=\d+/,'');

    $.get("../../controllers/OrderController.cfm",
    "action=search&p="+page+"&"+data,
    function(res){
        $("#orderContainer").html(res);
    });
});

});
</script>