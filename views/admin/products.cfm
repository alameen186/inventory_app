<!--- views/vendor/products.cfm  (updated with wholesale fields) --->
<cfif structKeyExists(session,"role_name") AND session.role_name EQ "vendor">
    <cfset vendorFilter = session.user_id>
<cfelse>
    <cfset vendorFilter = "">
</cfif>

<cfset productModel  = createObject("component","models.Product")>
<cfset categoryModel = createObject("component","models.Category")>
<cfset categories    = categoryModel.getAllActiveCategory(vendorFilter)>

<cfparam name="url.search"      default="">
<cfparam name="url.sort"        default="">
<cfparam name="url.p"           default="1">
<cfparam name="url.category_id" default="">

<cfset currentPage = max(1, val(url.p))>
<cfset limit       = 10>

<cfset products = productModel.getAllProductsAdmin(
    search      = url.search,
    sort        = url.sort,
    category_id = url.category_id,
    page        = currentPage,
    limit       = limit,
    vendor_id   = vendorFilter
)>

<cfset totalRecords = productModel.getProductCountAdmin(
    search      = url.search,
    category_id = url.category_id,
    vendor_id   = vendorFilter
)>
<cfset totalPages = max(1, ceiling(totalRecords / limit))>

<div class="container-fluid mt-4">
<h3 class="fw-bold mb-4">
    <i class="bi bi-box-seam me-2 text-primary"></i>Product Management
</h3>

<div id="ajaxMessage"></div>

<!--- ADD PRODUCT BUTTON --->
<button class="btn btn-primary mb-3" id="toggleAddFormBtn">
    <i class="bi bi-plus-circle me-1"></i> Add Product
</button>

<!--- ADD PRODUCT FORM --->
<div id="addProductCard" class="card shadow-sm mb-4 border-primary" style="display:none;">
    <div class="card-header bg-primary text-white d-flex justify-content-between align-items-center">
        <span><i class="bi bi-plus-circle me-2"></i>Add New Product</span>
        <button type="button" class="btn-close btn-close-white" id="closeAddForm"></button>
    </div>
    <div class="card-body">
        <form id="createProductForm" enctype="multipart/form-data">
            <input type="hidden" name="action" value="add">

            <!--- Row 1: Basic Info --->
            <div class="row g-3 mb-3">
                <div class="col-12 col-md-3">
                    <label class="form-label fw-semibold">Product Name <span class="text-danger">*</span></label>
                    <input name="product_name" class="form-control" placeholder="Product name">
                </div>
                <div class="col-6 col-md-2">
                    <label class="form-label fw-semibold">Retail Price <span class="text-danger">*</span></label>
                    <div class="input-group">
                        <span class="input-group-text"><i class="bi bi-currency-rupee"></i></span>
                        <input name="price" class="form-control" placeholder="0.00">
                    </div>
                </div>
                <div class="col-6 col-md-2">
                    <label class="form-label fw-semibold">Stock <span class="text-danger">*</span></label>
                    <input name="stock" class="form-control" placeholder="0">
                </div>
                <div class="col-12 col-md-3">
                    <label class="form-label fw-semibold">Category <span class="text-danger">*</span></label>
                    <select name="category_id" class="form-select">
                        <option value="">-- Select Category --</option>
                        <cfoutput query="categories">
                        <option value="#id#">#category_name#</option>
                        </cfoutput>
                    </select>
                </div>
                <div class="col-6 col-md-2">
                    <label class="form-label fw-semibold">Expiry Date</label>
                    <input type="date" name="expiry_date" class="form-control">
                </div>
            </div>

            <!--- Row 2: Rack --->
            <div class="row g-3 mb-3">
                <div class="col-12 col-md-3">
                    <label class="form-label fw-semibold">Rack</label>
                    <select name="rack_id" id="addRackId" class="form-select">
                        <option value="">No Rack</option>
                    </select>
                </div>
                <div class="col-12 col-md-3">
                    <label class="form-label fw-semibold">Rack Face</label>
                    <select name="rack_face_id" id="addFaceId" class="form-select" disabled>
                        <option value="">-- Select Face --</option>
                    </select>
                </div>
                <div class="col-12 col-md-6">
                    <label class="form-label fw-semibold">Product Images</label>
                    <input type="file" name="product_images" class="form-control" multiple accept="image/*">
                    <div class="form-text">Hold Ctrl/Cmd to select multiple (max 10)</div>
                </div>
            </div>

            <!--- Face Info Panel --->
            <div id="addFaceInfoPanel" class="alert alert-info py-2 small mb-3" style="display:none;">
                <strong>Face Info:</strong>
                Capacity: <span id="addInfoCap">-</span> |
                Used: <span id="addInfoUsed">-</span> |
                Available: <span id="addInfoAvail">-</span>
                <span id="addInfoFull" class="text-danger fw-bold ms-2" style="display:none;">FULL</span>
                <div id="addInfoProducts" class="mt-1"></div>
            </div>

            <!--- WHOLESALE SETTINGS  --->
            <div class="card border-success mb-3">
                <div class="card-header bg-success bg-opacity-10 d-flex justify-content-between align-items-center py-2"
                     style="cursor:pointer;" id="wholesaleToggleHeader">
                    <div class="d-flex align-items-center gap-2">
                        <div class="form-check mb-0">
                            <input class="form-check-input" type="checkbox"
                                   id="enableWholesaleAdd" name="enable_wholesale">
                            <label class="form-check-label fw-semibold text-success mb-0"
                                   for="enableWholesaleAdd">
                                <i class="bi bi-boxes me-1"></i>Enable Wholesale for this Product
                            </label>
                        </div>
                    </div>
                    <i class="bi bi-chevron-down text-success" id="wholesaleChevronAdd"></i>
                </div>
                <div id="wholesaleFieldsAdd" style="display:none;">
                    <div class="card-body">
                        <div class="alert alert-warning py-2 small mb-3">
                            <i class="bi bi-info-circle me-1"></i>
                            Wholesale price must be <strong>lower than retail price</strong>.
                            Minimum quantity is the minimum a buyer must order wholesale.
                        </div>
                        <div class="row g-3">
                            <div class="col-12 col-md-4">
                                <label class="form-label fw-semibold">
                                    Wholesale Price per Unit <span class="text-danger">*</span>
                                </label>
                                <div class="input-group">
                                    <span class="input-group-text"><i class="bi bi-currency-rupee"></i></span>
                                    <input type="number" name="wholesale_price" id="addWholesalePrice"
                                           class="form-control" placeholder="0.00"
                                           step="0.01" min="0" disabled>
                                </div>
                                <div class="form-text">Must be less than retail price</div>
                            </div>
                            <div class="col-12 col-md-4">
                                <label class="form-label fw-semibold">
                                    Minimum Order Quantity <span class="text-danger">*</span>
                                </label>
                                <input type="number" name="min_wholesale_qty" id="addMinWholesaleQty"
                                       class="form-control" placeholder="e.g. 10"
                                       min="1" disabled>
                                <div class="form-text">Minimum units per wholesale order</div>
                            </div>
                            <div class="col-12 col-md-4">
                                <label class="form-label fw-semibold d-block">&nbsp;</label>
                                <div class="alert alert-success py-2 small mb-0" id="wholesaleSavingsPreviewAdd" style="display:none;">
                                    <i class="bi bi-tag me-1"></i>
                                    Savings vs retail: <strong id="wholesaleSavingsPctAdd">—</strong>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!--- Submit --->
            <div class="d-flex justify-content-end gap-2">
                <button type="button" class="btn btn-secondary" id="closeAddFormBtn">Cancel</button>
                <button type="submit" class="btn btn-success" id="addProductSubmitBtn">
                    <i class="bi bi-check-circle me-1"></i> Add Product
                </button>
            </div>
        </form>
    </div>
</div>

<!--- SEARCH BAR --->
<form id="searchForm" class="card shadow-sm mb-4">
    <div class="card-body py-2">
        <input type="hidden" name="sort"        id="sortValue"     value="<cfoutput>#url.sort#</cfoutput>">
        <input type="hidden" name="category_id" id="categoryValue" value="<cfoutput>#url.category_id#</cfoutput>">
        <div class="row g-2 align-items-center">
            <div class="col-12 col-md-4">
                <cfoutput>
                <input name="search" value="#url.search#" class="form-control" placeholder="Search products...">
                </cfoutput>
            </div>
            <div class="col-12 col-md-3">
                <div class="dropdown w-100">
                    <button class="btn btn-outline-secondary dropdown-toggle w-100 text-start"
                            type="button" data-bs-toggle="dropdown">
                        <cfif url.sort EQ "a_z">A-Z
                        <cfelseif url.sort EQ "z_a">Z-A
                        <cfelseif url.sort EQ "price_low">Price Low
                        <cfelseif url.sort EQ "price_high">Price High
                        <cfelse>Sort By</cfif>
                    </button>
                    <ul class="dropdown-menu w-100">
                        <li><a class="dropdown-item sort-option" data-value="">Default</a></li>
                        <li><a class="dropdown-item sort-option" data-value="a_z">A-Z</a></li>
                        <li><a class="dropdown-item sort-option" data-value="z_a">Z-A</a></li>
                        <li><a class="dropdown-item sort-option" data-value="price_low">Price Low</a></li>
                        <li><a class="dropdown-item sort-option" data-value="price_high">Price High</a></li>
                    </ul>
                </div>
            </div>
            <div class="col-12 col-md-3">
                <div class="dropdown w-100">
                    <button class="btn btn-outline-secondary dropdown-toggle w-100 text-start"
                            type="button" data-bs-toggle="dropdown" id="categoryDropdown">
                        All Categories
                    </button>
                    <ul class="dropdown-menu w-100">
                        <li><a class="dropdown-item category-option" data-value="">All Categories</a></li>
                        <cfoutput query="categories">
                        <li><a class="dropdown-item category-option" data-value="#id#">#category_name#</a></li>
                        </cfoutput>
                    </ul>
                </div>
            </div>
            <div class="col-6 col-md-1">
                <button class="btn btn-primary w-100">Apply</button>
            </div>
            <div class="col-6 col-md-1">
                <button type="button" id="clearBtn" class="btn btn-secondary w-100">Clear</button>
            </div>
        </div>
    </div>
</form>

<!--- PRODUCTS TABLE --->
<div class="card shadow-sm">
    <div class="table-responsive">
        <table class="table table-hover align-middle mb-0">
            <thead class="table-dark">
                <tr>
                    <th>ID</th>
                    <th>Name</th>
                    <th>Retail Price</th>
                    <th>Wholesale</th>
                    <th>Min Qty</th>
                    <th>Stock</th>
                    <th>Category</th>
                    <th>Expiry</th>
                    <th>Image</th>
                    <th>Status</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody id="productTableBody">
            <cfoutput query="products">

                <!--- VIEW ROW --->
                <tr id="viewRow_#id#">
                    <td><small class="text-muted">#id#</small></td>
                    <td class="fw-semibold">#product_name#</td>
                    <td><i class="bi bi-currency-rupee"></i>#numberFormat(price,"0.00")#</td>
                    <td>
                        <cfif len(trim(wholesale_price)) AND wholesale_price GT 0>
                            <span class="badge bg-success"><i class="bi bi-currency-rupee"></i>#numberFormat(wholesale_price,"0.00")#</span>
                        <cfelse>
                            <span class="text-muted small">—</span>
                        </cfif>
                    </td>
                    <td>
                        <cfif len(trim(min_wholesale_qty)) AND min_wholesale_qty GT 0>
                            <span class="badge bg-secondary">#min_wholesale_qty#</span>
                        <cfelse>
                            <span class="text-muted small">—</span>
                        </cfif>
                    </td>
                    <td>
                        <span class="fw-semibold #iif(stock LTE 5, de('text-danger'), de('text-dark'))#">
                            #stock#
                        </span>
                    </td>
                    <td><small>#category_name#</small></td>
                    <td><small><cfif len(trim(expiry_date))>#dateFormat(expiry_date,"dd-mmm-yyyy")#<cfelse>—</cfif></small></td>
                    <td>
                        <cfif len(trim(first_image))>
                            <img src="../../assets/images/products/#first_image#" width="40" height="40"
                                 style="object-fit:cover;border-radius:4px;">
                        <cfelse>
                            <span class="text-muted small">No img</span>
                        </cfif>
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
                            <button class="toggleBtn btn btn-sm #iif(is_active EQ 1,de('btn-danger'),de('btn-success'))#"
                                data-id="#id#" data-status="#is_active#">
                                <cfif is_active EQ 1>Block<cfelse>Unblock</cfif>
                            </button>
                        </div>
                    </td>
                </tr>

                <!--- EDIT ROW --->
                <tr id="editRow_#id#" style="display:none;" class="table-warning">
                    <td><small class="text-muted">#id#</small></td>
                    <td><input value="#product_name#" class="form-control form-control-sm editName" style="min-width:120px;"></td>
                    <td>
                        <div class="input-group input-group-sm" style="min-width:100px;">
                            <span class="input-group-text"><i class="bi bi-currency-rupee"></i></span>
                            <input value="#price#" class="form-control editPrice">
                        </div>
                    </td>

                    <!--- Wholesale Price in edit row --->
                    <td>
                        <div class="input-group input-group-sm" style="min-width:100px;">
                            <span class="input-group-text"><i class="bi bi-currency-rupee"></i></span>
                            <input value="#wholesale_price#" class="form-control editWholesalePrice"
                                   placeholder="0.00" title="Wholesale price (leave blank to disable)">
                        </div>
                        <div class="form-text" style="font-size:0.7rem;">Leave blank = disabled</div>
                    </td>

                    <!--- Min Wholesale Qty in edit row --->
                    <td>
                        <input value="#min_wholesale_qty#" class="form-control form-control-sm editMinWholesaleQty"
                               style="min-width:70px;" placeholder="Min qty"
                               title="Minimum wholesale quantity">
                    </td>

                    <td><input value="#stock#" class="form-control form-control-sm editStock" style="min-width:70px;"></td>
                    <td>
                        <select class="form-select form-select-sm editCategory" style="min-width:120px;">
                            <cfloop query="categories">
                            <option value="#categories.id#"
                                <cfif categories.id EQ products.category_id>selected</cfif>>
                                #categories.category_name#
                            </option>
                            </cfloop>
                        </select>
                    </td>
                    <td><input type="date" value="#expiry_date#" class="form-control form-control-sm editExpiry"></td>
                    <td>
                        <div id="existingImgs_#id#" class="d-flex flex-wrap gap-1 mb-1"></div>
                        <input type="file" class="form-control form-control-sm editImages"
                               multiple accept="image/*">
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
</div>

<!--- Pagination --->
<cfset groupSize = 4>
<cfset pageGroup = ceiling(currentPage / groupSize)>
<cfset startPage = (pageGroup - 1) * groupSize + 1>
<cfset endPage   = min(startPage + groupSize - 1, totalPages)>
<cfoutput>
<div id="paginationArea" class="d-flex justify-content-center flex-wrap gap-2 mt-3">
    <cfif startPage GT 1>
        <button class="pageBtn btn btn-outline-primary btn-sm"
            data-page="#startPage-1#">&laquo; Prev</button>
    </cfif>
    <cfloop from="#startPage#" to="#endPage#" index="i">
        <button class="pageBtn btn btn-sm
            <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
            data-page="#i#">#i#</button>
    </cfloop>
    <cfif endPage LT totalPages>
        <button class="pageBtn btn btn-outline-primary btn-sm"
            data-page="#endPage+1#">Next &raquo;</button>
    </cfif>
</div>
</cfoutput>

</div><!--- end container --->


<script>
$(function(){

    var ADMIN_CTRL = "../../controllers/product/AdminProductController.cfc";
    var RC         = "../../controllers/RackController.cfc";

    /* ── Message helper ── */
    function msg(success, message){
        var cls  = success ? "success" : "danger";
        var icon = success
            ? '<i class="bi bi-check-circle-fill me-2"></i>'
            : '<i class="bi bi-exclamation-triangle-fill me-2"></i>';
        $("#ajaxMessage").html(
            '<div class="alert alert-' + cls + ' alert-dismissible fade show">'
          + icon + message
          + '<button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>'
        );
        if(success) setTimeout(function(){ $("#ajaxMessage .alert").alert("close"); }, 3000);
        $("html,body").animate({ scrollTop: $("#ajaxMessage").offset().top - 20 }, 200);
    }

    function showErrors(errors){
        var html = '<div class="alert alert-danger alert-dismissible"><ul class="mb-0 mt-1">';
        errors.forEach(function(e){ html += "<li>" + e + "</li>"; });
        html += '</ul><button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>';
        $("#ajaxMessage").html(html);
        $("html,body").animate({ scrollTop: $("#ajaxMessage").offset().top - 20 }, 200);
    }

    /* ── Add form toggle ── */
    $("#toggleAddFormBtn, #closeAddForm, #closeAddFormBtn").on("click", function(){
        $("#addProductCard").slideToggle(200);
    });

    /* ── Sort/Category dropdowns ── */
    $(document).on("click", ".sort-option", function(e){
        e.preventDefault();
        $("#sortValue").val($(this).data("value"));
        $(this).closest(".dropdown").find("button.dropdown-toggle").text($(this).text());
    });
    $(document).on("click", ".category-option", function(e){
        e.preventDefault();
        $("#categoryValue").val($(this).data("value"));
        $("#categoryDropdown").text($(this).text());
    });

    /* WHOLESALE TOGGLE LOGIC 
     */
    $("#enableWholesaleAdd").on("change", function(){
        var enabled = $(this).is(":checked");
        $("#wholesaleFieldsAdd").slideToggle(200);
        $("#addWholesalePrice, #addMinWholesaleQty").prop("disabled", !enabled);
        if(!enabled){
            $("#addWholesalePrice, #addMinWholesaleQty").val("");
            $("#wholesaleSavingsPreviewAdd").hide();
        }
    });

    /* Live savings preview */
    function updateSavingsPreview(){
        var retail    = parseFloat($("input[name='price']").val()) || 0;
        var wholesale = parseFloat($("#addWholesalePrice").val()) || 0;
        if(retail > 0 && wholesale > 0 && wholesale < retail){
            var pct = (((retail - wholesale) / retail) * 100).toFixed(1);
            $("#wholesaleSavingsPctAdd").text(pct + "% cheaper than retail");
            $("#wholesaleSavingsPreviewAdd").show();
        } else {
            $("#wholesaleSavingsPreviewAdd").hide();
        }
    }
    $("#addWholesalePrice, input[name='price']").on("input", updateSavingsPreview);


    function validateAddForm(fd){
        var errors = [];
        var name    = (fd.get("product_name") || "").trim();
        var price   = parseFloat(fd.get("price"));
        var stock   = (fd.get("stock") || "").trim();
        var cat     = fd.get("category_id");
        var wsOn    = fd.get("enable_wholesale") !== null;
        var wsPrice = parseFloat(fd.get("wholesale_price"));
        var wsMinQty= parseInt(fd.get("min_wholesale_qty"));

        if(!name || name.length < 2)     errors.push("Product name must be at least 2 characters");
        if(name.length > 100)            errors.push("Product name cannot exceed 100 characters");
        if(isNaN(price) || price <= 0)   errors.push("Retail price must be greater than 0");
        if(price > 999999)               errors.push("Price cannot exceed 999,999");
        if(stock === "" || isNaN(+stock) || +stock < 0) errors.push("Stock must be 0 or greater");
        if(!cat || !+cat)                errors.push("Please select a category");

        if(wsOn){
            if(isNaN(wsPrice) || wsPrice <= 0)
                errors.push("Wholesale price is required when wholesale is enabled");
            else if(wsPrice >= price)
                errors.push("Wholesale price must be lower than retail price (₹" + price.toFixed(2) + ")");
            if(isNaN(wsMinQty) || wsMinQty < 1)
                errors.push("Minimum wholesale quantity must be at least 1");
        }

        var expiry = (fd.get("expiry_date") || "").trim();
        if(expiry){
            var ed = new Date(expiry);
            if(isNaN(ed.getTime()))  errors.push("Expiry date is invalid");
            else if(ed < new Date()) errors.push("Expiry date cannot be in the past");
        }

        return errors;
    }

    /* ── Submit add form ── */
    $("#createProductForm").on("submit", function(e){
        e.preventDefault();
        var fd     = new FormData(this);
        var errors = validateAddForm(fd);
        if(errors.length){ showErrors(errors); return; }

        /* Face full check */
        var faceId = $("#addFaceId").val();
        if(faceId && parseInt($("#addInfoAvail").text()) <= 0){
            showErrors(["Selected rack face is full. Choose another."]);
            return;
        }

        var btn = $("#addProductSubmitBtn");
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
            success: function(res){
                btn.prop("disabled", false).html('<i class="bi bi-check-circle me-1"></i> Add Product');
                if(res.success){
                    msg(true, res.message);
                    setTimeout(function(){ location.reload(); }, 1500);
                } else { showErrors([res.message]); }
            },
            error: function(){
                btn.prop("disabled", false).html('<i class="bi bi-check-circle me-1"></i> Add Product');
                showErrors(["Server error. Please try again."]);
            }
        });
    });

    /* ── Edit toggle ── */
    $(document).on("click", ".editBtn", function(){
        var id = $(this).data("id");
        $(".editBtn").not(this).each(function(){
            var oid = $(this).data("id");
            $("#editRow_" + oid).hide();
            $("#viewRow_" + oid).show();
        });
        $("#viewRow_" + id).hide();
        $("#editRow_"  + id).show();

        /* Load existing images */
        $.get(ADMIN_CTRL, { method: "getImages", product_id: id }, function(res){
            if(!res.success) return;
            var html = "";
            $.each(res.data, function(i, img){
                html += '<div class="position-relative d-inline-block me-1">'
                      + '<img src="../../assets/images/products/' + img.image
                      + '" width="45" height="45" style="object-fit:cover;border-radius:3px;">'
                      + '<button type="button" class="btn btn-danger btn-sm deleteImgBtn position-absolute"'
                      + ' style="top:-4px;right:-4px;width:18px;height:18px;font-size:10px;padding:0;line-height:1;"'
                      + ' data-image-id="' + img.id + '" data-product-id="' + id + '">&times;</button>'
                      + '</div>';
            });
            $("#existingImgs_" + id).html(html);
        }, "json");
    });

    /* ── Delete single image ── */
    $(document).on("click", ".deleteImgBtn", function(){
        if(!confirm("Delete this image?")) return;
        var btn = $(this);
        $.get(ADMIN_CTRL, {
            method     : "deleteImage",
            image_id   : btn.data("image-id"),
            product_id : btn.data("product-id")
        }, function(res){
            if(res.success) btn.closest("div.position-relative").remove();
            else msg(false, res.message);
        }, "json");
    });

    /* ── Cancel edit ── */
    $(document).on("click", ".cancelBtn", function(){
        var id = $(this).data("id");
        $("#editRow_" + id).hide();
        $("#viewRow_" + id).show();
    });

    /* ── Save edit ── */
    $(document).on("click", ".saveBtn", function(){
        var id  = $(this).data("id");
        var row = $("#editRow_" + id);

        var name       = row.find(".editName").val().trim();
        var price      = parseFloat(row.find(".editPrice").val());
        var stock      = row.find(".editStock").val().trim();
        var wsPrice    = row.find(".editWholesalePrice").val().trim();
        var wsMinQty   = row.find(".editMinWholesaleQty").val().trim();

        /* Validate */
        var editErrors = [];
        if(!name || name.length < 2)    editErrors.push("Product name must be at least 2 characters");
        if(isNaN(price) || price <= 0)  editErrors.push("Retail price must be greater than 0");
        if(stock === "" || isNaN(+stock) || +stock < 0) editErrors.push("Stock must be 0 or greater");

        /* Wholesale validation — only if either field has a value */
        if(wsPrice !== "" || wsMinQty !== ""){
            var wsp  = parseFloat(wsPrice);
            var wsmq = parseInt(wsMinQty);
            if(isNaN(wsp) || wsp <= 0)
                editErrors.push("Wholesale price must be greater than 0");
            else if(wsp >= price)
                editErrors.push("Wholesale price must be lower than retail price");
            if(isNaN(wsmq) || wsmq < 1)
                editErrors.push("Minimum wholesale quantity must be at least 1");
        }

        if(editErrors.length){ showErrors(editErrors); return; }

        var fd = new FormData();
        fd.append("id",                 id);
        fd.append("product_name",       name);
        fd.append("price",              row.find(".editPrice").val().trim());
        fd.append("stock",              stock);
        fd.append("category_id",        row.find(".editCategory").val());
        fd.append("expiry_date",        row.find(".editExpiry").val());
        fd.append("wholesale_price",    wsPrice);
        fd.append("min_wholesale_qty",  wsMinQty);

        var fileInput = row.find(".editImages")[0];
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
            success: function(res){
                btn.prop("disabled", false).html("Save");
                msg(res.success, res.message);
                if(res.success) setTimeout(function(){ location.reload(); }, 1500);
            },
            error: function(){
                btn.prop("disabled", false).html("Save");
                msg(false, "Server error.");
            }
        });
    });

    /* ── Toggle status ── */
    $(document).on("click", ".toggleBtn", function(){
        var btn = $(this);
        $.get(ADMIN_CTRL, {
            method        : "toggleStatus",
            id            : btn.data("id"),
            currentStatus : btn.data("status")
        }, function(res){
            msg(res.success, res.message);
            if(!res.success) return;
            var s = res.data.newStatus;
            btn.data("status", s).text(s == 1 ? "Block" : "Unblock")
               .removeClass("btn-danger btn-success").addClass(s == 1 ? "btn-danger" : "btn-success");
        }, "json");
    });

    /* ── Search / pagination ── */
    function doSearch(page){
        $.get(ADMIN_CTRL, "method=search&p=" + page + "&" + $("#searchForm").serialize(), function(res){
            if(res.success){
                $("#productTableBody").html(res.data.rows);
                $("#paginationArea").html(res.data.pagination);
            }
        }, "json");
    }

    $("#searchForm").on("submit", function(e){ e.preventDefault(); doSearch(1); });
    $(document).on("click", ".pageBtn", function(){ doSearch($(this).data("page")); });
    $("#clearBtn").on("click", function(){
        $("#searchForm")[0].reset();
        $("#sortValue").val("");
        $("#categoryValue").val("");
        doSearch(1);
    });

    /*  RACK DROPDOWNS  */
    (function(){
        function loadAddRacks(){
            $.get(RC + "?method=getRacksForVendor", function(res){
                var opts = '<option value="">No Rack</option>';
                if(res.success && res.data && res.data.length){
                    $.each(res.data, function(i, r){
                        opts += '<option value="' + r.id + '">'
                              + r.rack_code + (r.rack_name ? " — " + r.rack_name : "") + '</option>';
                    });
                }
                $("#addRackId").html(opts);
            }, "json");
        }

        $("#addRackId").on("change", function(){
            var rackId = $(this).val();
            $("#addFaceId").html('<option value="">-- Select Face --</option>').prop("disabled", true);
            $("#addFaceInfoPanel").hide();
            if(!rackId) return;
            $.get(RC + "?method=getFacesForRack", { rack_id: rackId }, function(res){
                if(!res.success || !res.data || !res.data.length) return;
                var opts = '<option value="">-- Select Face --</option>';
                $.each(res.data, function(i, f){
                    var full  = f.available <= 0;
                    var label = f.face_code + " (" + f.used_slots + "/" + f.capacity + ")"
                              + (full ? " — FULL" : " — " + f.available + " free");
                    opts += '<option value="' + f.id + '"' + (full ? ' disabled' : '') + '>' + label + '</option>';
                });
                $("#addFaceId").html(opts).prop("disabled", false);
            }, "json");
        });

        $("#addFaceId").on("change", function(){
            var faceId = $(this).val();
            $("#addFaceInfoPanel").hide();
            if(!faceId) return;
            $.get(RC + "?method=getFaceDetail", { rack_face_id: faceId }, function(res){
                if(!res.success) return;
                var d = res.data;
                $("#addInfoCap").text(d.capacity);
                $("#addInfoUsed").text(d.used_slots);
                $("#addInfoAvail").text(d.available);
                $("#addInfoFull").toggle(d.available <= 0);
                $("#addProductSubmitBtn").prop("disabled", d.available <= 0)
                    .html(d.available <= 0
                        ? '<i class="bi bi-lock-fill me-1"></i>Face Full'
                        : '<i class="bi bi-check-circle me-1"></i> Add Product');
                var pHtml = "";
                if(d.products && d.products.length){
                    pHtml = "<strong>In face:</strong> " + d.products.map(function(p){ return p.product_name; }).join(", ");
                }
                $("#addInfoProducts").html(pHtml);
                $("#addFaceInfoPanel").show();
            }, "json");
        });

        loadAddRacks();
    })();


});
</script>
