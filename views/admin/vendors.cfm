<cfif NOT structKeyExists(session,"role_id") OR session.role_id NEQ 1>
    <cfabort>
</cfif>

<cfset userModel   = createObject("component","models.User")>
<cfset limit       = 5>
<cfset groupSize   = 4>
<cfparam name="url.search" default="">
<cfparam name="url.sort"   default="">
<cfparam name="url.p"      default="1">

<cfset currentPage  = val(url.p) GT 0 ? val(url.p) : 1>
<cfset vendors      = userModel.getAllVendors(search=trim(url.search), sort=url.sort, page=currentPage, limit=limit)>
<cfset totalRecords = userModel.getVendorCount(search=trim(url.search))>
<cfset totalPages   = ceiling(totalRecords / limit)>
<cfset pageGroup    = ceiling(currentPage / groupSize)>
<cfset startPage    = (pageGroup - 1) * groupSize + 1>
<cfset endPage      = min(startPage + groupSize - 1, totalPages)>

<div class="container-fluid mt-4">

    <h4 class="mb-3">Vendor Management</h4>
    <div id="ajaxMessage"></div>

    <form id="vendorSearchForm" class="mb-3">
        <input type="hidden" name="sort" id="sortValue" value="<cfoutput>#encodeForHTMLAttribute(url.sort)#</cfoutput>">
        <div class="row g-2">

            <div class="col-12 col-md-4">
                <input type="text" name="search"
                       value="<cfoutput>#encodeForHTML(url.search)#</cfoutput>"
                       class="form-control" placeholder="Search vendors">
            </div>

            <div class="col-12 col-md-4">
                <div class="dropdown w-100">
                    <button class="btn btn-outline-secondary dropdown-toggle w-100 text-start"
                            type="button" id="sortDropdown"
                            data-bs-toggle="dropdown" aria-expanded="false">
                        <cfoutput>
                        <cfif url.sort EQ "a_z">A-Z
                        <cfelseif url.sort EQ "z_a">Z-A
                        <cfelse>Sort</cfif>
                        </cfoutput>
                    </button>
                    <ul class="dropdown-menu w-100" aria-labelledby="sortDropdown">
                        <li><a class="dropdown-item sort-option" href="#" data-value="">Default</a></li>
                        <li><a class="dropdown-item sort-option" href="#" data-value="a_z">A-Z</a></li>
                        <li><a class="dropdown-item sort-option" href="#" data-value="z_a">Z-A</a></li>
                    </ul>
                </div>
            </div>

            <div class="col-12 col-md-2 d-grid">
                <button class="btn btn-primary">Search</button>
            </div>
            <div class="col-12 col-md-2 d-grid ">
            <button type="button" id="clearBtn" class="btn btn-secondary">
                Clear 
            </button>
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
                <cfif vendors.recordCount EQ 0>
                    <tr><td colspan="5" class="text-center">No vendors found.</td></tr>
                <cfelse>
                    <cfoutput query="vendors">
                    <tr id="vrow_#id#">
                        <td>#id#</td>
                        <td>#encodeForHTML(first_name)# #encodeForHTML(last_name)#</td>
                        <td class="text-break">#encodeForHTML(email)#</td>
                        <td>#role_name#</td>
                        <td>
                            <button class="btn btn-danger btn-sm deleteVendorBtn"
                                    data-id="#id#">Delete</button>
                        </td>
                    </tr>
                    </cfoutput>
                </cfif>
            </tbody>
        </table>
    </div>

    <!-- GROUPED PAGINATION  -->
    <div id="vendorPaginationBox" class="d-flex justify-content-center flex-wrap gap-2 mt-3">
    <cfoutput>
    <cfif totalPages GT 1>
        <cfif startPage GT 1>
            <button class="btn btn-outline-primary btn-sm vendorPageBtn"
                    data-page="#startPage - 1#">&laquo; Prev</button>
        </cfif>
        <cfloop from="#startPage#" to="#endPage#" index="i">
            <button class="btn btn-sm vendorPageBtn
                <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
                data-page="#i#">#i#</button>
        </cfloop>
        <cfif endPage LT totalPages>
            <button class="btn btn-outline-primary btn-sm vendorPageBtn"
                    data-page="#endPage + 1#">Next &raquo;</button>
        </cfif>
    </cfif>
    </cfoutput>
    </div>

</div>

<script>
$(document).ready(function(){

    const CTRL = "../../controllers/UserController.cfc";

    //  HELPERS 
    function showMsg(res){
        const cls = res.status === "success" ? "success" : "danger";
        $("#ajaxMessage").html(
            `<div class="alert alert-${cls}">${res.message}</div>`
        );
        setTimeout(() => $("#ajaxMessage .alert").fadeOut(), 3000);
    }

    function loadVendors(page){
        $.get(CTRL, {
            method : "searchVendors",
            search : $("#vendorSearchForm [name=search]").val(),
            sort   : $("#sortValue").val(),
            p      : page || 1
        }, function(res){
            if(res.status === "success"){
                $("#vendorTable").html(res.html);
                $("#vendorPaginationBox").html(res.pagination);
            } else {
                showMsg(res);
            }
        }, "json");
    }

    //  SORT DROPDOWN 
    $(document).on("click", ".sort-option", function(e){
        e.preventDefault();
        $("#sortValue").val($(this).data("value"));
        $("#sortDropdown").text($(this).text());
    });

    //  SEARCH 
    $("#vendorSearchForm").submit(function(e){
        e.preventDefault();
        loadVendors(1);
    });

    //  PAGINATION 
    $(document).on("click", ".vendorPageBtn", function(){
        loadVendors($(this).data("page"));
    });

    //  DELETE VENDOR 
    $(document).on("click", ".deleteVendorBtn", function(){
        const id = $(this).data("id");
        if(!confirm("Are you sure you want to delete this vendor?")) return;
        $.get(CTRL, { method:"deleteVendor", id:id }, function(res){
            showMsg(res);
            if(res.status === "success"){
                $("#vrow_" + id).remove();
            }
        }, "json");
    });

    $("#clearBtn").click(function(){
        $("#vendorSearchForm")[0].reset();
        doSearch(1);
    });


});
</script>