<link rel="stylesheet" href="../../assets/css/product-list.css">

<cfif NOT structKeyExists(session, "user_id")>
    <cflocation url="../../index.cfm?page=auth&message=Please login&type=error" addtoken="false">
    <cfabort>
</cfif>

<cfif NOT structKeyExists(session, "cart")>
    <cfset session.cart = structNew()>
</cfif>

<cfparam name="url.search"        default="">
<cfparam name="url.category_id"   default="">
<cfparam name="url.min_price"     default="">
<cfparam name="url.max_price"     default="">
<cfparam name="url.sort"          default="">
<cfparam name="url.p"             default="1">
<cfparam name="url.expiry_months" default="">

<cfset productModel  = createObject("component", "models.Product")>
<cfset categoryModel = createObject("component", "models.Category")>
<cfset categories    = categoryModel.getAllActiveCategory()>

<cfset products = productModel.searchProducts(
    keyword       = url.search,
    category_id   = isNumeric(url.category_id)   ? url.category_id   : "",
    min_price     = isNumeric(url.min_price)      ? url.min_price     : "",
    max_price     = isNumeric(url.max_price)      ? url.max_price     : "",
    sort          = url.sort,
    page          = val(url.p),
    limit         = 3,
    expiry_months = isNumeric(url.expiry_months)  ? url.expiry_months : ""
)>

<cfset totalRecords = productModel.getProductCount(
    keyword       = url.search,
    category_id   = isNumeric(url.category_id)   ? url.category_id   : "",
    min_price     = isNumeric(url.min_price)      ? url.min_price     : "",
    max_price     = isNumeric(url.max_price)      ? url.max_price     : "",
    expiry_months = isNumeric(url.expiry_months)  ? url.expiry_months : ""
)>

<cfset limit       = 3>
<cfset totalPages  = ceiling(totalRecords / limit)>
<cfset currentPage = val(url.p) GT 0 ? val(url.p) : 1>
<cfset groupSize   = 4>
<cfset startPage   = ((currentPage - 1) \ groupSize) * groupSize + 1>
<cfset endPage     = min(startPage + groupSize - 1, totalPages)>
<cfset prevPage    = startPage - 1>
<cfset nextPage    = endPage + 1>

<style>
.thumb-img {
    width: 56px;
    height: 56px;
    object-fit: cover;
    cursor: pointer;
    flex-shrink: 0;
    border: 2px solid #dee2e6;
    border-radius: 4px;
    transition: border-color 0.2s;
}
.thumb-img.active {
    border-color: #0d6efd;
}
</style>

<div class="container mt-4">

    <cfif structKeyExists(url, "message")>
        <div id="alertBox" class="alert <cfif structKeyExists(url,'type') AND url.type EQ 'success'>alert-success<cfelse>alert-danger</cfif>">
            <cfoutput>#encodeForHTML(url.message)#</cfoutput>
        </div>
        <script>
            setTimeout(function(){
                var b = document.getElementById("alertBox");
                if(b) b.style.display = "none";
            }, 5000);
        </script>
    </cfif>

    <!--- SEARCH FORM --->
    <form id="searchForm" class="mb-4">
        <input type="hidden" name="page"    value="dashboard">
        <input type="hidden" name="section" value="productList">

        <div class="row g-2 align-items-center">
            <div class="col-12 col-md-3">
                <cfoutput>
                <input type="text" name="search" value="#encodeForHTMLAttribute(url.search)#"
                       placeholder="Search product..." class="form-control">
                </cfoutput>
            </div>
            <div class="col-6 col-md-2">
                <input type="number" name="min_price" value="<cfoutput>#url.min_price#</cfoutput>"
                       class="form-control" placeholder="Min price">
            </div>
            <div class="col-6 col-md-2">
                <input type="number" name="max_price" value="<cfoutput>#url.max_price#</cfoutput>"
                       class="form-control" placeholder="Max price">
            </div>
            <div class="col-6 col-md-2">
                <select name="expiry_months" class="form-select">
                    <option value="">All Expiry</option>
                    <option value="1"  <cfif url.expiry_months EQ "1">selected</cfif>>Within 1 Month</option>
                    <option value="2"  <cfif url.expiry_months EQ "2">selected</cfif>>Within 2 Months</option>
                    <option value="3"  <cfif url.expiry_months EQ "3">selected</cfif>>Within 3 Months</option>
                    <option value="6"  <cfif url.expiry_months EQ "6">selected</cfif>>Within 6 Months</option>
                </select>
            </div>
            <div class="col-6 col-md-2">
                <select name="sort" class="form-select">
                    <option value="">Sort</option>
                    <option value="price_low"  <cfif url.sort EQ "price_low">selected</cfif>>Price: Low to High</option>
                    <option value="price_high" <cfif url.sort EQ "price_high">selected</cfif>>Price: High to Low</option>
                    <option value="a_z"        <cfif url.sort EQ "a_z">selected</cfif>>A to Z</option>
                    <option value="z_a"        <cfif url.sort EQ "z_a">selected</cfif>>Z to A</option>
                </select>
            </div>
            <div class="col-6 col-md-2">
                <select name="category_id" class="form-select">
                    <option value="">Category</option>
                    <cfoutput query="categories">
                    <option value="#id#" <cfif url.category_id EQ id>selected</cfif>>#category_name#</option>
                    </cfoutput>
                </select>
            </div>
            <div class="col-6 col-md-1 d-grid">
                <button type="submit" class="btn btn-primary">Search</button>
            </div>
            <div class="col-6 col-md-1 d-grid">
                <button type="button" id="clearBtn" class="btn btn-secondary">Clear</button>
            </div>
        </div>
    </form>

    <h3 class="mb-3">Products</h3>

    <!--- PRODUCT GRID --->
    <div class="row g-3" id="productContainer">
        <cfoutput query="products">
        <div class="col-6 col-md-4 col-lg-3">
            <div class="card h-100 product-card" data-pid="#id#">

                <cfif len(first_image)>
                    <img src="../../assets/images/products/#first_image#"
                         class="card-img-top" style="height:180px;object-fit:cover;">
                <cfelse>
                    <img src="https://via.placeholder.com/200"
                         class="card-img-top" style="height:180px;object-fit:cover;">
                </cfif>

                <div class="card-body d-flex flex-column text-center p-2">
                    <h6 class="card-title mb-1">#product_name#</h6>
                    <p class="text-muted small mb-1">#category_name#</p>
                    <p class="fw-semibold mb-1">#price# /-</p>
                    <div class="mb-2">
                        <cfif val(avg_rating) GT 0>
                            <span class="text-warning small">
                                <cfloop from="1" to="5" index="s">
                                    <cfif s LTE round(avg_rating)>&##9733;<cfelse>&##9734;</cfif>
                                </cfloop>
                            </span>
                            <small class="text-muted">#avg_rating# (#review_count#)</small>
                        <cfelse>
                            <small class="text-muted">No reviews yet</small>
                        </cfif>
                    </div>

                    <div class="mt-auto" onclick="event.stopPropagation()">
                        <cfif stock LTE 0>
                            <p class="text-danger fw-bold small mb-2">Out of Stock</p>
                            <div id="enqMsg_#id#"></div>
                            <div id="enqBtnArea_#id#">
                                <form class="enquiryForm">
                                    <input type="hidden" name="product_id" value="#id#">
                                    <button type="submit" class="btn btn-warning btn-sm w-100">Request</button>
                                </form>
                            </div>
                        <cfelse>
                            <cfif structKeyExists(session.cart, id)>
                                <a href="../../index.cfm?page=dashboard&section=cart"
                                   class="btn btn-success btn-sm w-100">Go to Cart</a>
                            <cfelse>
                                <form class="addToCartForm">
                                    <input type="hidden" name="product_id"   value="#id#">
                                    <input type="hidden" name="product_name" value="#product_name#">
                                    <input type="hidden" name="price"        value="#price#">
                                    <input type="hidden" name="image"        value="#first_image#">
                                    <button type="submit" class="btn btn-success btn-sm w-100">Add to Cart</button>
                                </form>
                            </cfif>
                        </cfif>
                    </div>
                </div>

            </div>
        </div>
        </cfoutput>
    </div>

</div>


<!--- PRODUCT DETAIL + REVIEWS MODAL --->
<div class="modal fade" id="productDetailModal" tabindex="-1" aria-hidden="true">
<div class="modal-dialog modal-lg modal-dialog-scrollable">
<div class="modal-content">

    <div class="modal-header bg-dark text-white">
        <h5 class="modal-title" id="modalProductName">Product Details</h5>
        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
    </div>

    <div class="modal-body">

        <div id="modalLoader" class="text-center py-5">
            <div class="spinner-border text-primary" role="status"></div>
            <p class="mt-2 text-muted">Loading...</p>
        </div>

        <div id="modalContent" style="display:none;">

            <div class="row g-3 mb-4">

                <!--- GALLERY COL --->
                <div class="col-12 col-md-5">
                    <img id="mainProductImg"
                         src="https://via.placeholder.com/400"
                         alt="Product image"
                         class="img-fluid rounded border w-100"
                         style="height:280px;object-fit:cover;">

                    <!--- THUMBNAIL STRIP WITH ARROWS --->
                    <div class="d-flex align-items-center gap-1 mt-2" id="thumbWrapper">
                        <button id="thumbPrev" class="btn btn-sm btn-outline-secondary flex-shrink-0"
                            style="width:28px;height:28px;padding:0;display:none;">&#8249;</button>

                        <div style="overflow:hidden;flex:1;" id="thumbViewport">
                            <div id="thumbContainer"
                                 class="d-flex gap-2"
                                 style="transition:transform 0.3s ease;will-change:transform;">
                            </div>
                        </div>

                        <button id="thumbNext" class="btn btn-sm btn-outline-secondary flex-shrink-0"
                            style="width:28px;height:28px;padding:0;display:none;">&#8250;</button>
                    </div>
                </div>

                <!--- INFO COL --->
                <div class="col-12 col-md-7 d-flex flex-column gap-2">
                    <span class="badge bg-secondary fs-6" id="modalCategoryBadge"></span>

                    <div>
                        <small class="text-muted d-block">Sold by</small>
                        <strong id="modalBusinessName">—</strong>
                    </div>
                    <div>
                        <small class="text-muted d-block">Price</small>
                        <h4 class="mb-0 fw-semibold" id="modalPrice">—</h4>
                    </div>
                    <div>
                        <small class="text-muted d-block">Expires</small>
                        <strong id="modalExpiry">—</strong>
                    </div>
                    <div>
                        <span class="text-warning" id="modalStars"></span>
                        <small class="text-muted ms-1">
                            <span id="modalAvgRating"></span>
                            (<span id="modalTotalReviews">0</span> reviews)
                        </small>
                    </div>

                    <div id="modalCartArea" class="mt-auto"></div>
                </div>
            </div>

            <hr>

            <!--- RATINGS SUMMARY --->
            <div class="row mb-4 align-items-center">
                <div class="col-4 text-center border-end">
                    <div class="display-4 fw-bold text-warning" id="avgRatingDisplay">—</div>
                    <div class="fs-5 text-warning" id="avgStarsDisplay"></div>
                    <small class="text-muted"><span id="totalReviewsDisplay">0</span> reviews</small>
                </div>
                <div class="col-8" id="starBreakdown"></div>
            </div>

            <hr>

            <!--- WRITE REVIEW --->
            <div id="reviewFormSection" class="mb-4" style="display:none;">
                <h6 class="fw-bold mb-3">Write a Review</h6>
                <div id="reviewFormMsg"></div>
                <div class="mb-3">
                    <label class="form-label fw-semibold">Your Rating</label>
                    <div id="starPicker" class="fs-3" style="cursor:pointer;">
                        <span class="star-pick text-warning"   data-val="1">&#9733;</span>
                        <span class="star-pick text-secondary" data-val="2">&#9733;</span>
                        <span class="star-pick text-secondary" data-val="3">&#9733;</span>
                        <span class="star-pick text-secondary" data-val="4">&#9733;</span>
                        <span class="star-pick text-secondary" data-val="5">&#9733;</span>
                    </div>
                    <input type="hidden" id="selectedRatingInput" value="1">
                </div>
                <div class="mb-3">
                    <label class="form-label fw-semibold">Your Comment</label>
                    <textarea id="reviewComment" class="form-control" rows="3"
                              placeholder="Share your experience (5-1000 characters)"
                              maxlength="1000"></textarea>
                    <div class="text-end">
                        <small class="text-muted"><span id="charCount">0</span>/1000</small>
                    </div>
                </div>
                <button id="submitReviewBtn" class="btn btn-success px-4">Submit Review</button>
            </div>

            <div id="alreadyReviewedMsg" class="alert alert-info mb-4" style="display:none;">
                &#10003; You have already submitted a review for this product.
            </div>
            <div id="notEligibleMsg" class="alert alert-warning mb-4" style="display:none;">
                You need to purchase this product at least <strong>2 times</strong> before you can write a review.
            </div>

            <hr>

            <h6 class="fw-bold mb-3">Customer Reviews</h6>
            <div id="reviewsList"></div>
            <div id="reviewsPagination" class="d-flex justify-content-center gap-2 mt-3 flex-wrap"></div>

        </div>
    </div>

    <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
    </div>

</div>
</div>
</div>

<!--- PAGINATION --->
<div id="paginationContainer" class="mt-3">
    <cfoutput>
    <cfif totalPages GT 1>
    <div class="d-flex gap-2 justify-content-center">
        <cfif startPage GT 1>
            <button class="pageBtn btn btn-outline-primary" data-page="#prevPage#">Prev</button>
        </cfif>
        <cfloop from="#startPage#" to="#endPage#" index="i">
            <button class="pageBtn btn btn-sm <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
                    data-page="#i#">#i#</button>
        </cfloop>
        <cfif endPage LT totalPages>
            <button class="pageBtn btn btn-outline-primary" data-page="#nextPage#">Next</button>
        </cfif>
    </div>
    </cfif>
    </cfoutput>
</div>

<script>
$(document).ready(function(){

    var USER_CTRL = "../../controllers/product/UserProductController.cfc";
    var CART_CTRL = "../../controllers/CartController.cfc";
    var ENQ_CTRL  = "../../controllers/EnquiryController.cfc";
    var REV_CTRL  = "../../controllers/review/UserReviewController.cfc";
    var IMG_BASE  = "../../assets/images/products/";

    // ── Single global thumbOffset — used by both loadProductDetail and arrow buttons
    var thumbOffset  = 0;
    var thumbItemW   = 64;   // thumb 56px + gap 8px
    var visibleCount = 4;

    // ── SEARCH
    function getFilterParams(){
        return $("#searchForm").find(
            "input[name=search], input[name=min_price], input[name=max_price], " +
            "select[name=sort], select[name=category_id], select[name=expiry_months]"
        ).serialize();
    }

    function doSearch(page){
        $.ajax({
            url      : USER_CTRL,
            type     : "GET",
            data     : "method=search&p=" + page + "&" + getFilterParams(),
            dataType : "json",
            success  : function(res){
                if(res.success){
                    $("#productContainer").html(res.data.products);
                    $("#paginationContainer").html(res.data.pagination);
                } else {
                    alert(res.message);
                }
            },
            error : function(xhr){ console.log("Search error:", xhr.responseText); }
        });
    }

    $("#searchForm").on("submit", function(e){ e.preventDefault(); doSearch(1); });
    $(document).on("click", ".pageBtn", function(){ doSearch($(this).data("page")); });
    $("#clearBtn").on("click", function(){ $("#searchForm")[0].reset(); doSearch(1); });

    // ── ADD TO CART
    $(document).on("submit", ".addToCartForm", function(e){
        e.preventDefault();
        $.ajax({
            url      : CART_CTRL + "?method=add",
            type     : "POST",
            data     : $(this).serialize(),
            dataType : "json",
            success  : function(res){ alert(res.message); },
            error    : function(xhr){ console.log("Cart error:", xhr.responseText); }
        });
    });

    // ── ENQUIRY
    $(document).on("submit", ".enquiryForm", function(e){
        e.preventDefault();
        var productId = $(this).find("input[name='product_id']").val();
        $.ajax({
            url      : ENQ_CTRL + "?method=addEnquiry",
            type     : "POST",
            data     : { product_id: productId },
            dataType : "json",
            success  : function(res){
                if(res.status === "success"){
                    $("#enqMsg_"+productId).html('<div class="alert alert-success p-1 small">'+res.message+'</div>');
                    $("#enqBtnArea_"+productId).html('<a href="../../index.cfm?page=dashboard&section=enquiry" class="btn btn-info btn-sm w-100">View Enquiries</a>');
                } else {
                    $("#enqMsg_"+productId).html('<div class="alert alert-danger p-1 small">'+res.message+'</div>');
                }
            },
            error: function(xhr){ console.log("Enquiry error:", xhr.responseText); }
        });
    });

    // ── OPEN MODAL ON CARD CLICK
    var currentPid     = 0;
    var selectedRating = 1;

    $(document).on("click", ".product-card", function(){
        currentPid     = $(this).data("pid");
        selectedRating = 1;

        // reset everything
        $("#modalLoader").show();
        $("#modalContent").hide();
        $("#modalProductName").text("Loading...");
        $("#modalCategoryBadge").text("");
        $("#modalBusinessName").text("—");
        $("#modalPrice").text("—");
        $("#modalExpiry").text("—");
        $("#modalStars").html("");
        $("#modalAvgRating").text("");
        $("#modalTotalReviews").text("0");
        $("#modalCartArea").html("");
        $("#mainProductImg").attr("src", "https://via.placeholder.com/400");
        $("#thumbContainer").html("").css("transform","translateX(0)");
        $("#thumbPrev, #thumbNext").hide();
        thumbOffset = 0;
        $("#reviewComment").val("");
        $("#charCount").text("0");
        $("#reviewFormMsg").html("");
        updateStarPicker(1);

        $("#productDetailModal").modal("show");
        loadProductDetail(currentPid, 1);
    });

    // ── MODAL CLOSE — reset thumb strip
    $("#productDetailModal").on("hidden.bs.modal", function(){
        thumbOffset = 0;
        $("#thumbContainer").css("transform","translateX(0)");
        $("body").focus();
    });

    // ── THUMBNAIL CLICK
    $(document).on("click", ".thumb-img", function(){
        $("#mainProductImg").attr("src", $(this).data("src"));
        $(".thumb-img").removeClass("active");
        $(this).addClass("active");
    });

    // ── THUMBNAIL ARROW NEXT
    $(document).on("click", "#thumbNext", function(){
        var total    = $("#thumbContainer .thumb-img").length;
        var maxShift = Math.max(0, total - visibleCount);
        if(thumbOffset < maxShift){
            thumbOffset++;
            $("#thumbContainer").css("transform",
                "translateX(-" + (thumbOffset * thumbItemW) + "px)");
        }
    });

    // ── THUMBNAIL ARROW PREV
    $(document).on("click", "#thumbPrev", function(){
        if(thumbOffset > 0){
            thumbOffset--;
            $("#thumbContainer").css("transform",
                "translateX(-" + (thumbOffset * thumbItemW) + "px)");
        }
    });

    // ── LOAD PRODUCT DETAIL
    function loadProductDetail(pid, page){
        $.ajax({
            url      : REV_CTRL,
            type     : "GET",
            data     : { method: "getProductDetail", product_id: pid, p: page },
            dataType : "json",
            success  : function(res){
                if(res.status !== "success"){
                    alert(res.message || "Could not load product details.");
                    return;
                }

                $("#modalProductName").text(res.product_name);
                $("#modalCategoryBadge").text(res.category_name || "");
                $("#modalBusinessName").text(res.business_name || "");
                $("#modalPrice").text(res.price ? res.price + " /-" : "");
                $("#modalExpiry").text(res.expiry_date || "N/A");

                var avg = parseFloat(res.avg_rating) || 0;
                $("#modalStars").html(buildStarHTML(avg));
                $("#modalAvgRating").text(avg > 0 ? avg.toFixed(1) : "");
                $("#modalTotalReviews").text(res.total_reviews);
                $("#avgRatingDisplay").text(avg > 0 ? avg.toFixed(1) : "");
                $("#avgStarsDisplay").html(buildStarHTML(avg));
                $("#totalReviewsDisplay").text(res.total_reviews);
                buildStarBreakdown(res.star_counts, parseInt(res.total_reviews));

                // ── GALLERY
                var images = (res.images && res.images.length) ? res.images : [];
                if(!images.length && res.image) images = [res.image];

                thumbOffset = 0;
                $("#thumbContainer").css("transform","translateX(0)");

                if(images.length){
                    $("#mainProductImg").attr("src", IMG_BASE + images[0]);
                    var thumbHtml = "";
                    $.each(images, function(i, img){
                        var src = IMG_BASE + img;
                        thumbHtml += '<img class="thumb-img' + (i === 0 ? " active" : "") + '" '
                                   + 'src="' + src + '" data-src="' + src + '" '
                                   + 'alt="Image ' + (i + 1) + '">';
                    });
                    $("#thumbContainer").html(thumbHtml);
                    if(images.length > visibleCount){
                        $("#thumbNext").show();
                        $("#thumbPrev").hide(); // prev hidden at start
                    } else {
                        $("#thumbPrev, #thumbNext").hide();
                    }
                } else {
                    $("#mainProductImg").attr("src", "https://via.placeholder.com/400");
                    $("#thumbContainer").html("");
                    $("#thumbPrev, #thumbNext").hide();
                }

                // ── CART AREA
$('#chatVendorWrap').remove(); 

if(res.stock !== undefined){
    if(parseInt(res.stock) <= 0){
        $("#modalCartArea").html(
            '<p class="text-danger fw-bold small mb-2">Out of Stock</p>' +
            '<form class="enquiryForm">' +
            '<input type="hidden" name="product_id" value="' + pid + '">' +
            '<button type="submit" class="btn btn-warning btn-sm w-100">Request Product</button></form>'
        );
    } else {
        $("#modalCartArea").html(
            '<form class="addToCartForm">' +
            '<input type="hidden" name="product_id"   value="' + pid + '">' +
            '<input type="hidden" name="product_name" value="' + (res.product_name || "") + '">' +
            '<input type="hidden" name="price"        value="' + (res.price || "") + '">' +
            '<input type="hidden" name="image"        value="' + (res.image || "") + '">' +
            '<button type="submit" class="btn btn-success w-100">Add to Cart</button></form>'
        );
    }
}

// Insert chat button once with a wrapper id so it can be removed next time
$("#modalCartArea").after(
    '<div id="chatVendorWrap" class="mt-2">' +
    '<button class="btn btn-info w-100 chatWithVendorBtn"' +
    ' data-vendor-id="' + (res.vendor_id || '') + '"' +
    ' data-product-id="' + pid + '"' +
    ' data-product-name="' + (res.product_name || '') + '">' +
    '💬 Chat with Vendor' +
    '</button></div>'
);
                // ── REVIEW ELIGIBILITY
                $("#reviewFormSection, #alreadyReviewedMsg, #notEligibleMsg").hide();
                if(res.has_reviewed){
                    $("#alreadyReviewedMsg").show();
                } else if(res.can_review){
                    $("#reviewFormSection").show();
                    $("#submitReviewBtn").prop("disabled", false).text("Submit Review");
                } else {
                    $("#notEligibleMsg").show();
                }

                $("#reviewsList").html(res.reviews_html);
                $("#reviewsPagination").html(res.pagination);
                $("#modalLoader").hide();
                $("#modalContent").show();
            },
            error: function(xhr){ console.log("Detail load error:", xhr.responseText); }
        });
    }

    // ── STAR PICKER
    $(document).on("click", ".star-pick", function(){
        selectedRating = parseInt($(this).data("val"));
        $("#selectedRatingInput").val(selectedRating);
        updateStarPicker(selectedRating);
    });
    $(document).on("mouseenter", ".star-pick", function(){ updateStarPicker(parseInt($(this).data("val"))); });
    $(document).on("mouseleave", "#starPicker",  function(){ updateStarPicker(selectedRating); });

    function updateStarPicker(val){
        $(".star-pick").each(function(){
            var s = parseInt($(this).data("val"));
            $(this).removeClass("text-warning text-secondary")
                   .addClass(s <= val ? "text-warning" : "text-secondary");
        });
    }

    $(document).on("input", "#reviewComment", function(){ $("#charCount").text($(this).val().length); });

    // ── SUBMIT REVIEW
    $(document).on("click", "#submitReviewBtn", function(){
        var btn     = $(this);
        var comment = $("#reviewComment").val().trim();
        if(comment.length < 5)   { showReviewMsg("Comment must be at least 5 characters.", "danger"); return; }
        if(comment.length > 1000){ showReviewMsg("Comment must not exceed 1000 characters.", "danger"); return; }
        btn.prop("disabled", true).text("Submitting...");
        $.ajax({
            url      : REV_CTRL + "?method=addReview",
            type     : "POST",
            data     : { product_id: currentPid, rating: selectedRating, comment: comment },
            dataType : "json",
            success  : function(res){
                if(res.status === "success"){
                    showReviewMsg(res.message, "success");
                    setTimeout(function(){
                        $("#reviewFormSection").hide();
                        $("#alreadyReviewedMsg").show();
                        loadProductDetail(currentPid, 1);
                    }, 1000);
                } else {
                    showReviewMsg(res.message, "danger");
                    btn.prop("disabled", false).text("Submit Review");
                }
            },
            error: function(){ showReviewMsg("Network error. Please try again.", "danger"); btn.prop("disabled", false).text("Submit Review"); }
        });
    });

    $(document).on("click", ".reviewPageBtn", function(){
        var page = $(this).data("page");
        var pid  = $(this).data("pid");
        $("#modalLoader").show();
        $("#modalContent").hide();
        loadProductDetail(pid, page);
    });

    function buildStarHTML(avg){
        var html = "";
        for(var i = 1; i <= 5; i++) html += (i <= Math.round(avg)) ? "&#9733;" : "&#9734;";
        return html;
    }

    function buildStarBreakdown(counts, total){
        var html = "";
        for(var star = 5; star >= 1; star--){
            var cnt = parseInt(counts[star - 1]) || 0;
            var pct = total > 0 ? Math.round((cnt / total) * 100) : 0;
            html += '<div class="d-flex align-items-center gap-2 mb-1">'
                  + '<small class="text-nowrap" style="width:28px;">' + star + ' &#9733;</small>'
                  + '<div class="progress flex-grow-1" style="height:9px;">'
                  + '<div class="progress-bar bg-warning" style="width:' + pct + '%"></div></div>'
                  + '<small class="text-nowrap text-muted" style="width:28px;">' + cnt + '</small></div>';
        }
        $("#starBreakdown").html(html || '<p class="text-muted small">No ratings yet.</p>');
    }

    function showReviewMsg(msg, type){
        $("#reviewFormMsg").html('<div class="alert alert-' + type + ' py-2 mb-2">' + msg + '</div>');
        if(type === "success") setTimeout(function(){ $("#reviewFormMsg").html(""); }, 3000);
    }

     $(document).on("click", ".chatWithVendorBtn", function(){
        var btn         = $(this);
        var vendorId    = btn.data("vendor-id");
        var productId   = btn.data("product-id");
        var productName = btn.data("product-name");
 
        if(!vendorId || vendorId === ""){
            alert("Vendor not found for this product.");
            return;
        }
 
        btn.prop("disabled", true).text("Connecting...");
 
        $.ajax({
            url      : "../../controllers/chat/ChatController.cfc?method=startConversation",
            type     : "POST",
            data     : { vendor_id: vendorId, product_id: productId, product_name: productName },
            dataType : "json",
            success  : function(res){
                if(!res.success){
                    alert(res.message || "Could not start chat.");
                    btn.prop("disabled", false).text("💬 Chat with Vendor");
                    return;
                }
 
                var convId  = res.data.conversation_id;
                var introMsg = "Hi, I am interested in your product: " + productName;
 
   
                $.ajax({
                    url      : "../../controllers/chat/ChatController.cfc?method=sendMessage",
                    type     : "POST",
                    data     : { conversation_id: convId, message: introMsg },
                    dataType : "json",
                    complete : function(){
                      
                        window.location.href =
                            "../../index.cfm?page=dashboard&section=chat&conversation_id=" + convId;
                    }
                });
            },
            error : function(xhr){
                console.log("Chat error:", xhr.responseText);
                alert("Server error. Check console.");
                btn.prop("disabled", false).text("💬 Chat with Vendor");
            }
        });
    });
 

});
</script>