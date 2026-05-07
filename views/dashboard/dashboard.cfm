<cfif NOT structKeyExists(session, "user_id")>
    <cflocation url="../../index.cfm?page=auth&message=please login first&type=error&tab=login" addtoken="false">
    <cfabort>
</cfif>

<!--- Vendor plan gate --->
<cfif session.role_name EQ "vendor">
    <cfif NOT structKeyExists(session,"plan_id") OR session.plan_id EQ 0>
        <cfset planModel = createObject("component","models.Plan")>
        <cfset planQ     = planModel.getVendorPlan(session.user_id)>
        <cfif planQ.recordCount>
            <cfset session.plan_id   = planQ.id>
            <cfset session.plan_name = lcase(planQ.plan_name)>
        <cfelse>
            <cfinclude template="/views/vendor/selectPlan.cfm">
            <cfabort>
        </cfif>
    </cfif>
</cfif>

<cfparam name="url.section" default="home">
<cfset section = url.section>

<cfset userModel = createObject("component","models.User")>
<cfset userData  = userModel.getUserWithRole(session.user_id)>

<!DOCTYPE html>
<html>
<head>
    <title>Dashboard</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        html, body { height: 100%; overflow: hidden; }

        .menuLink { transition: all 0.2s ease; }
        .menuLink:hover { background-color: rgba(255,255,255,0.1); }
        .menuLink.active {
            background-color: #0d6efd !important;
            color: #fff !important;
            font-weight: 600;
            border-left: 4px solid #fff;
            padding-left: 10px;
        }

        /* ── SKELETON LOADER ── */
        .skeleton-wrap { padding: 1.5rem; }
        .skeleton-line {
            height: 18px;
            background: linear-gradient(90deg, #e0e0e0 25%, #f5f5f5 50%, #e0e0e0 75%);
            background-size: 400% 100%;
            animation: shimmer 1.2s infinite;
            border-radius: 4px;
            margin-bottom: 12px;
        }
        .skeleton-line.short  { width: 40%; }
        .skeleton-line.medium { width: 70%; }
        .skeleton-line.full   { width: 100%; }
        .skeleton-card {
            background: linear-gradient(90deg, #e0e0e0 25%, #f5f5f5 50%, #e0e0e0 75%);
            background-size: 400% 100%;
            animation: shimmer 1.2s infinite;
            border-radius: 8px;
            height: 90px;
            margin-bottom: 16px;
        }
        .skeleton-table-row {
            height: 44px;
            background: linear-gradient(90deg, #e0e0e0 25%, #f5f5f5 50%, #e0e0e0 75%);
            background-size: 400% 100%;
            animation: shimmer 1.2s infinite;
            border-radius: 4px;
            margin-bottom: 8px;
        }
        @keyframes shimmer {
            0%   { background-position: 200% 0; }
            100% { background-position: -200% 0; }
        }


        #mainContent {
            flex: 1;
            overflow-y: auto;       /* default: normal sections scroll */
            display: flex;
            flex-direction: column;
        }
        #mainContent.chat-mode {
            overflow: hidden;       /* chat sections: no outer scroll */
            padding: 0 !important;  /* remove the p-3/p-md-4 padding */
        }
        /* chat shell must fill its parent when injected */
        #mainContent.chat-mode .chat-shell {
            flex: 1;
            min-height: 0;
        }
    </style>
</head>
<body class="bg-light">

<div class="container-fluid" style="height:100vh; display:flex; flex-direction:column; overflow:hidden;">
<div class="row" style="flex:1; min-height:0; overflow:hidden;">

<!-- DESKTOP SIDEBAR -->
<div class="col-md-2 d-none d-md-flex flex-column bg-dark text-white p-3" style="overflow-y:auto; height:100%;">
    <h5 class="text-center">Menu</h5>
    <hr class="bg-light">

    <cfif session.role_id EQ 1>
    <ul class="nav flex-column">
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'users'>active</cfif>"    data-section="users">Users</a></li>
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'vendors'>active</cfif>"  data-section="vendors">Vendors</a></li>
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'roles'>active</cfif>"    data-section="roles">Roles</a></li>
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'coupons'>active</cfif>"  data-section="coupons">Coupons</a></li>
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'reviews'>active</cfif>"  data-section="reviews">Reviews</a></li>
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'plans'>active</cfif>"    data-section="plans">Plans</a></li>
    </ul>

    <cfelseif session.role_name EQ "vendor">
    <ul class="nav flex-column">
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'vendorDashboard'>active</cfif>" data-section="vendorDashboard">Dashboard</a></li>
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'category'>active</cfif>"        data-section="category">Categories</a></li>
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'products'>active</cfif>"        data-section="products">Products</a></li>
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'allorders'>active</cfif>"       data-section="allorders">Orders</a></li>
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'createOrder'>active</cfif>"     data-section="createOrder">Create Order</a></li>
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'vendorChat'>active</cfif>"      data-section="vendorChat">Chat</a></li>
        <cfif session.plan_name EQ "pro">
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'adminEnquiries'>active</cfif>"  data-section="adminEnquiries">Enquiries</a></li>
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'scheduledOrders'>active</cfif>" data-section="scheduledOrders">Scheduled Orders</a></li>
        <cfelse>
        <li><span class="nav-link text-secondary" style="cursor:default;">Enquiries <span class="badge bg-warning text-dark ms-1">Pro</span></span></li>
        <li><span class="nav-link text-secondary" style="cursor:default;">Scheduled Orders <span class="badge bg-warning text-dark ms-1">Pro</span></span></li>
        </cfif>
    </ul>

    <cfelse>
    <ul class="nav flex-column">
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'productList'>active</cfif>" data-section="productList">Products</a></li>
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'orders'>active</cfif>"      data-section="orders">Orders</a></li>
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'enquiry'>active</cfif>"     data-section="enquiry">My Enquiries</a></li>
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'chat'>active</cfif>"        data-section="chat">Chat</a></li>
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
        <cfif session.role_id EQ 1>
        <ul class="nav flex-column">
            <li><a href="#" class="nav-link text-white menuLink" data-section="users">Users</a></li>
            <li><a href="#" class="nav-link text-white menuLink" data-section="vendors">Vendors</a></li>
            <li><a href="#" class="nav-link text-white menuLink" data-section="roles">Roles</a></li>
            <li><a href="#" class="nav-link text-white menuLink" data-section="coupons">Coupons</a></li>
            <li><a href="#" class="nav-link text-white menuLink" data-section="reviews">Reviews</a></li>
        </ul>
        <cfelseif session.role_name EQ "vendor">
        <ul class="nav flex-column">
            <li><a href="#" class="nav-link text-white menuLink" data-section="vendorDashboard">Dashboard</a></li>
            <li><a href="#" class="nav-link text-white menuLink" data-section="category">Categories</a></li>
            <li><a href="#" class="nav-link text-white menuLink" data-section="products">Products</a></li>
            <li><a href="#" class="nav-link text-white menuLink" data-section="allorders">Orders</a></li>
            <li><a href="#" class="nav-link text-white menuLink" data-section="createOrder">Create Order</a></li>
            <li><a href="#" class="nav-link text-white menuLink" data-section="vendorChat">Chat</a></li>
            <cfif session.plan_name EQ "pro">
            <li><a href="#" class="nav-link text-white menuLink" data-section="adminEnquiries">Enquiries</a></li>
            <li><a href="#" class="nav-link text-white menuLink" data-section="scheduledOrders">Scheduled Orders</a></li>
            <cfelse>
            <li><span class="nav-link text-secondary" style="cursor:default;">Enquiries <span class="badge bg-warning text-dark ms-1">Pro</span></span></li>
            <li><span class="nav-link text-secondary" style="cursor:default;">Scheduled Orders <span class="badge bg-warning text-dark ms-1">Pro</span></span></li>
            </cfif>
        </ul>
        <cfelse>
        <ul class="nav flex-column">
            <li><a href="#" class="nav-link text-white menuLink" data-section="productList">Products</a></li>
            <li><a href="#" class="nav-link text-white menuLink" data-section="orders">Orders</a></li>
            <li><a href="#" class="nav-link text-white menuLink" data-section="enquiry">My Enquiries</a></li>
            <li><a href="#" class="nav-link text-white menuLink" data-section="chat">Chat</a></li>
        </ul>
        </cfif>
        <a href="../../controllers/LogoutController.cfm" class="btn btn-danger w-100 mt-4">Logout</a>
    </div>
</div>

<!-- MAIN CONTENT AREA -->
<div class="col-12 col-md-10 d-flex flex-column" style="height:100%; overflow:hidden;">

    <!-- HEADER -->
    <div class="d-flex justify-content-between align-items-center p-3 bg-white border-bottom" style="flex-shrink:0;">
        <button class="btn btn-dark d-md-none" data-bs-toggle="offcanvas" data-bs-target="#mobileSidebar">☰</button>
        <h5 class="mb-0">Inventory Store</h5>
        <div class="d-flex align-items-center gap-2">
            <cfif session.role_id NEQ 1 AND session.role_name NEQ 'vendor'>
                <a href="../../index.cfm?page=dashboard&section=cart" class="btn btn-success btn-sm">Cart</a>
            </cfif>
            <div class="dropdown">
                <button class="btn btn-secondary btn-sm dropdown-toggle" data-bs-toggle="dropdown">Profile</button>
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
                    <a href="../../controllers/LogoutController.cfm" class="btn btn-danger btn-sm w-100">Logout</a>
                    </cfoutput>
                </div>
            </div>
        </div>
    </div>

    <div id="mainContent" class="p-3 p-md-4 <cfif section EQ 'chat' OR section EQ 'vendorChat'>chat-mode</cfif>">

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
            <cfif session.role_name EQ "vendor" AND session.plan_name NEQ "pro">
                <div class="alert alert-warning">This feature requires the Pro plan.</div>
            <cfelse>
                <cfinclude template="../admin/enquiries.cfm">
            </cfif>
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
        <cfelseif section EQ "plans">
            <cfinclude template="../admin/plans.cfm">
        <cfelseif section EQ "chat">
            <cfinclude template="../user/chat.cfm">
        <cfelseif section EQ "vendorChat">
            <cfinclude template="../vendor/chats.cfm">
        <cfelseif section EQ "createOrder">
            <cfinclude template="../vendor/createOrder.cfm">
        <cfelseif section EQ "scheduledOrders">
            <cfif session.role_name EQ "vendor" AND session.plan_name NEQ "pro">
                <div class="alert alert-warning">This feature requires the Pro plan.</div>
            <cfelse>
                <cfinclude template="../vendor/scheduledOrders.cfm">
            </cfif>
        <cfelseif section EQ "reviews">
            <cfinclude template="../admin/reviews.cfm">
        <cfelse>
            <h5>Welcome</h5>
        </cfif>

    </div>
</div>
</div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
$(function(){

    var chatSections = { chat: 1, vendorChat: 1 };

    /* ── SKELETON TEMPLATES ── */
    var skeletons = {
        table: '<div class="skeleton-wrap">'
             + '<div class="skeleton-line short mb-4"></div>'
             + '<div class="skeleton-table-row"></div>'
             + '<div class="skeleton-table-row"></div>'
             + '<div class="skeleton-table-row"></div>'
             + '<div class="skeleton-table-row"></div>'
             + '<div class="skeleton-table-row"></div>'
             + '</div>',
        cards: '<div class="skeleton-wrap">'
             + '<div class="skeleton-line short mb-4"></div>'
             + '<div class="row g-3">'
             + '<div class="col-md-4"><div class="skeleton-card"></div></div>'
             + '<div class="col-md-4"><div class="skeleton-card"></div></div>'
             + '<div class="col-md-4"><div class="skeleton-card"></div></div>'
             + '</div>'
             + '<div class="skeleton-table-row mt-3"></div>'
             + '<div class="skeleton-table-row"></div>'
             + '<div class="skeleton-table-row"></div>'
             + '</div>',
        chat: '<div class="p-4 text-center text-muted"><div class="spinner-border"></div></div>'
    };

    var skeletonMap = {
        users           : 'table',
        vendors         : 'table',
        roles           : 'table',
        coupons         : 'table',
        reviews         : 'table',
        category        : 'table',
        products        : 'table',
        allorders       : 'table',
        adminEnquiries  : 'table',
        productList     : 'cards',
        cart            : 'table',
        orders          : 'table',
        enquiry         : 'table',
        vendorDashboard : 'cards',
        createOrder     : 'table',
        scheduledOrders : 'table',
        chat            : 'chat',
        vendorChat      : 'chat'
    };

    var noCacheSet = { orders:1, allorders:1, vendorDashboard:1, cart:1, chat:1, vendorChat:1 };
    var tabCache   = {};
    var activeXhr  = null;

    function applyContainerMode(section){
        var mc = $('#mainContent');
        if(chatSections[section]){
            mc.addClass('chat-mode').removeClass('p-3 p-md-4');
        } else {
            mc.removeClass('chat-mode').addClass('p-3 p-md-4');
        }
    }

    function loadSection(section, fromCache){
        $(".menuLink").removeClass("active");
        $(".menuLink[data-section='" + section + "']").addClass("active");
        window.history.pushState(null, "", "?page=dashboard&section=" + section);

        applyContainerMode(section);

        if(fromCache && tabCache[section] && !noCacheSet[section]){
            $("#mainContent").html(tabCache[section]);
            return;
        }

        var skelType = skeletonMap[section] || 'table';
        $("#mainContent").html(skeletons[skelType]);

        if(activeXhr){ activeXhr.abort(); }

        activeXhr = $.ajax({
            url     : "../../controllers/DashboardController.cfm",
            type    : "GET",
            data    : { section: section },
            success : function(res){
                tabCache[section] = res;
                $("#mainContent").html(res);
                activeXhr = null;
            },
            error   : function(xhr){
                if(xhr.statusText !== "abort"){
                    $("#mainContent").html(
                        '<div class="alert alert-danger m-3">Failed to load section. '
                        + '<a href="#" onclick="loadSection(\'' + section + '\')">Retry</a></div>'
                    );
                }
                activeXhr = null;
            }
        });
    }

    window.loadSection = loadSection;

    applyContainerMode("<cfoutput>#section#</cfoutput>");

    $(document).on("click", ".menuLink", function(e){
        e.preventDefault();
        loadSection($(this).data("section"), true);
    });

    /* ── PREFETCH ── */
    <cfif session.role_name EQ "vendor">
    setTimeout(function(){
        var prefetchOrder   = ["products","allorders","category","adminEnquiries"];
        var i               = 0;
        var currentSection  = "<cfoutput>#section#</cfoutput>";
        function next(){
            if(i >= prefetchOrder.length) return;
            var s = prefetchOrder[i++];
            if(s === currentSection || tabCache[s]){ next(); return; }
            $.get("../../controllers/DashboardController.cfm",{section:s},function(res){ tabCache[s]=res; })
             .always(function(){ setTimeout(next,600); });
        }
        next();
    }, 2000);
    <cfelseif session.role_id EQ 1>
    setTimeout(function(){
        var prefetchOrder   = ["users","vendors","roles","coupons"];
        var i               = 0;
        var currentSection  = "<cfoutput>#section#</cfoutput>";
        function next(){
            if(i >= prefetchOrder.length) return;
            var s = prefetchOrder[i++];
            if(s === currentSection || tabCache[s]){ next(); return; }
            $.get("../../controllers/DashboardController.cfm",{section:s},function(res){ tabCache[s]=res; })
             .always(function(){ setTimeout(next,600); });
        }
        next();
    }, 2000);
    </cfif>

});
</script>
</body>
</html>
