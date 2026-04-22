<cfif NOT structKeyExists(session, "user_id")> <cflocation url="../../index.cfm?page=auth&message=please login&type=error" addtoken="false"> <cfabort> </cfif>

<cfparam name="url.section" default="home">
<cfset section = url.section>

<cfset userModel = createObject("component","models.User")> <cfset userData = userModel.getUserWithRole(session.user_id)>

<!DOCTYPE html>

<html>
<head>
    <title>Dashboard</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">

<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">

</head>

<body class="bg-light">

<div class="container-fluid vh-100">
<div class="row h-100">

<!-- DESKTOP SIDEBAR -->

<div class="col-md-2 d-none d-md-block bg-dark text-white p-3 overflow-auto">

<h5 class="text-center">Menu</h5>
<hr class="bg-light">

<cfif session.role_id EQ 1>

<ul class="nav flex-column">
<li><a href="#" class="nav-link text-white menuLink" data-section="users">Users</a></li>
<li><a href="#" class="nav-link text-white menuLink" data-section="vendors">Vendors</a></li>
<li><a href="#" class="nav-link text-white menuLink" data-section="roles">Roles</a></li>
<li><a href="#" class="nav-link text-white menuLink" data-section="coupons">Coupons</a></li>
</ul>

<cfelseif session.role_name EQ "vendor">

<ul class="nav flex-column">
<li><a href="#" class="nav-link text-white menuLink" data-section="vendorDashboard">Dashboard</a></li>
<li><a href="#" class="nav-link text-white menuLink" data-section="products">Products</a></li>
<li><a href="#" class="nav-link text-white menuLink" data-section="allorders">Orders</a></li>
</ul>

<cfelse>
<ul class="nav flex-column">
<li><a href="#" class="nav-link text-white menuLink" data-section="productList">Products</a></li>
<li><a href="#" class="nav-link text-white menuLink" data-section="orders">Orders</a></li>
<li><a href="#" class="nav-link text-white menuLink" data-section="cart">Cart</a></li>
</ul>
</cfif>

<a href="../../controllers/LogoutController.cfm" class="btn btn-danger w-100 mt-4">Logout</a>

</div>

<!-- MOBILE SIDEBAR -->

<div class="offcanvas offcanvas-start bg-dark text-white" id="mobileSidebar">
<div class="offcanvas-header">
<h5>Menu</h5>
<button class="btn-close btn-close-white" data-bs-dismiss="offcanvas"></button>
</div>

<div class="offcanvas-body">

<!-- SAME MENU -->

<cfif session.role_id EQ 1>

<ul class="nav flex-column">
<li><a href="#" class="nav-link text-white menuLink" data-section="users">Users</a></li>
<li><a href="#" class="nav-link text-white menuLink" data-section="vendors">Vendors</a></li>
<li><a href="#" class="nav-link text-white menuLink" data-section="roles">Roles</a></li>
<li><a href="#" class="nav-link text-white menuLink" data-section="coupons">Coupons</a></li>
</ul>

<cfelseif session.role_name EQ "vendor">

<ul class="nav flex-column">
<li><a href="#" class="nav-link text-white menuLink" data-section="vendorDashboard">Dashboard</a></li>
<li><a href="#" class="nav-link text-white menuLink" data-section="products">Products</a></li>
<li><a href="#" class="nav-link text-white menuLink" data-section="allorders">Orders</a></li>
</ul>

<cfelse>
<ul class="nav flex-column">
<li><a href="#" class="nav-link text-white menuLink" data-section="productList">Products</a></li>
<li><a href="#" class="nav-link text-white menuLink" data-section="orders">Orders</a></li>
<li><a href="#" class="nav-link text-white menuLink" data-section="cart">Cart</a></li>
</ul>
</cfif>

<a href="../../controllers/LogoutController.cfm" class="btn btn-danger w-100 mt-4">Logout</a>

</div>
</div>

<!-- MAIN -->

<div class="col-12 col-md-10 d-flex flex-column h-100">

<!-- HEADER -->

<div class="d-flex justify-content-between align-items-center p-3 bg-white border-bottom">

<button class="btn btn-dark d-md-none" data-bs-toggle="offcanvas" data-bs-target="#mobileSidebar">
=
</button>

<h4 class="mb-0">Inventory Store</h4>

<div class="dropdown">
    <button class="btn btn-secondary btn-sm dropdown-toggle" data-bs-toggle="dropdown">
        Profile
    </button>


<div class="dropdown-menu dropdown-menu-end p-3 text-center shadow" style="min-width: 220px;">

    <cfoutput>

    <!-- Avatar -->
    <div class="mb-2">
        <div class="bg-primary text-white rounded-circle d-inline-flex justify-content-center align-items-center"
             style="width:50px;height:50px;font-weight:bold;">
            #ucase(left(userData.first_name,1))#
        </div>
    </div>
    <h6 class="mb-0 fw-bold">
        #userData.first_name# #userData.last_name#
    </h6>
    <small class="text-muted d-block mb-2">
        #userData.email#
    </small>
    <span class="badge bg-dark mb-3">
        #userData.role_name#
    </span>
        <hr class="my-2">

    <a href="../../controllers/LogoutController.cfm"
       class="btn btn-danger btn-sm w-100">
        Logout
    </a>

    </cfoutput>

</div>

</div>


</div>

<!-- CONTENT -->

<div id="mainContent" class="p-4 flex-grow-1 overflow-auto">

<cfif section EQ "users"> <cfinclude template="../admin/users.cfm">
<cfelseif section EQ "vendors"> <cfinclude template="../admin/vendors.cfm">
<cfelseif section EQ "roles"> <cfinclude template="../admin/roles.cfm">
<cfelseif section EQ "coupons"> <cfinclude template="../admin/coupon.cfm">
<cfelseif section EQ "products"> <cfinclude template="../admin/products.cfm">
<cfelseif section EQ "allorders"> <cfinclude template="../admin/orders.cfm">
<cfelseif section EQ "productList"> <cfinclude template="../user/products.cfm">
<cfelseif section EQ "cart"> <cfinclude template="../user/cart.cfm">
<cfelseif section EQ "orders"> <cfinclude template="../user/orders.cfm"> <cfelse> <h4>Welcome</h4> </cfif>

</div>

</div>
</div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

<script>
$(document).on("click",".menuLink",function(e){
    e.preventDefault();

    let section = $(this).data("section");

    window.history.pushState(null,"","?page=dashboard&section="+section);

    $.get("../../controllers/DashboardController.cfm",{section:section},function(res){
        $("#mainContent").html(res);
    });
});
</script>

</body>
</html>
