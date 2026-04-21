<cfparam name="url.section" default="home">

<cfif url.section EQ "users">
    <cfinclude template="../views/admin/users.cfm">

<cfelseif url.section EQ "roles">
    <cfinclude template="../views/admin/roles.cfm">

<cfelseif url.section EQ "category">
    <cfinclude template="../views/admin/category.cfm">

<cfelseif url.section EQ "products">
    <cfinclude template="../views/admin/products.cfm">

<cfelseif url.section EQ "allorders">
    <cfinclude template="../views/admin/orders.cfm">

<cfelseif url.section EQ "coupons">
    <cfinclude template="../views/admin/coupon.cfm">

<cfelseif url.section EQ "adminEnquiries">
    <cfinclude template="../views/admin/enquiries.cfm">

<cfelseif url.section EQ "productList">
    <cfinclude template="../views/user/products.cfm">

<cfelseif url.section EQ "cart">
    <cfinclude template="../views/user/cart.cfm">

<cfelseif url.section EQ "orders">
    <cfinclude template="../views/user/orders.cfm">

<cfelseif url.section EQ "enquiry">
    <cfinclude template="../views/user/enquiry.cfm">

<cfelseif url.section EQ "vendorDashboard">
    <cfinclude template="../views/vendor/dashboard.cfm">

<cfelseif url.section EQ "createOrder">
    <cfinclude template="../views/vendor/createOrder.cfm">

<cfelse>
    <cfoutput>
        <h4>Welcome Dashboard</h4>
    </cfoutput>
</cfif>