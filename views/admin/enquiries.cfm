<cfif structKeyExists(session,"role_name") AND session.role_name EQ "vendor">
    <cfset vendorFilter = session.user_id>
<cfelse>
    <cfset vendorFilter = "">
</cfif>

<cfparam name="url.search" default="">
<cfparam name="url.status" default="">
<cfparam name="url.p" default="1">
<cfparam name="url.fromDate" default="">
<cfparam name="url.toDate" default="">

<cfset enquiryModel = createObject("component","models.Enquiry")>

<cfset currentPage = val(url.p)>
<cfif currentPage LT 1><cfset currentPage = 1></cfif>

<cfset limit = 2>

<cfset enquiries = enquiryModel.getAllEnquiries(
    search = url.search,
    status = url.status,
    page = currentPage,
    limit = limit,
    vendor_id = vendorFilter,
    fromDate = url.fromDate,
    toDate = url.toDate
)>

<cfset totalRecords = enquiryModel.getEnquiryCount(
    search = url.search,
    status = url.status,
    vendor_id = vendorFilter,
    fromDate = url.fromDate,
    toDate = url.toDate
)>
<cfset totalPages = ceiling(totalRecords / limit)>

<div class="container-fluid mt-4">

<h3>Product Enquiries</h3>

<div id="ajaxMessage"></div>

<!-- SEARCH -->
<cfoutput>
<form id="searchForm" class="mb-4">

    <input type="hidden" name="status" id="statusValue" value="#url.status#">

    <div class="row g-2">

        <div class="col-12 col-md-3">
            <input type="text" name="search" value="#url.search#"
                   placeholder="Product or user..." class="form-control">
        </div>

        <div class="col-12 col-md-2">
            <div class="dropdown w-100">
                <button class="btn btn-outline-secondary dropdown-toggle w-100 text-start"
                        type="button" id="statusDropdown"
                        data-bs-toggle="dropdown" aria-expanded="false">
                    <cfif url.status EQ "pending">Pending
                    <cfelseif url.status EQ "fulfilled">Fulfilled
                    <cfelse>All Status
                    </cfif>
                </button>
                <ul class="dropdown-menu w-100" aria-labelledby="statusDropdown">
                    <li><a class="dropdown-item status-option" href="##" data-value="">All Status</a></li>
                    <li><a class="dropdown-item status-option" href="##" data-value="pending">Pending</a></li>
                    <li><a class="dropdown-item status-option" href="##" data-value="fulfilled">Fulfilled</a></li>
                </ul>
            </div>
        </div>

        <div class="col-6 col-md-2">
            <input type="date" name="fromDate" value="#url.fromDate#" class="form-control">
        </div>

        <div class="col-6 col-md-2">
            <input type="date" name="toDate" value="#url.toDate#" class="form-control">
        </div>

        <div class="col-6 col-md-2 d-grid">
            <button type="submit" class="btn btn-primary">Search</button>
        </div>

        <div class="col-6 col-md-1 d-grid">
            <button type="button" id="resetBtn" class="btn btn-outline-secondary">Reset</button>
        </div>

    </div>

</form>
</cfoutput>

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

<tbody id="tableBody">

<cfif enquiries.recordCount EQ 0>
    <tr><td colspan="8" class="text-center">No data</td></tr>
<cfelse>

<cfoutput query="enquiries">
<tr id="row_#product_id#">
    <td>#user_name#</td>
    <td>#product_name#</td>
    <td>
        <img src="../../assets/images/products/#image#"
             width="50" height="50" style="object-fit:cover;">
    </td>
    <td>#price#</td>
    <td class="stockCell">#stock#</td>
    <td class="statusCell">
        <cfif status EQ "pending">
            <span class="badge bg-warning text-dark">Pending</span>
        <cfelse>
            <span class="badge bg-success">Restocked</span>
        </cfif>
    </td>
    <td>#dateFormat(created_at,"dd-mmm-yyyy")#</td>
    <td>
        <cfif status EQ "pending">
            <button class="btn btn-warning btn-sm restockBtn"
                data-id="#product_id#"
                data-name="#product_name#"
                data-category="#category_name#"
                data-price="#price#"
                data-stock="#stock#">
                Restock
            </button>
        <cfelse>
            <span class="text-muted">Completed</span>
        </cfif>
    </td>
</tr>
</cfoutput>

</cfif>

</tbody>
</table>
</div>

<!-- PAGINATION -->
<cfif totalPages GT 0>
<cfset groupSize = 4>
<cfset pageGroup = ceiling(currentPage / groupSize)>
<cfset startPage = (pageGroup - 1) * groupSize + 1>
<cfset endPage = min(startPage + groupSize - 1, totalPages)>

<cfoutput>
<div class="d-flex justify-content-center flex-wrap gap-2 mt-3">

    <cfif startPage GT 1>
        <button class="btn btn-outline-primary btn-sm pageBtn"
                data-page="#startPage - 1#">&laquo; Prev</button>
    </cfif>

    <cfloop from="#startPage#" to="#endPage#" index="i">
        <button class="btn btn-sm pageBtn <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
                data-page="#i#">#i#</button>
    </cfloop>

    <cfif endPage LT totalPages>
        <button class="btn btn-outline-primary btn-sm pageBtn"
                data-page="#endPage + 1#">Next &raquo;</button>
    </cfif>

</div>
</cfoutput>
</cfif>

</div>

<!-- RESTOCK FORM TEMPLATE -->
<div id="restockTemplate" style="display:none;">
    <div class="card shadow-sm p-3 mt-2">
        <h5>Restock Product</h5>
        <form id="restockForm">
            <input type="hidden" name="action" value="restockProduct">
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
                <button class="btn btn-success">Update Stock</button>
                <button type="button" class="btn btn-secondary cancelRestock">Cancel</button>
            </div>
        </form>
    </div>
</div>


<script>
$(document).ready(function(){

    // STATUS DROPDOWN
    $(document).on("click", ".status-option", function(e){
        e.preventDefault();
        $("#statusValue").val($(this).data("value"));
        $("#statusDropdown").text($(this).text());
    });

    function showMsg(res){
        $("#ajaxMessage").html(
            '<div id="msgBox" class="alert alert-' +
            (res.status==="success"?"success":"danger") +
            '">'+res.message+'</div>'
        );
        setTimeout(()=>$("#msgBox").fadeOut(),3000);
    }

    // RESTOCK OPEN
    $(document).on("click",".restockBtn",function(){
        let btn=$(this);
        let row=btn.closest("tr");
        $(".restockRow").remove();
        let formHtml=$("#restockTemplate").html();
        row.after('<tr class="restockRow"><td colspan="8">'+formHtml+'</td></tr>');
        $("#restock_product_id").val(btn.data("id"));
        $("#restock_product_name").val(btn.data("name"));
        $("#restock_category").val(btn.data("category"));
        $("#restock_price").val(btn.data("price"));
        $("#restock_stock").val(btn.data("stock"));
    });

    // CANCEL RESTOCK
    $(document).on("click",".cancelRestock",function(){
        $(".restockRow").remove();
    });

    // SUBMIT RESTOCK
    $(document).on("submit","#restockForm",function(e){
        e.preventDefault();
        $.post("../../controllers/AdminEnquiryController.cfm",
            $(this).serialize(),
            function(res){
                showMsg(res);
                if(res.status==="success"){
                    $(".restockRow").remove();
                    let row=$("#row_"+res.product_id);
                    row.find(".statusCell").html('<span class="badge bg-success">Restocked</span>');
                    row.find(".restockBtn").remove();
                }
            },"json");
    });

    // SEARCH
    $("#searchForm").submit(function(e){
        e.preventDefault();
        $.get("../../controllers/AdminEnquiryController.cfm",
            "action=search&"+$(this).serialize(),
            function(res){ $("#tableBody").html(res); }
        );
    });

    // PAGINATION
    $(document).on("click",".pageBtn",function(){
        let page=$(this).data("page");
        $(".pageBtn").removeClass("btn-primary").addClass("btn-outline-primary");
        $(this).removeClass("btn-outline-primary").addClass("btn-primary");
        $.get("../../controllers/AdminEnquiryController.cfm",
            "action=search&p="+page+"&"+$("#searchForm").serialize(),
            function(res){ $("#tableBody").html(res); }
        );
    });

    // RESET
    $("#resetBtn").click(function(){
        $("input[name='search']").val('');
        $("input[name='fromDate']").val('');
        $("input[name='toDate']").val('');
        $("#statusValue").val('');
        $("#statusDropdown").text('All Status');
        $.get("../../controllers/AdminEnquiryController.cfm",
            "action=search",
            function(res){ $("#tableBody").html(res); }
        );
    });

});
</script>