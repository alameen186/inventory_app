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
    <link rel="stylesheet" href="../../assets/css/dashboard.css">
    <link rel="stylesheet"href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

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
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'adminTickets'>active</cfif>"data-section="adminTickets">Support Tickets</a></li>
    </ul>

    <cfelseif session.role_name EQ "vendor">
    <ul class="nav flex-column">
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'vendorDashboard'>active</cfif>" data-section="vendorDashboard">Dashboard</a></li>
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'category'>active</cfif>"        data-section="category">Categories</a></li>
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'products'>active</cfif>"        data-section="products">Products</a></li>
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'allorders'>active</cfif>"       data-section="allorders">Orders</a></li>
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'createOrder'>active</cfif>"     data-section="createOrder">Create Order</a></li>
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'vendorChat'>active</cfif>"      data-section="vendorChat">Chat</a></li>
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'report'>active</cfif>"      data-section="report">Report</a></li>
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'staff'>active</cfif>"      data-section="staff">Staff</a></li>
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'staffLeave'>active</cfif>"      data-section="staffLeave">Staff Leave</a></li>
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'offer'>active</cfif>"      data-section="offer">Offer</a></li>
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
        <li><a href="#" class="nav-link text-white menuLink <cfif section EQ 'tickets'>active</cfif>" data-section="tickets">My Tickets</a></li>
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
            <li><a href="#" class="nav-link text-white menuLink" data-section="report">Report</a></li>
            <li><a href="#" class="nav-link text-white menuLink" data-section="staff">Staff</a></li>
            <li><a href="#" class="nav-link text-white menuLink" data-section="staffLeave">Staff Leave</a></li>
            <li><a href="#" class="nav-link text-white menuLink" data-section="offer">Offer</a></li>
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
<div class="d-flex justify-content-between align-items-center p-3 bg-white border-bottom flex-wrap gap-2"
     style="flex-shrink:0;">

    <!-- Left Section -->
    <div class="d-flex align-items-center gap-2">

    <button class="btn btn-dark d-md-none"
            data-bs-toggle="offcanvas"
            data-bs-target="#mobileSidebar">

        <i class="bi bi-list fs-5"></i>

    </button>

    <h5 class="mb-0 fw-semibold">Inventory Store</h5>

</div>

    <!-- Right Section -->
    <div class="d-flex align-items-center gap-3">

        <!-- Cart -->
        <cfif session.role_id NEQ 1 AND session.role_name NEQ 'vendor'>
            <a href="../../index.cfm?page=dashboard&section=cart"
               class="btn btn-success btn-sm d-flex align-items-center justify-content-center px-3"
               style="height:38px;">
                Cart
            </a>
        </cfif>

        <!-- Notification -->
        <div class="position-relative d-flex align-items-center">

            <button class="btn btn-outline-secondary btn-sm d-flex align-items-center justify-content-center position-relative"
                    id="notifBellBtn"
                    title="Notifications"
                    style="width:38px; height:38px;">

<i class="bi bi-bell-fill fs-5 text-dark"></i>
            </button>

            <span id="notifBadge"
                  class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger"
                  style="display:none; font-size:0.65rem; padding:4px 6px;">
                0
            </span>
        </div>

        <!-- Profile Dropdown -->
        <div class="dropdown">

            <button class="btn btn-secondary btn-sm dropdown-toggle d-flex align-items-center justify-content-center px-3"
                    data-bs-toggle="dropdown"
                    style="height:38px;">
                Profile
            </button>

            <div class="dropdown-menu dropdown-menu-end p-3 text-center shadow border-0"
                 style="min-width:220px; border-radius:12px;">

                <cfoutput>

                    <div class="mb-2">
                        <div class="bg-primary text-white rounded-circle d-inline-flex justify-content-center align-items-center fw-bold"
                             style="width:55px;height:55px;font-size:20px;">
                            #ucase(left(userData.first_name,1))#
                        </div>
                    </div>

                    <h6 class="mb-1 fw-bold">
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

    <!-- Notification Modal -->
    <div class="modal fade" id="notifModal" tabindex="-1" aria-hidden="true">

        <div class="modal-dialog modal-dialog-scrollable"
             style="max-width:420px;">

            <div class="modal-content">

                <div class="modal-header py-2 px-3 bg-dark text-white">

                    <h6 class="modal-title mb-0 d-flex align-items-center gap-2">

                        <i class="bi bi-bell-fill fs-5 text-white"></i>

                        Notifications
                    </h6>

                    <div class="d-flex align-items-center gap-2 ms-auto">

                        <button class="btn btn-sm btn-outline-light py-1 px-2"
                                id="markAllReadBtn"
                                title="Mark all as read"
                                style="font-size:0.75rem;">

                             <i class="bi bi-check2-circle text-success"></i>

                            All Read
                        </button>

                        <button type="button"
                                class="btn-close btn-close-white"
                                data-bs-dismiss="modal">
                        </button>

                    </div>
                </div>

                <!-- Notification List -->
                <div class="modal-body p-0"
                     style="max-height:480px; overflow-y:auto;">

                    <div id="notifList">

                        <div class="text-center text-muted py-5">
                            <div class="spinner-border spinner-border-sm"></div>
                            <p class="mt-2 small mb-0">Loading...</p>
                        </div>

                    </div>
                </div>

                <div class="modal-footer py-2 px-3 justify-content-center">
                    <small class="text-muted">
                        Only last 20 notifications shown
                    </small>
                </div>

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
        <cfelseif section EQ "report">
            <cfinclude template="../vendor/reports.cfm">
        <cfelseif section EQ "staff">
            <cfinclude template="../vendor/staff.cfm">
        <cfelseif section EQ "staffLeave">
            <cfinclude template="../vendor/leaves.cfm">
        <cfelseif section EQ "offer">
            <cfinclude template="../vendor/offers.cfm">
        <cfelseif section EQ "tickets">
            <cfinclude template="../user/tickets.cfm">
        <cfelseif section EQ "adminTickets">
            <cfinclude template="../admin/tickets.cfm">    
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



(function(){
    var NOTIF = "../../controllers/NotificationController.cfc";

   var iconMap = {

    order_placed : `
        <i class="bi bi-bag-check-fill text-success"></i>`,

    order_cancelled_vendor : `
        <i class="bi bi-x-circle-fill text-danger"></i>`,

    order_cancelled_user : `
        <i class="bi bi-check-circle-fill text-primary"></i>`,

    cancel_request_vendor : `
        <i class="bi bi-exclamation-triangle-fill text-warning"></i>`,

    restock_alert : `
        <i class="bi bi-box-seam-fill text-purple"></i>`,

    scheduled_order_created : `
        <i class="bi bi-calendar-check-fill text-info"></i>`,

    new_enquiry : `
        <i class="bi bi-question-circle-fill text-info"></i>`,

    cancel_approved : `
        <i class="bi bi-check2-circle text-success"></i>`
};

    // ── Update badge count
    function updateBadge(count){
        if(count > 0){
            $('#notifBadge').text(count > 99 ? '99+' : count).show();
        } else {
            $('#notifBadge').hide();
        }
    }

    // ── Poll unread count every 15s
    function pollCount(){
        $.get(NOTIF + "?method=getCount", function(res){
            if(res && res.success) updateBadge(res.data.count);
        }, "json");
    }


function loadNotifList(){
    
    $('#notifList').html(
        '<div class="text-center text-muted py-4">' +
        '<div class="spinner-border spinner-border-sm"></div>' +
        '<p class="mt-2 small">Loading...</p></div>'
    );

    $.get(NOTIF + "?method=getList", function(res){
        if(!res || !res.success){
            $('#notifList').html('<div class="notif-empty">⚠️ Failed to load notifications.</div>');
            return;
        }

        var notifs = res.data || [];
        if(!notifs.length){
            $('#notifList').html(
                '<div class="notif-empty"> &#128276;<br><strong>All caught up!</strong><br>' +
                '<small>No notifications yet.</small></div>'
            );
            return;
        }

        var html = '';
        $.each(notifs, function(i, n){
            var icon    = iconMap[n.type] || '&#128276;';
            var unread  = (n.is_read == 0 || n.is_read === false || n.is_read === 'false');
            var itemCls = unread ? 'notif-item unread' : 'notif-item';

            html += `<div class="${itemCls}" id="notifRow_${n.id}">`;
            html +=   `<div class="d-flex align-items-start gap-2 p-3">`;
            html +=     `<span class="notif-icon">${icon}</span>`;
            html +=     `<div class="flex-grow-1">`;
            html +=       `<div class="notif-title">${$('<div>').text(n.title).html()}</div>`;
            html +=       `<div class="notif-msg">${$('<div>').text(n.message).html()}</div>`;
            html +=       `<div class="notif-time small text-muted">${n.time}</div>`;
            html +=     `</div>`;
            
            if(unread){
                html += `<button class="notif-read-btn markOneBtn btn btn-sm" data-id="${n.id}" title="Mark as read">✔</button>`;
            }
            html +=   `</div>`;

            // === IMPORTANT: Better Click Handler ===
            if(n.link && n.link.length){
                html += `<a href="${n.link}" class="stretched-link" ` +
                        `onclick="markOneRead(${n.id}); event.stopImmediatePropagation();"></a>`;
            }
            html += `</div>`;
        });

        $('#notifList').html(html);
        pollCount();
    }, "json");
}
    // ── Mark one read 
    window.markOneRead = function(id){
    $.post(NOTIF + "?method=markRead", { id: id }, function(res){
        if(res && res.success){
            $('#notifRow_' + id).removeClass('unread');
            pollCount();
        }
    }, "json");
};

    // ── Tick button click 
    $(document).on('click', '.markOneBtn', function(e){
        e.preventDefault();
        e.stopPropagation();
        markOneRead(parseInt($(this).data('id')));
    });

    // ── Mark all read
    $(document).on('click', '#markAllReadBtn', function(){
        $.post(NOTIF + "?method=markAllRead", function(res){
            if(res && res.success){
                loadNotifList();
            }
        }, "json");
    });

    
    $(document).on('click', '#notifBellBtn', function(){
        var modal = new bootstrap.Modal(document.getElementById('notifModal'));
        modal.show();
        loadNotifList();
    });

    // ── Boot
    pollCount();
    setInterval(pollCount, 15000);

})();


});
</script>

<cfif session.role_id NEQ 1 AND session.role_name NEQ 'vendor'>
<button onclick="openTicketModal()"
        title="Report Issue"
        class="btn btn-danger rounded-circle shadow-lg d-flex align-items-center justify-content-center"
        style="position:fixed; bottom:28px; right:28px; z-index:1055; width:52px; height:52px; font-size:22px;">
    <i class="bi bi-ticket-perforated-fill"></i>
</button>
</cfif>

<script src="../../assets/js/ticket-widget.js"></script>
</body>
</html>
