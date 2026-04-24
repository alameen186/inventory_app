<!--admin porduct page-->
<cfif structKeyExists(session,"role_name") AND session.role_name EQ "vendor">
    <cfset vendorFilter = session.user_id>
<cfelse>
    <cfset vendorFilter = "">
</cfif>

<cfset productModel = createObject("component", "models.Product")>
<cfset categoryModel = createObject("component", "models.Category")>

<cfset categories = categoryModel.getAllActiveCategory(vendorFilter)>
<cfparam name="url.search" default="">
<cfparam name="url.sort" default="">
<cfparam name="url.p" default="1">
<cfparam name="url.category_id" default="">

<cfset currentPage = val(url.p)>
<cfif currentPage LT 1><cfset currentPage = 1></cfif>

<cfset limit = 2>

<cfset products = productModel.getAllProductsAdmin(
    search = url.search,
    sort = url.sort,
    category_id = url.category_id,
    page = currentPage,
    limit = limit,
    vendor_id = vendorFilter
)>

<cfset totalRecords = productModel.getProductCountAdmin(
    search = url.search,
    category_id = url.category_id,
    vendor_id = vendorFilter
)>
<cfset totalPages = ceiling(totalRecords / limit)>

<div class="container-fluid mt-4">
<h3>Product Management</h3>

<div id="ajaxMessage"></div>

<!-- ADD -->
<button class="btn btn-primary mb-3" onclick="$('#addForm').toggle()">Add Product</button>

<div id="addForm" style="display:none;">
    <form id="createProductForm" enctype="multipart/form-data" class="mb-3">
        <input type="hidden" name="action" value="add">
        <div class="row g-2">
            <div class="col-12 col-md-2">
                <input name="product_name" class="form-control" placeholder="Name">
            </div>
            <div class="col-6 col-md-2">
                <input name="price" class="form-control" placeholder="Price">
            </div>
            <div class="col-6 col-md-2">
                <input name="stock" class="form-control" placeholder="Stock">
            </div>
            <div class="col-12 col-md-2">
                <select name="category_id" class="form-control">
                    <cfoutput query="categories">
                    <option value="#id#">#category_name#</option>
                    </cfoutput>
                </select>
            </div>
            <div class="col-6 col-md-2">
    <input type="date" name="expiry_date" class="form-control" placeholder="Expiry Date">
</div>
            <div class="col-12 col-md-2">
                <input type="file" name="product_image" class="form-control">
            </div>
            <div class="col-12 col-md-2 d-grid">
                <button class="btn btn-success">Add</button>
            </div>
        </div>
    </form>
</div>

<!-- SEARCH -->
<form id="searchForm" class="mb-3">

    <input type="hidden" name="sort" id="sortValue" value="<cfoutput>#url.sort#</cfoutput>">
    <input type="hidden" name="category_id" id="categoryValue" value="<cfoutput>#url.category_id#</cfoutput>">

    <div class="row g-2">
        <div class="col-12 col-md-3">
            <cfoutput>
            <input name="search" value="#url.search#" class="form-control" placeholder="Search...">
            </cfoutput>
        </div>

        <div class="col-12 col-md-3">
            <div class="dropdown w-100">
                <button class="btn btn-outline-secondary dropdown-toggle w-100 text-start"
                        type="button" id="sortDropdown"
                        data-bs-toggle="dropdown" aria-expanded="false">
                    <cfif url.sort EQ "a_z">A-Z
                    <cfelseif url.sort EQ "z_a">Z-A
                    <cfelseif url.sort EQ "price_low">Price Low
                    <cfelseif url.sort EQ "price_high">Price High
                    <cfelse>Sort
                    </cfif>
                </button>
                <ul class="dropdown-menu w-100" aria-labelledby="sortDropdown">
                    <li><a class="dropdown-item sort-option" href="#" data-value="">Sort</a></li>
                    <li><a class="dropdown-item sort-option" href="#" data-value="a_z">A-Z</a></li>
                    <li><a class="dropdown-item sort-option" href="#" data-value="z_a">Z-A</a></li>
                    <li><a class="dropdown-item sort-option" href="#" data-value="price_low">Price Low</a></li>
                    <li><a class="dropdown-item sort-option" href="#" data-value="price_high">Price High</a></li>
                </ul>
            </div>
        </div>

        <div class="col-12 col-md-3">
            <div class="dropdown w-100">
                <button class="btn btn-outline-secondary dropdown-toggle w-100 text-start"
                        type="button" id="categoryDropdown"
                        data-bs-toggle="dropdown" aria-expanded="false">
                    All Categories
                </button>
                <ul class="dropdown-menu w-100" aria-labelledby="categoryDropdown">
                    <li><a class="dropdown-item category-option" href="##" data-value="">All</a></li>
<cfoutput query="categories">
<li><a class="dropdown-item category-option" href="##" data-value="#id#">#category_name#</a></li>
</cfoutput>
                </ul>
            </div>
        </div>

        <div class="col-12 col-md-1 d-grid ">
            <button class="btn btn-primary">Apply</button>
        </div>
         <div class="col-12 col-md-1 d-grid ">
            <button type="button" id="clearBtn" class="btn btn-secondary">
                Clear 
            </button>
        </div>
    </div>
</form>

<div class="table-responsive">
<table class="table table-bordered">
    <thead>
        <tr>
            <th>ID</th><th>Name</th><th>Price</th><th>Stock</th>
            <th>Category</th><th>Expiry</th><th>Image</th><th>Status</th><th>Action</th>
        </tr>
    </thead>

    <tbody id="productTableBody">
    <cfoutput query="products">

        <tr id="viewRow_#id#">
            <td>#id#</td>
            <td>#product_name#</td>
            <td>#price#</td>
            <td>#stock#</td>
            <td>#category_name#</td>
            <td><cfif len(trim(expiry_date))>#dateFormat(expiry_date, "dd-mmm-yyyy")#<cfelse>-</cfif></td>
            <td>
                <cfif len(image)>
                    <img src="../../assets/images/products/#image#" width="50">
                <cfelse>No Image</cfif>
            </td>
            <td>
                <cfif is_active EQ 1>
                    <span class="badge bg-success">Active</span>
                <cfelse>
                    <span class="badge bg-warning text-dark">Blocked</span>
                </cfif>
            </td>
            <td>
                <div class="d-flex flex-wrap gap-1">
                    <button class="editBtn btn btn-warning btn-sm" data-id="#id#">Edit</button>
                    <button class="toggleBtn btn btn-sm #iif(is_active EQ 1, de('btn-danger'), de('btn-success'))#"
                        data-id="#id#" data-status="#is_active#">
                        <cfif is_active EQ 1>Block<cfelse>Unblock</cfif>
                    </button>
                </div>
            </td>
        </tr>

        <!-- EDIT ROW -->
        <tr id="editRow_#id#" style="display:none;">
            <td>#id#</td>
            <td><input value="#product_name#" class="form-control name" style="min-width:100px;"></td>
            <td><input value="#price#" class="form-control price" style="min-width:80px;"></td>
            <td><input value="#stock#" class="form-control stock" style="min-width:70px;"></td>
            <td>
                <select class="form-control category" style="min-width:110px;">
                    <cfloop query="categories">
                    <option value="#categories.id#"
                        <cfif categories.id EQ products.category_id>selected</cfif>>
                        #categories.category_name#
                    </option>
                    </cfloop>
                </select>
            </td>
            <td><input type="date" value="#expiry_date#" class="form-control expiry"></td>
            <td><input type="file" class="form-control image" style="min-width:120px;"></td>
            <td>
                <cfif is_active EQ 1>
                    <span class="badge bg-success">Active</span>
                <cfelse>
                    <span class="badge bg-warning text-dark">Blocked</span>
                </cfif>
            </td>
            <td>
                <div class="d-flex flex-wrap gap-1">
                    <button class="saveBtn btn btn-success btn-sm" data-id="#id#">Save</button>
                    <button class="cancelBtn btn btn-secondary btn-sm" data-id="#id#">Cancel</button>
                </div>
            </td>
        </tr>

    </cfoutput>
    </tbody>
</table>
</div>

<!-- PAGINATION -->
<cfset groupSize = 4>
<cfset pageGroup = ceiling(currentPage / groupSize)>
<cfset startPage = (pageGroup - 1) * groupSize + 1>
<cfset endPage   = min(startPage + groupSize - 1, totalPages)>
<cfset prevPage  = startPage - 1>
<cfset nextPage  = endPage + 1>

<cfoutput>
<div id="paginationArea" class="d-flex justify-content-center flex-wrap gap-2 mt-3">

    <!--- PREV --->
    <cfif startPage GT 1>
        <button class="pageBtn btn btn-outline-primary btn-sm"
            data-page="#prevPage#">&laquo; Prev</button>
    </cfif>

    <!--- PAGE NUMBERS --->
    <cfloop from="#startPage#" to="#endPage#" index="i">
        <button class="pageBtn btn btn-sm
            <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
            data-page="#i#">#i#</button>
    </cfloop>

    <!--- NEXT --->
    <cfif endPage LT totalPages>
        <button class="pageBtn btn btn-outline-primary btn-sm"
            data-page="#nextPage#">Next &raquo;</button>
    </cfif>

</div>
</cfoutput>

</div>

<script>
$(function(){

    var ADMIN_CTRL = "../../controllers/product/AdminProductController.cfc";

    $(document).on("click", ".sort-option", function(e){
        e.preventDefault();
        $("#sortValue").val($(this).data("value"));
        $("#sortDropdown").text($(this).text());
    });

    $(document).on("click", ".category-option", function(e){
        e.preventDefault();
        $("#categoryValue").val($(this).data("value"));
        $("#categoryDropdown").text($(this).text());
    });

    function msg(res) {
        var type = res.success ? "success" : "danger";
        $("#ajaxMessage").html(
            '<div class="alert alert-' + type + '">' + res.message + '</div>'
        );
        setTimeout(function(){ $("#ajaxMessage").fadeOut(); }, 3000);
    }

    // ADD
    $("#createProductForm").submit(function(e){
        e.preventDefault();
        var fd = new FormData(this);
        $.ajax({
            url         : ADMIN_CTRL + "?method=add",
            type        : "POST",
            data        : fd,
            processData : false,
            contentType : false,
            dataType    : "json",
            success     : function(res){
                msg(res);
                if(res.success) location.reload();
            }
        });
    });

    // EDIT TOGGLE
    $(document).on("click", ".editBtn", function(){
        var id = $(this).data("id");
        $("#viewRow_" + id).hide();
        $("#editRow_" + id).show();
    });

    $(document).on("click", ".cancelBtn", function(){
        var id = $(this).data("id");
        $("#editRow_" + id).hide();
        $("#viewRow_" + id).show();
    });

    // SAVE EDIT
    $(document).on("click", ".saveBtn", function(){
        var id  = $(this).data("id");
        var row = $("#editRow_" + id);
        var fd  = new FormData();
        fd.append("id",           id);
        fd.append("product_name", row.find(".name").val());
        fd.append("price",        row.find(".price").val());
        fd.append("stock",        row.find(".stock").val());
        fd.append("category_id",  row.find(".category").val());
        fd.append("expiry_date",  row.find(".expiry").val());
        var file = row.find(".image")[0].files[0];
        if(file) fd.append("product_image", file);

        $.ajax({
            url         : ADMIN_CTRL + "?method=update",
            type        : "POST",
            data        : fd,
            processData : false,
            contentType : false,
            dataType    : "json",
            success     : function(res){
                msg(res);
                if(res.success) location.reload();
            }
        });
    });

    // TOGGLE STATUS
    $(document).on("click", ".toggleBtn", function(){
        var btn = $(this);
        $.ajax({
            url      : ADMIN_CTRL,
            type     : "GET",
            data     : { method: "toggleStatus", id: btn.data("id"), currentStatus: btn.data("status") },
            dataType : "json",
            success  : function(res){
                msg(res);
                if(!res.success) return;
                var s = res.data.newStatus;
                btn.data("status", s);
                btn.text(s == 1 ? "Block" : "Unblock");
                btn.removeClass("btn-danger btn-success")
                   .addClass(s == 1 ? "btn-danger" : "btn-success");
            }
        });
    });

    // SEARCH
    function doSearch(page) {
        $.ajax({
            url      : ADMIN_CTRL,
            type     : "GET",
            data     : "method=search&p=" + page + "&" + $("#searchForm").serialize(),
            dataType : "json",
            success  : function(res){
                if(res.success){
                    $("#productTableBody").html(res.data.rows);
                    $("#paginationArea").html(res.data.pagination);
                }
            }
        });
    }

    $("#searchForm").submit(function(e){
        e.preventDefault();
        doSearch(1);
    });

    $(document).on("click", ".pageBtn", function(){
        doSearch($(this).data("page"));
    });

      // CLEAR
    $("#clearBtn").click(function(){
        $("#searchForm")[0].reset();
        doSearch(1);
    });

});
</script>