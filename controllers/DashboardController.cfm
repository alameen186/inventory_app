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
    
<cfelseif url.section EQ "chat">
    <cfinclude template="../views/user/chat.cfm">

<cfelseif url.section EQ "vendorDashboard">
    <cfinclude template="../views/vendor/dashboard.cfm">

<cfelseif url.section EQ "createOrder">
    <cfinclude template="../views/vendor/createOrder.cfm">

<cfelseif url.section EQ "vendors">
    <cfinclude template="../views/admin/vendors.cfm">

<cfelseif url.section EQ "reviews">
    <cfinclude template="../views/admin/reviews.cfm">    

<cfelseif url.section EQ "scheduledOrders">
    <cfinclude template="../views/vendor/scheduledOrders.cfm">   

<cfelseif url.section EQ "vendorChat">
    <cfinclude template="../views/vendor/chats.cfm">  

<cfelseif url.section EQ "report">
    <cfinclude template="../views/vendor/reports.cfm">    

<cfelseif url.section EQ "staff">
    <cfinclude template="../views/vendor/staff.cfm">    

<cfelseif url.section EQ "staffLeave">
    <cfinclude template="../views/vendor/leaves.cfm">    

<cfelseif url.section EQ "offer">
    <cfinclude template="../views/vendor/offers.cfm">  
      
<cfelseif url.section EQ "adminTickets">
    <cfinclude template="../views/admin/tickets.cfm">    

<cfelseif url.section EQ "tickets">
    <cfinclude template="../views/user/tickets.cfm">    

<cfelseif url.section EQ "racks">
    <cfinclude template="../views/admin/racks.cfm">

<cfelseif url.section EQ "rackPlacement">
    <cfinclude template="../views/vendor/rackPlacement.cfm">

<cfelseif url.section EQ "rackManagement">
    <cfinclude template="../views/vendor/rackManagement.cfm">

<cfelseif url.section EQ "vehicle">
    <cfinclude template="../views/vendor/vehicles.cfm">

<cfelseif url.section EQ "wholesaleOrders">
    <cfinclude template="../views/vendor/wholesaleOrders.cfm">

<cfelse>
    <cfoutput>
        <h4>Welcome Dashboard</h4>
    </cfoutput>
</cfif>