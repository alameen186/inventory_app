<cfset dashModel = createObject("component","models.Dashboard")>

<cfset totalProducts = dashModel.getVendorTotalProducts(session.user_id)>
<cfset totalOrders   = dashModel.getVendorOrdersCount(session.user_id)>
<cfset revenue       = dashModel.getVendorRevenue(session.user_id)>

<cfset dashModel.evaluatePendingSwaps(session.user_id)>
<cfset slowProducts = dashModel.getSlowMovingProducts(session.user_id)>
<cfset swapResults  = dashModel.getSwapResults(session.user_id)>

<cfif session.plan_name EQ "pro">
    <cfset logModel          = createObject("component","models.SearchLog")>
    <cfset searchStats       = logModel.getVendorSearchStats(session.user_id)>
    <cfset unmatchedSearches = logModel.getUnmatchedSearches(10)>
</cfif>

<cfset planModel = createObject("component","models.Plan")>
<cfset allPlans  = planModel.getAll()>

<!--- Get swap usage for this month --->
<cfset placementModel  = createObject("component","models.RackPlacement")>
<cfset swapsUsed       = placementModel.getMonthlySwapCount(session.user_id)>
<cfset swapsAllowed    = 3>
<cfset swapsRemaining  = max(0, swapsAllowed - swapsUsed)>

<h4 class="mb-4 fw-bold">Vendor Dashboard</h4>

<!--- STATS CARDS --->
<div class="row g-4 mb-4">
 <cfoutput>
    <div class="col-md-3">
        <div class="card shadow-sm border-0 text-center p-4">
            <h6 class="text-muted">My Products</h6>
            <h2 class="fw-bold">#totalProducts#</h2>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card shadow-sm border-0 text-center p-4">
            <h6 class="text-muted">Orders</h6>
            <h2 class="fw-bold">#totalOrders#</h2>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card shadow-sm border-0 text-center p-4">
            <h6 class="text-muted">Revenue</h6>
            <h2 class="fw-bold">#numberFormat(revenue,"0,0")#</h2>
        </div>
    </div>
    <!--- SWAP USAGE CARD --->
    <div class="col-md-3">
        <div class="card shadow-sm border-0 text-center p-4
            #swapsRemaining EQ 0 ? 'border-danger' : ''#">
            <h6 class="text-muted">Swaps This Month</h6>
            <h2 class="fw-bold
                #swapsRemaining EQ 0 ? 'text-danger' : (swapsRemaining EQ 1 ? 'text-warning' : 'text-success')#">
                #swapsUsed# / #swapsAllowed#
            </h2>
            <small class="
                #swapsRemaining EQ 0 ? 'text-danger' : 'text-muted'#">
                <cfif swapsRemaining EQ 0>
                    Limit reached. Resets 1st of next month.
                <cfelse>
                    #swapsRemaining# swap#swapsRemaining NEQ 1 ? 's' : ''# remaining
                </cfif>
            </small>
            <div class="progress mt-2" style="height:5px;">
                <div class="progress-bar
                    #swapsRemaining EQ 0 ? 'bg-danger' : (swapsUsed GT 0 ? 'bg-warning' : 'bg-success')#"
                    style="width:#int((swapsUsed/swapsAllowed)*100)#%;"></div>
            </div>
        </div>
    </div>
 </cfoutput>
</div>


<!--- ANALYTICS SECTION --->
<div class="row g-4 mb-4">

    <!--- SLOW MOVING PRODUCTS --->
    <div class="col-md-6">
        <div class="card shadow-sm h-100">
            <div class="card-header bg-dark text-white">
                <strong><i class="bi bi-graph-down-arrow me-2"></i>Slow-Moving Products</strong>
                <small class="text-muted ms-2">last 30 days</small>
            </div>
            <div class="card-body p-0">
                <cfif slowProducts.recordCount EQ 0>
                    <div class="p-4 text-center text-muted">
                        <i class="bi bi-check-circle-fill text-success fs-4 d-block mb-2"></i>
                        All products are moving well!
                    </div>
                <cfelse>
    <ul class="list-group list-group-flush">
    <cfoutput query="slowProducts">
        
        <cfset badge = "">
        <cfset tip   = "">
        
        <cfif movement_status EQ "not_placed">
            <cfset badge = '<span class="badge bg-info text-dark">Not placed</span>'>
            <cfset tip   = "Place this product in a rack to start selling.">
            
        <cfelseif movement_status EQ "no_sales">
            <cfset badge = '<span class="badge bg-danger">0 sales</span>'>
            <cfset tip   = "Consider moving to a higher-visibility rack face.">
            
        <cfelse>
            <cfset badge = '<span class="badge bg-warning text-dark">#sale_count# sales</span>'>
            <cfset tip   = "Low movement — consider swapping with a better position.">
        </cfif>
        
        <li class="list-group-item px-3 py-2">
            <div class="d-flex justify-content-between align-items-start">
                <div>
                    <div class="fw-semibold small">#encodeForHTML(product_name)#</div>
                    <small class="text-muted">
                        <cfif len(trim(rack_code))>
                            #rack_code# &rarr; #face_code#
                        <cfelse>
                            No rack assigned
                        </cfif>
                    </small>
                    <div class="text-muted fst-italic" style="font-size:11px;">#tip#</div>
                </div>
                #badge#
            </div>
        </li>
    </cfoutput>
    </ul>
</cfif>
            </div>
        </div>
    </div>

    <!--- SWAP RESULTS --->
    <div class="col-md-6">
        <div class="card shadow-sm h-100">
            <div class="card-header bg-dark text-white">
                <strong><i class="bi bi-arrow-left-right me-2"></i>Swap Results</strong>
            </div>
            <div class="card-body p-0">
                <cfif swapResults.recordCount EQ 0>
                    <div class="p-4 text-center text-muted">No swaps done yet.</div>
                <cfelse>
                    <ul class="list-group list-group-flush">
                    <cfoutput query="swapResults">

    <cfset isPending  = NOT len(trim(evaluated_at))>
    <cfset isWin      = false>
    <cfset isFail     = false>
    <cfset pctChange  = 0>
    <cfset borderCol  = "border-start border-4 border-info">
    <cfset resultLabel = "">
    <cfset resultClass = "">

    <cfif NOT isPending>
        <cfif total_before GT 0>
            <cfset pctChange = int(((total_after - total_before) / total_before) * 100)>
        <cfelse>
            <cfset pctChange = total_after GT 0 ? 100 : 0>
        </cfif>

        <cfif pctChange GTE 10>
            <cfset isWin      = true>
            <cfset borderCol  = "border-start border-4 border-success">
            <cfset resultLabel = "Swap success">
            <cfset resultClass = "text-success">
        <cfelseif pctChange LTE -5>
            <cfset isFail     = true>
            <cfset borderCol  = "border-start border-4 border-danger">
            <cfset resultLabel = "No improvement">
            <cfset resultClass = "text-danger">
        <cfelse>
            <cfset borderCol  = "border-start border-4 border-secondary">
            <cfset resultLabel = "Neutral">
            <cfset resultClass = "text-secondary">
        </cfif>
    </cfif>

                        <li class="list-group-item px-3 py-2 #borderCol#">
                            <div class="d-flex justify-content-between align-items-center mb-1">
                                <cfif isPending>
                                    <span class="badge bg-info text-dark">Pending evaluation</span>
                                <cfelse>
                                    <span class="fw-semibold small #resultClass#">#resultLabel#</span>
                                </cfif>
                                <small class="text-muted">#dateFormat(swapped_at,"dd mmm yyyy")#</small>
                            </div>
                            <div class="small">
                                <strong>#encodeForHTML(product1_name)#</strong>
                                <i class="bi bi-arrow-left-right mx-1 text-muted"></i>
                                <strong>#encodeForHTML(product2_name)#</strong>
                            </div>
                            <cfif isPending>
                                <small class="text-muted fst-italic">
                                    Sales data collected in
                                    #max(0, 1 - dateDiff("d", swapped_at, now()))# more day(s).
                                </small>
                            <cfelse>
                                <small class="text-muted">
                                    Combined sales: #total_before# before
                                    &rarr; #total_after# after
                                    <cfif pctChange GT 0>
                                        <span class="text-success ms-1">&##9650; +#pctChange#%</span>
                                    <cfelseif pctChange LT 0>
                                        <span class="text-danger ms-1">&##9660; #pctChange#%</span>
                                    <cfelse>
                                        <span class="text-muted ms-1">no change</span>
                                    </cfif>
                                </small>
                            </cfif>
                        </li>
                    </cfoutput>
                    </ul>
                </cfif>
            </div>
        </div>
    </div>

</div>

<!--- QUICK PRODUCT SEARCH --->
<div class="card shadow-sm mb-4">
    <div class="card-header bg-dark text-white">
        <strong><i class="bi bi-search me-2"></i>Quick Product Search</strong>
    </div>
    <div class="card-body">
        <div class="input-group mb-3">
            <input type="text" id="productSearchInput" class="form-control"
                   placeholder="Search your products by name...">
            <button class="btn btn-primary" id="productSearchBtn">
                <i class="bi bi-search me-1"></i>Search
            </button>
        </div>
        <div id="productSearchResults"></div>
    </div>
</div>

<!--- PRO FEATURES --->
<cfif session.plan_name EQ "pro">

    <h5 class="mt-4">Your Product Search Appearances</h5>
    <table class="table table-bordered table-sm">
        <thead class="table-dark">
            <tr>
                <th>Product</th>
                <th>Times Appeared in Searches</th>
                <th>Last Appeared</th>
            </tr>
        </thead>
        <tbody>
        <cfoutput query="searchStats">
        <tr>
            <td>#product_name#</td>
            <td><span class="badge bg-primary">#search_appearances#</span></td>
            <td>#len(last_appeared) ? dateFormat(last_appeared,"dd-mmm-yyyy") : "Never"#</td>
        </tr>
        </cfoutput>
        </tbody>
    </table>

    <h5 class="mt-4">Users Searching for Products Not in Your Store</h5>
    <p class="text-muted small">These are keywords with zero results - potential new products to stock.</p>
    <table class="table table-bordered table-sm">
        <thead class="table-dark">
            <tr>
                <th>Keyword</th>
                <th>Times Searched</th>
                <th>Last Searched</th>
            </tr>
        </thead>
        <tbody>
        <cfoutput query="unmatchedSearches">
        <tr>
            <td><strong>#encodeForHTML(keyword)#</strong></td>
            <td><span class="badge bg-warning text-dark">#search_count#</span></td>
            <td>#dateFormat(last_searched_at,"dd-mmm-yyyy")#</td>
        </tr>
        </cfoutput>
        </tbody>
    </table>

<cfelse>

    <div class="alert alert-warning mt-4 d-flex align-items-center justify-content-between flex-wrap gap-2">
        <div>
            <strong>Pro Plan Feature:</strong>
            You are on the <strong>Basic</strong> plan.
            Upgrade to Pro to unlock Search Analytics and unmatched keyword insights.
        </div>
        <button class="btn btn-warning btn-sm flex-shrink-0 switchPlanBtn"
            data-plan-id="2"
            data-plan-name="Pro">
            Upgrade to Pro
        </button>
    </div>

</cfif>

<!--- PLAN SWITCHER --->
<div class="card mt-4 shadow-sm border-0">
    <div class="card-body">
        <div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
            <div>
                <h6 class="mb-0 fw-bold">
                    Current Plan:
                    <cfoutput>
                    <span class="badge <cfif session.plan_name EQ 'pro'>bg-primary<cfelse>bg-secondary</cfif>">
                        #ucase(session.plan_name)#
                    </span>
                    </cfoutput>
                </h6>
                <small class="text-muted">Switch your plan anytime.</small>
            </div>
            <div class="d-flex gap-2">
                <cfoutput query="allPlans">
                <cfif lcase(plan_name) NEQ session.plan_name>
                    <button class="btn btn-outline-primary btn-sm switchPlanBtn"
                        data-plan-id="#id#"
                        data-plan-name="#plan_name#">
                        Switch to #plan_name#
                    </button>
                </cfif>
                </cfoutput>
            </div>
        </div>
        <div id="planSwitchMsg" class="mt-2"></div>
    </div>
</div>

<script>
$(function(){

    /* ── PRODUCT QUICK SEARCH ── */
    var RPC = '../../controllers/RackPlacementController.cfc';

    function doSearch(){
        var keyword = $.trim($('#productSearchInput').val());
        if(!keyword){
            $('#productSearchResults').html(
                '<div class="alert alert-warning py-2">Please enter a product name to search.</div>'
            );
            return;
        }

        $('#productSearchResults').html(
            '<div class="text-center py-3">'
          + '<div class="spinner-border spinner-border-sm text-primary me-2"></div>'
          + 'Searching...</div>'
        );

        $.get(RPC + '?method=searchProducts', { keyword: keyword }, function(res){
            if(!res.success){
                $('#productSearchResults').html(
                    '<div class="alert alert-danger py-2">' + res.message + '</div>'
                );
                return;
            }

            if(!res.data || res.data.length === 0){
                $('#productSearchResults').html(
                    '<div class="alert alert-info py-2">No products found matching <strong>'
                  + $('<div>').text(keyword).html()
                  + '</strong>.</div>'
                );
                return;
            }

            var html = '<div class="table-responsive">'
                     + '<table class="table table-hover table-sm mb-0">'
                     + '<thead class="table-dark">'
                     + '<tr>'
                     + '<th>Product Name</th>'
                     + '<th>Stock</th>'
                     + '<th>Rack</th>'
                     + '<th>Face</th>'
                     + '<th>Status</th>'
                     + '</tr>'
                     + '</thead><tbody>';

            $.each(res.data, function(i, p){
                var statusBadge = p.placement_status === 'Placed'
                    ? '<span class="badge bg-success">Placed</span>'
                    : '<span class="badge bg-secondary">Not Placed</span>';

                var rackInfo = p.rack_code
                    ? '<span class="fw-semibold">' + p.rack_code + '</span>'
                      + (p.rack_name ? '<small class="text-muted d-block">' + p.rack_name + '</small>' : '')
                    : '<span class="text-muted"><i class="bi bi-ban"></i></span>';

                var faceInfo = p.face_code
                    ? '<span class="badge bg-secondary">' + p.face_code + '</span>'
                    : '<span class="text-muted"><i class="bi bi-ban"></i></span>';

                var stockBadge = p.stock_quantity <= 0
                    ? '<span class="badge bg-danger">' + p.stock_quantity + '</span>'
                    : (p.stock_quantity <= 5
                        ? '<span class="badge bg-warning text-dark">' + p.stock_quantity + '</span>'
                        : '<span class="badge bg-success">' + p.stock_quantity + '</span>');

                html += '<tr>'
                      + '<td class="fw-semibold">' + p.product_name + '</td>'
                      + '<td>' + stockBadge + '</td>'
                      + '<td>' + rackInfo + '</td>'
                      + '<td>' + faceInfo + '</td>'
                      + '<td>' + statusBadge + '</td>'
                      + '</tr>';
            });

            html += '</tbody></table></div>';
            html += '<small class="text-muted mt-1 d-block">'
                  + res.data.length + ' result(s) found.</small>';

            $('#productSearchResults').html(html);
        }, 'json');
    }

    $('#productSearchBtn').on('click', doSearch);

    $('#productSearchInput').on('keypress', function(e){
        if(e.which === 13) doSearch();
    });

    /* ── PLAN SWITCHER ── */
    $(document).on('click', '.switchPlanBtn', function(){
        var btn       = $(this);
        var plan_id   = btn.data('plan-id');
        var plan_name = btn.data('plan-name');

        if(!confirm('Switch to ' + plan_name + ' plan?')) return;

        btn.prop('disabled', true).text('Switching...');

        $.ajax({
            url      : '../../controllers/PlanController.cfc?method=selectPlan',
            type     : 'POST',
            data     : { plan_id: plan_id },
            dataType : 'json',
            success  : function(res){
                if(res.success){
                    $('#planSwitchMsg').html(
                        '<div class="alert alert-success py-1">Switched to ' + plan_name + '. Reloading...</div>'
                    );
                    setTimeout(function(){
                        window.location.href = '../../index.cfm?page=dashboard&section=vendorDashboard';
                    }, 800);
                } else {
                    $('#planSwitchMsg').html(
                        '<div class="alert alert-danger py-1">' + res.message + '</div>'
                    );
                    btn.prop('disabled', false).text('Switch to ' + plan_name);
                }
            },
            error: function(){
                $('#planSwitchMsg').html(
                    '<div class="alert alert-danger py-1">Network error. Please try again.</div>'
                );
                btn.prop('disabled', false).text('Switch to ' + plan_name);
            }
        });
    });
});

</script>
