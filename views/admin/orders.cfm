<cfset orderModel = createObject("component","models.Order")>

<cfparam name="url.search" default="">
<cfparam name="url.p" default="1">

<cfset searchValue = trim(url.search)>
<cfset currentPage = val(url.p) GT 0 ? val(url.p) : 1>
<cfset limit = 2>

<cfset orders = orderModel.getAllOrdersWithPagination(
    search=searchValue,
    page=currentPage,
    limit=limit
)>

<cfset totalRecords = orderModel.getOrderCount(search=searchValue)>
<cfset totalPages = ceiling(totalRecords / limit)>

<div class="container mt-4">

<!-- MESSAGE -->
<div id="ajaxMessage"></div>

<!-- SEARCH -->
<form id="orderSearchForm" class="mb-3">
    <div class="input-group w-50">
    <cfoutput>
        <input type="text" name="search"
               value="#encodeForHTMLAttribute(searchValue)#"
               placeholder="Search Order ID or Username"
               class="form-control">

    </cfoutput>
        <button class="btn btn-primary">Search</button>

        <cfif len(searchValue)>
            <button type="button" id="clearSearch" class="btn btn-outline-secondary">Clear</button>
        </cfif>
    </div>
</form>

<h3>All Orders</h3>

<div id="orderContainer">

<cfif orders.recordCount EQ 0>

    <div class="alert alert-info">
        No orders found matching your criteria.
    </div>

<cfelse>

<cfset currentGroup = "">
<cfset gTotal = 0>

<cfoutput query="orders">

<!-- GROUP START -->
<cfif currentGroup NEQ order_group_id>

    <cfif currentGroup NEQ "">
        <tr class="table-secondary">
            <td colspan="4" class="text-end"><strong>Total:</strong></td>
            <td><strong>#gTotal#</strong></td>
        </tr>
        </table></div>
        <cfset gTotal = 0>
    </cfif>

    <div class="card mb-4 shadow">

    <div class="card-header bg-dark text-white d-flex justify-content-between">

        <span>
            <strong>Order: #order_group_id#</strong> |
            #dateFormat(created_at, "dd-mmm-yyyy")# |
            #user_name#
        </span>

        <div>

            <!-- PDF -->
            <a href="../../assets/invoices/invoice_#order_group_id#.pdf"
               target="_blank"
               class="btn btn-success btn-sm">
               PDF
            </a>

            <!-- STATUS -->
            <cfif status EQ "cancel_requested">
                <span class="badge bg-warning text-dark ms-2">Cancel Requested</span>
            <cfelseif status EQ "cancelled">
                <span class="badge bg-secondary ms-2">Cancelled</span>
            <cfelse>
                <span class="badge bg-success ms-2">Active</span>
            </cfif>

        </div>

    </div>

    <!-- APPROVE CANCEL -->
    <cfif status EQ "cancel_requested">
    <div class="p-3 border-top bg-light">

        <p><strong>Cancel Reason:</strong></p>

        <div class="alert alert-warning">
            #cancel_reason#
        </div>

        <button class="approveBtn btn btn-success btn-sm"
                data-id="#order_group_id#">
            Approve Cancel
        </button>

    </div>
    </cfif>

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

<!-- ROW -->
<tr>
    <td>#product_name#</td>
    <td>
        <img src="../../assets/images/products/#image#" width="40"
        onerror="this.src='https://placehold.co'">
    </td>
    <td>#price#</td>
    <td>#quantity#</td>
    <td>#total_amount#</td>
</tr>

<cfset gTotal += total_amount>

<!-- GROUP END -->
<cfif currentRow EQ recordCount>
    <tr class="table-secondary">
        <td colspan="4" class="text-end"><strong>Total:</strong></td>
        <td><strong>#gTotal#</strong></td>
    </tr>
    </table></div>
</cfif>

</cfoutput>

<!-- PAGINATION -->
<nav class="mt-4">
<ul class="pagination">

<cfoutput>
<cfloop from="1" to="#totalPages#" index="i">

<li class="page-item # (i eq currentPage ? 'active' : '') #">

<button class="page-link pageBtn" data-page="#i#">
#i#
</button>

</li>

</cfloop>
</cfoutput>

</ul>
</nav>

</cfif>

</div>
</div>


<script>
$(function(){

function showMessage(res){
$("#ajaxMessage").html(
'<div id="msgBox" class="alert alert-'+
(res.status==="success"?"success":"danger")+
'">'+res.message+'</div>'
);
setTimeout(()=>$("#msgBox").fadeOut(),3000);
}


// SEARCH
$("#orderSearchForm").submit(function(e){
e.preventDefault();

$.get("../../controllers/OrderController.cfm",
"action=search&"+$(this).serialize(),
function(res){
$("#orderContainer").html(res);
});
});


// CLEAR
$("#clearSearch").click(function(){
$("input[name='search']").val('');
$("#orderSearchForm").submit();
});


// PAGINATION
$(document).on("click",".pageBtn",function(){

let page=$(this).data("page");
let data=$("#orderSearchForm").serialize();

$.get("../../controllers/OrderController.cfm",
"action=search&p="+page+"&"+data,
function(res){
$("#orderContainer").html(res);
});

});


// APPROVE CANCEL
$(document).on("click",".approveBtn",function(){

let id=$(this).data("id");

$.post("../../controllers/OrderController.cfm",{
action:"approveCancel",
order_group_id:id
},function(res){

showMessage(res);

if(res.status==="success"){
location.reload(); // safe for grouped UI
}

},"json");

});

});
</script>