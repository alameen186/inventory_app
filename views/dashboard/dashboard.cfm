<cfif NOT structKeyExists(session, "user_id")>
   <cflocation url="../../index.cfm?page=auth&message=please login first&type=error&tab=login" addtoken="false">
   <cfabort>
</cfif>

<cfif structKeyExists(url, "section")>
     <cfset section = url.section>
<cfelse>
     <cfset section = "home">   
</cfif>

<cfset userModel = createObject("component","models.User")>
<cfset userData = userModel.getUserWithRole(session.user_id)>

<!DOCTYPE html>
<html>
<head>
    <title>Dashboard</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>

<body class="bg-light style="overflow: hidden;">

<div class="container-fluid vh-100">
    <div class="row h-100">

        <!-- LEFT SIDEBAR -->
        <div class="col-md-2 bg-dark text-white h-100 p-3">

            <h5 class="text-center">Menu</h5>
            <hr class="bg-light">

            <!-- Admin Only -->
            <cfif session.role_id EQ 1>
                <ul class="nav flex-column">
                    <li class="nav-item mb-2">
                        <a class="nav-link text-white" href="../../index.cfm?page=dashboard">dashboard</a>
                    </li>
                    <li class="nav-item mb-2">
                        <a class="nav-link text-white" href="../../index.cfm?page=dashboard&section=users">Users</a>
                    </li>
                    <li class="nav-item mb-2">
                        <a class="nav-link text-white" href="../../index.cfm?page=dashboard&section=roles">Roles</a>
                    </li>
                    <li class="nav-item mb-2">
                        <a class="nav-link text-white" href="../../index.cfm?page=dashboard&section=category">Categories</a>
                    </li>
                    <li class="nav-item mb-2">
                        <a class="nav-link text-white" href="../../index.cfm?page=dashboard&section=products">Products</a>
                    </li>
                    <li class="nav-item mb-2">
                        <a class="nav-link text-white" href="../../index.cfm?page=dashboard&section=allorders">Orders</a>
                    </li>
                    <li class="nav-item mb-2">
                        <a class="nav-link text-white" href="../../index.cfm?page=dashboard&section=createOrder">Create Order</a>
                    </li>
                    <li class="nav-item mb-2">
                        <a class="nav-link text-white" href="../../index.cfm?page=dashboard&section=coupons">Coupons</a>
                    </li>
                </ul>
            <cfelse>  
                <ul class="nav flex-column">
                    <li class="nav-item mb-2">
                        <a class="nav-link text-white" href="../../index.cfm?page=dashboard&section=productList">Products</a>
                    </li>
                    <li class="nav-item mb-2">
                        <a class="nav-link text-white" href="../../index.cfm?page=dashboard&section=orders">Orders</a>
                    </li>
                </ul>
                     

            </cfif>

            <!-- Logout -->
            <div class="mt-auto">
                <a href="../../controllers/LogoutController.cfm" class="btn btn-danger w-100 mt-4">
                    Logout
                </a>
            </div>

        </div>

        <!-- MAIN CONTENT -->
        <div class="col-md-10 d-flex flex-column h-100">

            <!-- TOP BAR -->
            <div class="d-flex justify-content-between align-items-center p-3 border-bottom shadow-sm">

                <h4 class="mb-0">Inventory Store</h4>

                <!-- PROFILE DROPDOWN -->
                <div class="dropdown">
                <a href="../../index.cfm?page=dashboard&section=cart" class="btn btn-success btn-sm w-35 d-inline">Cart</a>
                    </button>
                    <button class="btn btn-secondary dropdown-toggle" data-bs-toggle="dropdown">
                        Profile
                    </button>

                    <div class="dropdown-menu dropdown-menu-end p-3" style="min-width: 250px;">

                        <cfoutput>
                            <p><strong>#userData.first_name# #userData.last_name#</strong></p>
                            <p class="mb-1">#userData.email#</p>
                            <hr>
                            <p class="mb-1"><strong>#userData.role_name#</strong></p>
                        </cfoutput>

                    </div>
                </div>

            </div>

            <!-- CENTER CONTENT -->
            <div class="p-4 flex-grow-1 overflow-auto">

    <cfif section EQ "users">

        <cfinclude template="../admin/users.cfm">

    <cfelseif section EQ "roles">

        <cfinclude template="../admin/roles.cfm">
    <cfelseif section EQ "category">

        <cfinclude template="../admin/category.cfm">
    <cfelseif section EQ "products">

        <cfinclude template="../admin/products.cfm">
    <cfelseif section EQ "productList">

        <cfinclude template="../user/products.cfm">

    <cfelseif section EQ "cart">
        <cfinclude template="../user/cart.cfm">   
        
    <cfelseif section EQ "orders">
        <cfinclude template="../user/orders.cfm">  

    <cfelseif section EQ "allorders">
        <cfinclude template="../admin/orders.cfm">

    <cfelseif section EQ "coupons">
        <cfinclude template="../admin/coupon.cfm">

    <cfelseif section EQ "createOrder">
        <cfinclude template="../admin/createOrder.cfm">

<cfelse>

<cfset dashModel = createObject("component","models.Dashboard")>

<cfset totalOrders = dashModel.getTotalOrders()>
<cfset totalRevenue = dashModel.getTotalRevenue()>
<cfset totalUsers = dashModel.getTotalUsers()>
<cfset totalProducts = dashModel.getTotalProducts()>
<cfset totalCoupons = dashModel.getTotalCoupons()>
<cfset lowStock = dashModel.getLowStockProducts()>
<cfset latestOrders = dashModel.getLatestOrders()>

<style>
.dashboard-card{
    border:none;
    border-radius:16px;
    background:#ffffff;
    box-shadow:0 6px 18px rgba(0,0,0,0.05);
}

.stat-title{
    font-size:14px;
    color:#6c757d;
    margin-bottom:8px;
}

.stat-value{
    font-size:28px;
    font-weight:700;
    color:#212529;
}

.section-title{
    font-size:18px;
    font-weight:600;
    margin-bottom:18px;
    color:#212529;
}

.list-row{
    padding:12px 0;
    border-bottom:1px solid #f1f1f1;
}

.list-row:last-child{
    border-bottom:none;
}
</style>

<div class="mb-4">
    <h3 class="fw-bold mb-1">Admin Dashboard</h3>
    <p class="text-muted mb-0">Inventory analytics overview</p>
</div>

<cfoutput>

<div class="row g-4 mb-4">

    <div class="col-md-3">
        <div class="card dashboard-card p-4 text-center">
            <div class="stat-title">Total Orders</div>
            <div class="stat-value">#totalOrders#</div>
        </div>
    </div>

    <div class="col-md-3">
        <div class="card dashboard-card p-4 text-center">
            <div class="stat-title">Revenue</div>
            <div class="stat-value">#numberFormat(totalRevenue,"0,0")#</div>
        </div>
    </div>

    <div class="col-md-3">
        <div class="card dashboard-card p-4 text-center">
            <div class="stat-title">Users</div>
            <div class="stat-value">#totalUsers#</div>
        </div>
    </div>

    <div class="col-md-3">
        <div class="card dashboard-card p-4 text-center">
            <div class="stat-title">Products</div>
            <div class="stat-value">#totalProducts#</div>
        </div>
    </div>

</div>

<div class="row g-4 mb-4">

    <!-- LOW STOCK -->
    <div class="col-md-6">
        <div class="card dashboard-card p-4">
            <div class="section-title">Low Stock Products</div>

            <cfif lowStock.recordCount EQ 0>
                <p class="text-muted mb-0">All products are sufficiently stocked.</p>
            <cfelse>
                <cfoutput query="lowStock">
                    <div class="list-row d-flex justify-content-between">
                        <span>#product_name#</span>
                        <span class="text-danger fw-semibold">#stock# left</span>
                    </div>
                </cfoutput>
            </cfif>
        </div>
    </div>

    <!-- LATEST ORDERS -->
    <div class="col-md-6">
        <div class="card dashboard-card p-4">
            <div class="section-title">Latest Orders</div>

            <cfif latestOrders.recordCount EQ 0>
                <p class="text-muted mb-0">No recent orders found.</p>
            <cfelse>
                <cfoutput query="latestOrders">
                    <div class="list-row d-flex justify-content-between">
                        <span>#order_group_id#</span>
                        <span class="fw-semibold">#final_amount#</span>
                    </div>
                </cfoutput>
            </cfif>
        </div>
    </div>

</div>

<!-- COUPON CARD -->
<div class="row">
    <div class="col-md-12">
        <div class="card dashboard-card p-4 text-center">
            <div class="stat-title">Total Coupons Available</div>
            <div class="stat-value">#totalCoupons#</div>
        </div>
    </div>
</div>
</cfoutput>

</cfif>



</div>

        </div>

    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>