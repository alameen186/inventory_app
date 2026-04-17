<cfset productModel = createObject("component", "models.Product")>
<cfset categoryModel = createObject("component", "models.Category")>

<cfset categories = categoryModel.getAllActiveCategory()>

<cfparam name="url.search" default="">
<cfparam name="url.sort" default="">
<cfparam name="url.p" default="1">
<cfparam name="url.category_id" default="">

<cfset currentPage = val(url.p)>
<cfif currentPage LT 1><cfset currentPage = 1></cfif>

<cfset limit = 3>

<cfset products = productModel.getAllProductsAdmin(
    search = url.search,
    sort = url.sort,
    category_id = url.category_id,
    page = currentPage,
    limit = limit
)>

<cfset totalRecords = productModel.getProductCountAdmin(search=url.search)>
<cfset totalPages = ceiling(totalRecords / limit)>

<div class="container mt-4">
<h3>Product Management</h3>

<div id="ajaxMessage"></div>

<!-- ADD -->
<button class="btn btn-primary mb-3" onclick="$('#addForm').toggle()">Add Product</button>

<div id="addForm" style="display:none;">
<form id="createProductForm" enctype="multipart/form-data">
<input type="hidden" name="action" value="add">

<div class="row g-2">
<input name="product_name" class="form-control col" placeholder="Name">
<input name="price" class="form-control col" placeholder="Price">
<input name="stock" class="form-control col" placeholder="Stock">

<select name="category_id" class="form-control col">
<cfoutput query="categories">
<option value="#id#">#category_name#</option>
</cfoutput>
</select>

<input type="file" name="product_image" class="form-control col">

<button class="btn btn-success">Add</button>
</div>
</form>
</div>

<!-- SEARCH -->
<form id="searchForm" class="mb-3">
<cfoutput>
<input name="search" value="#url.search#" class="form-control w-25 d-inline">
</cfoutput>
<select name="sort" class="form-control w-25 d-inline">
<option value="">Sort</option>
<option value="a_z">A-Z</option>
<option value="z_a">Z-A</option>
<option value="price_low">Price Low</option>
<option value="price_high">Price High</option>
</select>
<select name="category_id" class="form-control w-25 d-inline">
<option value="">All</option>
<cfoutput query="categories">
<option value="#id#">#category_name#</option>
</cfoutput>
</select>
<button class="btn btn-primary btn-sm">Apply</button>
</form>

<table class="table table-bordered">
<thead>
<tr>
<th>ID</th><th>Name</th><th>Price</th><th>Stock</th>
<th>Category</th><th>Image</th><th>Status</th><th>Action</th>
</tr>
</thead>

<tbody id="productTableBody">

<cfoutput query="products">

<tr id="viewRow_#id#">
<td>#id#</td>
<td>#product_name#</td>
<td>#price#</td>
<td>#stock#</td>
<td>#category_name#</td>

<td>
<cfif len(image)>
<img src="../../assets/images/products/#image#" width="50">
<cfelse>No Image</cfif>
</td>

<td>
<cfif is_active EQ 1>
<span class="badge bg-success">Active</span>
<cfelse>
<span class="badge bg-warning">Blocked</span>
</cfif>
</td>

<td>
<button class="editBtn btn btn-warning btn-sm" data-id="#id#">Edit</button>

<button class="toggleBtn btn btn-danger btn-sm"
data-id="#id#" data-status="#is_active#">
<cfif is_active EQ 1>Block<cfelse>Unblock</cfif>
</button>
</td>
</tr>

<!-- EDIT ROW -->
<tr id="editRow_#id#" style="display:none;">
<td>#id#</td>

<td><input value="#product_name#" class="form-control name"></td>
<td><input value="#price#" class="form-control price"></td>
<td><input value="#stock#" class="form-control stock"></td>

<td>
<select class="form-control category">
<cfloop query="categories">
<option value="#categories.id#"
<cfif categories.id EQ products.category_id>selected</cfif>>
#categories.category_name#
</option>
</cfloop>
</select>
</td>

<td>
<input type="file" class="form-control image">
</td>

<td><cfif is_active EQ 1>
<span class="badge bg-success">Active</span>
<cfelse>
<span class="badge bg-warning">Blocked</span>
</cfif></td>

<td>
<button class="saveBtn btn btn-success btn-sm" data-id="#id#">Save</button>
<button class="cancelBtn btn btn-secondary btn-sm" data-id="#id#">Cancel</button>
</td>
</tr>

</cfoutput>

</tbody>
</table>

<!-- PAGINATION -->
<cfoutput>
<div>
<cfloop from="1" to="#totalPages#" index="i">
<button class="pageBtn btn btn-sm 
<cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
data-page="#i#">#i#</button>
</cfloop>
</div>
</cfoutput>

</div>

<script>
$(function(){

function msg(res){
$("#ajaxMessage").html(
'<div class="alert alert-'+(res.status=="success"?"success":"danger")+'">'+res.message+'</div>'
);
setTimeout(()=>$("#ajaxMessage").fadeOut(),3000);
}

// ADD
$("#createProductForm").submit(function(e){
e.preventDefault();

let fd=new FormData(this);

$.ajax({
url:"../../controllers/ProductController.cfm",
type:"POST",
data:fd,
processData:false,
contentType:false,
dataType:"json",
success:(res)=>{msg(res); if(res.status=="success") location.reload();}
});
});

// EDIT TOGGLE
$(document).on("click",".editBtn",function(){
let id=$(this).data("id");
$("#viewRow_"+id).hide();
$("#editRow_"+id).show();
});

$(document).on("click",".cancelBtn",function(){
let id=$(this).data("id");
$("#editRow_"+id).hide();
$("#viewRow_"+id).show();
});

// SAVE EDIT
$(document).on("click",".saveBtn",function(){

let id=$(this).data("id");
let row=$("#editRow_"+id);

let fd=new FormData();
fd.append("action","update");
fd.append("id",id);
fd.append("product_name",row.find(".name").val());
fd.append("price",row.find(".price").val());
fd.append("stock",row.find(".stock").val());
fd.append("category_id",row.find(".category").val());

let file=row.find(".image")[0].files[0];
if(file) fd.append("product_image",file);

$.ajax({
url:"../../controllers/ProductController.cfm",
type:"POST",
data:fd,
processData:false,
contentType:false,
dataType:"json",
success:(res)=>{
msg(res);
if(res.status=="success") location.reload();
}
});

});

// TOGGLE
$(document).on("click",".toggleBtn",function(){

let btn=$(this);

$.get("../../controllers/ProductController.cfm",{
action:"block",
id:btn.data("id"),
currentStatus:btn.data("status")
},function(res){

msg(res);

if(res.status!="success") return;

let s=res.newStatus;
btn.data("status",s);
btn.text(s==1?"Block":"Unblock");

},"json");

});

// SEARCH
$("#searchForm").submit(function(e){
e.preventDefault();

$.get("../../controllers/ProductController.cfm",
"action=search&p=1&"+$(this).serialize(),
(res)=>$("#productTableBody").html(res));
});

// PAGINATION
$(document).on("click",".pageBtn",function(){

let page=$(this).data("page");
let data=$("#searchForm").serialize();

$.get("../../controllers/ProductController.cfm",
"action=search&p="+page+"&"+data,
(res)=>$("#productTableBody").html(res));

});

});
</script>