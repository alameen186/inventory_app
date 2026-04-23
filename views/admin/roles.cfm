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

<cfset totalRecords = roleModel.getRoleCount(search = trim(url.search))>
<cfset totalPages = ceiling(totalRecords / limit)>

<div class="container-fluid mt-4">

    <h4>Role Management</h4>

    <form id="searchForm" class="mb-3">

        <div class="row g-2">

            <div class="col-12 col-md-4">
                <input type="text" name="search" class="form-control" placeholder="Search role">
            </div>

            <div class="col-12 col-md-4">
                <!-- Hidden input carries the actual value on submit -->
                <input type="hidden" name="sort" id="sortValue" value="">

            
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
                <button class="btn btn-primary">Apply</button>
            </div>

        </div>

    </form>

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
                <cfoutput query="roles">
                <tr id="roleRow_#id#">
                    <td>#id#</td>
                    <td>#role_name#</td>
                    <td>#description#</td>
                    <td>
                        <div class="d-flex flex-wrap gap-1">
                            <button class="btn btn-warning btn-sm editBtn"
                                data-id="#id#"
                                data-name="#role_name#"
                                data-desc="#description#">Edit</button>
                            <button class="btn btn-danger btn-sm deleteBtn"
                                data-id="#id#">Delete</button>
                        </div>
                    </td>
                </tr>
                </cfoutput>
            </tbody>
        </table>
    </div>

    <div class="d-flex justify-content-center flex-wrap gap-2 mt-3">
        <cfoutput>
        <cfloop from="1" to="#totalPages#" index="i">
            <button class="btn btn-sm pageBtn <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
                data-page="#i#">#i#</button>
        </cfloop>
        </cfoutput>
    </div>

</div>

<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>

<script>
$(document).ready(function(){

    // SORT DROPDOWN OPTION CLICK
    $(document).on("click", ".sort-option", function(e){
        e.preventDefault();
        $("#sortValue").val($(this).data("value"));
        $("#sortDropdown").text($(this).text());
    });

    function showMsg(res){
        $("#ajaxMessage").html(
            '<div id="msgBox" class="alert alert-' +
            (res.status==="success" ? "success" : "danger") +
            '">' + res.message + '</div>'
        );
        setTimeout(()=>$("#msgBox").fadeOut(), 3000);
    }

    // DELETE
    $(document).on("click", ".deleteBtn", function(){
        let id = $(this).data("id");
        if(confirm("Delete this role?")){
            $.get("../../controllers/RoleController.cfm",
                {action:"delete", id:id},
                function(res){
                    showMsg(res);
                    $("#roleRow_"+id).remove();
                }, "json");
        }
    });

    // EDIT OPEN
    $(document).on("click", ".editBtn", function(){
        let btn = $(this);
        let row = btn.closest("tr");
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
    $(document).on("click", ".cancelEdit", function(){
        $(".editRow").remove();
    });

    // UPDATE
    $(document).on("submit", ".updateForm", function(e){
        e.preventDefault();
        $.post("../../controllers/RoleController.cfm",
            $(this).serialize(),
            function(res){
                showMsg(res);
                if(res.status === "success"){
                    $(".editRow").remove();
                }
            }, "json");
    });

    // SEARCH
    $("#searchForm").submit(function(e){
        e.preventDefault();
        $.get("../../controllers/RoleController.cfm",
            "action=search&" + $(this).serialize(),
            function(res){
                $("#tableBody").html(res);
            });
    });

    // PAGINATION
    $(document).on("click", ".pageBtn", function(){
        let page = $(this).data("page");
        $.get("../../controllers/RoleController.cfm",
            "action=search&p=" + page + "&" + $("#searchForm").serialize(),
            function(res){
                $("#tableBody").html(res);
            });
    });

});
</script>