<cfset enquiryModel = createObject("component","models.Enquiry")>

<cfparam name="url.search" default="">
<cfparam name="url.status" default="">
<cfparam name="url.p" default="1">

<cfset currentPage = val(url.p)>
<cfif currentPage LT 1>
    <cfset currentPage = 1>
</cfif>

<cfset limit = 2>

<cfset enquiries = enquiryModel.getAllEnquiries(
    search = url.search,
    status = url.status,
    page = currentPage,
    limit = limit
)>

<cfset totalRecords = enquiryModel.getEnquiryCount(
    search = url.search,
    status = url.status
)>

<cfset totalPages = ceiling(totalRecords / limit)>

<div class="container mt-4">

<h3>Product Enquiries</h3>

<div id="ajaxMessage"></div>

<!-- SEARCH -->
<cfoutput>
<form id="searchForm" class="mb-3">

<input type="text" name="search" value="#url.search#"
placeholder="Search product or user"
class="form-control w-25 d-inline">

<select name="status" class="form-control w-25 d-inline">
<option value="">All Status</option>
<option value="pending" <cfif url.status EQ "pending">selected</cfif>>Pending</option>
<option value="fulfilled" <cfif url.status EQ "fulfilled">selected</cfif>>Fulfilled</option>
</select>

<button class="btn btn-primary btn-sm">Search</button>

</form>
</cfoutput>

<!-- TABLE -->
<table class="table table-bordered mt-3">
<thead class="table-dark">
<tr>
<th>User</th>
<th>Product</th>
<th>Image</th>
<th>Price</th>
<th>Stock</th>
<th>Status</th>
<th>Date</th>
<th>Action</th>
</tr>
</thead>

<tbody id="tableBody">

<cfif enquiries.recordCount EQ 0>
<tr><td colspan="8" class="text-center">No data</td></tr>
<cfelse>

<cfoutput query="enquiries">
<tr id="row_#product_id#">

<td>#user_name#</td>
<td>#product_name#</td>

<td>
<img src="../../assets/images/products/#image#" width="50">
</td>

<td>#price#</td>
<td class="stockCell">#stock#</td>

<td class="statusCell">
<cfif status EQ "pending">
<span class="badge bg-warning text-dark">Pending</span>
<cfelse>
<span class="badge bg-success">Restocked</span>
</cfif>
</td>

<td>#dateFormat(created_at,"dd-mmm-yyyy")#</td>

<td>
<cfif status EQ "pending">
<button 
class="btn btn-warning btn-sm restockBtn"
data-id="#product_id#"
data-name="#product_name#"
data-category="#category_name#"
data-price="#price#"
data-stock="#stock#">
Restock Product
</button>
<cfelse>
<span class="text-muted">Completed</span>
</cfif>
</td>

</tr>
</cfoutput>

</cfif>

</tbody>
</table>

<!-- PAGINATION -->
<cfif totalPages GT 1>
<cfoutput>
<div class="mt-3">
<cfloop from="1" to="#totalPages#" index="i">
<button class="btn btn-sm pageBtn
<cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
data-page="#i#">#i#</button>
</cfloop>
</div>
</cfoutput>
</cfif>

</div>


<!-- ================= RESTOCK TEMPLATE ================= -->
<div id="restockTemplate" style="display:none;">
<div class="card shadow-sm p-4 mt-3">

<h5>Restock Product</h5>

<form id="restockForm">

<input type="hidden" name="action" value="restockProduct">
<input type="hidden" name="product_id" id="restock_product_id">

<div class="mb-3">
<label>Product Name</label>
<input type="text" id="restock_product_name" class="form-control" readonly>
</div>

<div class="mb-3">
<label>Category</label>
<input type="text" id="restock_category" class="form-control" readonly>
</div>

<div class="mb-3">
<label>Price</label>
<input type="text" id="restock_price" class="form-control" readonly>
</div>

<div class="mb-3">
<label>Current Stock</label>
<input type="text" id="restock_stock" class="form-control" readonly>
</div>

<div class="mb-3">
<label>Add New Stock</label>
<input type="number" name="add_stock" class="form-control" required min="1">
</div>

<button class="btn btn-success">Update Stock</button>
<button type="button" class="btn btn-secondary cancelRestock">Cancel</button>

</form>

</div>
</div>


<script>
$(document).ready(function(){

function showMsg(res){
$("#ajaxMessage").html(
'<div id="msgBox" class="alert alert-' +
(res.status==="success"?"success":"danger") +
'">'+res.message+'</div>'
);
setTimeout(()=>$("#msgBox").fadeOut(),3000);
}


// RESTOCK OPEN
$(document).on("click",".restockBtn",function(){

let btn=$(this);
let row=btn.closest("tr");

$(".restockRow").remove();

let formHtml=$("#restockTemplate").html();

row.after('<tr class="restockRow"><td colspan="8">'+formHtml+'</td></tr>');

$("#restock_product_id").val(btn.data("id"));
$("#restock_product_name").val(btn.data("name"));
$("#restock_category").val(btn.data("category"));
$("#restock_price").val(btn.data("price"));
$("#restock_stock").val(btn.data("stock"));

});


// CANCEL
$(document).on("click",".cancelRestock",function(){
$(".restockRow").remove();
});


// SUBMIT
$(document).on("submit","#restockForm",function(e){

e.preventDefault();

let form=$(this);

$.post("../../controllers/AdminEnquiryController.cfm",
form.serialize(),
function(res){

showMsg(res);

if(res.status==="success"){

$(".restockRow").remove();

let row=$("#row_"+res.product_id);

row.find(".statusCell").html('<span class="badge bg-success">Restocked</span>');
row.find(".restockBtn").remove();

}

},"json");

});


// SEARCH
$("#searchForm").submit(function(e){
e.preventDefault();

$.get("../../controllers/AdminEnquiryController.cfm",
"action=search&"+$(this).serialize(),
function(res){
$("#tableBody").html(res);
});
});


// PAGINATION
$(document).on("click",".pageBtn",function(){

let page=$(this).data("page");

$.get("../../controllers/AdminEnquiryController.cfm",
"action=search&p="+page+"&"+$("#searchForm").serialize(),
function(res){
$("#tableBody").html(res);
});

});

});
</script>