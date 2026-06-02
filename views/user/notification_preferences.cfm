<cfif NOT structKeyExists(session,"user_id")>
    <cfabort>
</cfif>

<div class="container-fluid mt-3" id="notifPrefPage">

    <!--- ── PAGE HEADER ── --->
    <div class="d-flex align-items-center gap-3 mb-4">
        <div class="rounded-circle bg-primary bg-opacity-10 d-flex align-items-center
                    justify-content-center" style="width:52px;height:52px;flex-shrink:0;">
            <i class="bi bi-bell-fill text-primary fs-4"></i>
        </div>
        <div>
            <h4 class="mb-0 fw-bold">Notification Preferences</h4>
            <small class="text-muted">Control which smart notifications you receive</small>
        </div>
    </div>

    <div id="prefMsg"></div>

    <div class="row g-4">

        <!--- ── LEFT: STATS CARD ── --->
        <div class="col-12 col-lg-4">

            <!--- Recent Smart Notifications --->
            <div class="card shadow-sm border-0">
                <div class="card-header bg-dark text-white fw-semibold rounded-top">
                    <i class="bi bi-clock-history me-2"></i>Recent Smart Notifications
                </div>
                <div class="card-body p-0" id="historyBody">
                    <div class="text-center py-3">
                        <div class="spinner-border text-primary spinner-border-sm"></div>
                    </div>
                </div>
            </div>

        </div>

        <!--- ── RIGHT: TOGGLE CARDS ── --->
        <div class="col-12 col-lg-8">

            <!--- Saving indicator --->
            <div id="savingIndicator" class="alert alert-info py-2 mb-3 d-none">
                <div class="spinner-border spinner-border-sm me-2"></div>
                Saving preferences...
            </div>

            <!--- 1. Reorder Reminders --->
            <div class="card shadow-sm mb-3 border-0 notif-toggle-card" id="card_reorder">
                <div class="card-body">
                    <div class="d-flex align-items-start justify-content-between gap-3">
                        <div class="d-flex align-items-start gap-3">
                            <div class="rounded-circle bg-success bg-opacity-10
                                        d-flex align-items-center justify-content-center flex-shrink-0"
                                 style="width:44px;height:44px;">
                                <i class="bi bi-arrow-repeat text-success fs-5"></i>
                            </div>
                            <div>
                                <h6 class="mb-1 fw-bold">Reorder Reminders</h6>
                                <p class="text-muted small mb-2">
                                    We track how often you buy each product and remind you
                                    when it's time to restock - based on <em>your</em> pattern.
                                </p>
                                <div class="example-box bg-light rounded p-2 small text-muted border-start border-success border-3">
                                    <i class="bi bi-chat-quote-fill text-success me-1"></i>
                                    <em>"You usually buy milk every 7 days. Would you like to reorder now?"</em>
                                </div>
                            </div>
                        </div>
                        <div class="form-check form-switch flex-shrink-0 mt-1">
                            <input class="form-check-input pref-toggle fs-4"
                                   type="checkbox"
                                   id="tog_reorder"
                                   data-key="reorder_reminders"
                                   style="width:3rem;height:1.5rem;cursor:pointer;">
                        </div>
                    </div>
                </div>
            </div>

            <!--- 2. Personalized Offers --->
            <div class="card shadow-sm mb-3 border-0 notif-toggle-card" id="card_offers">
                <div class="card-body">
                    <div class="d-flex align-items-start justify-content-between gap-3">
                        <div class="d-flex align-items-start gap-3">
                            <div class="rounded-circle bg-warning bg-opacity-10
                                        d-flex align-items-center justify-content-center flex-shrink-0"
                                 style="width:44px;height:44px;">
                                <i class="bi bi-tag-fill text-warning fs-5"></i>
                            </div>
                            <div>
                                <h6 class="mb-1 fw-bold">Personalized Offer Notifications</h6>
                                <p class="text-muted small mb-2">
                                    Get notified when a discount is available on products
                                    you've bought before - not random spam.
                                </p>
                                <div class="example-box bg-light rounded p-2 small text-muted border-start border-warning border-3">
                                    <i class="bi bi-chat-quote-fill text-warning me-1"></i>
                                    <em>"Your favourite coffee brand is now 15% OFF. Offer valid until 30-Jun-2025."</em>
                                </div>
                            </div>
                        </div>
                        <div class="form-check form-switch flex-shrink-0 mt-1">
                            <input class="form-check-input pref-toggle fs-4"
                                   type="checkbox"
                                   id="tog_offers"
                                   data-key="personalized_offers"
                                   style="width:3rem;height:1.5rem;cursor:pointer;">
                        </div>
                    </div>
                </div>
            </div>

            <!--- 3. Smart Recommendations --->
            <div class="card shadow-sm mb-3 border-0 notif-toggle-card" id="card_reco">
                <div class="card-body">
                    <div class="d-flex align-items-start justify-content-between gap-3">
                        <div class="d-flex align-items-start gap-3">
                            <div class="rounded-circle bg-info bg-opacity-10
                                        d-flex align-items-center justify-content-center flex-shrink-0"
                                 style="width:44px;height:44px;">
                                <i class="bi bi-lightbulb-fill text-info fs-5"></i>
                            </div>
                            <div>
                                <h6 class="mb-1 fw-bold">Smart Recommendations</h6>
                                <p class="text-muted small mb-2">
                                    Suggestions based on what customers like you commonly
                                    buy together - bread - butter, noodles - sauce.
                                </p>
                                <div class="example-box bg-light rounded p-2 small text-muted border-start border-info border-3">
                                    <i class="bi bi-chat-quote-fill text-info me-1"></i>
                                    <em>"People who buy bread often also buy butter. Try it today!"</em>
                                </div>
                            </div>
                        </div>
                        <div class="form-check form-switch flex-shrink-0 mt-1">
                            <input class="form-check-input pref-toggle fs-4"
                                   type="checkbox"
                                   id="tog_reco"
                                   data-key="smart_recommendations"
                                   style="width:3rem;height:1.5rem;cursor:pointer;">
                        </div>
                    </div>
                </div>
            </div>

            <!--- 4. Seasonal Predictions --->
            <div class="card shadow-sm mb-3 border-0 notif-toggle-card" id="card_seasonal">
                <div class="card-body">
                    <div class="d-flex align-items-start justify-content-between gap-3">
                        <div class="d-flex align-items-start gap-3">
                            <div class="rounded-circle bg-danger bg-opacity-10
                                        d-flex align-items-center justify-content-center flex-shrink-0"
                                 style="width:44px;height:44px;">
                                <i class="bi bi-calendar-event-fill text-danger fs-5"></i>
                            </div>
                            <div>
                                <h6 class="mb-1 fw-bold">Seasonal Purchase Predictions</h6>
                                <p class="text-muted small mb-2">
                                    Timely nudges during weekends, festivals, and month-end periods
                                    based on your past shopping history.
                                </p>
                                <div class="example-box bg-light rounded p-2 small text-muted border-start border-danger border-3">
                                    <i class="bi bi-chat-quote-fill text-danger me-1"></i>
                                    <em>"Special Ramadan grocery combo available for you. Shop before it runs out!"</em>
                                </div>
                            </div>
                        </div>
                        <div class="form-check form-switch flex-shrink-0 mt-1">
                            <input class="form-check-input pref-toggle fs-4"
                                   type="checkbox"
                                   id="tog_seasonal"
                                   data-key="seasonal_predictions"
                                   style="width:3rem;height:1.5rem;cursor:pointer;">
                        </div>
                    </div>
                </div>
            </div>

            <!--- 5. Cart Recovery --->
            <div class="card shadow-sm mb-3 border-0 notif-toggle-card" id="card_cart">
                <div class="card-body">
                    <div class="d-flex align-items-start justify-content-between gap-3">
                        <div class="d-flex align-items-start gap-3">
                            <div class="rounded-circle bg-primary bg-opacity-10
                                        d-flex align-items-center justify-content-center flex-shrink-0"
                                 style="width:44px;height:44px;">
                                <i class="bi bi-cart-check-fill text-primary fs-5"></i>
                            </div>
                            <div>
                                <h6 class="mb-1 fw-bold">Cart Recovery Reminders</h6>
                                <p class="text-muted small mb-2">
                                    If you add products to your cart but don't complete the purchase
                                    within 2 hours, we'll send a friendly reminder.
                                </p>
                                <div class="example-box bg-light rounded p-2 small text-muted border-start border-primary border-3">
                                    <i class="bi bi-chat-quote-fill text-primary me-1"></i>
                                    <em>"You left 2 items (Milk, Butter) in your cart worth Rs.180. Complete your order!"</em>
                                </div>
                            </div>
                        </div>
                        <div class="form-check form-switch flex-shrink-0 mt-1">
                            <input class="form-check-input pref-toggle fs-4"
                                   type="checkbox"
                                   id="tog_cart"
                                   data-key="cart_recovery"
                                   style="width:3rem;height:1.5rem;cursor:pointer;">
                        </div>
                    </div>
                </div>
            </div>

            <!--- Save Button --->
            <div class="d-grid mt-2">
                <button id="savePrefBtn" class="btn btn-primary btn-lg py-3 fw-semibold">
                    <i class="bi bi-check-circle-fill me-2"></i>Save Notification Preferences
                </button>
            </div>

        </div>
    </div>
</div>

<style>
.notif-toggle-card {
    transition: box-shadow 0.2s, transform 0.2s;
    border: 1px solid #e9ecef !important;
}
.notif-toggle-card:hover {
    box-shadow: 0 4px 18px rgba(0,0,0,0.10) !important;
    transform: translateY(-1px);
}
.notif-toggle-card.is-enabled {
    border-left: 4px solid #0d6efd !important;
}
.example-box {
    font-style: italic;
    font-size: 0.82rem;
}
</style>

<script>
(function(){
    var CTRL = "../../controllers/CustomerNotificationController.cfc";

    /* ── Notification type icons for history -─ */
    var typeIconMap = {
        reorder_reminder    : { icon: "bi-arrow-repeat",       color: "success" },
        personalized_offer  : { icon: "bi-tag-fill",           color: "warning" },
        smart_recommendation: { icon: "bi-lightbulb-fill",     color: "info"    },
        seasonal_weekend    : { icon: "bi-calendar-event-fill",color: "danger"  },
        seasonal_monthend   : { icon: "bi-calendar-event-fill",color: "danger"  },
        seasonal_ramadan    : { icon: "bi-calendar-event-fill",color: "danger"  },
        seasonal_christmas  : { icon: "bi-calendar-event-fill",color: "danger"  },
        seasonal_festival   : { icon: "bi-calendar-event-fill",color: "danger"  },
        cart_recovery       : { icon: "bi-cart-check-fill",    color: "primary" },
        low_stock_alert  : { icon: "bi-exclamation-triangle-fill", color: "warning" },
        price_drop_alert : { icon: "bi-graph-down-arrow",          color: "success" },
        loyalty_points   : { icon: "bi-star-fill",                 color: "warning" }

    };

    /* ── Map preference key → toggle checkbox id ── */
    var keyToId = {
        reorder_reminders     : "tog_reorder",
        personalized_offers   : "tog_offers",
        smart_recommendations : "tog_reco",
        seasonal_predictions  : "tog_seasonal",
        cart_recovery         : "tog_cart"
    };

    /* ── Load preferences + stats from server ── */
    function loadPreferences(){
        $.ajax({
            url      : CTRL + "?method=getPreferences",
            type     : "GET",
            dataType : "json",
            success  : function(res){
                if(!res.success){
                    showMsg(false, "Could not load preferences: " + res.message);
                    return;
                }

                /* Set toggles */
                $.each(keyToId, function(key, togId){
                    var isOn = parseInt(res.data[key]) === 1;
                    $("#" + togId).prop("checked", isOn);
                    updateCardStyle(togId, isOn);
                });

                /* Render stats */
                renderStats(res.data.stats);

                /* Render history */
                renderHistory(res.data.history);
            },
            error: function(){
                showMsg(false, "Network error loading preferences.");
            }
        });
    }

    /* ── Render shopping profile stats ── */
    function renderStats(s){
        var html = "";

        if(!s || s.total_orders === 0){
            html = '<div class="text-center text-muted py-3">'
                 + '<i class="bi bi-bag-x-fill fs-2 d-block mb-2"></i>'
                 + '<small>Place your first order to unlock smart notifications!</small>'
                 + '</div>';
        } else {
            html = '<div class="row g-3 text-center">'

                + '<div class="col-6">'
                + '<div class="bg-primary bg-opacity-10 rounded p-3">'
                + '<div class="fw-bold fs-4 text-primary">' + s.total_orders + '</div>'
                + '<small class="text-muted">Total Orders</small>'
                + '</div></div>'

                + '<div class="col-6">'
                + '<div class="bg-success bg-opacity-10 rounded p-3">'
                + '<div class="fw-bold fs-4 text-success">' + s.unique_products + '</div>'
                + '<small class="text-muted">Products Tried</small>'
                + '</div></div>'

                + '</div>';

            if(s.top_product){
                html += '<div class="mt-3 p-3 bg-warning bg-opacity-10 rounded border-start border-warning border-3">'
                     + '<small class="text-muted d-block">Most Purchased</small>'
                     + '<strong class="text-warning"><i class="bi bi-star-fill me-1"></i>'
                     + $('<div>').text(s.top_product).html() + '</strong>'
                     + '</div>';
            }

            if(s.avg_order_days > 0){
                html += '<div class="mt-3 p-3 bg-info bg-opacity-10 rounded border-start border-info border-3">'
                     + '<small class="text-muted d-block">Average Reorder Cycle</small>'
                     + '<strong class="text-info"><i class="bi bi-arrow-repeat me-1"></i>'
                     + 'Every ' + s.avg_order_days + ' day(s)</strong>'
                     + '</div>';
            }

            if(s.last_order_days >= 0){
                var lastLabel = s.last_order_days === 0 ? "Today"
                              : s.last_order_days === 1 ? "Yesterday"
                              : s.last_order_days + " day(s) ago";
                html += '<div class="mt-3 p-3 bg-secondary bg-opacity-10 rounded">'
                     + '<small class="text-muted">Last Order: </small>'
                     + '<strong>' + lastLabel + '</strong>'
                     + '</div>';
            }
        }

        $("#statsBody").html(html);
    }

    /* ── Render notification history ── */
    function renderHistory(history){
        if(!history || history.length === 0){
            $("#historyBody").html(
                '<div class="text-center text-muted py-4 px-3">'
                + '<i class="bi bi-bell-slash fs-3 d-block mb-2"></i>'
                + '<small>No smart notifications yet. They will appear here once sent.</small>'
                + '</div>'
            );
            return;
        }

        var html = '<ul class="list-group list-group-flush">';
        $.each(history, function(i, n){
            var meta    = typeIconMap[n.type] || { icon:"bi-bell", color:"secondary" };
            var readCls = n.is_read ? "text-muted" : "fw-semibold";
            var dot     = !n.is_read
                ? '<span class="badge bg-danger rounded-pill ms-1" style="font-size:7px;">NEW</span>'
                : "";

            html += '<li class="list-group-item px-3 py-2">'
                 + '<div class="d-flex align-items-start gap-2">'
                 + '<i class="bi ' + meta.icon + ' text-' + meta.color + ' mt-1 flex-shrink-0"></i>'
                 + '<div class="flex-grow-1">'
                 + '<div class="' + readCls + ' small">' + $('<div>').text(n.title).html() + dot + '</div>'
                 + '<div class="text-muted" style="font-size:11px;">' + n.created_at + '</div>'
                 + '</div></div></li>';
        });
        html += '</ul>';
        $("#historyBody").html(html);
    }

    /* ── Visual style when toggle is on/off ── */
    function updateCardStyle(togId, isOn){
        var cardMap = {
            tog_reorder  : "card_reorder",
            tog_offers   : "card_offers",
            tog_reco     : "card_reco",
            tog_seasonal : "card_seasonal",
            tog_cart     : "card_cart"
        };
        var cardId = cardMap[togId];
        if(cardId){
            if(isOn){
                $("#" + cardId).addClass("is-enabled");
            } else {
                $("#" + cardId).removeClass("is-enabled");
            }
        }
    }

    /* ── Toggle change — update card border instantly ── */
    $(document).on("change", ".pref-toggle", function(){
        updateCardStyle($(this).attr("id"), $(this).is(":checked"));
    });

    /* ── Save preferences ── */
    $("#savePrefBtn").on("click", function(){
        var btn = $(this);
        btn.prop("disabled", true)
           .html('<span class="spinner-border spinner-border-sm me-2"></span>Saving...');
        $("#savingIndicator").removeClass("d-none");

        var data = {};
        $(".pref-toggle").each(function(){
            if($(this).is(":checked")){
                data[$(this).data("key")] = "1";
            }
        });

        $.ajax({
            url      : CTRL + "?method=savePreferences",
            type     : "POST",
            data     : data,
            dataType : "json",
            success  : function(res){
                btn.prop("disabled", false)
                   .html('<i class="bi bi-check-circle-fill me-2"></i>Save Notification Preferences');
                $("#savingIndicator").addClass("d-none");
                showMsg(res.success, res.message);
            },
            error: function(){
                btn.prop("disabled", false)
                   .html('<i class="bi bi-check-circle-fill me-2"></i>Save Notification Preferences');
                $("#savingIndicator").addClass("d-none");
                showMsg(false, "Network error. Please try again.");
            }
        });
    });

    /* ── Show message alert ── */
    function showMsg(success, msg){
        var cls = success ? "success" : "danger";
        var icon = success ? "bi-check-circle-fill" : "bi-exclamation-triangle-fill";
        $("#prefMsg").html(
            '<div class="alert alert-' + cls + ' d-flex align-items-center gap-2 alert-dismissible">'
            + '<i class="bi ' + icon + '"></i>'
            + '<span>' + $('<div>').text(msg).html() + '</span>'
            + '<button type="button" class="btn-close" data-bs-dismiss="alert"></button>'
            + '</div>'
        );
        $("html,body").animate({ scrollTop: $("#prefMsg").offset().top - 20 }, 300);
        if(success) setTimeout(function(){ $("#prefMsg .alert").alert("close"); }, 3000);
    }

    /* ── Boot ── */
    loadPreferences();

})();
</script>