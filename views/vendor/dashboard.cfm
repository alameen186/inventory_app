<cfset dashModel = createObject("component","models.Dashboard")>

<cfset totalProducts = dashModel.getVendorTotalProducts(session.user_id)>
<cfset totalOrders   = dashModel.getVendorOrdersCount(session.user_id)>
<cfset revenue       = dashModel.getVendorRevenue(session.user_id)>

<cfif session.plan_name EQ "pro">
    <cfset logModel          = createObject("component","models.SearchLog")>
    <cfset searchStats       = logModel.getVendorSearchStats(session.user_id)>
    <cfset unmatchedSearches = logModel.getUnmatchedSearches(10)>
</cfif>

<cfset planModel = createObject("component","models.Plan")>
<cfset allPlans  = planModel.getAll()>

<h4 class="mb-4 fw-bold">Vendor Dashboard</h4>

<!--- STATS CARDS --->
<div class="row g-4">
<cfoutput>
    <div class="col-md-4">
        <div class="card shadow-sm border-0 text-center p-4">
            <h6 class="text-muted">My Products</h6>
            <h2 class="fw-bold">#totalProducts#</h2>
        </div>
    </div>
    <div class="col-md-4">
        <div class="card shadow-sm border-0 text-center p-4">
            <h6 class="text-muted">Orders</h6>
            <h2 class="fw-bold">#totalOrders#</h2>
        </div>
    </div>
    <div class="col-md-4">
        <div class="card shadow-sm border-0 text-center p-4">
            <h6 class="text-muted">Revenue</h6>
            <h2 class="fw-bold">#numberFormat(revenue,"0,0")#</h2>
        </div>
    </div>
</cfoutput>
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
    <p class="text-muted small">These are keywords with zero results — potential new products to stock.</p>
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