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

<div class="container-fluid mt-4">
<h3>Category Management</h3>

<div id="ajaxMessage"></div>

<button class="btn btn-primary mb-3" onclick="$('#addForm').toggle()">Add Category</button>

<div id="addForm" style="display:none;">
    <form id="createCategoryForm" class="mb-3">
        <input type="hidden" name="action" value="add">
        <div class="row g-2">
            <div class="col-12 col-md-4">
                <input type="text" name="category_name" class="form-control" placeholder="Category Name" required>
            </div>
            <div class="col-12 col-md-4">
                <input type="text" name="description" class="form-control" placeholder="Description" required>
            </div>
            <div class="col-12 col-md-2 d-grid">
                <button class="btn btn-success">Add</button>
            </div>
            <div class="col-12 col-md-2 d-grid">
                    <button type="button" class="btn btn-secondary w-100"
                        onclick="document.getElementById('addForm').style.display='none'">
                        Cancel
                    </button>
                </div>
        </div>
    </form>
</div>

<!-- SEARCH -->
<form id="searchForm" class="mt-3 mb-3">
    <input type="hidden" name="sort" id="sortValue" value="<cfoutput>#url.sort#</cfoutput>">
    <div class="row g-2">
        <div class="col-12 col-md-4">
            <cfoutput>
            <input type="text" placeholder="Search category..." name="search"
                value="#url.search#" class="form-control">
            </cfoutput>
        </div>
        <div class="col-12 col-md-4">
            <div class="dropdown w-100">
                <button class="btn btn-outline-secondary dropdown-toggle w-100 text-start"
                        type="button" id="sortDropdown"
                        data-bs-toggle="dropdown" aria-expanded="false">
                    <cfif url.sort EQ "a_z">A-Z
                    <cfelseif url.sort EQ "z_a">Z-A
                    <cfelse>Sort
                    </cfif>
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
                    <span class="text-success">Active</span>
                <cfelse>
                    <span class="text-warning">Blocked</span>
                </cfif>
            </td>
            <td>
                <div class="d-flex flex-wrap gap-1">
                    <button class="editBtn btn btn-warning btn-sm" data-id="#id#">Edit</button>
                    <button class="toggleStatusBtn btn btn-sm #iif(is_active EQ 1, de('btn-danger'), de('btn-success'))#"
                        data-id="#id#" data-status="#is_active#">
                        <cfif is_active EQ 1>Block<cfelse>Unblock</cfif>
                    </button>
                </div>
            </td>
        </tr>

        <tr id="editCategoryRow_#id#" style="display:none;">
            <td>#id#</td>
            <td><input value="#category_name#" class="form-control name"></td>
            <td><input value="#description#" class="form-control desc"></td>
            <td>
                <cfif is_active EQ 1>
                    <span class="text-success">Active</span>
                <cfelse>
                    <span class="text-warning">Blocked</span>
                </cfif>
            </td>
            <td>
                <div class="d-flex flex-wrap gap-1">
                    <button class="saveEdit btn btn-success btn-sm" data-id="#id#">Save</button>
                    <button class="cancelEdit btn btn-secondary btn-sm" data-id="#id#">Cancel</button>
                </div>
            </td>
        </tr>

    </cfoutput>
    </tbody>
</table>
</div>

<!-- PAGINATION -->
<cfoutput>
<div id="paginationArea" class="d-flex justify-content-center flex-wrap gap-2 mt-3">
    <cfif totalPages GT 0>
        <cfloop from="1" to="#totalPages#" index="i">
            <button class="btn btn-sm pageBtn <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
                data-page="#i#">#i#</button>
        </cfloop>
    </cfif>
</div>
</cfoutput>

</div>

<script>
$(document).ready(function(){

    // SORT DROPDOWN
    $(document).on("click", ".sort-option", function(e){
        e.preventDefault();
        $("#sortValue").val($(this).data("value"));
        $("#sortDropdown").text($(this).text());
    });

    function showMessage(res){
        $("#ajaxMessage").html(
            '<div id="msgBox" class="alert alert-'+
            (res.status==="success"?"success":"danger")+
            '">' + res.message + '</div>'
        );
        setTimeout(function(){ $("#msgBox").fadeOut(); }, 5000);
    }

    // ADD
    $("#createCategoryForm").submit(function(e){
        e.preventDefault();
        $.post("../../controllers/CategoryController.cfm",
            $(this).serialize(),
            function(res){
                showMessage(res);
                if(res.status==="success") location.reload();
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
            if(res.status !== "success") return;

            let updatedRow = `
            <tr id="categoryRow_${res.id}">
                <td>${res.id}</td>
                <td>${res.category_name}</td>
                <td>${res.description}</td>
                <td><span class="text-success">Active</span></td>
                <td>
                    <div class="d-flex flex-wrap gap-1">
                        <button class="editBtn btn btn-warning btn-sm" data-id="${res.id}">Edit</button>
                        <button class="toggleStatusBtn btn btn-danger btn-sm" data-id="${res.id}" data-status="1">Block</button>
                    </div>
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
            btn.removeClass("btn-danger btn-success")
               .addClass(newStatus == 1 ? "btn-danger" : "btn-success");

            $("#categoryRow_"+res.id+" td:nth-child(4)").html(
                newStatus == 1
                ? '<span class="text-success">Active</span>'
                : '<span class="text-warning">Blocked</span>'
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
                updatePagination(1);
            });
    });

    // PAGINATION
    $(document).on("click",".pageBtn",function(){
        let page=$(this).data("page");

        // highlight active page btn
        $(".pageBtn").removeClass("btn-primary").addClass("btn-outline-primary");
        $(this).removeClass("btn-outline-primary").addClass("btn-primary");

        $.get("../../controllers/CategoryController.cfm",
            "action=search&p="+page+"&"+$("#searchForm").serialize(),
            function(res){
                $("#categoryTableBody").html(res);
            });
    });

    function updatePagination(activePage){
        $(".pageBtn").removeClass("btn-primary").addClass("btn-outline-primary");
        $(".pageBtn[data-page='"+activePage+"']").removeClass("btn-outline-primary").addClass("btn-primary");
    }

});
</script>