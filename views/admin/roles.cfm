<cfset roleModel = createObject("component", "models.Role")>

<cfparam name="url.search" default="">
<cfparam name="url.sort" default="">
<cfparam name="url.p" default="1">

<cfset currentPage = val(url.p)>
<cfif currentPage LT 1>
    <cfset currentPage = 1>
</cfif>

<cfset limit = 2>

<cfset roles = roleModel.getAllRoles(
    search = trim(url.search),
    sort = url.sort,
    page = currentPage,
    limit = limit
)>

<cfset totalRecords = roleModel.getRoleCount(
    search = trim(url.search)
)>

<cfset totalPages = ceiling(totalRecords / limit)>

<div class="container mt-4">

<h3>Role Management</h3>

<div id="ajaxMessage"></div>

<!-- SEARCH -->
<form id="searchForm" class="mb-3">
<cfoutput>
<input type="text" name="search" value="#url.search#"
class="form-control w-25 d-inline" placeholder="Search role">
</cfoutput>

<select name="sort" class="form-control w-25 d-inline">
<option value="">Sort</option>
<option value="a_z" <cfif url.sort EQ "a_z">selected</cfif>>A-Z</option>
<option value="z_a" <cfif url.sort EQ "z_a">selected</cfif>>Z-A</option>
</select>

<button type="submit" class="btn btn-primary btn-sm">Apply</button>

</form>

<!-- TABLE -->
<table class="table table-bordered">

<thead>
<tr>
<th>ID</th>
<th>Name</th>
<th>Description</th>
<th>Actions</th>
</tr>
</thead>

<tbody id="tableBody">

<cfoutput query="roles">
<tr id="roleRow_#id#">

<td>#id#</td>
<td>#role_name#</td>
<td>#description#</td>

<td>

<button class="btn btn-warning btn-sm editBtn"
data-id="#id#"
data-name="#role_name#"
data-desc="#description#">Edit</button>

<button class="btn btn-danger btn-sm deleteBtn"
data-id="#id#">Delete</button>

</td>

</tr>
</cfoutput>

</tbody>

</table>

<!-- PAGINATION -->
<div>
<cfoutput>
<cfloop from="1" to="#totalPages#" index="i">
<button class="pageBtn btn btn-sm <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
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
'<div id="msgBox" class="alert alert-' +
(res.status==="success"?"success":"danger") +
'">'+res.message+'</div>'
);
setTimeout(()=>$("#msgBox").fadeOut(),3000);
}

// DELETE
$(document).on("click",".deleteBtn",function(){

let id=$(this).data("id");

if(confirm("Delete this role?")){
$.get("../../controllers/RoleController.cfm",
{action:"delete",id:id},
function(res){
showMsg(res);
$("#roleRow_"+id).remove();
},"json");
}

});

// EDIT OPEN
$(document).on("click",".editBtn",function(){

let btn=$(this);
let row=btn.closest("tr");

$(".editRow").remove();

row.after(`
<tr class="editRow">
<td colspan="4">

<form class="updateForm">

<input type="hidden" name="action" value="update">
<input type="hidden" name="id" value="${btn.data("id")}">

<input name="name" value="${btn.data("name")}" class="form-control mb-1">
<input name="description" value="${btn.data("desc")}" class="form-control mb-1">

<button class="btn btn-success btn-sm">Save</button>
<button type="button" class="cancelEdit btn btn-secondary btn-sm">Cancel</button>

</form>

</td>
</tr>
`);

});

// CANCEL
$(document).on("click",".cancelEdit",function(){
$(".editRow").remove();
});

// UPDATE
$(document).on("submit",".updateForm",function(e){
e.preventDefault();

$.post("../../controllers/RoleController.cfm",
$(this).serialize(),
function(res){
showMsg(res);
if(res.status==="success"){
$(".editRow").remove();
}
},"json");

});

// SEARCH
$("#searchForm").submit(function(e){

e.preventDefault();

$.get("../../controllers/RoleController.cfm",
"action=search&"+$(this).serialize(),
function(res){
$("#tableBody").html(res);
});

});

// PAGINATION
$(document).on("click",".pageBtn",function(){

let page=$(this).data("page");

$.get("../../controllers/RoleController.cfm",
"action=search&p="+page+"&"+$("#searchForm").serialize(),
function(res){
$("#tableBody").html(res);
});

});

});
</script>