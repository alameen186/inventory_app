<cfset dashModel = createObject("component","models.Dashboard")>

<cfset totalUsers = dashModel.getTotalUsers()>
<cfset totalVendors = dashModel.getTotalVendors()>
<cfset totalCoupons = dashModel.getTotalCoupons()>

<h3 class="mb-4">Admin Dashboard</h3>

<div class="row g-4">
<cfoutput>
    <div class="col-md-4">
        <div class="card p-4 text-center shadow-sm">
            <h6>Users</h6>
            <h3>#totalUsers#</h3>
        </div>
    </div>

    <div class="col-md-4">
        <div class="card p-4 text-center shadow-sm">
            <h6>Vendors</h6>
            <h3>#totalVendors#</h3>
        </div>
    </div>

    <div class="col-md-4">
        <div class="card p-4 text-center shadow-sm">
            <h6>Coupons</h6>
            <h3>#totalCoupons#</h3>
        </div>
    </div>
</cfoutput>

</div>