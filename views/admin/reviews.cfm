<cfif NOT structKeyExists(session, "user_id")>
    <cfabort>
</cfif>

<div class="container-fluid mt-4">

<h3 class="mb-3">Product Reviews</h3>
<div id="ajaxMessage"></div>

<!--- SEARCH FORM --->
<form id="reviewSearchForm" class="mb-4">

    <input type="hidden" name="rating" id="ratingValue" value="">
    <input type="hidden" name="status" id="statusValue" value="">

    <div class="row g-2">

        <div class="col-12 col-md-4">
            <input type="text" name="search" class="form-control"
                   placeholder="Product name, user, comment...">
        </div>

        <!--- RATING FILTER --->
        <div class="col-6 col-md-2">
            <div class="dropdown w-100">
                <button class="btn btn-outline-secondary dropdown-toggle w-100 text-start"
                        type="button" id="ratingDropdown"
                        data-bs-toggle="dropdown">All Ratings</button>
                <ul class="dropdown-menu w-100">
                    <li><a class="dropdown-item rating-option" href="#" data-value="">All</a></li>
                    <li><a class="dropdown-item rating-option" href="#" data-value="5">
                        &#9733;&#9733;&#9733;&#9733;&#9733; (5)</a></li>
                    <li><a class="dropdown-item rating-option" href="#" data-value="4">
                        &#9733;&#9733;&#9733;&#9733;&#9734; (4)</a></li>
                    <li><a class="dropdown-item rating-option" href="#" data-value="3">
                        &#9733;&#9733;&#9733;&#9734;&#9734; (3)</a></li>
                    <li><a class="dropdown-item rating-option" href="#" data-value="2">
                        &#9733;&#9733;&#9734;&#9734;&#9734; (2)</a></li>
                    <li><a class="dropdown-item rating-option" href="#" data-value="1">
                        &#9733;&#9734;&#9734;&#9734;&#9734; (1)</a></li>
                </ul>
            </div>
        </div>

        <!--- STATUS FILTER --->
        <div class="col-6 col-md-2">
            <div class="dropdown w-100">
                <button class="btn btn-outline-secondary dropdown-toggle w-100 text-start"
                        type="button" id="statusDropdown"
                        data-bs-toggle="dropdown">All Status</button>
                <ul class="dropdown-menu w-100">
                    <li><a class="dropdown-item status-option" href="#" data-value="">All</a></li>
                    <li><a class="dropdown-item status-option" href="#" data-value="active">Active</a></li>
                    <li><a class="dropdown-item status-option" href="#" data-value="removed">Removed</a></li>
                </ul>
            </div>
        </div>

        <div class="col-6 col-md-2 d-grid">
            <button type="submit" class="btn btn-primary">Search</button>
        </div>

        <div class="col-6 col-md-2 d-grid">
            <button type="button" id="clearBtn" class="btn btn-secondary">Clear</button>
        </div>

    </div>
</form>

<!--- TOTAL COUNT --->
<p class="text-muted small mb-2">
    Total: <strong><span id="totalCount">0</span></strong> reviews found
</p>

<!--- TABLE --->
<div class="table-responsive">
<table class="table table-bordered align-middle">
    <thead class="table-dark">
        <tr>
            <th>Product</th>
            <th>User</th>
            <th>Rating</th>
            <th>Comment</th>
            <th>Status</th>
            <th>Date</th>
            <th>Action</th>
        </tr>
    </thead>
    <tbody id="reviewTableBody">
        <tr>
            <td colspan="7" class="text-center py-4">
                <div class="spinner-border text-primary" role="status"></div>
            </td>
        </tr>
    </tbody>
</table>
</div>

<!--- PAGINATION --->
<div id="paginationContainer"
     class="d-flex justify-content-center flex-wrap gap-2 mt-3">
</div>

</div>

<script>
$(function(){

    var CTRL = "../../controllers/review/AdminReviewController.cfc";

    function showMsg(res){
        var cls = res.status === "success" ? "success" : "danger";
        $("#ajaxMessage").html(
            '<div class="alert alert-' + cls + '">' + 
            (res.message || "") + '</div>'
        );
        setTimeout(function(){ $("#ajaxMessage").html(""); }, 3000);
    }

    function loadReviews(page){
        var formData = $("#reviewSearchForm").serialize();
        formData     = formData.replace(/(&|^)p=\d+/, "");

        $.ajax({
            url      : CTRL,
            type     : "GET",
            data     : "method=searchReviews&p=" + (page || 1) + "&" + formData,
            dataType : "json",
            success  : function(res){
                if(res.status === "success"){
                    $("#reviewTableBody").html(res.html);
                    $("#paginationContainer").html(res.pagination);
                    $("#totalCount").text(res.total);
                } else {
                    showMsg(res);
                }
            },
            error: function(xhr){
                console.log("Load error:", xhr.responseText);
            }
        });
    }

    // DROPDOWNS
    $(document).on("click", ".rating-option", function(e){
        e.preventDefault();
        $("#ratingValue").val($(this).data("value"));
        $("#ratingDropdown").text($(this).text() || "All Ratings");
        loadReviews(1);
    });

    $(document).on("click", ".status-option", function(e){
        e.preventDefault();
        $("#statusValue").val($(this).data("value"));
        $("#statusDropdown").text($(this).text());
        loadReviews(1);
    });

    // SEARCH
    $("#reviewSearchForm").submit(function(e){
        e.preventDefault();
        loadReviews(1);
    });

    // CLEAR
    $("#clearBtn").click(function(){
        $("#reviewSearchForm")[0].reset();
        $("#ratingValue").val("");
        $("#statusValue").val("");
        $("#ratingDropdown").text("All Ratings");
        $("#statusDropdown").text("All Status");
        loadReviews(1);
    });

    // PAGINATION
    $(document).on("click", ".pageBtn", function(){
        loadReviews($(this).data("page"));
    });

    // TOGGLE REMOVE/RESTORE
    $(document).on("click", ".toggleReviewBtn", function(){
        var btn    = $(this);
        var id     = btn.data("id");
        var action = btn.hasClass("btn-danger") ? "Remove" : "Restore";

        if(!confirm(action + " this review?")) return;

        $.ajax({
            url      : CTRL + "?method=toggleReview",
            type     : "POST",
            data     : { id: id },
            dataType : "json",
            success  : function(res){
                showMsg(res);
                if(res.status === "success") loadReviews(1);
            }
        });
    });

    // INITIAL LOAD
    loadReviews(1);
});
</script>