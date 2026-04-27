<cfif NOT structKeyExists(session, "user_id")>
    <cfabort>
</cfif>

<div class="container-fluid mt-4">

<h3>Product Enquiries</h3>

<div id="ajaxMessage"></div>

<!-- SEARCH -->
<form id="searchForm" class="mb-4">
    <input type="hidden" name="status" id="statusValue" value="">
    <div class="row g-2">

        <div class="col-12 col-md-3">
            <input type="text" name="search"
                   placeholder="Product or user..." class="form-control">
        </div>

        <div class="col-12 col-md-2">
            <div class="dropdown w-100">
                <button class="btn btn-outline-secondary dropdown-toggle w-100 text-start"
                        type="button" id="statusDropdown"
                        data-bs-toggle="dropdown">All Status</button>
                <ul class="dropdown-menu w-100">
                    <li><a class="dropdown-item status-option" href="#" data-value="">All Status</a></li>
                    <li><a class="dropdown-item status-option" href="#" data-value="pending">Pending</a></li>
                    <li><a class="dropdown-item status-option" href="#" data-value="fulfilled">Fulfilled</a></li>
                </ul>
            </div>
        </div>

        <div class="col-6 col-md-2">
            <input type="date" name="fromDate" class="form-control">
        </div>

        <div class="col-6 col-md-2">
            <input type="date" name="toDate" class="form-control">
        </div>

        <div class="col-6 col-md-2 d-grid">
            <button type="submit" class="btn btn-primary">Search</button>
        </div>

        <div class="col-6 col-md-1 d-grid">
            <button type="button" id="resetBtn" class="btn btn-outline-secondary">Reset</button>
        </div>

    </div>
</form>

<!-- TABLE -->
<div class="table-responsive">
<table class="table table-bordered mt-3">
    <thead class="table-dark">
        <tr>
            <th>User</th>
            <th>Product</th>
            <th>Image</th>
            <th>Price</th>
            <th>Stock</th>
            <th>Status</th>
            <th>Date</th>
            <th>Action</th>
        </tr>
    </thead>
    <tbody id="tableBody"></tbody>
</table>
</div>

<!-- PAGINATION -->
<div id="paginationContainer" class="d-flex justify-content-center flex-wrap gap-2 mt-3"></div>

</div>

<!-- RESTOCK FORM TEMPLATE -->
<div id="restockTemplate" style="display:none;">
    <div class="card shadow-sm p-3 mt-2">
        <h5>Restock Product</h5>
        <form id="restockForm">
            <input type="hidden" name="product_id" id="restock_product_id">
            <div class="row g-2 mb-2">
                <div class="col-12 col-md-6">
                    <label class="form-label">Product Name</label>
                    <input type="text" id="restock_product_name" class="form-control" readonly>
                </div>
                <div class="col-12 col-md-6">
                    <label class="form-label">Category</label>
                    <input type="text" id="restock_category" class="form-control" readonly>
                </div>
                <div class="col-6 col-md-3">
                    <label class="form-label">Price</label>
                    <input type="text" id="restock_price" class="form-control" readonly>
                </div>
                <div class="col-6 col-md-3">
                    <label class="form-label">Current Stock</label>
                    <input type="text" id="restock_stock" class="form-control" readonly>
                </div>
                <div class="col-12 col-md-6">
                    <label class="form-label">Add New Stock</label>
                    <input type="number" name="add_stock" class="form-control" required min="1">
                </div>
            </div>
            <div class="d-flex gap-2">
                <button type="submit" class="btn btn-success">Update Stock</button>
                <button type="button" class="btn btn-secondary cancelRestock">Cancel</button>
            </div>
        </form>
    </div>
</div>

<script>
$(function(){

    var ENQ_CTRL = "../../controllers/AdminEnquiryController.cfc";

    // MESSAGE
    function showMsg(res){
        $("#ajaxMessage").html(
            '<div class="alert alert-'+(res.status==="success"?"success":"danger")+'">'+
            (res.message||"")+'</div>'
        );
        setTimeout(()=>$("#ajaxMessage").html(""), 3000);
    }

    // LOAD ENQUIRIES
    function loadEnquiries(page){
        let formData = $("#searchForm").serialize();
        formData = formData.replace(/(&|^)p=\d+/,"");
        let finalData = "method=searchEnquiries&p=" + page + "&" + formData;

        $.ajax({
            url      : ENQ_CTRL,
            type     : "GET",
            data     : finalData,
            dataType : "json",
            success  : function(res){
                if(res.status === "success"){
                    $(".restockRow").remove();
                    $("#tableBody").html(res.html);
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

    // STATUS DROPDOWN
    $(document).on("click", ".status-option", function(e){
        e.preventDefault();
        $("#statusValue").val($(this).data("value"));
        $("#statusDropdown").text($(this).text());
        loadEnquiries(1);
    });

    // SEARCH
    $("#searchForm").submit(function(e){
        e.preventDefault();
        loadEnquiries(1);
    });

    // PAGINATION
    $(document).on("click", ".pageBtn", function(){
        loadEnquiries($(this).data("page"));
    });

    // RESET
    $("#resetBtn").click(function(){
        $("#searchForm")[0].reset();
        $("#statusValue").val('');
        $("#statusDropdown").text('All Status');
        loadEnquiries(1);
    });

    // RESTOCK OPEN
    $(document).on("click", ".restockBtn", function(){
        let btn = $(this);
        let row = btn.closest("tr");
        $(".restockRow").remove();
        let formHtml = $("#restockTemplate").html();
        row.after('<tr class="restockRow"><td colspan="8">'+formHtml+'</td></tr>');
        $("#restock_product_id").val(btn.data("id"));
        $("#restock_product_name").val(btn.data("name"));
        $("#restock_category").val(btn.data("category"));
        $("#restock_price").val(btn.data("price"));
        $("#restock_stock").val(btn.data("stock"));
    });

    // CANCEL RESTOCK
    $(document).on("click", ".cancelRestock", function(){
        $(".restockRow").remove();
    });

    // SUBMIT RESTOCK
    $(document).on("submit", "#restockForm", function(e){
        e.preventDefault();
        $.ajax({
            url      : ENQ_CTRL + "?method=restockProduct",
            type     : "POST",
            data     : $(this).serialize(),
            dataType : "json",
            success  : function(res){
                showMsg(res);
                if(res.status === "success"){
                    $(".restockRow").remove();
                    let row = $("#row_"+res.product_id);
                    row.find(".statusCell").html('<span class="badge bg-success">Restocked</span>');
                    row.find(".restockBtn").replaceWith('<span class="text-muted">Completed</span>');
                }
            },
            error : function(xhr){
                console.log("Restock error:", xhr.responseText);
            }
        });
    });

    // INITIAL LOAD
    loadEnquiries(1);

});
</script>