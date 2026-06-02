<cfif NOT structKeyExists(session, "user_id")>
    <cfabort>
</cfif>

<div class="container-fluid mt-3" id="loyaltyPage">

    <!--- HEADER --->
    <div class="d-flex align-items-center gap-3 mb-4">
        <div class="rounded-circle bg-warning bg-opacity-10 d-flex align-items-center
                    justify-content-center" style="width:52px;height:52px;flex-shrink:0;">
            <i class="bi bi-star-fill text-warning fs-4"></i>
        </div>
        <div>
            <h4 class="mb-0 fw-bold">Loyalty Rewards</h4>
            <small class="text-muted">Earn points on every order and redeem for discounts</small>
        </div>
    </div>

    <!--- MESSAGE AREA --->
    <div id="loyaltyMsg"></div>

    <!--- LOADING STATE --->
    <div id="loyaltyLoading" class="text-center py-5">
        <div class="spinner-border text-warning"></div>
        <p class="text-muted mt-2">Loading your points...</p>
    </div>

    <!--- MAIN CONTENT (hidden until loaded) --->
    <div id="loyaltyContent" style="display:none;">

        <div class="row g-4">

            <!--- LEFT — POINTS SUMMARY + REDEEM --->
            <div class="col-12 col-lg-4">

                <!--- Points Balance Card --->
                <div class="card border-0 shadow-sm mb-4"
                     style="background: linear-gradient(135deg, #f6c90e 0%, #f9a825 100%);">
                    <div class="card-body text-center py-4">
                        <i class="bi bi-star-fill text-white fs-1 mb-2 d-block"></i>
                        <div class="text-white fw-bold" style="font-size:3rem;" id="availablePoints">0</div>
                        <div class="text-white opacity-75 mb-1">Available Points</div>
                        <div class="text-white opacity-75 small">
                            Worth <strong>Rs.<span id="worthRupees">0</span></strong>
                        </div>
                    </div>
                </div>

                <!--- Stats Row --->
                <div class="row g-2 mb-4">
                    <div class="col-6">
                        <div class="card border-0 shadow-sm text-center p-3">
                            <div class="fw-bold fs-5 text-success" id="totalEarned">0</div>
                            <small class="text-muted">Total Earned</small>
                        </div>
                    </div>
                    <div class="col-6">
                        <div class="card border-0 shadow-sm text-center p-3">
                            <div class="fw-bold fs-5 text-danger" id="totalRedeemed">0</div>
                            <small class="text-muted">Total Redeemed</small>
                        </div>
                    </div>
                </div>

                <!--- How it works 
                <div class="card border-0 shadow-sm mb-4">
                    <div class="card-header bg-dark text-white fw-semibold rounded-top">
                        <i class="bi bi-info-circle me-2"></i>How It Works
                    </div>
                    <div class="card-body">
                        <div class="d-flex align-items-start gap-2 mb-2">
                            <i class="bi bi-1-circle-fill text-warning mt-1"></i>
                            <small>Earn <strong>1 point</strong> for every <strong>Rs.10</strong> you spend</small>
                        </div>
                        <div class="d-flex align-items-start gap-2 mb-2">
                            <i class="bi bi-2-circle-fill text-warning mt-1"></i>
                            <small>Collect at least <strong>100 points</strong> to redeem</small>
                        </div>
                        <div class="d-flex align-items-start gap-2 mb-2">
                            <i class="bi bi-3-circle-fill text-warning mt-1"></i>
                            <small>Every <strong>10 points = Rs.1</strong> discount coupon</small>
                        </div>
                        <div class="d-flex align-items-start gap-2">
                            <i class="bi bi-4-circle-fill text-warning mt-1"></i>
                            <small>Coupon is valid for <strong>30 days</strong> after generation</small>
                        </div>
                    </div>
                </div>

                <!--- Redeem Button --->
                <div id="redeemSection">
                    <!--- Filled by JS --->
                </div>
--->
            </div>

            <!--- RIGHT — HISTORY TABS --->
            <div class="col-12 col-lg-8">

                <ul class="nav nav-tabs mb-3" id="loyaltyTabs">
                    <li class="nav-item">
                        <a class="nav-link active" href="#" data-tab="earned">
                            <i class="bi bi-plus-circle me-1"></i>Points Earned
                        </a>
                    </li>
                  
                </ul>

                <!--- Earned History --->
                <div id="tab_earned">
                    <div class="card border-0 shadow-sm">
                        <div class="card-body p-0">
                            <table class="table table-hover mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th>Points</th>
                                        <th>Reason</th>
                                        <th>Order</th>
                                        <th>Date</th>
                                    </tr>
                                </thead>
                                <tbody id="earnedTableBody">
                                    <tr><td colspan="4" class="text-center text-muted py-4">No points earned yet.</td></tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                <!--- Redeemed History
                <div id="tab_redeemed" style="display:none;">
                    <div class="card border-0 shadow-sm">
                        <div class="card-body p-0">
                            <table class="table table-hover mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th>Points Used</th>
                                        <th>Coupon Code</th>
                                        <th>Date</th>
                                    </tr>
                                </thead>
                                <tbody id="redeemedTableBody">
                                    <tr><td colspan="3" class="text-center text-muted py-4">No redemptions yet.</td></tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                 --->
            </div>
        </div>
    </div>
</div>

<!--- Coupon Popup Modal --->
<div class="modal fade" id="couponModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered" style="max-width:380px;">
        <div class="modal-content border-0 shadow">
            <div class="modal-body text-center p-4">
                <i class="bi bi-gift-fill text-warning fs-1 mb-3 d-block"></i>
                <h5 class="fw-bold mb-1">Your Coupon is Ready!</h5>
                <p class="text-muted small mb-3">Use this code at checkout to get your discount.</p>

                <div class="bg-warning bg-opacity-10 border border-warning rounded p-3 mb-3">
                    <div class="fw-bold fs-4 text-warning letter-spacing" id="modalCouponCode">-</div>
                    <small class="text-muted">Copy and paste at checkout</small>
                </div>

                <div class="row g-2 text-center mb-3">
                    <div class="col-6">
                        <div class="bg-success bg-opacity-10 rounded p-2">
                            <div class="fw-bold text-success">Rs.<span id="modalDiscount">0</span></div>
                            <small class="text-muted">Discount Value</small>
                        </div>
                    </div>
                    <div class="col-6">
                        <div class="bg-info bg-opacity-10 rounded p-2">
                            <div class="fw-bold text-info"><span id="modalPoints">0</span> pts</div>
                            <small class="text-muted">Points Used</small>
                        </div>
                    </div>
                </div>

                <small class="text-muted d-block mb-3">Valid until: <strong id="modalExpiry">-</strong></small>

                <button class="btn btn-warning w-100 fw-semibold"
                        onclick="copyCode()"
                        id="copyBtn">
                    <i class="bi bi-clipboard me-2"></i>Copy Code
                </button>
                <button class="btn btn-outline-secondary w-100 mt-2"
                        data-bs-dismiss="modal">
                    Close
                </button>
            </div>
        </div>
    </div>
</div>

<script>
(function(){

    var CTRL = "../../controllers/LoyaltyController.cfc";

    /* ── Tab switching ── */
    $(document).on("click", "#loyaltyTabs .nav-link", function(e){
        e.preventDefault();
        $("#loyaltyTabs .nav-link").removeClass("active");
        $(this).addClass("active");
        var tab = $(this).data("tab");
        $("#tab_earned, #tab_redeemed").hide();
        $("#tab_" + tab).show();
    });

    /* ── Load points data ── */
    function loadPoints(){
        $.ajax({
            url      : CTRL + "?method=getPoints",
            type     : "GET",
            dataType : "json",
            success  : function(res){
                $("#loyaltyLoading").hide();
                if(!res.success){
                    showMsg(false, res.message || "Could not load points.");
                    return;
                }

                var d = res.data;

                /* Summary numbers */
                $("#availablePoints").text(d.available);
                $("#worthRupees").text(d.worth_rupees);
                $("#totalEarned").text(d.total_earned);
                $("#totalRedeemed").text(d.total_redeemed);

                /* Redeem section */
                renderRedeemSection(d);

                /* Earned history table */
                if(d.history && d.history.length){
                    var rows = "";
                    $.each(d.history, function(i, h){
                        rows += "<tr>"
                             + "<td><span class='badge bg-success'>+" + h.points + "</span></td>"
                             + "<td>" + $("<div>").text(h.reason).html() + "</td>"
                             + "<td><small class='text-muted'>" + (h.order_id ? h.order_id.substring(0,12) + "..." : "-") + "</small></td>"
                             + "<td><small>" + h.date + "</small></td>"
                             + "</tr>";
                    });
                    $("#earnedTableBody").html(rows);
                }

                /* Redeemed history table */
                if(d.redeem_history && d.redeem_history.length){
                    var rrows = "";
                    $.each(d.redeem_history, function(i, r){
                        rrows += "<tr>"
                              + "<td><span class='badge bg-danger'>-" + r.points_used + "</span></td>"
                              + "<td><code class='text-warning fw-bold'>" + r.coupon_code + "</code></td>"
                              + "<td><small>" + r.date + "</small></td>"
                              + "</tr>";
                    });
                    $("#redeemedTableBody").html(rrows);
                }

                $("#loyaltyContent").show();
            },
            error: function(){
                $("#loyaltyLoading").hide();
                showMsg(false, "Network error loading points.");
            }
        });
    }

    /* ── Render redeem button or progress bar ── */
    function renderRedeemSection(d){
        var html = "";

        if(d.can_redeem){
            var maxRedeem  = Math.min(d.available, 500);
            var maxDiscount = Math.floor(maxRedeem / d.points_per_rupee);

            html = '<div class="card border-0 shadow-sm border-warning" style="border:2px solid #f6c90e !important;">'
                 + '<div class="card-body text-center">'
                 + '<i class="bi bi-gift-fill text-warning fs-3 mb-2 d-block"></i>'
                 + '<h6 class="fw-bold mb-1">Ready to Redeem!</h6>'
                 + '<p class="text-muted small mb-3">Use up to ' + maxRedeem + ' points for a <strong>Rs.' + maxDiscount + '</strong> coupon</p>'
                 + '<button class="btn btn-warning w-100 fw-semibold" id="redeemBtn" onclick="redeemPoints()">'
                 + '<i class="bi bi-gift me-2"></i>Generate Coupon'
                 + '</button>'
                 + '</div></div>';
        } else {
            var pct      = Math.min(Math.round((d.available / d.threshold) * 100), 100);
            var needed   = d.threshold - d.available;

            html = '<div class="card border-0 shadow-sm">'
                 + '<div class="card-body">'
                 + '<h6 class="fw-bold mb-1 text-muted">Progress to Redemption</h6>'
                 + '<div class="progress mb-2" style="height:12px;">'
                 + '<div class="progress-bar bg-warning" style="width:' + pct + '%"></div>'
                 + '</div>'
                 + '<div class="d-flex justify-content-between">'
                 + '<small class="text-muted">' + d.available + ' points</small>'
                 + '<small class="text-muted">' + d.threshold + ' needed</small>'
                 + '</div>'
                 + '<div class="alert alert-warning mt-3 mb-0 py-2 small text-center">'
                 + '<i class="bi bi-info-circle me-1"></i>Earn <strong>' + needed + ' more points</strong> to redeem!'
                 + '</div>'
                 + '</div></div>';
        }

        $("#redeemSection").html(html);
    }

    /* ── Redeem points ── */
    window.redeemPoints = function(){
        var btn = $("#redeemBtn");
        btn.prop("disabled", true).html('<span class="spinner-border spinner-border-sm me-2"></span>Generating...');

        $.ajax({
            url      : CTRL + "?method=redeem",
            type     : "POST",
            dataType : "json",
            success  : function(res){
                btn.prop("disabled", false).html('<i class="bi bi-gift me-2"></i>Generate Coupon');
                if(!res.success){
                    showMsg(false, res.message);
                    return;
                }
                /* Show coupon popup */
                var d = res.data;
                $("#modalCouponCode").text(d.coupon_code);
                $("#modalDiscount").text(d.discount_amt);
                $("#modalPoints").text(d.points_used);
                $("#modalExpiry").text(d.valid_until);
                new bootstrap.Modal(document.getElementById("couponModal")).show();
                /* Reload points after redeem */
                setTimeout(loadPoints, 500);
            },
            error: function(){
                btn.prop("disabled", false).html('<i class="bi bi-gift me-2"></i>Generate Coupon');
                showMsg(false, "Network error. Please try again.");
            }
        });
    };

    /* ── Copy coupon code ── */
    window.copyCode = function(){
        var code = $("#modalCouponCode").text();
        navigator.clipboard.writeText(code).then(function(){
            $("#copyBtn").html('<i class="bi bi-check-circle me-2"></i>Copied!').addClass("btn-success").removeClass("btn-warning");
            setTimeout(function(){
                $("#copyBtn").html('<i class="bi bi-clipboard me-2"></i>Copy Code').removeClass("btn-success").addClass("btn-warning");
            }, 2000);
        });
    };

    /* ── Show message ── */
    function showMsg(success, msg){
        var cls  = success ? "success" : "danger";
        var icon = success ? "bi-check-circle-fill" : "bi-exclamation-triangle-fill";
        $("#loyaltyMsg").html(
            '<div class="alert alert-' + cls + ' d-flex align-items-center gap-2 alert-dismissible">'
            + '<i class="bi ' + icon + '"></i><span>' + msg + '</span>'
            + '<button type="button" class="btn-close" data-bs-dismiss="alert"></button>'
            + '</div>'
        );
    }

    /* ── Boot ── */
    loadPoints();

})();
</script>
