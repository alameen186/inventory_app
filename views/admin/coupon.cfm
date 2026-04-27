<cfif NOT structKeyExists(session,"role_id") OR session.role_id NEQ 1>
    <cfabort>
</cfif>

<cfset couponModel  = createObject("component","models.Coupon")>
<cfset limit        = 2>
<cfset groupSize    = 4>
<cfparam name="url.search" default="">
<cfparam name="url.status" default="">
<cfparam name="url.p"      default="1">

<cfset currentPage  = val(url.p) GT 0 ? val(url.p) : 1>
<cfset coupons      = couponModel.getCoupon(search=trim(url.search), status=url.status, page=currentPage, limit=limit)>
<cfset totalRecords = couponModel.getCouponCount(search=trim(url.search), status=url.status)>
<cfset totalPages   = ceiling(totalRecords / limit)>
<cfset pageGroup    = ceiling(currentPage / groupSize)>
<cfset startPage    = (pageGroup - 1) * groupSize + 1>
<cfset endPage      = min(startPage + groupSize - 1, totalPages)>

<div class="container-fluid mt-4">

    <h3 class="mb-3">Coupon Management</h3>
    <div id="ajaxMessage"></div>

    <!--- ADD COUPON BUTTON + PANEL --->
    <button id="showAddForm" class="btn btn-success mb-3">+ Add Coupon</button>

    <div id="addCouponPanel" style="display:none;" class="card p-3 mb-3">
        <h6 class="mb-3">New Coupon</h6>
        <div class="row g-2">
            <div class="col-6 col-md-2">
                <label class="form-label small">Code</label>
                <input id="cc_code" class="form-control text-uppercase" placeholder="e.g. SAVE20"
                       oninput="this.value=this.value.toUpperCase()">
            </div>
            <div class="col-6 col-md-2">
                <label class="form-label small">Type</label>
                <select id="cc_type" class="form-control">
                    <option value="percent">% Percent</option>
                    <option value="fixed">₹ Fixed</option>
                </select>
            </div>
            <div class="col-6 col-md-2">
                <label class="form-label small">Value</label>
                <input id="cc_value" type="number" min="1" class="form-control" placeholder="e.g. 10">
            </div>
            <div class="col-6 col-md-2">
                <label class="form-label small">Min Purchase</label>
                <input id="cc_min" type="number" min="0" class="form-control" placeholder="e.g. 500">
            </div>
            <div class="col-6 col-md-2">
                <label class="form-label small">Max Discount</label>
                <input id="cc_max" type="number" min="0" class="form-control" placeholder="e.g. 200">
            </div>
            <div class="col-6 col-md-2">
                <label class="form-label small">Expiry Date</label>
                <input id="cc_expiry" type="date" class="form-control">
            </div>
        </div>
        <div class="d-flex gap-2 mt-3">
            <button id="submitCreate" class="btn btn-success">Create Coupon</button>
            <button id="cancelAdd"    class="btn btn-secondary">Cancel</button>
        </div>
    </div>

    <!--- SEARCH FORM --->
    <form id="searchForm" class="mb-3">
        <input type="hidden" name="status" id="statusValue"
               value="<cfoutput>#encodeForHTMLAttribute(url.status)#</cfoutput>">
        <div class="row g-2">

            <div class="col-12 col-md-4">
                <input type="text" name="search"
                       value="<cfoutput>#encodeForHTML(url.search)#</cfoutput>"
                       class="form-control" placeholder="Search coupon code...">
            </div>

            <div class="col-12 col-md-4">
                <div class="dropdown w-100">
                    <button class="btn btn-outline-secondary dropdown-toggle w-100 text-start"
                            type="button" id="statusDropdown"
                            data-bs-toggle="dropdown" aria-expanded="false">
                        <cfoutput>
                        <cfif url.status EQ "active">Active
                        <cfelseif url.status EQ "blocked">Blocked
                        <cfelse>All Status</cfif>
                        </cfoutput>
                    </button>
                    <ul class="dropdown-menu w-100" aria-labelledby="statusDropdown">
                        <li><a class="dropdown-item status-option" href="#" data-value="">All</a></li>
                        <li><a class="dropdown-item status-option" href="#" data-value="active">Active</a></li>
                        <li><a class="dropdown-item status-option" href="#" data-value="blocked">Blocked</a></li>
                    </ul>
                </div>
            </div>

            <div class="col-12 col-md-4 d-grid">
                <button class="btn btn-primary">Apply</button>
            </div>
        </div>
    </form>

    <!--- TABLE --->
    <div class="table-responsive">
        <table class="table table-bordered align-middle">
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
                <cfif coupons.recordCount EQ 0>
                    <tr><td colspan="9" class="text-center">No coupons found.</td></tr>
                <cfelse>
                    <cfoutput query="coupons">
                    <tr id="couponRow_#id#">
                        <td>#id#</td>
                        <td>#encodeForHTML(code)#</td>
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
                        <td>#dateFormat(expiry_date,"dd-mmm-yyyy")#</td>
                        <td>
                            <div class="d-flex flex-wrap gap-1">
                                <button class="btn btn-warning btn-sm editBtn"
                                    data-id="#id#"
                                    data-code="#encodeForHTMLAttribute(code)#"
                                    data-type="#discount_type#"
                                    data-value="#discount_value#"
                                    data-min="#min_amount#"
                                    data-max="#max_discount#"
                                    data-expiry="#dateFormat(expiry_date,'yyyy-mm-dd')#">Edit</button>
                                <button class="btn btn-sm toggleBtn
                                    #is_active EQ 1 ? 'btn-danger' : 'btn-success'#"
                                    data-id="#id#"
                                    data-code="#encodeForHTMLAttribute(code)#">
                                    #is_active EQ 1 ? 'Block' : 'Unblock'#
                                </button>
                            </div>
                        </td>
                    </tr>
                    </cfoutput>
                </cfif>
            </tbody>
        </table>
    </div>

    <!--- GROUPED PAGINATION --->
    <div id="paginationBox" class="d-flex justify-content-center flex-wrap gap-2 mt-3">
    <cfoutput>
    <cfif totalPages GT 1>
        <cfif startPage GT 1>
            <button class="btn btn-outline-primary btn-sm pageBtn"
                    data-page="#startPage - 1#">&laquo; Prev</button>
        </cfif>
        <cfloop from="#startPage#" to="#endPage#" index="i">
            <button class="btn btn-sm pageBtn
                <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
                data-page="#i#">#i#</button>
        </cfloop>
        <cfif endPage LT totalPages>
            <button class="btn btn-outline-primary btn-sm pageBtn"
                    data-page="#endPage + 1#">Next &raquo;</button>
        </cfif>
    </cfif>
    </cfoutput>
    </div>

</div>

<!--- EDIT MODAL --->
<div class="modal fade" id="editModal" tabindex="-1" aria-labelledby="editModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header bg-dark text-white">
                <h5 class="modal-title" id="editModalLabel">Edit Coupon</h5>
                <button type="button" class="btn-close btn-close-white"
                        data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <input type="hidden" id="ec_id">
                <div class="row g-3">
                    <div class="col-6 col-md-4">
                        <label class="form-label small">Code</label>
                        <input id="ec_code" class="form-control text-uppercase"
                               oninput="this.value=this.value.toUpperCase()">
                    </div>
                    <div class="col-6 col-md-4">
                        <label class="form-label small">Type</label>
                        <select id="ec_type" class="form-control">
                            <option value="percent">% Percent</option>
                            <option value="fixed">₹ Fixed</option>
                        </select>
                    </div>
                    <div class="col-6 col-md-4">
                        <label class="form-label small">Value</label>
                        <input id="ec_value" type="number" min="1" class="form-control">
                    </div>
                    <div class="col-6 col-md-4">
                        <label class="form-label small">Min Purchase</label>
                        <input id="ec_min" type="number" min="0" class="form-control">
                    </div>
                    <div class="col-6 col-md-4">
                        <label class="form-label small">Max Discount</label>
                        <input id="ec_max" type="number" min="0" class="form-control">
                    </div>
                    <div class="col-6 col-md-4">
                        <label class="form-label small">Expiry Date</label>
                        <input id="ec_expiry" type="date" class="form-control">
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button id="submitEdit" class="btn btn-success">Save Changes</button>
                <button type="button" class="btn btn-secondary"
                        data-bs-dismiss="modal">Cancel</button>
            </div>
        </div>
    </div>
</div>

<script>
$(document).ready(function(){

    const CTRL = "/controllers/CouponController.cfc";

    //  HELPERS 
    function showMsg(res){
        const cls = res.status === "success" ? "success" : "danger";
        $("#ajaxMessage").html(
            `<div class="alert alert-${cls}">${res.message}</div>`
        );
        setTimeout(() => $("#ajaxMessage .alert").fadeOut(), 3000);
    }

    function loadCoupons(page){
        $.get(CTRL, {
            method : "searchCoupons",
            search : $("#searchForm [name=search]").val(),
            status : $("#statusValue").val(),
            p      : page || 1
        }, function(res){
            if(res.status === "success"){
                $("#couponTableBody").html(res.html);
                $("#paginationBox").html(res.pagination);
            } else {
                showMsg(res);
            }
        }, "json");
    }

    //  STATUS DROPDOWN 
    $(document).on("click", ".status-option", function(e){
        e.preventDefault();
        $("#statusValue").val($(this).data("value"));
        $("#statusDropdown").text($(this).text());
    });

    //  SEARCH 
    $("#searchForm").submit(function(e){
        e.preventDefault();
        loadCoupons(1);
    });

    //  PAGINATION 
    $(document).on("click", ".pageBtn", function(){
        loadCoupons($(this).data("page"));
    });

    //  ADD FORM TOGGLE 
    $("#showAddForm").click(() => $("#addCouponPanel").slideDown());
    $("#cancelAdd").click(function(){
        $("#addCouponPanel").slideUp();
        $("#cc_code,#cc_value,#cc_min,#cc_max,#cc_expiry").val("");
        $("#cc_type").val("percent");
    });

    //  CREATE COUPON 
    $("#submitCreate").click(function(){
        $.post(CTRL + "?method=createCoupon", {
            code   : $("#cc_code").val(),
            type   : $("#cc_type").val(),
            value  : $("#cc_value").val(),
            min    : $("#cc_min").val(),
            max    : $("#cc_max").val(),
            expiry : $("#cc_expiry").val()
        }, function(res){
            showMsg(res);
            if(res.status === "success"){
                $("#addCouponPanel").slideUp();
                $("#cc_code,#cc_value,#cc_min,#cc_max,#cc_expiry").val("");
                $("#cc_type").val("percent");
                loadCoupons(1);
            }
        }, "json");
    });

    //  OPEN EDIT MODAL 
    $(document).on("click", ".editBtn", function(){
        const btn = $(this);
        $("#ec_id").val(btn.data("id"));
        $("#ec_code").val(btn.data("code"));
        $("#ec_type").val(btn.data("type"));
        $("#ec_value").val(btn.data("value"));
        $("#ec_min").val(btn.data("min"));
        $("#ec_max").val(btn.data("max"));
        $("#ec_expiry").val(btn.data("expiry"));
        $("#editModal").modal("show");
    });

    //  SAVE EDIT 
    $("#submitEdit").click(function(){
        $.post(CTRL + "?method=updateCoupon", {
            id     : $("#ec_id").val(),
            code   : $("#ec_code").val(),
            type   : $("#ec_type").val(),
            value  : $("#ec_value").val(),
            min    : $("#ec_min").val(),
            max    : $("#ec_max").val(),
            expiry : $("#ec_expiry").val()
        }, function(res){
            showMsg(res);
            if(res.status === "success"){
                $("#editModal").modal("hide");
                loadCoupons(1);
            }
        }, "json");
    });

    //  TOGGLE COUPON 
    $(document).on("click", ".toggleBtn", function(){
        const btn    = $(this);
        const id     = btn.data("id");
        const action = btn.hasClass("btn-danger") ? "Block" : "Unblock";
        if(!confirm(`${action} this coupon?`)) return;
        $.get(CTRL, { method:"toggleCoupon", id:id }, function(res){
            showMsg(res);
            if(res.status === "success") loadCoupons(1);
        }, "json");
    });

});
</script>