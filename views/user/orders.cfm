<cfif NOT structKeyExists(session, "user_id")>
    <cfabort>
</cfif>

<cfset orderModel = createObject("component","models.Order")>

<cfparam name="url.search" default="">
<cfparam name="url.p" default="1">

<cfset searchValue = trim(url.search)>
<cfset currentPage = max(val(url.p),1)>
<cfset limit = 5>

<!-- FETCH -->
<cfset orders = orderModel.getUserOrdersWithPagination(
    user_id = session.user_id,
    search = searchValue,
    page = currentPage,
    limit = limit
)>

<cfset totalRecords = orderModel.getUserOrderCount(
    user_id = session.user_id,
    search = searchValue
)>

<cfset totalPages = ceiling(totalRecords / limit)>

<div class="container mt-4">

<h4 class="mb-3">Your Orders</h4>

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
<button class="btn btn-primary">Search</button>
</div>

<div class="col-6 col-md-3 d-grid">
<button type="button" id="clearSearch" class="btn btn-secondary">Clear</button>
</div>

</div>
</form>
</cfoutput>

<div id="orderContainer">

<cfif orders.recordCount EQ 0>

<div class="alert alert-info text-center">
No orders found
</div>

<cfelse>

<cfset orderGroupTracker = "">
<cfset groupTotal = 0>

<cfoutput query="orders">

<!-- NEW ORDER GROUP -->
<cfif orderGroupTracker NEQ order_group_id>

    <!-- CLOSE PREVIOUS -->
    <cfif orderGroupTracker NEQ "">
        <tr class="table-light">
            <td colspan="4" class="text-end"><strong>Total:</strong></td>
            <td><strong>#groupTotal#</strong></td>
        </tr>
        </table>
        </div>
        </div>
        <cfset groupTotal = 0>
    </cfif>

    <!-- CARD START -->
    <div class="card mb-4 shadow-sm">

    <div class="card-header bg-dark text-white d-flex justify-content-between align-items-center flex-wrap">

        <div>
            <strong>#order_group_id#</strong><br>
            <small>#dateFormat(created_at,"dd-mmm-yyyy")#</small>
        </div>

        <div class="d-flex gap-2 flex-wrap">

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

    <!-- CANCEL BOX -->
    <div class="p-3 border-top cancelBox d-none"
    id="cancelBox_#order_group_id#">

    <textarea class="form-control mb-2 cancelReason"
    data-id="#order_group_id#"
    placeholder="Enter cancel reason"></textarea>

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

    <cfset orderGroupTracker = order_group_id>

</cfif>

<!-- ROW -->
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

<cfset groupTotal += total_amount>

<!-- LAST RECORD -->
<cfif currentRow EQ recordCount>
<tr class="table-light">
<td colspan="4" class="text-end"><strong>Total:</strong></td>
<td><strong>#groupTotal#</strong></td>
</tr>
</table>
</div>
</div>
</div>
</cfif>

</cfoutput>

</cfif>

<!-- ================= PAGINATION ================= -->

<cfset groupSize = 4>
<cfset pageGroup = ceiling(currentPage / groupSize)>

<cfset startPage = (pageGroup - 1) * groupSize + 1>
<cfset endPage = min(startPage + groupSize - 1, totalPages)>

<div class="mt-4 d-flex justify-content-center gap-2 flex-wrap">

<cfoutput>

<!-- PREV -->
<cfif startPage GT 1>
<button class="btn btn-outline-primary btn-sm pageBtn"
data-page="#startPage - 1#">Prev</button>
</cfif>

<!-- NUMBERS -->
<cfloop from="#startPage#" to="#endPage#" index="i">
<button class="btn btn-sm pageBtn 
#i EQ currentPage ? 'btn-primary' : 'btn-outline-primary'#"
data-page="#i#">#i#</button>
</cfloop>

<!-- NEXT -->
<cfif endPage LT totalPages>
<button class="btn btn-outline-primary btn-sm pageBtn"
data-page="#endPage + 1#">Next</button>
</cfif>

</cfoutput>

</div>

</div>
</div>

<script>
$(function(){

function showMsg(res){
$("#ajaxMessage").html(
'<div class="alert alert-'+
(res.status==="success"?"success":"danger")+
'">'+res.message+'</div>'
);
}

// SEARCH
$("#searchForm").submit(function(e){
e.preventDefault();

$("#orderContainer").html("<div class='text-center'>Loading...</div>");

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

// CANCEL TOGGLE
$(document).on("click",".cancelBtn",function(){
let id=$(this).data("id");
$(".cancelBox").addClass("d-none");
$("#cancelBox_"+id).removeClass("d-none");
});

$(document).on("click",".closeCancel",function(){
let id=$(this).data("id");
$("#cancelBox_"+id).addClass("d-none");
});

// CONFIRM CANCEL
$(document).on("click",".confirmCancel",function(){

let id=$(this).data("id");
let reason = $(".cancelReason[data-id='"+id+"']").val();

if(!reason.trim()){
alert("Please enter reason");
return;
}

$.post("../../controllers/OrderController.cfm",{
action:"cancel",
order_group_id:id,
reason:reason
},function(res){

showMsg(res);
$("#searchForm").submit();

},"json");

});

// PAGINATION
$(document).on("click",".pageBtn",function(){

let page=$(this).data("page");

let data=$("#searchForm").serialize().replace(/(&|^)p=\d+/,"");

$("#orderContainer").html("<div class='text-center'>Loading...</div>");

$.get("../../controllers/OrderController.cfm",
"action=search&p="+page+"&"+data,
function(res){
$("#orderContainer").html(res);
});

});

});
</script>