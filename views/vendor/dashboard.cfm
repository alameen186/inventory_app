<cfset dashModel = createObject("component","models.Dashboard")>

<cfset totalProducts = dashModel.getVendorTotalProducts(session.user_id)>
<cfset totalOrders = dashModel.getVendorOrdersCount(session.user_id)>
<cfset revenue = dashModel.getVendorRevenue(session.user_id)>

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

</div>