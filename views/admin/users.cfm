<cfif NOT structKeyExists(session,"role_id") OR session.role_id NEQ 1>
    <cfabort>
</cfif>

<cfset userModel   = createObject("component","models.User")>
<cfset limit       = 2>
<cfset groupSize   = 4>
<cfparam name="url.search" default="">
<cfparam name="url.sort"   default="">
<cfparam name="url.p"      default="1">

<cfset currentPage  = val(url.p) GT 0 ? val(url.p) : 1>
<cfset users        = userModel.getAllUsers(search=trim(url.search), sort=url.sort, page=currentPage, limit=limit)>
<cfset totalRecords = userModel.getUserCount(search=trim(url.search))>
<cfset totalPages   = ceiling(totalRecords / limit)>
<cfset pageGroup    = ceiling(currentPage / groupSize)>
<cfset startPage    = (pageGroup - 1) * groupSize + 1>
<cfset endPage      = min(startPage + groupSize - 1, totalPages)>

<div class="container-fluid mt-4">

    <h4 class="mb-3">Users Management</h4>
    <div id="ajaxMessage"></div>

    <cfoutput>
    <form id="searchForm" class="mb-3">
        <div class="row g-2">
            <div class="col-12 col-md-4">
                <input type="text" name="search" value="#encodeForHTML(url.search)#"
                       class="form-control" placeholder="Search">
            </div>
            <div class="col-12 col-md-4">
                <select name="sort" class="form-control">
                    <option value="">Sort</option>
                    <option value="a_z" <cfif url.sort EQ "a_z">selected</cfif>>A–Z</option>
                    <option value="z_a" <cfif url.sort EQ "z_a">selected</cfif>>Z–A</option>
                </select>
            </div>
            <div class="col-12 col-md-4 d-grid">
                <button class="btn btn-primary">Apply</button>
            </div>
        </div>
    </form>
    </cfoutput>

    <button id="showAddForm" class="btn btn-primary mb-3">Add User</button>

    <div id="addUserForm" style="display:none;" class="card p-3 mb-3">
        <div id="createUserForm">
            <div class="row g-2">
                <div class="col-12 col-md-6">
                    <input id="cu_first_name" class="form-control" placeholder="First Name">
                </div>
                <div class="col-12 col-md-6">
                    <input id="cu_last_name" class="form-control" placeholder="Last Name">
                </div>
                <div class="col-12">
                    <input id="cu_email" class="form-control" placeholder="Email">
                </div>
                <div class="col-12 col-md-6">
                    <input id="cu_password" type="password" class="form-control" placeholder="Password">
                </div>
                <div class="col-12 col-md-6">
                    <input id="cu_confirm" type="password" class="form-control" placeholder="Confirm Password">
                </div>
                <div class="col-12">
                    <select id="cu_role_id" class="form-control">
                        <option value="2">Customer</option>
                        <option value="3">Manager</option>
                    </select>
                </div>
                <div class="col-12 d-flex gap-2">
                    <button id="submitCreate" class="btn btn-success w-100">Create</button>
                    <button type="button" id="cancelAdd" class="btn btn-secondary w-100">Cancel</button>
                </div>
            </div>
        </div>
    </div>

    <div class="table-responsive">
        <table class="table table-bordered align-middle">
            <thead class="table-dark">
                <tr>
                    <th>ID</th><th>Name</th><th>Email</th><th>Role</th><th>Actions</th>
                </tr>
            </thead>
            <tbody id="tableBody">

<cfif users.recordCount EQ 0>
    <tr>
        <td colspan="5" class="text-center">No users found.</td>
    </tr>
<cfelse>

    <cfoutput query="users">
    <tr id="row_#id#">
        <td>#id#</td>
        <td>#encodeForHTML(first_name)# #encodeForHTML(last_name)#</td>
        <td class="text-break">#encodeForHTML(email)#</td>
        <td>#role_name#</td>

        <td class="d-flex flex-wrap gap-1">
            <cfif role_id EQ 1>
                <span class="badge bg-secondary">Action Restricted</span>
            <cfelse>
                <button class="btn btn-warning btn-sm editBtn"
                    data-id="#id#"
                    data-first="#encodeForHTMLAttribute(first_name)#"
                    data-last="#encodeForHTMLAttribute(last_name)#"
                    data-email="#encodeForHTMLAttribute(email)#">
                    Edit
                </button>

                <button class="btn btn-danger btn-sm deleteBtn"
                    data-id="#id#">
                    Delete
                </button>
            </cfif>
        </td>

    </tr>
    </cfoutput>

</cfif>

</tbody>
        </table>
    </div>

    <!-- GROUPED PAGINATION (initial render) -->
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

    const CTRL = "../../controllers/UserController.cfc";

    // ── HELPERS ──────────────────────────────────────────────
    function showMsg(res){
        const cls = res.status === "success" ? "success" : "danger";
        $("#ajaxMessage").html(
            `<div class="alert alert-${cls}">${res.message}</div>`
        );
        setTimeout(() => $("#ajaxMessage .alert").fadeOut(), 3000);
    }

    function loadUsers(page){
        const params = {
            method : "searchUsers",
            search : $("#searchForm [name=search]").val(),
            sort   : $("#searchForm [name=sort]").val(),
            p      : page || 1
        };
        $.get(CTRL, params, function(res){
            if(res.status === "success"){
                $("#tableBody").html(res.html);
                $("#paginationBox").html(res.pagination);
            } else {
                showMsg(res);
            }
        }, "json");
    }

    // ── SEARCH ────────────────────────────────────────────────
    $("#searchForm").submit(function(e){
        e.preventDefault();
        loadUsers(1);
    });

    // ── PAGINATION ────────────────────────────────────────────
    $(document).on("click", ".pageBtn", function(){
        loadUsers($(this).data("page"));
    });

    // ── ADD FORM TOGGLE ───────────────────────────────────────
    $("#showAddForm").click(() => $("#addUserForm").slideDown());
    $("#cancelAdd").click(() => $("#addUserForm").slideUp());

    // ── CREATE USER ───────────────────────────────────────────
    $("#submitCreate").click(function(){
        $.post(CTRL + "?method=createUser", {
            first_name : $("#cu_first_name").val(),
            last_name  : $("#cu_last_name").val(),
            email      : $("#cu_email").val(),
            password   : $("#cu_password").val(),
            confirm    : $("#cu_confirm").val(),
            role_id    : $("#cu_role_id").val()
        }, function(res){
            showMsg(res);
            if(res.status === "success"){
                $("#addUserForm").slideUp();
                // clear fields
                $("#cu_first_name,#cu_last_name,#cu_email,#cu_password,#cu_confirm").val("");
                loadUsers(1);
            }
        }, "json");
    });

    // ── EDIT ROW ──────────────────────────────────────────────
    $(document).on("click", ".editBtn", function(){
        const btn = $(this);
        $(".editRow").remove();
        btn.closest("tr").after(`
            <tr class="editRow">
                <td colspan="5">
                    <div class="row g-2 p-2">
                        <input type="hidden" class="eu_id"    value="${btn.data("id")}">
                        <div class="col-12 col-md-4">
                            <input class="form-control eu_first" value="${btn.data("first")}">
                        </div>
                        <div class="col-12 col-md-4">
                            <input class="form-control eu_last"  value="${btn.data("last")}">
                        </div>
                        <div class="col-12 col-md-4">
                            <input class="form-control eu_email" value="${btn.data("email")}">
                        </div>
                        <div class="col-12 d-flex gap-2">
                            <button class="btn btn-success btn-sm saveEdit w-100">Save</button>
                            <button class="btn btn-secondary btn-sm cancelEdit w-100">Cancel</button>
                        </div>
                    </div>
                </td>
            </tr>`);
    });

    $(document).on("click", ".cancelEdit", () => $(".editRow").remove());

    // ── UPDATE USER ───────────────────────────────────────────
    $(document).on("click", ".saveEdit", function(){
        const row = $(this).closest("tr");
        $.post(CTRL + "?method=updateUser", {
            id         : row.find(".eu_id").val(),
            first_name : row.find(".eu_first").val(),
            last_name  : row.find(".eu_last").val(),
            email      : row.find(".eu_email").val()
        }, function(res){
            showMsg(res);
            if(res.status === "success"){
                $(".editRow").remove();
                loadUsers(1);
            }
        }, "json");
    });

    // ── DELETE USER ───────────────────────────────────────────
    $(document).on("click", ".deleteBtn", function(){
        const id = $(this).data("id");
        if(!confirm("Are you sure you want to delete this user?")) return;
        $.get(CTRL, { method:"deleteUser", id:id }, function(res){
            showMsg(res);
            if(res.status === "success"){
                $("#row_" + id).remove();
            }
        }, "json");
    });

});
</script>