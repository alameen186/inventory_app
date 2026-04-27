<cfif NOT structKeyExists(session,"role_id") OR session.role_id NEQ 1>
    <cfabort>
</cfif>

<cfset roleModel   = createObject("component","models.Role")>
<cfset limit       = 2>
<cfset groupSize   = 4>
<cfparam name="url.search" default="">
<cfparam name="url.sort"   default="">
<cfparam name="url.p"      default="1">

<cfset currentPage  = val(url.p) GT 0 ? val(url.p) : 1>
<cfset roles        = roleModel.getAllRoles(search=trim(url.search), sort=url.sort, page=currentPage, limit=limit)>
<cfset totalRecords = roleModel.getRoleCount(search=trim(url.search))>
<cfset totalPages   = ceiling(totalRecords / limit)>
<cfset pageGroup    = ceiling(currentPage / groupSize)>
<cfset startPage    = (pageGroup - 1) * groupSize + 1>
<cfset endPage      = min(startPage + groupSize - 1, totalPages)>

<div class="container-fluid mt-4">

    <h4 class="mb-3">Role Management</h4>
    <div id="ajaxMessage"></div>

    <!--- SEARCH FORM --->
    <form id="searchForm" class="mb-3">
        <input type="hidden" name="sort" id="sortValue"
               value="<cfoutput>#encodeForHTMLAttribute(url.sort)#</cfoutput>">
        <div class="row g-2">

            <div class="col-12 col-md-4">
                <input type="text" name="search"
                       value="<cfoutput>#encodeForHTML(url.search)#</cfoutput>"
                       class="form-control" placeholder="Search roles">
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

            <div class="col-12 col-md-4 d-grid">
                <button class="btn btn-primary">Apply</button>
            </div>

        </div>
    </form>

    <!--- ADD ROLE BUTTON  --->
    <button id="showAddForm" class="btn btn-success mb-3">+ Add Role</button>

    <div id="addRoleForm" style="display:none;" class="card p-3 mb-3">
        <h6 class="mb-3">New Role</h6>
        <div class="row g-2">
            <div class="col-12 col-md-5">
                <input id="cr_name" class="form-control" placeholder="Role Name (3 - 20 chars)">
            </div>
            <div class="col-12 col-md-5">
                <input id="cr_description" class="form-control" placeholder="Description (5 - 100 chars)">
            </div>
            <div class="col-12 col-md-2 d-flex gap-2">
                <button id="submitCreate" class="btn btn-success w-100">Create</button>
                <button id="cancelAdd"    class="btn btn-secondary w-100">Cancel</button>
            </div>
        </div>
    </div>

    <!--- TABLE --->
    <div class="table-responsive">
        <table class="table table-bordered align-middle">
            <thead class="table-dark">
                <tr>
                    <th>ID</th>
                    <th>Name</th>
                    <th>Description</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody id="tableBody">
                <cfif roles.recordCount EQ 0>
                    <tr><td colspan="4" class="text-center">No roles found.</td></tr>
                <cfelse>
                    <cfoutput query="roles">
                    <tr id="roleRow_#id#">
                        <td>#id#</td>
                        <td>#encodeForHTML(role_name)#</td>
                        <td>#encodeForHTML(description)#</td>
                        <td>
                            <div class="d-flex flex-wrap gap-1">
                                <button class="btn btn-warning btn-sm editBtn"
                                    data-id="#id#"
                                    data-name="#encodeForHTMLAttribute(role_name)#"
                                    data-desc="#encodeForHTMLAttribute(description)#">Edit</button>
                                <button class="btn btn-danger btn-sm deleteBtn"
                                    data-id="#id#">Delete</button>
                            </div>
                        </td>
                    </tr>
                    </cfoutput>
                </cfif>
            </tbody>
        </table>
    </div>

    <!--- GROUPED PAGINATION --->
    <div id="paginationBox" class="d-flex justify-content-center flex-wrap gap-2 mt-3">
    <cfoutput>
    <cfif totalPages GT 1>
        <cfif startPage GT 1>
            <button class="btn btn-outline-primary btn-sm pageBtn"
                    data-page="#startPage - 1#">&laquo; Prev</button>
        </cfif>
        <cfloop from="#startPage#" to="#endPage#" index="i">
            <button class="btn btn-sm pageBtn
                <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
                data-page="#i#">#i#</button>
        </cfloop>
        <cfif endPage LT totalPages>
            <button class="btn btn-outline-primary btn-sm pageBtn"
                    data-page="#endPage + 1#">Next &raquo;</button>
        </cfif>
    </cfif>
    </cfoutput>
    </div>

</div>

<script>
$(document).ready(function(){

    const CTRL = "../../controllers/RoleController.cfc";

    //   HELPERS  
    function showMsg(res){
        const cls = res.status === "success" ? "success" : "danger";
        $("#ajaxMessage").html(
            `<div class="alert alert-${cls}">${res.message}</div>`
        );
        setTimeout(() => $("#ajaxMessage .alert").fadeOut(), 3000);
    }

    function loadRoles(page){
        $.get(CTRL, {
            method : "searchRoles",
            search : $("#searchForm [name=search]").val(),
            sort   : $("#sortValue").val(),
            p      : page || 1
        }, function(res){
            if(res.status === "success"){
                $("#tableBody").html(res.html);
                $("#paginationBox").html(res.pagination);
            } else {
                showMsg(res);
            }
        }, "json");
    }

    //   SORT DROPDOWN  
    $(document).on("click", ".sort-option", function(e){
        e.preventDefault();
        $("#sortValue").val($(this).data("value"));
        $("#sortDropdown").text($(this).text());
    });

    //    SEARCH  
    $("#searchForm").submit(function(e){
        e.preventDefault();
        loadRoles(1);
    });

    //   PAGINATION  
    $(document).on("click", ".pageBtn", function(){
        loadRoles($(this).data("page"));
    });

    //   ADD FORM TOGGLE  
    $("#showAddForm").click(() => $("#addRoleForm").slideDown());
    $("#cancelAdd").click(function(){
        $("#addRoleForm").slideUp();
        $("#cr_name, #cr_description").val("");
    });

    //   CREATE ROLE 
    $("#submitCreate").click(function(){
        $.post(CTRL + "?method=createRole", {
            name        : $("#cr_name").val(),
            description : $("#cr_description").val()
        }, function(res){
            showMsg(res);
            if(res.status === "success"){
                $("#addRoleForm").slideUp();
                $("#cr_name, #cr_description").val("");
                loadRoles(1);
            }
        }, "json");
    });

    //   EDIT ROW  
    $(document).on("click", ".editBtn", function(){
        const btn = $(this);
        $(".editRow").remove();
        btn.closest("tr").after(`
            <tr class="editRow">
                <td colspan="4">
                    <div class="row g-2 p-2">
                        <input type="hidden" class="er_id"   value="${btn.data("id")}">
                        <div class="col-12 col-md-5">
                            <input class="form-control er_name"
                                   value="${btn.data("name")}"
                                   placeholder="Role Name">
                        </div>
                        <div class="col-12 col-md-5">
                            <input class="form-control er_desc"
                                   value="${btn.data("desc")}"
                                   placeholder="Description">
                        </div>
                        <div class="col-12 col-md-2 d-flex gap-2">
                            <button class="btn btn-success btn-sm saveEdit w-100">Save</button>
                            <button class="btn btn-secondary btn-sm cancelEdit w-100">Cancel</button>
                        </div>
                    </div>
                </td>
            </tr>`);
    });

    $(document).on("click", ".cancelEdit", () => $(".editRow").remove());

    //   UPDATE ROLE  
    $(document).on("click", ".saveEdit", function(){
        const row = $(this).closest("tr");
        $.post(CTRL + "?method=updateRole", {
            id          : row.find(".er_id").val(),
            name        : row.find(".er_name").val(),
            description : row.find(".er_desc").val()
        }, function(res){
            showMsg(res);
            if(res.status === "success"){
                $(".editRow").remove();
                loadRoles(1);
            }
        }, "json");
    });

    //  DELETE ROLE 
    $(document).on("click", ".deleteBtn", function(){
        const id = $(this).data("id");
        if(!confirm("Delete this role?")) return;
        $.get(CTRL, { method:"deleteRole", id:id }, function(res){
            showMsg(res);
            if(res.status === "success"){
                $("#roleRow_" + id).remove();
            }
        }, "json");
    });

});
</script>