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

<div class="container mt-4">
    <h3 class="mb-3">Coupon Management</h3>

    <!-- ALERT -->
    <cfif structKeyExists(url, "message")>
        <div id="alertBox" class="alert 
            <cfif structKeyExists(url, "type") AND url.type EQ 'success'>
                alert-success
            <cfelse>
                alert-danger
            </cfif>">
            <cfoutput>#url.message#</cfoutput>
        </div>
    </cfif>

    <!-- add button-->
    <button class="btn btn-primary mb-3" 
        onclick="document.getElementById('addForm').style.display='block'">
        Add Coupon
    </button>

    <!-- add from -->
    <div id="addForm" style="display:<cfif url.showForm EQ 1>block<cfelse>none</cfif>;">
        <form method="post" action="../../controllers/CouponController.cfm" class="mb-4">

            <input type="hidden" name="action" value="add">

            <div class="row">

                <div class="col-md-2">
                    <input type="text" name="code" class="form-control" placeholder="Code" required>
                </div>

                <div class="col-md-2">
                    <select name="type" class="form-control">
                        <option value="percent">%</option>
                        <option value="fixed">rs</option>
                    </select>
                </div>

                <div class="col-md-2">
                    <input type="number" name="value" class="form-control" placeholder="Value" required>
                </div>

                <div class="col-md-2">
                    <input type="number" name="min" class="form-control" placeholder="Min Amount">
                </div>

                <div class="col-md-2">
                    <input type="number" name="max" class="form-control" placeholder="Max Discount">
                </div>

                <div class="col-md-2">
                    <input type="date" name="expiry" class="form-control">
                </div>

                <div class="col-md-2 mt-2">
                    <button class="btn btn-primary w-100">Add</button>
                    <button type="button" class="btn btn-secondary btn-sm mt-2 w-100"
                        onclick="document.getElementById('addForm').style.display='none'">
                        Cancel
                    </button>
                </div>

            </div>
        </form>
    </div>

    <!-- search -->
    <cfoutput>
    <form method="get" action="../../index.cfm" class="mb-3">

        <input type="hidden" name="page" value="dashboard">
        <input type="hidden" name="section" value="coupons">

        <input type="text" name="search" value="#url.search#" 
               placeholder="Search coupon..." 
               class="form-control w-25 d-inline">

        <select name="status" class="form-control w-25 d-inline">
            <option value="">All</option>
            <option value="active" <cfif url.status EQ "active">selected</cfif>>Active</option>
            <option value="blocked" <cfif url.status EQ "blocked">selected</cfif>>Blocked</option>
        </select>

        <button class="btn btn-primary btn-sm">Apply</button>
    </form>
    </cfoutput>

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
            <th>Expiry Date</th>
            <th>Actions</th>
        </tr>
    </thead>

    <tbody>
    <cfoutput query="coupons">

        <cfif url.editId EQ id>

            <tr>
            <form method="post" action="../../controllers/CouponController.cfm">

                <td>#id#</td>

                <td>
                    <input type="text" name="code" value="#code#" class="form-control">
                </td>

                <td>
                    <select name="type" class="form-control">
                        <option value="percent" <cfif discount_type EQ "percent">selected</cfif>>%</option>
                        <option value="fixed" <cfif discount_type EQ "fixed">selected</cfif>>₹</option>
                    </select>
                </td>

                <td>
                    <input type="number" name="value" value="#discount_value#" class="form-control">
                </td>

                <td>
                    <input type="number" name="min" value="#min_amount#" class="form-control">
                </td>

                <td>
                    <input type="number" name="max" value="#max_discount#" class="form-control">
                </td>

                <td>
                    <cfif is_active EQ 1>
                        <span class="badge bg-success">Active</span>
                    <cfelse>
                        <span class="badge bg-warning">Blocked</span>
                    </cfif>
                </td>

                <td>
                    <input type="date" name="expiry" 
                           value="#dateFormat(expiry_date, 'yyyy-mm-dd')#" 
                           class="form-control">
                </td>

                <td>
                    <input type="hidden" name="id" value="#id#">
                    <input type="hidden" name="action" value="update">

                    <button class="btn btn-success btn-sm">Save</button>

                    <a href="../../index.cfm?page=dashboard&section=coupons" 
                       class="btn btn-secondary btn-sm">Cancel</a>
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
                        <span class="text-success">Active</span>
                    <cfelse>
                        <span class="text-warning">Blocked</span>
                    </cfif>
                </td>

                <td>#dateFormat(expiry_date, "dd-mmm-yyyy")#</td>

                <td>
                    <a href="../../index.cfm?page=dashboard&section=coupons&editId=#id#" 
                       class="btn btn-warning btn-sm">Edit</a>

                    <a href="../../controllers/CouponController.cfm?action=toggle&id=#id#"
                       class="btn btn-danger btn-sm">
                       <cfif is_active EQ 1>Block<cfelse>Unblock</cfif>
                    </a>
                </td>
            </tr>

        </cfif>

    </cfoutput>
    </tbody>
</table>

    <!-- pagination -->
    <cfoutput>
    <div class="mt-4">

        <cfloop from="1" to="#totalPages#" index="i">

            <a href="?page=dashboard&section=coupons&p=#i#&search=#url.search#&status=#url.status#"
               class="btn btn-sm <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>">

                #i#

            </a>

        </cfloop>

    </div>
    </cfoutput>

</div>

<script>
setTimeout(function () {
    var alertBox = document.getElementById("alertBox");
    if (alertBox) {
        alertBox.style.display = "none";
    }
}, 5000);
</script>