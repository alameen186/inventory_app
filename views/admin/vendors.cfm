<cfset userModel = createObject("component","models.User")>

<cfparam name="url.search" default="">
<cfparam name="url.sort" default="">
<cfparam name="url.p" default="1">

<cfset currentPage = val(url.p)>
<cfif currentPage LT 1><cfset currentPage = 1></cfif>

<cfset limit = 5>

<cfset vendors = userModel.getAllVendors(
    search = trim(url.search),
    sort = url.sort,
    page = currentPage,
    limit = limit
)>

<cfset totalRecords = userModel.getVendorCount(search=trim(url.search))>
<cfset totalPages = ceiling(totalRecords / limit)>

<div class="container mt-4">

<h3>Vendor Management</h3>

<!-- SEARCH -->
<form id="vendorSearchForm" class="mb-3">

<div class="row g-2">

<div class="col-md-4">
<cfoutput>
<input type="text" name="search"
value="#url.search#"
placeholder="Search vendors..."
class="form-control">
</cfoutput>
</div>

<div class="col-md-3">
<select name="sort" class="form-select">
<option value="">Sort</option>
<option value="a_z">A-Z</option>
<option value="z_a">Z-A</option>
</select>
</div>

<div class="col-md-2">
<button class="btn btn-primary">Search</button>
</div>

</div>

</form>

<!-- TABLE -->
<table class="table table-bordered">

<thead>
<tr>
<th>ID</th>
<th>Name</th>
<th>Email</th>
<th>Role</th>
<th>Action</th>
</tr>
</thead>

<tbody id="vendorTable">

<cfoutput query="vendors">
<tr>
<td>#id#</td>
<td>#first_name# #last_name#</td>
<td>#email#</td>
<td>#role_name#</td>

<td>
<button class="btn btn-danger btn-sm deleteBtn" data-id="#id#">Delete</button>
</td>
</tr>
</cfoutput>

</tbody>

</table>

<!-- PAGINATION -->
<div>
<cfoutput>
<cfloop from="1" to="#totalPages#" index="i">
<button class="btn btn-sm pageBtn 
<cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
data-page="#i#">#i#</button>
</cfloop>
</cfoutput>
</div>

</div>

<script>
$(document).on("submit","#vendorSearchForm",function(e){
    e.preventDefault();

    $.get("../../controllers/UserController.cfm",
    "action=vendorSearch&"+$(this).serialize(),
    function(res){
        $("#vendorTable").html(res);
    });
});

$(document).on("click",".pageBtn",function(){

    let page=$(this).data("page");

    $.get("../../controllers/UserController.cfm",
    "action=vendorSearch&p="+page+"&"+$("#vendorSearchForm").serialize(),
    function(res){
        $("#vendorTable").html(res);
    });

});
</script>