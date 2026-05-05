<cfscript>
    function getOrdinalSuffix(n) {
        var num = val(arguments.n);
        if (num >= 11 && num <= 13) return "th";
        var r = num mod 10;
        if (r == 1) return "st";
        if (r == 2) return "nd";
        if (r == 3) return "rd";
        return "th";
    }
</cfscript>

<!--- ── data  --->
<cfset schedModel    = createObject("component","models.ScheduledOrder")>
<cfset prodModel     = createObject("component","models.Product")>
<cfset userModel     = createObject("component","models.User")>
<cfset vendorProducts = prodModel.getByVendorSimple(session.user_id)>
<cfset customers     = userModel.getCustomers()>

<!--- initial server-side load  --->
<cfset schedules = schedModel.getByVendor(
    vendor_id = session.user_id,
    search    = "",
    sort      = "",
    page      = 1,
    limit     = 10
)>
<cfset totalRecords = schedModel.getByVendorCount(
    vendor_id = session.user_id,
    search    = ""
)>
<cfset totalPages  = max(1, ceiling(totalRecords / 10))>

<div class="container mt-4">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h3 class="mb-0">Scheduled Orders</h3>
        <button class="btn btn-primary" onclick="$('#schedForm').toggle()">
            + New Schedule
        </button>
    </div>

    <div id="schedMsg"></div>

    <!--- CREATE FORM --->
    <div id="schedForm" style="display:none;" class="card p-4 mb-4 border-primary">
        <h5 class="mb-3">Create New Schedule</h5>

        <div class="row g-2 mb-3">
            <div class="col-md-5">
                <label class="form-label fw-semibold">Customer</label>
                <select id="s_customer" class="form-select">
                    <option value="">Select customer</option>
                    <cfoutput query="customers">
                    <option value="#id#">#full_name#
                        <cfif len(trim(business_name))> (#business_name#)</cfif>
                    </option>
                    </cfoutput>
                </select>
            </div>
            <div class="col-md-3">
                <label class="form-label fw-semibold">Start Date</label>
                <input type="date" id="s_start" class="form-control">
                <small class="text-muted">Day of month repeats every month.</small>
            </div>
        </div>

        <label class="form-label fw-semibold">Products</label>
        <div id="productRows">
            <div class="product-row row g-2 mb-2 align-items-end">
                <div class="col-md-6">
                    <select class="form-select prod-select">
                        <option value="">Select product</option>
                        <cfoutput query="vendorProducts">
                        <option value="#id#" data-stock="#stock#" data-price="#price#">
                            #product_name# (Stock: #stock# | #numberFormat(price,"9,999.99")#)
                        </option>
                        </cfoutput>
                    </select>
                </div>
                <div class="col-md-3">
                    <input type="number" class="form-control prod-qty" placeholder="Qty" min="1">
                </div>
                <div class="col-md-3">
                    <button type="button" class="btn btn-outline-danger btn-sm removeRow"
                        style="display:none;">Remove</button>
                </div>
            </div>
        </div>

        <button type="button" class="btn btn-outline-secondary btn-sm mb-3" id="addRowBtn">
            + Add Another Product
        </button>

        <div>
            <button class="btn btn-success" id="createSchedBtn">Create Schedule</button>
            <button class="btn btn-secondary ms-2" onclick="$('#schedForm').hide()">Cancel</button>
        </div>
    </div>

    <!--- SEARCH --->
    <div class="row g-2 mb-3" id="schedSearchBar">

        <div class="col-md-5">
            <input type="text" id="schedSearch" class="form-control"
                placeholder="Search product or customer">
        </div>

        <div class="col-md-3">
            <select id="schedSort" class="form-select">
                <option value="">Newest first</option>
                <option value="product_az">Product A - Z</option>
                <option value="product_za">Product Z - A</option>
                <option value="qty_high">Qty High - Low</option>
                <option value="qty_low">Qty Low - High</option>
                <option value="day_asc">Run Day (earliest)</option>
            </select>
        </div>

        <div class="col-md-2 d-grid">
            <button class="btn btn-primary" id="schedSearchBtn">Search</button>
        </div>

        <div class="col-md-2 d-grid">
            <button class="btn btn-outline-secondary" id="schedClearBtn">Clear</button>
        </div>

    </div>

    <!--- TABLE  --->
    <div class="table-responsive">
    <table class="table table-bordered table-hover align-middle">
        <thead class="table-dark">
            <tr>
                <th>#</th>
                <th>Product</th>
                <th>Qty</th>
                <th>Customer</th>
                <th>Start Date</th>
                <th>Runs On</th>
                <th>Status</th>
                <th>Action</th>
            </tr>
        </thead>
        <tbody id="schedTableBody">
            <!--- filled by AJAX --->
            <tr>
                <td colspan="8" class="text-center py-4">
                    <div class="spinner-border text-primary" role="status"></div>
                </td>
            </tr>
        </tbody>
    </table>
    </div>

    <!--- PAGINATION  --->
    <div id="schedPagination" class="d-flex justify-content-center flex-wrap gap-2 mt-3"></div>

</div>


<script>
$(function(){

    var SCHED_CTRL = "../../controllers/ScheduledOrderController.cfc";

    // ── ADD PRODUCT ROW 
    var productRowTemplate = $('#productRows .product-row').first().clone();

    $('#addRowBtn').on('click', function(){
        var newRow = productRowTemplate.clone();
        newRow.find('.removeRow').show();
        newRow.find('select').val('');
        newRow.find('input').val('');
        $('#productRows').append(newRow);
    });

    $(document).on('click', '.removeRow', function(){
        $(this).closest('.product-row').remove();
    });

    // ── SEARCH / PAGINATION 
    function loadSchedules(page) {
        page = page || 1;
        $.ajax({
            url      : SCHED_CTRL,
            type     : 'GET',
            data     : {
                method : 'search',
                search : $('#schedSearch').val(),
                sort   : $('#schedSort').val(),
                p      : page
            },
            dataType : 'json',
            success  : function(res){
                if(res.success){
                    $('#schedTableBody').html(res.data.rows);
                    $('#schedPagination').html(res.data.pagination);
                } else {
                    $('#schedMsg').html(
                        '<div class="alert alert-danger">' + res.message + '</div>'
                    );
                }
            },
            error : function(xhr){
                console.log('Load error:', xhr.responseText);
            }
        });
    }

    // search button
    $('#schedSearchBtn').on('click', function(){
        loadSchedules(1);
    });

    // clear button
    $('#schedClearBtn').on('click', function(){
        $('#schedSearch').val('');
        $('#schedSort').val('');
        loadSchedules(1);
    });

    // pagination clicks 
    $(document).on('click', '.schedPageBtn', function(){
        loadSchedules($(this).data('page'));
    });

    // ── CREATE 
    $('#createSchedBtn').on('click', function(){
        var customer_id = $('#s_customer').val();
        var start_date  = $('#s_start').val();
        var items       = [];

        $('.product-row').each(function(){
            var pid = $(this).find('.prod-select').val();
            var qty = $(this).find('.prod-qty').val();
            if (pid && qty && parseInt(qty) > 0) {
                items.push(pid + ':' + qty);
            }
        });

        if (!customer_id) { alert('Please select a customer.'); return; }
        if (!start_date)  { alert('Please select a start date.'); return; }
        if (!items.length){ alert('Add at least one product with a quantity.'); return; }

        $.ajax({
            url      : SCHED_CTRL + '?method=create',
            type     : 'POST',
            data     : {
                customer_id : customer_id,
                start_date  : start_date,
                items       : items.join('|')
            },
            dataType : 'json',
            success  : function(res){
                var cls = res.success ? 'success' : 'danger';
                $('#schedMsg').html(
                    '<div class="alert alert-' + cls + '">' + res.message + '</div>'
                );
                if (res.success) {
                    $('#schedForm').hide();
                    loadSchedules(1);  
                }
            }
        });
    });

    // ── STOP / RESUME 
    $(document).on('click', '.toggleSchedBtn', function(){
        var btn = $(this);
        $.ajax({
            url      : SCHED_CTRL,
            type     : 'GET',
            data     : {
                method        : 'toggleStatus',
                id            : btn.data('id'),
                currentStatus : btn.data('status')
            },
            dataType : 'json',
            success  : function(res){
                if (!res.success) { alert(res.message); return; }
                var s = parseInt(res.data.newStatus);
                btn.data('status', s)
                   .text(s ? 'Stop' : 'Resume')
                   .removeClass('btn-danger btn-success')
                   .addClass(s ? 'btn-danger' : 'btn-success');
                btn.closest('tr').find('.badge')
                   .removeClass('bg-success bg-danger')
                   .addClass(s ? 'bg-success' : 'bg-danger')
                   .text(s ? 'Active' : 'Stopped');
            }
        });
    });

    // ── INITIAL LOAD 
    loadSchedules(1);

});
</script>