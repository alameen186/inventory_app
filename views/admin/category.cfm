<cfset categoryModel = createObject("component", "models.Category")>

<cfif session.role_name EQ "vendor">
    <cfset vendorFilter = session.user_id>
<cfelse>
    <cfset vendorFilter = "">
</cfif>

<cfparam name="url.search" default="">
<cfparam name="url.sort" default="">
<cfparam name="url.p" default="1">

<cfset currentPage = val(url.p)>
<cfif currentPage LT 1>
    <cfset currentPage = 1>
</cfif>

<cfset limit = 5>

<cfset totalRecords = categoryModel.getCategoryCount(
    search = trim(url.search),
    vendor_id = vendorFilter
)>
<cfset totalPages = ceiling(totalRecords / limit)>



<cfset category = categoryModel.getAllCategories(
    search = trim(url.search),
    sort = url.sort,
    page = currentPage,
    limit = limit,
    vendor_id = vendorFilter
)>
<div class="container mt-4">
<h3>Category Management</h3>

<div id="ajaxMessage"></div>

<button class="btn btn-primary mb-3" onclick="$('#addForm').toggle()">Add Category</button>

<div id="addForm" style="display:none;">
<form id="createCategoryForm">
<input type="hidden" name="action" value="add">

<div class="row">
<div class="col-md-4">
<input type="text" name="category_name" class="form-control" placeholder="Category Name" required>
</div>

<div class="col-md-4">
<input type="text" name="description" class="form-control" placeholder="Description" required>
</div>

<div class="col-md-2">
<button class="btn btn-success">Add</button>
</div>
</div>
</form>
</div>

<!-- SEARCH -->
<form id="searchForm" class="mt-3">
<cfoutput>
<input type="text" placeholder="Search category..."  name="search" value="#url.search#" class="form-control w-25 d-inline">
</cfoutput>
<select name="sort" class="form-control w-25 d-inline">
<option value="">Sort</option>
<option value="a_z" <cfif url.sort EQ "a_z">selected</cfif>>A-Z</option>
<option value="z_a" <cfif url.sort EQ "z_a">selected</cfif>>Z-A</option>
</select>
<button class="btn btn-primary btn-sm">Search</button>
</form>

<table class="table table-bordered mt-3">
<thead>
<tr>
<th>ID</th>
<th>Name</th>
<th>Description</th>
<th>Status</th>
<th>Action</th>
</tr>
</thead>

<tbody id="categoryTableBody">

<cfoutput query="category">

<tr id="categoryRow_#id#">
<td>#id#</td>
<td>#category_name#</td>
<td>#description#</td>

<td>
<cfif is_active EQ 1>
<p class="text-success">Active</p>
<cfelse>
<p class="text-warning">Blocked</p>
</cfif>
</td>

<td>
<button class="editBtn btn btn-warning btn-sm" data-id="#id#">Edit</button>

<button class="toggleStatusBtn btn btn-danger btn-sm"
data-id="#id#" data-status="#is_active#">
<cfif is_active EQ 1>Block<cfelse>Unblock</cfif>
</button>
</td>
</tr>

<tr id="editCategoryRow_#id#" style="display:none;">
<td>#id#</td>
<td><input value="#category_name#" class="form-control name"></td>
<td><input value="#description#" class="form-control desc"></td>
<td><cfif is_active EQ 1>
<p class="text-success">Active</p>
<cfelse>
<p class="text-warning">Blocked</p>
</cfif>
</td>
<td>
<button class="saveEdit btn btn-success btn-sm" data-id="#id#">Save</button>
<button class="cancelEdit btn btn-secondary btn-sm" data-id="#id#">Cancel</button>
</td>
</tr>

</cfoutput>

</tbody>
</table>

<!-- PAGINATION -->
<cfoutput>
<div id="paginationArea" class="mt-3">

<cfloop from="1" to="#totalPages#" index="i">

<button 
class="btn btn-sm pageBtn <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
data-page="#i#">

#i#

</button>

</cfloop>

</div>
</cfoutput>

</div>

<script>
$(document).ready(function(){

function showMessage(res){
    $("#ajaxMessage").html(
        '<div id="msgBox" class="alert alert-'+
        (res.status==="success"?"success":"danger")+
        '">' + res.message + '</div>'
    );

    setTimeout(function(){
        $("#msgBox").fadeOut();
    }, 5000);
}


// ADD
$("#createCategoryForm").submit(function(e){
    e.preventDefault();

    $.post("../../controllers/CategoryController.cfm",
        $(this).serialize(),
        function(res){

            showMessage(res);

            if(res.status==="success"){
                location.reload(); 
            }

        },"json");
});


// EDIT
$(document).on("click",".editBtn",function(){
    let id=$(this).data("id");
    $("#categoryRow_"+id).hide();
    $("#editCategoryRow_"+id).show();
});


// CANCEL
$(document).on("click",".cancelEdit",function(){
    let id=$(this).data("id");
    $("#editCategoryRow_"+id).hide();
    $("#categoryRow_"+id).show();
});


// SAVE EDIT
$(document).on("click",".saveEdit",function(){

    let id=$(this).data("id");
    let row=$("#editCategoryRow_"+id);

    $.post("../../controllers/CategoryController.cfm",{
        action:"update",
        id:id,
        category_name:row.find(".name").val(),
        description:row.find(".desc").val()
    },function(res){

        showMessage(res);

        // ❗ stop if validation error
        if(res.status !== "success") return;

        // update UI
        let updatedRow = `
        <tr id="categoryRow_${res.id}">
            <td>${res.id}</td>
            <td>${res.category_name}</td>
            <td>${res.description}</td>
            <td><p class="text-success">Active</p></td>
            <td>
                <button class="editBtn btn btn-warning btn-sm" data-id="${res.id}">Edit</button>
            </td>
        </tr>`;

        $("#editCategoryRow_"+id).replaceWith(updatedRow);

    },"json");

});


// TOGGLE
$(document).on("click",".toggleStatusBtn",function(){

    let btn=$(this);

    $.get("../../controllers/CategoryController.cfm",{
        action:"block",
        id:btn.data("id"),
        currentStatus:btn.data("status")
    },function(res){

        showMessage(res);

        if(res.status !== "success") return;

        let newStatus = res.newStatus;

        btn.data("status", newStatus);
        btn.text(newStatus == 1 ? "Block" : "Unblock");

        $("#categoryRow_"+res.id+" td:nth-child(4)").html(
            newStatus == 1
            ? '<p class="text-success">Active</p>'
            : '<p class="text-warning">Blocked</p>'
        );

    },"json");

});


// SEARCH
$("#searchForm").submit(function(e){
    e.preventDefault();

    $.get("../../controllers/CategoryController.cfm",
        "action=search&p=1&"+$(this).serialize(),
        function(res){
            $("#categoryTableBody").html(res);
        }
    );
});


// PAGINATION
$(document).on("click",".pageBtn",function(){

    let page=$(this).data("page");

    let searchData=$("#searchForm").serialize();

    $.get("../../controllers/CategoryController.cfm",
        "action=search&p="+page+"&"+searchData,
        function(res){
            $("#categoryTableBody").html(res);
        }
    );
});

});
</script>