<cfset dashModel = createObject("component","models.Dashboard")>

<cfset totalProducts = dashModel.getVendorTotalProducts(session.user_id)>
<cfset totalOrders = dashModel.getVendorOrdersCount(session.user_id)>
<cfset revenue = dashModel.getVendorRevenue(session.user_id)>

<cfset logModel = createObject("component","models.SearchLog")>
<cfset searchStats = logModel.getVendorSearchStats(session.user_id)>
<cfset unmatchedSearches = logModel.getUnmatchedSearches(10)>

<h4 class="mb-4 fw-bold">Vendor Dashboard</h4>

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
<h5 class="mt-4">Your Product Search Appearances</h5>
<table class="table table-bordered table-sm">
<thead><tr><th>Product</th><th>Times Appeared in Searches</th><th>Last Appeared</th></tr></thead>
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
<thead><tr><th>Keyword</th><th>Times Searched</th><th>Last Searched</th></tr></thead>
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
</div>