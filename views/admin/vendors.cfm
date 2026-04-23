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

<div class="container-fluid mt-4">

<h4>Vendor Management</h4>

<form id="vendorSearchForm" class="mb-3">

    <input type="hidden" name="sort" id="sortValue" value="">

    <div class="row g-2">

        <div class="col-12 col-md-4">
            <input type="text" name="search" value="#url.search#"
            class="form-control" placeholder="Search vendors">
        </div>

        <div class="col-12 col-md-4">
            <div class="dropdown w-100">
                <button class="btn btn-outline-secondary dropdown-toggle w-100 text-start"
                        type="button"
                        id="sortDropdown"
                        data-bs-toggle="dropdown"
                        aria-expanded="false">
                    Sort
                </button>
                <ul class="dropdown-menu w-100" aria-labelledby="sortDropdown">
                    <li><a class="dropdown-item sort-option" href="#" data-value="">Sort</a></li>
                    <li><a class="dropdown-item sort-option" href="#" data-value="a_z">A-Z</a></li>
                    <li><a class="dropdown-item sort-option" href="#" data-value="z_a">Z-A</a></li>
                </ul>
            </div>
        </div>

        <div class="col-12 col-md-4 d-grid">
            <button class="btn btn-primary">Search</button>
        </div>

    </div>
</form>

<div class="table-responsive">
<table class="table table-bordered align-middle">

<thead class="table-dark">
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
</div>

<div class="d-flex justify-content-center flex-wrap gap-2 mt-3">
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
$(document).ready(function(){

    // SORT OPTION CLICK
    $(document).on("click", ".sort-option", function(e){
        e.preventDefault();
        $("#sortValue").val($(this).data("value"));
        $("#sortDropdown").text($(this).text());
    });

    // SEARCH
    $(document).on("submit","#vendorSearchForm",function(e){
        e.preventDefault();
        $.get("../../controllers/UserController.cfm",
        "action=vendorSearch&"+$(this).serialize(),
        function(res){
            $("#vendorTable").html(res);
        });
    });

    // PAGINATION
    $(document).on("click",".pageBtn",function(){
        let page=$(this).data("page");
        $.get("../../controllers/UserController.cfm",
        "action=vendorSearch&p="+page+"&"+$("#vendorSearchForm").serialize(),
        function(res){
            $("#vendorTable").html(res);
        });
    });

});
</script>