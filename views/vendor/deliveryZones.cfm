<cfif NOT structKeyExists(session,"user_id") OR session.role_name NEQ "vendor">
    <cflocation url="../index.cfm?page=auth" addtoken="false">
</cfif>

<cfset CTRL = "../../controllers/DeliveryZoneController.cfc">

<div class="container-fluid mt-4">

    <!--- Page Header --->
    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h3 class="mb-0 fw-bold">
                <i class="bi bi-geo-alt me-2 text-danger"></i>Delivery Zones
            </h3>
            <small class="text-muted">Set your delivery places, distances and per-km pricing</small>
        </div>
        <button class="btn btn-danger" id="showAddZoneBtn">
            <i class="bi bi-plus-circle me-1"></i> Add Zone
        </button>
    </div>

    <div id="zoneMsg"></div>

    <!--- Km-price info  --->
    <div class="alert alert-info d-flex align-items-start gap-2 py-2 mb-4">
        <i class="bi bi-info-circle-fill text-info mt-1 flex-shrink-0"></i>
        <div class="small">
            <strong>How it works:</strong> Set a <em>price per km</em> (e.g. &#8377;2/km) for each place.
            The delivery fee is calculated automatically as <strong>Distance &times; Price/km</strong>.
            You can set a different km-price for each zone, or keep them the same.
            These zones appear in the <em>Create Wholesale Order</em> dropdown.
        </div>
    </div>

    <!--- Add / Edit Form Card --->
    <div id="zoneFormCard" class="card mb-4 border-danger shadow-sm" style="display:none;">
        <div class="card-header bg-danger text-white d-flex justify-content-between align-items-center">
            <span id="zoneFormTitle">
                <i class="bi bi-plus-circle me-2"></i>Add Delivery Zone
            </span>
            <button type="button" class="btn-close btn-close-white" id="closeZoneForm"></button>
        </div>
        <div class="card-body">
            <div class="row g-3 align-items-end">
                <input type="hidden" id="zoneId" value="0">

                <!--- Place Name --->
                <div class="col-12 col-md-3">
                    <label class="form-label fw-semibold">
                        Place Name <span class="text-danger">*</span>
                    </label>
                    <input type="text" id="zonePlaceName" class="form-control"
                           placeholder="e.g. Kochi, Kozhikode...">
                    <div class="form-text">City or area name</div>
                </div>

                <!--- Distance --->
                <div class="col-12 col-md-3">
                    <label class="form-label fw-semibold">
                        Distance (km) <span class="text-danger">*</span>
                    </label>
                    <div class="input-group">
                        <input type="number" id="zoneKm" class="form-control"
                               placeholder="e.g. 200" min="1" max="9999" step="0.1">
                        <span class="input-group-text">km</span>
                    </div>
                    <div class="form-text">Distance from your location</div>
                </div>

                <!--- Price per km --->
                <div class="col-12 col-md-3">
                    <label class="form-label fw-semibold">
                        Price per km <span class="text-danger">*</span>
                    </label>
                    <div class="input-group">
                        <span class="input-group-text">&#8377;</span>
                        <input type="number" id="zoneKmPrice" class="form-control"
                               placeholder="e.g. 2" min="0.01" max="9999" step="0.01">
                        <span class="input-group-text">/ km</span>
                    </div>
                    <div class="form-text">Cost charged per kilometre</div>
                </div>

                <!--- Computed Fee Preview --->
                <div class="col-12 col-md-3">
                    <label class="form-label fw-semibold text-success">
                        <i class="bi bi-calculator me-1"></i>Delivery Fee (auto)
                    </label>
                    <div class="input-group">
                        <span class="input-group-text bg-success text-white">&#8377;</span>
                        <input type="text" id="zoneFeePreview" class="form-control fw-bold text-success"
                               value="0.00" readonly>
                    </div>
                    <div class="form-text text-success">Distance &times; Price/km</div>
                </div>

                <div class="col-12 d-flex gap-2 justify-content-end">
                    <button class="btn btn-secondary" id="cancelZoneForm">Cancel</button>
                    <button class="btn btn-success" id="saveZoneBtn">
                        <i class="bi bi-check-circle me-1"></i>
                        <span id="saveZoneBtnText">Save Zone</span>
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!--- Zones Table --->
    <div class="card shadow-sm">
        <div class="card-header bg-dark text-white">
            <i class="bi bi-list-ul me-2"></i>Your Delivery Zones
        </div>
        <div class="table-responsive">
            <table class="table table-hover mb-0 align-middle">
                <thead class="table-dark">
                    <tr>
                        <th>Place</th>
                        <th class="text-center">Distance</th>
                        <th class="text-center">Price / km</th>
                        <th class="text-center">Delivery Fee</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody id="zoneTableBody">
                    <tr>
                        <td colspan="6" class="text-center py-4">
                            <div class="spinner-border spinner-border-sm text-danger me-2"></div>
                            Loading zones...
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>

</div>

<script>
$(function(){
    var CTRL = "<cfoutput>#CTRL#</cfoutput>";

    /* ── Show message ── */
    function showMsg(success, text){
        var cls  = success ? "success" : "danger";
        var icon = success
            ? '<i class="bi bi-check-circle-fill me-2"></i>'
            : '<i class="bi bi-exclamation-triangle-fill me-2"></i>';
        $("#zoneMsg").html(
            '<div class="alert alert-' + cls + ' alert-dismissible fade show">'
          + icon + text
          + '<button type="button" class="btn-close" data-bs-dismiss="alert"></button>'
          + '</div>'
        );
        if(success){
            setTimeout(function(){ $("#zoneMsg .alert").alert("close"); }, 3000);
        }
        $("html,body").animate({ scrollTop: $("#zoneMsg").offset().top - 20 }, 200);
    }

    /* ── Live fee preview ── */
    function updateFeePreview(){
        var km    = parseFloat($("#zoneKm").val())       || 0;
        var price = parseFloat($("#zoneKmPrice").val())  || 0;
        var fee   = (km > 0 && price > 0) ? (km * price).toFixed(2) : "0.00";
        $("#zoneFeePreview").val(fee);
    }
    $("#zoneKm, #zoneKmPrice").on("input", updateFeePreview);

    /* ── Validate form ── */
    function validateForm(){
        var errors = [];
        var name   = $("#zonePlaceName").val().trim();
        var km     = parseFloat($("#zoneKm").val());
        var price  = parseFloat($("#zoneKmPrice").val());

        if(!name)               errors.push("Place name is required");
        else if(name.length < 2) errors.push("Place name must be at least 2 characters");
        else if(name.length > 100) errors.push("Place name cannot exceed 100 characters");

        if(isNaN(km) || km <= 0)    errors.push("Distance must be a positive number");
        else if(km > 9999)           errors.push("Distance seems too large (max 9999 km)");

        if(isNaN(price) || price <= 0) errors.push("Price per km must be a positive number");
        else if(price > 9999)           errors.push("Price per km seems too large");

        return errors;
    }

    /* ── Load zones table ── */
    function loadZones(){
        $("#zoneTableBody").html(
            '<tr><td colspan="6" class="text-center py-4">'
          + '<div class="spinner-border spinner-border-sm text-danger me-2"></div>Loading...</td></tr>'
        );
        $.get(CTRL, { method: "getAll" }, function(res){
            if(res.success){
                $("#zoneTableBody").html(res.data.html);
            } else {
                $("#zoneTableBody").html(
                    '<tr><td colspan="6" class="text-center text-danger py-3">'
                  + (res.message || "Failed to load") + '</td></tr>'
                );
            }
        }, "json").fail(function(){
            $("#zoneTableBody").html(
                '<tr><td colspan="6" class="text-center text-danger py-3">Server error</td></tr>'
            );
        });
    }

    /* ── Show add form ── */
    $("#showAddZoneBtn").on("click", function(){
        $("#zoneId").val("0");
        $("#zonePlaceName").val("");
        $("#zoneKm").val("");
        $("#zoneKmPrice").val("");
        $("#zoneFeePreview").val("0.00");
        $("#zoneFormTitle").html('<i class="bi bi-plus-circle me-2"></i>Add Delivery Zone');
        $("#saveZoneBtnText").text("Save Zone");
        $("#zoneFormCard").slideDown(200);
        $("#zonePlaceName").focus();
    });

    /* ── Close form ── */
    $("#closeZoneForm, #cancelZoneForm").on("click", function(){
        $("#zoneFormCard").slideUp(200);
    });

    /* ── Save zone ── */
    $("#saveZoneBtn").on("click", function(){
        var errors = validateForm();
        if(errors.length){ showMsg(false, errors.join("<br>")); return; }

        var btn = $(this);
        btn.prop("disabled", true).html('<span class="spinner-border spinner-border-sm me-1"></span>Saving...');

        $.post(CTRL + "?method=save", {
            id          : $("#zoneId").val(),
            place_name  : $("#zonePlaceName").val().trim(),
            distance_km : $("#zoneKm").val(),
            km_price    : $("#zoneKmPrice").val()
        }, function(res){
            btn.prop("disabled", false).html('<i class="bi bi-check-circle me-1"></i><span id="saveZoneBtnText">Save Zone</span>');
            showMsg(res.success, res.message);
            if(res.success){
                $("#zoneFormCard").slideUp(200);
                loadZones();
            }
        }, "json").fail(function(){
            btn.prop("disabled", false).html('<i class="bi bi-check-circle me-1"></i><span id="saveZoneBtnText">Save Zone</span>');
            showMsg(false, "Server error. Please try again.");
        });
    });

    /* ── Edit zone ── */
    $(document).on("click", ".editZoneBtn", function(){
        var btn = $(this);
        $("#zoneId").val(btn.data("id"));
        $("#zonePlaceName").val(btn.data("place"));
        $("#zoneKm").val(btn.data("km"));
        $("#zoneKmPrice").val(btn.data("kmprice"));
        updateFeePreview();
        $("#zoneFormTitle").html('<i class="bi bi-pencil-square me-2"></i>Edit Delivery Zone');
        $("#saveZoneBtnText").text("Update Zone");
        $("#zoneFormCard").slideDown(200);
        $("html,body").animate({ scrollTop: $("#zoneFormCard").offset().top - 20 }, 200);
        $("#zonePlaceName").focus();
    });

    /* ── Toggle status ── */
    $(document).on("click", ".toggleZoneBtn", function(){
        var btn = $(this);
        var id  = btn.data("id");
        if(!confirm("Change zone status?")) return;
        btn.prop("disabled", true);
        $.post(CTRL + "?method=toggle", { id: id }, function(res){
            btn.prop("disabled", false);
            showMsg(res.success, res.message);
            if(res.success) loadZones();
        }, "json").fail(function(){
            btn.prop("disabled", false);
            showMsg(false, "Server error.");
        });
    });

    /* ── Delete zone ── */
    $(document).on("click", ".deleteZoneBtn", function(){
        var btn   = $(this);
        var id    = btn.data("id");
        var place = btn.data("place");
        if(!confirm('Delete zone "' + place + '"? This cannot be undone.')) return;
        btn.prop("disabled", true);
        $.post(CTRL + "?method=delete", { id: id }, function(res){
            btn.prop("disabled", false);
            showMsg(res.success, res.message);
            if(res.success) loadZones();
        }, "json").fail(function(){
            btn.prop("disabled", false);
            showMsg(false, "Server error.");
        });
    });

    /* ── Initial load ── */
    loadZones();
});
</script>
