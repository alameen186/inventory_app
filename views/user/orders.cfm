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

<cfset limit = 2>

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

<h3>Your Orders</h3>

<div id="ajaxMessage"></div>

<!-- SEARCH -->
<cfoutput>
<form id="searchForm" class="mb-3">
<div class="input-group w-50">

<input type="text" name="search"
value="#encodeForHTMLAttribute(searchValue)#"
placeholder="Search Order ID"
class="form-control">

<button type="submit" class="btn btn-primary">Search</button>
<button type="button" id="clearSearch" class="btn btn-secondary">Clear</button>

</div>
</form>
</cfoutput>


<div id="orderContainer">

<cfif orders.recordCount EQ 0>
    <div class="alert alert-info">No orders found</div>
<cfelse>

<cfset currentGroup = "">
<cfset gTotal = 0>

<cfoutput query="orders">

<cfif currentGroup NEQ order_group_id>

<cfif currentGroup NEQ "">
<tr class="table-secondary">
<td colspan="4" class="text-end"><strong>Total:</strong></td>
<td><strong>#gTotal#</strong></td>
</tr>
</table>
</div>
<cfset gTotal = 0>
</cfif>

<div class="card mb-4">

<div class="card-header bg-dark text-white d-flex justify-content-between">
<span>
Order ID: #order_group_id# |
#dateFormat(created_at, "dd-mmm-yyyy")#
</span>

<div>
<cfif status EQ "placed">
<a href="../../assets/invoices/invoice_#order_group_id#.pdf"
target="_blank"
class="btn btn-success btn-sm">PDF</a>

<button class="btn btn-danger btn-sm cancelBtn"
data-id="#order_group_id#">Cancel</button>

<cfelseif status EQ "cancel_requested">
<span class="badge bg-warning">Cancel Requested</span>
<cfelse>
<span class="badge bg-secondary">Cancelled</span>
</cfif>
</div>
</div>

<div class="p-3 border-top cancelBox"
id="cancelBox_#order_group_id#"
style="display:none;">

<textarea class="form-control mb-2 cancelReason"
data-id="#order_group_id#"></textarea>

<button class="btn btn-danger btn-sm confirmCancel"
data-id="#order_group_id#">Confirm Cancel</button>

<button class="btn btn-secondary btn-sm closeCancel"
data-id="#order_group_id#">Close</button>

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

<cfif currentRow EQ recordCount>
<tr class="table-secondary">
<td colspan="4" class="text-end"><strong>Total:</strong></td>
<td><strong>#gTotal#</strong></td>
</tr>
</table>
</div>
</cfif>

</cfoutput>

</cfif>


<cfoutput>
<div class="mt-4">

<cfloop from="1" to="#totalPages#" index="i">

<button type="button"
class="btn btn-sm pageBtn <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
data-page="#i#">
#i#
</button>

</cfloop>

</div>
</cfoutput>

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

// PAGINATION
$(document).on("click",".pageBtn",function(){

let page=$(this).data("page");

let data=$("#searchForm").serialize().replace(/(&|^)p=\d+/,'');

$.get("../../controllers/OrderController.cfm",
"action=search&p="+page+"&"+data,
function(res){
$("#orderContainer").html(res);
});

});

// CANCEL LOGIC
$(document).on("click",".cancelBtn",function(){
let id=$(this).data("id");
$(".cancelBox").hide();
$("#cancelBox_"+id).show();
});

$(document).on("click",".closeCancel",function(){
let id=$(this).data("id");
$("#cancelBox_"+id).hide();
});

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

});
</script>