<cfset userModel = createObject("component", "models.User")>

<cfparam name="url.search" default="">
<cfparam name="url.sort" default="">
<cfparam name="url.p" default="1">

<cfset currentPage = val(url.p)>
<cfif currentPage LT 1>
    <cfset currentPage = 1>
</cfif>

<cfset limit = 2>

<cfset users = userModel.getAllUsers(
    search = trim(url.search),
    sort = url.sort,
    page = currentPage,
    limit = limit
)>

<cfset totalRecords = userModel.getUserCount(
    search = trim(url.search)
)>

<cfset totalPages = ceiling(totalRecords / limit)>

<div class="container-fluid mt-4">

<h4 class="mb-3">Users Management</h4>

<div id="ajaxMessage"></div>

<!-- SEARCH -->
<cfoutput>
<form id="searchForm" class="mb-3">
<div class="row g-2">

<div class="col-12 col-md-4">
<input type="text" name="search" value="#url.search#"
class="form-control" placeholder="Search">
</div>

<div class="col-12 col-md-4">
<select name="sort" class="form-control">
<option value="">Sort</option>
<option value="a_z" <cfif url.sort EQ "a_z">selected</cfif>>A-Z</option>
<option value="z_a" <cfif url.sort EQ "z_a">selected</cfif>>Z-A</option>
</select>
</div>

<div class="col-12 col-md-4 d-grid">
<button class="btn btn-primary">Apply</button>
</div>

</div>
</form>
</cfoutput>

<!-- ADD BUTTON -->
<button id="showAddForm" class="btn btn-primary mb-3 w-100 w-md-auto">
Add User
</button>

<!-- ADD FORM -->
<div id="addUserForm" style="display:none;" class="card p-3 mb-3">

<form id="createUserForm">

<input type="hidden" name="action" value="create">

<div class="row g-2">

<div class="col-12 col-md-6">
<input name="first_name" class="form-control" placeholder="First Name">
</div>

<div class="col-12 col-md-6">
<input name="last_name" class="form-control" placeholder="Last Name">
</div>

<div class="col-12">
<input name="email" class="form-control" placeholder="Email">
</div>

<div class="col-12 col-md-6">
<input name="password" class="form-control" placeholder="Password">
</div>

<div class="col-12 col-md-6">
<input name="confirm" class="form-control" placeholder="Confirm">
</div>

<div class="col-12">
<select name="role_id" class="form-control">
<option value="2">Customer</option>
<option value="3">Manager</option>
</select>
</div>

<div class="col-12 d-flex gap-2">
<button class="btn btn-success w-100">Create</button>
<button type="button" id="cancelAdd" class="btn btn-secondary w-100">Cancel</button>
</div>

</div>

</form>
</div>

<!-- TABLE -->
<div class="table-responsive">
<table class="table table-bordered align-middle text-nowrap">
<thead class="table-dark">
<tr>
<th>ID</th>
<th>Name</th>
<th>Email</th>
<th>Role</th>
<th>Actions</th>
</tr>
</thead>

<tbody id="tableBody">

<cfoutput query="users">
<tr id="row_#id#">

<td>#id#</td>
<td>#first_name# #last_name#</td>
<td class="text-break">#email#</td>
<td>#role_name#</td>

<td class="d-flex flex-wrap gap-1">
<button class="btn btn-warning btn-sm editBtn"
data-id="#id#"
data-first="#first_name#"
data-last="#last_name#"
data-email="#email#">Edit</button>

<button class="btn btn-danger btn-sm deleteBtn" data-id="#id#">Delete</button>
</td>

</tr>
</cfoutput>

</tbody>
</table>
</div>

<!-- PAGINATION -->
<div class="d-flex justify-content-center flex-wrap gap-2 mt-3">
<cfoutput>
<cfloop from="1" to="#totalPages#" index="i">
<button class="pageBtn btn btn-sm 
<cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
data-page="#i#">#i#</button>
</cfloop>
</cfoutput>
</div>

</div>

<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>

<script>
$(document).ready(function(){

function showMsg(res){
$("#ajaxMessage").html(
'<div id="msgBox" class="alert alert-'+
(res.status==="success"?"success":"danger")+
'">'+res.message+'</div>'
);
setTimeout(()=>$("#msgBox").fadeOut(),3000);
}

// ADD FORM
$("#showAddForm").click(()=>$("#addUserForm").slideDown());
$("#cancelAdd").click(()=>$("#addUserForm").slideUp());

// CREATE
$("#createUserForm").submit(function(e){
e.preventDefault();

$.post("../../controllers/UserController.cfm",
$(this).serialize(),
function(res){
showMsg(res);
if(res.status==="success"){
$("#addUserForm").slideUp();
}
},"json");
});

// EDIT
$(document).on("click",".editBtn",function(){

let btn=$(this);
let row=btn.closest("tr");

$(".editRow").remove();

row.after(`
<tr class="editRow">
<td colspan="5">

<form class="updateForm">

<input type="hidden" name="action" value="update">
<input type="hidden" name="id" value="${btn.data("id")}">

<div class="row g-2">

<div class="col-12 col-md-4">
<input name="first_name" value="${btn.data("first")}" class="form-control">
</div>

<div class="col-12 col-md-4">
<input name="last_name" value="${btn.data("last")}" class="form-control">
</div>

<div class="col-12 col-md-4">
<input name="email" value="${btn.data("email")}" class="form-control">
</div>

<div class="col-12 d-flex gap-2">
<button class="btn btn-success btn-sm w-100">Save</button>
<button type="button" class="cancelEdit btn btn-secondary btn-sm w-100">Cancel</button>
</div>

</div>

</form>

</td>
</tr>
`);
});

$(document).on("click",".cancelEdit",()=>$(".editRow").remove());

// UPDATE
$(document).on("submit",".updateForm",function(e){
e.preventDefault();

$.post("../../controllers/UserController.cfm",
$(this).serialize(),
function(res){
showMsg(res);
if(res.status==="success"){
$(".editRow").remove();
}
},"json");
});

// DELETE
$(document).on("click",".deleteBtn",function(){

let id=$(this).data("id");

if(confirm("Delete?")){
$.get("../../controllers/UserController.cfm",
{action:"delete",id:id},
function(res){
showMsg(res);
$("#row_"+id).remove();
},"json");
}
});

// SEARCH
$("#searchForm").submit(function(e){
e.preventDefault();

$.get("../../controllers/UserController.cfm",
"action=search&"+$(this).serialize(),
function(res){
$("#tableBody").html(res);
});
});

// PAGINATION
$(document).on("click",".pageBtn",function(){

let page=$(this).data("page");

$.get("../../controllers/UserController.cfm",
"action=search&p="+page+"&"+$("#searchForm").serialize(),
function(res){
$("#tableBody").html(res);
});
});

});
</script>