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
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
.menuLink {
    transition: all 0.2s ease;
}

.menuLink:hover {
    background-color: rgba(255,255,255,0.1);
}


.menuLink.active {
    background-color: #0d6efd !important;
    color: #fff !important;
    font-weight: 600;
    border-left: 4px solid #fff;
    padding-left: 10px;
}
</style>
</head>

<body class="bg-light">

<div class="container-fluid vh-100">
<div class="row h-100">

<!--  DESKTOP SIDEBAR  -->
<div class="col-md-2 d-none d-md-block bg-dark text-white p-3 overflow-auto">

<h5 class="text-center">Menu</h5>
<hr class="bg-light">

<cfif session.role_id EQ 1>
<ul class="nav flex-column">
<li><a href="#"class="nav-link text-white menuLink <cfif section EQ 'users'>active</cfif>"data-section="users">Users</a></li>
<li><a href="#"class="nav-link text-white menuLink <cfif section EQ 'vendors'>active</cfif>"data-section="vendors">Vendors</a></li>
<li><a href="#"class="nav-link text-white menuLink <cfif section EQ 'roles'>active</cfif>"data-section="roles">Roles</a></li>
<li><a href="#"class="nav-link text-white menuLink <cfif section EQ 'coupons'>active</cfif>"data-section="coupons">Coupons</a></li>
</ul>

<cfelseif session.role_name EQ "vendor">
<ul class="nav flex-column">
<li><a href="#"class="nav-link text-white menuLink <cfif section EQ 'vendorDashboard'>active</cfif>"data-section="vendorDashboard"> Dashboard</a></li>
<li><a href="#"class="nav-link text-white menuLink <cfif section EQ 'category'>active</cfif>"data-section="category"> Categories</a></li>
<li><a href="#"class="nav-link text-white menuLink <cfif section EQ 'products'>active</cfif>"data-section="products"> Products</a></li>
<li><a href="#"class="nav-link text-white menuLink <cfif section EQ 'allorders'>active</cfif>"data-section="allorders"> Orders</a></li>
<li><a href="#"class="nav-link text-white menuLink <cfif section EQ 'adminEnquiries'>active</cfif>"data-section="adminEnquiries"> Enquiries</a></li>
<li><a href="#"class="nav-link text-white menuLink <cfif section EQ 'createOrder'>active</cfif>"data-section="createOrder"> Create Order</a></li>
</ul> 
    
<cfelse>
<ul class="nav flex-column">
<li><a href="#"class="nav-link text-white menuLink <cfif section EQ 'productList'>active</cfif>"data-section="productList"> Products</a></li>
<li><a href="#"class="nav-link text-white menuLink <cfif section EQ 'orders'>active</cfif>"data-section="orders"> Orders</a></li>
<li><a href="#"class="nav-link text-white menuLink <cfif section EQ 'enquiry'>active</cfif>"data-section="enquiry"> My Enquiries</a></li>
</ul>
</cfif>

<a href="../../controllers/LogoutController.cfm" class="btn btn-danger w-100 mt-4">Logout</a>
</div>

<!--  MOBILE SIDEBAR  -->
<div class="offcanvas offcanvas-start bg-dark text-white" id="mobileSidebar">
<div class="offcanvas-header">
<h5>Menu</h5>
<button class="btn-close btn-close-white" data-bs-dismiss="offcanvas"></button>
</div>

<div class="offcanvas-body">

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
<li><a href="#" class="nav-link text-white menuLink" data-section="category">Categories</a></li>
<li><a href="#" class="nav-link text-white menuLink" data-section="products">Products</a></li>
<li><a href="#" class="nav-link text-white menuLink" data-section="allorders">Orders</a></li>
<li><a href="#" class="nav-link text-white menuLink" data-section="adminEnquiries">Enquiries</a></li>
<li><a href="#" class="nav-link text-white menuLink" data-section="createOrder">Create Order</a></li>
</ul>

<cfelse>
<ul class="nav flex-column">
<li><a href="#" class="nav-link text-white menuLink" data-section="productList">Products</a></li>
<li><a href="#" class="nav-link text-white menuLink" data-section="orders">Orders</a></li>
<li><a href="#" class="nav-link text-white menuLink" data-section="enquiry">My Enquiries</a></li>
</ul>
</cfif>

<a href="../../controllers/LogoutController.cfm" class="btn btn-danger w-100 mt-4">Logout</a>
</div>
</div>

<!--  main page  -->
<div class="col-12 col-md-10 d-flex flex-column h-100">

<!-- HEADER -->
<div class="d-flex justify-content-between align-items-center p-3 bg-white border-bottom">

<!-- MOBILE TOGGLE -->
<button class="btn btn-dark d-md-none" data-bs-toggle="offcanvas" data-bs-target="#mobileSidebar">
=
</button>

<h5 class="mb-0">Inventory Store</h5>

<div class="d-flex align-items-center gap-2">

<cfif session.role_id NEQ 1 AND session.role_name NEQ 'vendor'>
<a href="../../index.cfm?page=dashboard&section=cart" class="btn btn-success btn-sm">Cart</a>
</cfif>

<div class="dropdown">
<button class="btn btn-secondary btn-sm dropdown-toggle" data-bs-toggle="dropdown">
Profile
</button>

<div class="dropdown-menu dropdown-menu-end p-3 text-center shadow" style="min-width:220px;">
<cfoutput>
<div class="mb-2">
<div class="bg-primary text-white rounded-circle d-inline-flex justify-content-center align-items-center"
style="width:50px;height:50px;">
#ucase(left(userData.first_name,1))#
</div>
</div>

<h6 class="mb-0 fw-bold">#userData.first_name# #userData.last_name#</h6>
<small class="text-muted d-block mb-2">#userData.email#</small>
<small><span class="badge bg-dark mb-2">#userData.role_name#</span></small>


<hr>

<a href="../../controllers/LogoutController.cfm" class="btn btn-danger btn-sm w-100">
Logout
</a>
</cfoutput>
</div>
</div>

</div>
</div>

<!-- CONTENT -->
<div id="mainContent" class="p-3 p-md-4 flex-grow-1 overflow-auto">

<cfif section EQ "users">
<cfinclude template="../admin/users.cfm">

<cfelseif section EQ "vendors">
<cfinclude template="../admin/vendors.cfm">

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

<cfelse>
<h5>Welcome</h5>
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


$(".menuLink").removeClass("active");


$(".menuLink[data-section='"+section+"']").addClass("active");


window.history.pushState(null,"","?page=dashboard&section="+section);


$.get("../../controllers/DashboardController.cfm",
{section:section},
function(res){
$("#mainContent").html(res);
});
});
</script>

</body>
</html>