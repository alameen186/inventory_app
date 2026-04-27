<cfif NOT structKeyExists(session, "user_id")>
    <cfabort>
</cfif>

<div class="container-fluid mt-4">
<h3>Category Management</h3>

<div id="ajaxMessage"></div>

<button class="btn btn-primary mb-3" onclick="$('#addForm').toggle()">Add Category</button>

<div id="addForm" style="display:none;">
    <form id="createCategoryForm" class="mb-3">
        <div class="row g-2">
            <div class="col-12 col-md-4">
                <input type="text" name="category_name" class="form-control" placeholder="Category Name" required>
            </div>
            <div class="col-12 col-md-4">
                <input type="text" name="description" class="form-control" placeholder="Description">
            </div>
            <div class="col-12 col-md-2 d-grid">
                <button type="submit" class="btn btn-success">Add</button>
            </div>
            <div class="col-12 col-md-2 d-grid">
                <button type="button" class="btn btn-secondary"
                        onclick="$('#addForm').hide()">Cancel</button>
            </div>
        </div>
    </form>
</div>

<!-- SEARCH -->
<form id="searchForm" class="mt-3 mb-3">
    <input type="hidden" name="sort" id="sortValue" value="">
    <div class="row g-2">
        <div class="col-12 col-md-4">
            <input type="text" name="search" placeholder="Search category..." class="form-control">
        </div>
        <div class="col-12 col-md-4">
            <div class="dropdown w-100">
                <button class="btn btn-outline-secondary dropdown-toggle w-100 text-start"
                        type="button" id="sortDropdown"
                        data-bs-toggle="dropdown">Sort</button>
                <ul class="dropdown-menu w-100">
                    <li><a class="dropdown-item sort-option" href="#" data-value="">Sort</a></li>
                    <li><a class="dropdown-item sort-option" href="#" data-value="a_z">A-Z</a></li>
                    <li><a class="dropdown-item sort-option" href="#" data-value="z_a">Z-A</a></li>
                </ul>
            </div>
        </div>
        <div class="col-12 col-md-2 d-grid">
            <button type="submit" class="btn btn-primary">Search</button>
        </div>
        <div class="col-12 col-md-2 d-grid ">
            <button type="button" id="clearBtn" class="btn btn-secondary">
                Clear 
            </button>
        </div>
    </div>
</form>

<!-- TABLE -->
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
    <tbody id="categoryTableBody"></tbody>
</table>
</div>

<!-- PAGINATION -->
<div id="paginationContainer" class="d-flex justify-content-center flex-wrap gap-2 mt-3"></div>

</div>

<script>
$(function(){

    var CAT_CTRL = "../../controllers/CategoryController.cfc";

    // MESSAGE
    function showMsg(res){
        $("#ajaxMessage").html(
            '<div class="alert alert-'+(res.status==="success"?"success":"danger")+'">'+
            (res.message||"")+'</div>'
        );
        setTimeout(()=>$("#ajaxMessage").html(""), 4000);
    }

    // LOAD CATEGORIES
    function loadCategories(page){
        let formData = $("#searchForm").serialize();
        formData = formData.replace(/(&|^)p=\d+/,"");
        let finalData = "method=searchCategories&p=" + page + "&" + formData;

        $.ajax({
            url      : CAT_CTRL,
            type     : "GET",
            data     : finalData,
            dataType : "json",
            success  : function(res){
                if(res.status === "success"){
                    $("#categoryTableBody").html(res.html);
                    $("#paginationContainer").html(res.pagination);
                } else {
                    showMsg(res);
                }
            },
            error : function(xhr){
                console.log("Load error:", xhr.responseText);
            }
        });
    }

    // SORT DROPDOWN
    $(document).on("click", ".sort-option", function(e){
        e.preventDefault();
        $("#sortValue").val($(this).data("value"));
        $("#sortDropdown").text($(this).text());
        loadCategories(1);
    });

    // SEARCH
    $("#searchForm").submit(function(e){
        e.preventDefault();
        loadCategories(1);
    });

    // PAGINATION
    $(document).on("click", ".pageBtn", function(){
        loadCategories($(this).data("page"));
    });

    // ADD CATEGORY
    $("#createCategoryForm").submit(function(e){
        e.preventDefault();
        $.ajax({
            url      : CAT_CTRL + "?method=addCategory",
            type     : "POST",
            data     : $(this).serialize(),
            dataType : "json",
            success  : function(res){
                showMsg(res);
                if(res.status === "success"){
                    $("#createCategoryForm")[0].reset();
                    $("#addForm").hide();
                    loadCategories(1);
                }
            },
            error : function(xhr){
                console.log("Add error:", xhr.responseText);
            }
        });
    });

    // EDIT TOGGLE
    $(document).on("click", ".editBtn", function(){
        let id = $(this).data("id");
        $("#categoryRow_"+id).hide();
        $("#editCategoryRow_"+id).show();
    });

    // CANCEL EDIT
    $(document).on("click", ".cancelEdit", function(){
        let id = $(this).data("id");
        $("#editCategoryRow_"+id).hide();
        $("#categoryRow_"+id).show();
    });

    // SAVE EDIT
    $(document).on("click", ".saveEdit", function(){
        let id  = $(this).data("id");
        let row = $("#editCategoryRow_"+id);
        $.ajax({
            url      : CAT_CTRL + "?method=updateCategory",
            type     : "POST",
            data     : {
                id            : id,
                category_name : row.find(".editName").val(),
                description   : row.find(".editDesc").val()
            },
            dataType : "json",
            success  : function(res){
                showMsg(res);
                if(res.status === "success") loadCategories(1);
            },
            error : function(xhr){
                console.log("Update error:", xhr.responseText);
            }
        });
    });

    // TOGGLE STATUS
    $(document).on("click", ".toggleStatusBtn", function(){
        let btn = $(this);
        $.ajax({
            url      : CAT_CTRL,
            type     : "GET",
            data     : {
                method        : "toggleStatus",
                id            : btn.data("id"),
                currentStatus : btn.data("status")
            },
            dataType : "json",
            success  : function(res){
                showMsg(res);
                if(res.status === "success") loadCategories(1);
            },
            error : function(xhr){
                console.log("Toggle error:", xhr.responseText);
            }
        });
    });

    $("#clearBtn").click(function(){
        $("#searchForm")[0].reset();
        doSearch(1);
    });

    // INITIAL LOAD
    loadCategories(1);

});
</script>