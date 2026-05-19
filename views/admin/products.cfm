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
            <!--- Rack selection in product add form --->
    <div class="col-12 col-md-2">
     <select name="rack_id" id="addRackId" class="form-control">
        <option value="">No Rack</option>
     </select>
    </div>
    <div class="col-12 col-md-2">
     <select name="rack_face_id" id="addFaceId" class="form-control" disabled>
        <option value="">-- Select Face --</option>
     </select>
    </div>

<!--- Face info panel shown after face selected --->
    <div class="col-12" id="addFaceInfoPanel" style="display:none;">
     <div class="alert alert-info py-2 small">
        <strong>Face Info:</strong>
        Capacity: <span id="addInfoCap">-</span> |
        Used: <span id="addInfoUsed">-</span> |
        Available: <span id="addInfoAvail">-</span>
        <span id="addInfoFull" class="text-danger fw-bold ms-2" style="display:none;">
            FULL — Cannot add more products
        </span>
        <div id="addInfoProducts" class="mt-1"></div>
     </div>
    </div>
    <div class="col-6 col-md-2">
        <input type="date" name="expiry_date" class="form-control" placeholder="Expiry Date">
    </div>
    <div class="col-12 col-md-3">
     <input type="file" name="product_images" class="form-control"
        multiple accept="image/*">
     <small class="text-muted">Hold Ctrl/Cmd to select multiple</small>
    </div>
    <div class="col-12 col-md-2 align-items-end">
      <button class="btn btn-success w-100">
        Add
      </button>
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
               <cfif len(image)><img src="../../assets/images/products/#image#"  width="40" class="me-1"></cfif>
               <cfif len(image2)><img src="../../assets/images/products/#image2#" width="40" class="me-1"></cfif>
               <cfif len(image3)><img src="../../assets/images/products/#image3#" width="40"></cfif>
               <cfif NOT len(image) AND NOT len(image2) AND NOT len(image3)>No Image</cfif>
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
           <td>
    <div id="existingImgs_#id#" class="d-flex flex-wrap gap-1 mb-2">
        <!-- filled by JS when edit row opens -->
    </div>
    <input type="file" name="product_images" class="form-control"
        multiple accept="image/*">
    <small class="text-muted">Add more images (max 10 total)</small>
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
    var RC         = "../../controllers/RackController.cfc";

    /* ── SORT DROPDOWN ── */
    $(document).on("click", ".sort-option", function(e){
        e.preventDefault();
        $("#sortValue").val($(this).data("value"));
        $("#sortDropdown").text($(this).text());
    });

    /* ── CATEGORY DROPDOWN ── */
    $(document).on("click", ".category-option", function(e){
        e.preventDefault();
        $("#categoryValue").val($(this).data("value"));
        $("#categoryDropdown").text($(this).text());
    });

    /* ── MESSAGE HELPER ── */
    function msg(success, message){
        var cls = success ? "success" : "danger";
        var icon = success
            ? '<i class="bi bi-check-circle-fill me-2"></i>'
            : '<i class="bi bi-exclamation-triangle-fill me-2"></i>';
        $("#ajaxMessage").html(
            '<div class="alert alert-' + cls + ' alert-dismissible">'
          + icon + message
          + '<button type="button" class="btn-close" data-bs-dismiss="alert"></button>'
          + '</div>'
        );
        if(success){
            setTimeout(function(){ $("#ajaxMessage").find(".alert").alert("close"); }, 3000);
        }
        $("html, body").animate({ scrollTop: $("#ajaxMessage").offset().top - 20 }, 300);
    }

    /* ── VALIDATION HELPER ── */
    function validateProductForm(fd){
        var errors = [];

        var name = (fd.get("product_name") || "").trim();
        if(!name)
            errors.push("Product name is required");
        else if(name.length < 2)
            errors.push("Product name must be at least 2 characters");
        else if(name.length > 100)
            errors.push("Product name cannot exceed 100 characters");

        var price = (fd.get("price") || "").trim();
        if(!price)
            errors.push("Price is required");
        else if(isNaN(price) || +price <= 0)
            errors.push("Price must be a number greater than 0");
        else if(+price > 999999)
            errors.push("Price cannot exceed 999,999");

        var stock = (fd.get("stock") || "").trim();
        if(stock === "")
            errors.push("Stock is required");
        else if(isNaN(stock) || +stock < 0)
            errors.push("Stock must be 0 or greater");
        else if(+stock > 99999)
            errors.push("Stock cannot exceed 99,999");

        var cat = fd.get("category_id");
        if(!cat || !+cat)
            errors.push("Please select a category");

        var expiry = (fd.get("expiry_date") || "").trim();
        if(expiry){
            var ed = new Date(expiry);
            if(isNaN(ed.getTime()))
                errors.push("Expiry date is not a valid date");
            else if(ed < new Date())
                errors.push("Expiry date cannot be in the past");
        }

        return errors;
    }

    function showErrors(errors){
        var html = '<div class="alert alert-danger alert-dismissible">'
                 + '<ul class="mb-0 mt-2">';
        errors.forEach(function(e){ html += "<li>" + e + "</li>"; });
        html += '</ul><button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>';
        $("#ajaxMessage").html(html);
        $("html, body").animate({ scrollTop: $("#ajaxMessage").offset().top - 20 }, 300);
    }

    /* ── ADD PRODUCT ── */
    $("#createProductForm").on("submit", function(e){
        e.preventDefault();

        var fd = new FormData(this);

        /* 1. Client-side field validation */
        var errors = validateProductForm(fd);
        if(errors.length){
            showErrors(errors);
            return;
        }

        /* 2. Face full check before sending to server */
        var faceId = $("#addFaceId").val();
        if(faceId){
            var avail = parseInt($("#addInfoAvail").text(), 10);
            if(!isNaN(avail) && avail <= 0){
                showErrors(["The selected rack face is full. Please choose a different face."]);
                return;
            }
        }

        /* 3. Submit */
        var btn = $(this).find(".btn-success");
        btn.prop("disabled", true).html(
            '<span class="spinner-border spinner-border-sm me-1"></span>Saving...'
        );

        $.ajax({
            url         : ADMIN_CTRL + "?method=add",
            type        : "POST",
            data        : fd,
            processData : false,
            contentType : false,
            dataType    : "json",
            success     : function(res){
                btn.prop("disabled", false).html("Add");
                if(res.success){
                    msg(true, res.message);
                    setTimeout(function(){ location.reload(); }, 1500);
                } else {
                    showErrors([res.message]);
                }
            },
            error: function(){
                btn.prop("disabled", false).html("Add");
                showErrors(["Server error. Please try again."]);
            }
        });
    });

    /* ── EDIT TOGGLE ── */
    $(document).on("click", ".editBtn", function(){
        var id = $(this).data("id");
        $("#viewRow_" + id).hide();
        $("#editRow_"  + id).show();

        $.get(ADMIN_CTRL, { method: "getImages", product_id: id }, function(res){
            if(!res.success) return;
            var html = "";
            $.each(res.data, function(i, img){
                html += '<div class="position-relative d-inline-block me-1">'
                      + '<img src="../../assets/images/products/' + img.image
                      + '" width="50" class="rounded border">'
                      + '<button type="button"'
                      + ' class="btn btn-danger btn-sm deleteImgBtn position-absolute top-0 end-0 p-0"'
                      + ' style="width:16px;height:16px;font-size:10px;line-height:1;"'
                      + ' data-image-id="' + img.id + '"'
                      + ' data-product-id="' + id + '">&times;</button>'
                      + '</div>';
            });
            $("#existingImgs_" + id).html(html);
        }, "json");
    });

    /* ── DELETE IMAGE ── */
    $(document).on("click", ".deleteImgBtn", function(){
        if(!confirm("Delete this image?")) return;
        var btn = $(this);
        $.get(ADMIN_CTRL, {
            method     : "deleteImage",
            image_id   : btn.data("image-id"),
            product_id : btn.data("product-id")
        }, function(res){
            if(res.success) btn.closest("div.position-relative").remove();
            else alert(res.message);
        }, "json");
    });

    /* ── CANCEL EDIT ── */
    $(document).on("click", ".cancelBtn", function(){
        var id = $(this).data("id");
        $("#editRow_"  + id).hide();
        $("#viewRow_" + id).show();
    });

    /* ── SAVE EDIT ── */
    $(document).on("click", ".saveBtn", function(){
        var id  = $(this).data("id");
        var row = $("#editRow_" + id);

        /* Basic inline validation for edit */
        var name  = row.find(".name").val().trim();
        var price = row.find(".price").val().trim();
        var stock = row.find(".stock").val().trim();

        var editErrors = [];
        if(!name || name.length < 2)
            editErrors.push("Product name must be at least 2 characters");
        if(name.length > 100)
            editErrors.push("Product name cannot exceed 100 characters");
        if(!price || isNaN(price) || +price <= 0)
            editErrors.push("Price must be greater than 0");
        if(+price > 999999)
            editErrors.push("Price cannot exceed 999,999");
        if(stock === "" || isNaN(stock) || +stock < 0)
            editErrors.push("Stock must be 0 or greater");
        if(+stock > 99999)
            editErrors.push("Stock cannot exceed 99,999");

        if(editErrors.length){
            showErrors(editErrors);
            return;
        }

        var fd = new FormData();
        fd.append("id",           id);
        fd.append("product_name", name);
        fd.append("price",        price);
        fd.append("stock",        stock);
        fd.append("category_id",  row.find(".category").val());
        fd.append("expiry_date",  row.find(".expiry").val());

        var fileInput = row.find("input[type='file']")[0];
        if(fileInput && fileInput.files.length){
            for(var i = 0; i < fileInput.files.length; i++){
                fd.append("product_images", fileInput.files[i]);
            }
        }

        var btn = $(this);
        btn.prop("disabled", true).html(
            '<span class="spinner-border spinner-border-sm me-1"></span>Saving...'
        );

        $.ajax({
            url         : ADMIN_CTRL + "?method=update",
            type        : "POST",
            data        : fd,
            processData : false,
            contentType : false,
            dataType    : "json",
            success     : function(res){
                btn.prop("disabled", false).html("Save");
                msg(res.success, res.message);
                if(res.success) setTimeout(function(){ location.reload(); }, 1500);
            },
            error: function(){
                btn.prop("disabled", false).html("Save");
                msg(false, "Server error. Please try again.");
            }
        });
    });

    /* ── TOGGLE STATUS ── */
    $(document).on("click", ".toggleBtn", function(){
        var btn = $(this);
        $.ajax({
            url      : ADMIN_CTRL,
            type     : "GET",
            data     : {
                method        : "toggleStatus",
                id            : btn.data("id"),
                currentStatus : btn.data("status")
            },
            dataType : "json",
            success  : function(res){
                msg(res.success, res.message);
                if(!res.success) return;
                var s = res.data.newStatus;
                btn.data("status", s);
                btn.text(s == 1 ? "Block" : "Unblock");
                btn.removeClass("btn-danger btn-success")
                   .addClass(s == 1 ? "btn-danger" : "btn-success");
            }
        });
    });

    /* ── SEARCH ── */
    function doSearch(page){
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

    $("#searchForm").on("submit", function(e){
        e.preventDefault();
        doSearch(1);
    });

    $(document).on("click", ".pageBtn", function(){
        doSearch($(this).data("page"));
    });

    $("#clearBtn").on("click", function(){
        $("#searchForm")[0].reset();
        $("#sortValue").val("");
        $("#categoryValue").val("");
        $("#sortDropdown").text("Sort");
        $("#categoryDropdown").text("All Categories");
        doSearch(1);
    });

    /* ── RACK DROPDOWNS IN ADD FORM ── */
    (function(){

        function loadAddRacks(){
            $.get(RC + "?method=getRacksForVendor", function(res){
                var opts = "";
                if(!res.success || !res.data || !res.data.length){
                    opts = '<option value="">No racks assigned</option>';
                } else {
                    opts = '<option value="">No Rack</option>';
                    $.each(res.data, function(i, r){
                        opts += '<option value="' + r.id + '">'
                              + r.rack_code
                              + (r.rack_name ? " - " + r.rack_name : "")
                              + "</option>";
                    });
                }
                $("#addRackId").html(opts);
            }, "json");
        }

        /* When rack selected — load faces */
        $("#addRackId").on("change", function(){
            var rackId = $(this).val();

            /* Reset face dropdown and info panel */
            $("#addFaceId")
                .html('<option value="">-- Select Face --</option>')
                .prop("disabled", true);
            $("#addFaceInfoPanel").hide();
            $("#addInfoFull").hide();

            /* Re-enable submit in case it was disabled by a previously full face */
            $("#createProductForm .btn-success")
                .prop("disabled", false)
                .html("Add");

            if(!rackId) return;

            $.get(RC + "?method=getFacesForRack", { rack_id: rackId }, function(res){
                if(!res.success || !res.data || !res.data.length){
                    $("#addFaceId").html('<option value="">No faces configured</option>');
                    return;
                }
                var opts = '<option value="">-- Select Face --</option>';
                $.each(res.data, function(i, f){
                    var isFull = f.available <= 0;
                    var label  = f.face_code
                               + " (" + f.used_slots + "/" + f.capacity + ")"
                               + (isFull ? " — FULL" : " - " + f.available + " free");
                    opts += '<option value="' + f.id + '"'
                          + (isFull ? ' disabled style="color:#aaa;"' : "")
                          + ">" + label + "</option>";
                });
                $("#addFaceId").html(opts).prop("disabled", false);
            }, "json");
        });

        /* When face selected — show info panel */
        $("#addFaceId").on("change", function(){
            var faceId = $(this).val();
            $("#addFaceInfoPanel").hide();
            $("#addInfoFull").hide();

            /* Re-enable submit */
            $("#createProductForm .btn-success")
                .prop("disabled", false)
                .html("Add");

            if(!faceId) return;

            $.get(RC + "?method=getFaceDetail", { rack_face_id: faceId }, function(res){
                if(!res.success) return;
                var d = res.data;

                $("#addInfoCap").text(d.capacity);
                $("#addInfoUsed").text(d.used_slots);
                $("#addInfoAvail").text(d.available);

                if(d.available <= 0){
                    /* Face is full — show warning and disable submit */
                    $("#addInfoFull").show();
                    $("#createProductForm .btn-success")
                        .prop("disabled", true)
                        .html('<i class="bi bi-lock-fill me-1"></i>Face Full');
                } else {
                    $("#addInfoFull").hide();
                    $("#createProductForm .btn-success")
                        .prop("disabled", false)
                        .html("Add");
                }

                /* Products already in face */
                var pHtml = "";
                if(d.products && d.products.length){
                    var names = [];
                    $.each(d.products, function(i, p){ names.push(p.product_name); });
                    pHtml = "<strong>Products in this face:</strong> " + names.join(", ");
                } else {
                    pHtml = '<span class="text-muted fst-italic">No products in this face yet</span>';
                }
                $("#addInfoProducts").html(pHtml);
                $("#addFaceInfoPanel").show();
            }, "json");
        });

        loadAddRacks();

    })();

});
</script>