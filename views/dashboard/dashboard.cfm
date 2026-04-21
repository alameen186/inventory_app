<cfif NOT structKeyExists(session, "user_id")>
   <cflocation url="../../index.cfm?page=auth&message=please login first&type=error&tab=login" addtoken="false">
   <cfabort>
</cfif>

<cfparam name="url.section" default="home">
<cfset section = url.section>

<cfset userModel = createObject("component","models.User")>
<cfset userData = userModel.getUserWithRole(session.user_id)>

<!DOCTYPE html>
<html>
<head>
    <title>Dashboard</title>
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>

<body class="bg-light" style="overflow: hidden;">

<div class="container-fluid vh-100 overflow-hidden">
<div class="row h-100">

<!-- SIDEBAR -->
<div class="col-md-2 bg-dark text-white p-3 h-100 overflow-auto">
<h5 class="text-center">Menu</h5>
<hr class="bg-light">

<cfif session.role_id EQ 1>

<ul class="nav flex-column">
<li class="nav-item"><a href="../../index.cfm?page=dashboard" class="nav-link text-white">Dashboard</a></li>
<li class="nav-item"><a href="#" class="nav-link text-white menuLink" data-section="users">Users</a></li>
<li class="nav-item"><a href="#" class="nav-link text-white menuLink" data-section="vendors">Vendors</a></li>
<li class="nav-item"><a href="#" class="nav-link text-white menuLink" data-section="roles">Roles</a></li>
<li class="nav-item"><a href="#" class="nav-link text-white menuLink" data-section="coupons">Coupons</a></li>
</ul>

<cfelseif session.role_name EQ "vendor">

<ul class="nav flex-column">
<li class="nav-item mb-2"><a href="#" class="nav-link text-white menuLink" data-section="vendorDashboard">Dashboard</a></li>
<li class="nav-item"><a href="#" class="nav-link text-white menuLink" data-section="category">Categories</a></li>
<li class="nav-item"><a href="#" class="nav-link text-white menuLink" data-section="products">Products</a></li>
<li class="nav-item"><a href="#" class="nav-link text-white menuLink" data-section="allorders">Orders</a></li>
<li class="nav-item"><a href="#" class="nav-link text-white menuLink" data-section="adminEnquiries">Enquiries</a></li>
<li class="nav-item"><a href="#" class="nav-link text-white menuLink" data-section="createOrder">Creat Order</a></li>
</ul>

<cfelse>

<ul class="nav flex-column">
<li class="nav-item"><a href="#" class="nav-link text-white menuLink" data-section="productList">Products</a></li>
<li class="nav-item"><a href="#" class="nav-link text-white menuLink" data-section="orders">Orders</a></li>
<li class="nav-item"><a href="#" class="nav-link text-white menuLink" data-section="enquiry">My Enquiries</a></li>
</ul>

</cfif>

<a href="../../controllers/LogoutController.cfm" class="btn btn-danger w-100 mt-4">Logout</a>

</div>

<!-- MAIN -->
<div class="col-md-10 d-flex flex-column h-100 overflow-hidden">    
<!-- HEADER -->
<div class="d-flex justify-content-between p-3 border-bottom">
<h4>Inventory Store</h4>

<div class="dropdown">
<cfif session.role_id NEQ 1 AND session.role_name NEQ 'vendor'>
    <a href="../../index.cfm?page=dashboard&section=cart" class="btn btn-success btn-sm">Cart</a>
</cfif>


<button class="btn btn-secondary btn-sm dropdown-toggle" data-bs-toggle="dropdown">Profile</button>

<div class="dropdown-menu dropdown-menu-end p-3">
<cfoutput>
<p><strong>#userData.first_name# #userData.last_name#</strong></p>
<p>#userData.email#</p>
<p><strong>#userData.role_name#</strong></p>
</cfoutput>
</div>
</div>

</div>

<!-- CONTENT -->
<div id="mainContent" class="p-4 flex-grow-1 overflow-auto">

<cfif section EQ "users">
    <cfinclude template="../admin/users.cfm">

<cfelseif section EQ "roles">
    <cfinclude template="../admin/roles.cfm">

<cfelseif section EQ "coupons">
    <cfinclude template="../admin/coupon.cfm">

<cfelseif section EQ "category">
    <cfinclude template="../admin/category.cfm">

<cfelseif section EQ "products">
    <cfinclude template="../admin/products.cfm">

<cfelseif section EQ "allorders">
    <cfinclude template="../admin/orders.cfm">

<cfelseif section EQ "adminEnquiries">
    <cfinclude template="../admin/enquiries.cfm">

<cfelseif section EQ "productList">
    <cfinclude template="../user/products.cfm">

<cfelseif section EQ "cart">
    <cfinclude template="../user/cart.cfm">

<cfelseif section EQ "orders">
    <cfinclude template="../user/orders.cfm">

<cfelseif section EQ "enquiry">
    <cfinclude template="../user/enquiry.cfm">

<cfelseif section EQ "vendorDashboard">
        <cfinclude template="../vendor/dashboard.cfm">

<cfelseif section EQ "createOrder">
        <cfinclude template="../vendor/createOrder.cfm">

<cfelseif url.section EQ "vendors">
    <cfinclude template="../admin/vendors.cfm">

<cfelse>

    <cfif session.role_id EQ 1>
        <cfinclude template="../admin/dashboard.cfm">

    <cfelseif session.role_name EQ "vendor">
        <cfinclude template="../vendor/dashboard.cfm">

    <cfelse>
        <cfinclude template="../user/products.cfm">
    </cfif>

</cfif>

</div>

</div>
</div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

<script>
$(document).on("click",".menuLink",function(e){
    e.preventDefault();

    let section = $(this).data("section");

    // 🔥 update URL (IMPORTANT)
    window.history.pushState(null, "", "?page=dashboard&section=" + section);

    $.get("../../controllers/DashboardController.cfm",{section:section},function(res){
        $("#mainContent").html(res);
    });
});
</script>

</body>
</html>