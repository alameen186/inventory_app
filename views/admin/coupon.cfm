<cfset couponModel = createObject("component", "models.Coupon")>

<cfparam name="url.editId" default="0">
<cfparam name="url.showForm" default="0">
<cfparam name="url.search" default="">
<cfparam name="url.status" default="">
<cfparam name="url.p" default="1">

<cfset currentPage = val(url.p)>
<cfif currentPage LT 1>
    <cfset currentPage = 1>
</cfif>

<cfset limit = 2>

<cfset coupons = couponModel.getCoupon(
    search = trim(url.search),
    status = url.status,
    page = currentPage,
    limit = limit
)>

<cfset totalRecords = couponModel.getCouponCount(
    search = trim(url.search),
    status = url.status
)>

<cfset totalPages = ceiling(totalRecords / limit)>

<div class="container-fluid mt-4">
    <h3 class="mb-3">Coupon Management</h3>

    <button class="btn btn-primary mb-3"
        onclick="document.getElementById('addForm').style.display='block'">
        Add Coupon
    </button>

    <div id="ajaxMessage"></div>

    <!-- Add Form -->
    <div id="addForm" style="display:<cfif url.showForm EQ 1>block<cfelse>none</cfif>;">
        <form method="post" id="createCouponForm" class="mb-4">
            <input type="hidden" name="action" value="add">

            <div class="row g-2">
                <div class="col-6 col-md-2">
                    <input type="text" name="code" class="form-control" placeholder="Code" required>
                </div>
                <div class="col-6 col-md-2">
                    <select name="type" class="form-control">
                        <option value="percent">%</option>
                        <option value="fixed">Rs</option>
                    </select>
                </div>
                <div class="col-6 col-md-2">
                    <input type="number" name="value" class="form-control" placeholder="Value" required>
                </div>
                <div class="col-6 col-md-2">
                    <input type="number" name="min" class="form-control" placeholder="Min Amount">
                </div>
                <div class="col-6 col-md-2">
                    <input type="number" name="max" class="form-control" placeholder="Max Discount">
                </div>
                <div class="col-6 col-md-2">
                    <input type="date" name="expiry" class="form-control">
                </div>
                <div class="col-6 col-md-2">
                    <button class="btn btn-primary w-100">Add</button>
                </div>
                <div class="col-6 col-md-2">
                    <button type="button" class="btn btn-secondary w-100"
                        onclick="document.getElementById('addForm').style.display='none'">
                        Cancel
                    </button>
                </div>
            </div>
        </form>
    </div>

    <!-- Search Form -->
    <cfoutput>
    <form method="get" id="searchForm" class="mb-3">
        <input type="hidden" name="page" value="dashboard">
        <input type="hidden" name="section" value="coupons">
        <input type="hidden" name="status" id="statusValue" value="#url.status#">

        <div class="row g-2">
            <div class="col-12 col-md-4">
                <input type="text" name="search" value="#url.search#"
                    placeholder="Search coupon..."
                    class="form-control">
            </div>

            <div class="col-12 col-md-4">
                <div class="dropdown w-100">
                    <button class="btn btn-outline-secondary dropdown-toggle w-100 text-start"
                            type="button" id="statusDropdown"
                            data-bs-toggle="dropdown" aria-expanded="false">
                        <cfif url.status EQ "active">Active
                        <cfelseif url.status EQ "blocked">Blocked
                        <cfelse>All
                        </cfif>
                    </button>
                    <ul class="dropdown-menu w-100" aria-labelledby="statusDropdown">
                        <li><a class="dropdown-item status-option" href="##" data-value="">All</a></li>
                        <li><a class="dropdown-item status-option" href="##" data-value="active">Active</a></li>
                        <li><a class="dropdown-item status-option" href="##" data-value="blocked">Blocked</a></li>
                    </ul>
                </div>
            </div>

            <div class="col-12 col-md-4 d-grid">
                <button class="btn btn-primary">Apply</button>
            </div>
        </div>
    </form>
    </cfoutput>

    <!-- Table -->
    <div class="table-responsive">
    <table class="table table-bordered table-striped table-hover shadow-sm mt-3">
        <thead class="table-dark">
            <tr>
                <th>ID</th>
                <th>Code</th>
                <th>Type</th>
                <th>Value</th>
                <th>Min</th>
                <th>Max</th>
                <th>Status</th>
                <th>Expiry</th>
                <th>Actions</th>
            </tr>
        </thead>

        <tbody id="couponTableBody">
        <cfoutput query="coupons">

            <cfif url.editId EQ id>
            <tr>
            <form class="updateForm" method="post">
                <td>#id#</td>
                <td><input type="text" name="code" value="#code#" class="form-control" style="min-width:80px;"></td>
                <td>
                    <select name="type" class="form-control" style="min-width:60px;">
                        <option value="percent" <cfif discount_type EQ "percent">selected</cfif>>%</option>
                        <option value="fixed" <cfif discount_type EQ "fixed">selected</cfif>>₹</option>
                    </select>
                </td>
                <td><input type="number" name="value" value="#discount_value#" class="form-control" style="min-width:70px;"></td>
                <td><input type="number" name="min" value="#min_amount#" class="form-control" style="min-width:70px;"></td>
                <td><input type="number" name="max" value="#max_discount#" class="form-control" style="min-width:70px;"></td>
                <td>
                    <cfif is_active EQ 1>
                        <span class="badge bg-success">Active</span>
                    <cfelse>
                        <span class="badge bg-warning">Blocked</span>
                    </cfif>
                </td>
                <td><input type="date" name="expiry" value="#dateFormat(expiry_date, 'yyyy-mm-dd')#" class="form-control" style="min-width:130px;"></td>
                <td>
                    <input type="hidden" name="id" value="#id#">
                    <input type="hidden" name="action" value="update">
                    <div class="d-flex flex-wrap gap-1">
                        <button class="btn btn-success btn-sm">Save</button>
                        <a href="../../index.cfm?page=dashboard&section=coupons"
                           class="btn btn-secondary btn-sm">Cancel</a>
                    </div>
                </td>
            </form>
            </tr>

            <cfelse>
            <tr>
                <td>#id#</td>
                <td>#code#</td>
                <td>#discount_type#</td>
                <td>#discount_value#</td>
                <td>#min_amount#</td>
                <td>#max_discount#</td>
                <td>
                    <cfif is_active EQ 1>
                        <span class="badge bg-success">Active</span>
                    <cfelse>
                        <span class="badge bg-warning text-dark">Blocked</span>
                    </cfif>
                </td>
                <td>#dateFormat(expiry_date, "dd-mmm-yyyy")#</td>
                <td>
                    <div class="d-flex flex-wrap gap-1">
                        <a href="../../index.cfm?page=dashboard&section=coupons&editId=#id#"
                           class="btn btn-warning btn-sm">Edit</a>
                        <button class="toggleBtn btn btn-sm #iif(is_active EQ 1, de('btn-danger'), de('btn-success'))#"
                            data-id="#id#" data-status="#is_active#">
                            <cfif is_active EQ 1>Block<cfelse>Unblock</cfif>
                        </button>
                    </div>
                </td>
            </tr>
            </cfif>

        </cfoutput>
        </tbody>
    </table>
    </div>

    <!-- Pagination -->
    <cfoutput>
    <div class="d-flex justify-content-center flex-wrap gap-2 mt-3">
        <cfloop from="1" to="#totalPages#" index="i">
            <button class="btn btn-sm pageBtn <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
                data-page="#i#">#i#</button>
        </cfloop>
    </div>
    </cfoutput>

</div>

<script>
$(function(){

    // STATUS DROPDOWN
    $(document).on("click", ".status-option", function(e){
        e.preventDefault();
        $("#statusValue").val($(this).data("value"));
        $("#statusDropdown").text($(this).text());
    });

    function msg(res){
        $("#ajaxMessage").html(
            '<div class="alert alert-'+(res.status=="success"?"success":"danger")+'">'+res.message+'</div>'
        );
        setTimeout(()=>$("#ajaxMessage").fadeOut(),3000);
    }

    // ADD
    $("#createCouponForm").submit(function(e){
        e.preventDefault();
        $.post("../../controllers/CouponController.cfm",
            $(this).serialize(),
            function(res){
                msg(res);
                if(res.status=="success") location.reload();
            },"json");
    });

    // UPDATE
    $(document).on("submit",".updateForm",function(e){
        e.preventDefault();
        $.post("../../controllers/CouponController.cfm",
            $(this).serialize(),
            function(res){
                msg(res);
                if(res.status=="success") location.reload();
            },"json");
    });

    // TOGGLE
    $(document).on("click",".toggleBtn",function(){
        let btn=$(this);
        $.get("../../controllers/CouponController.cfm",
            {action:"toggle", id:btn.data("id")},
            function(res){
                msg(res);
                if(res.status=="success") location.reload();
            },"json");
    });

    // SEARCH
    $("#searchForm").submit(function(e){
        e.preventDefault();
        $.get("../../controllers/CouponController.cfm",
            "action=search&"+$(this).serialize(),
            function(res){
                $("#couponTableBody").html(res);
            });
    });

    // PAGINATION
    $(document).on("click",".pageBtn",function(){
        let page=$(this).data("page");
        $.get("../../controllers/CouponController.cfm",
            "action=search&p="+page+"&"+$("#searchForm").serialize(),
            function(res){
                $("#couponTableBody").html(res);
            });
    });

});
</script>