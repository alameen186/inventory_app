<cfif NOT structKeyExists(session,"user_id") OR session.role_name NEQ "vendor">
    <cflocation url="../index.cfm?page=auth" addtoken="false">
</cfif>

<cfset CTRL = "../../controllers/VehicleController.cfc">

<div class="container-fluid mt-4">

    <!--- Page Header --->
    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h3 class="mb-0 fw-bold">
                <i class="bi bi-truck me-2 text-primary"></i>My Vehicles
            </h3>
            <small class="text-muted">Manage your delivery fleet</small>
        </div>
        <button class="btn btn-primary" id="showAddVehicleBtn">
            <i class="bi bi-plus-circle me-1"></i> Add Vehicle
        </button>
    </div>

    <!--- Alert Area --->
    <div id="vehicleMsg"></div>

    <!--- Add / Edit Form Card --->
    <div id="vehicleFormCard" class="card mb-4 border-primary shadow-sm" style="display:none;">
        <div class="card-header bg-primary text-white d-flex justify-content-between align-items-center">
            <span id="vehicleFormTitle">
                <i class="bi bi-plus-circle me-2"></i>Add New Vehicle
            </span>
            <button type="button" class="btn-close btn-close-white" id="closeVehicleForm"></button>
        </div>
        <div class="card-body">
            <div class="row g-3">
                <input type="hidden" id="vehicleId" value="0">

                <div class="col-12 col-md-4">
                    <label class="form-label fw-semibold">Vehicle Name <span class="text-danger">*</span></label>
                    <input type="text" id="vehicleName" class="form-control"
                           placeholder="e.g. Main Delivery Truck">
                    <div class="form-text">A friendly name to identify this vehicle</div>
                </div>

                <div class="col-12 col-md-4">
                    <label class="form-label fw-semibold">Registration Number <span class="text-danger">*</span></label>
                    <input type="text" id="vehicleNumber" class="form-control"
                           placeholder="e.g. KL 01 AB 1234" style="text-transform:uppercase;">
                    <div class="form-text">Vehicle plate / registration number</div>
                </div>

                <div class="col-12 col-md-4">
                    <label class="form-label fw-semibold">Vehicle Type <span class="text-danger">*</span></label>
                    <select id="vehicleType" class="form-select">
                        <option value="">-- Select Type --</option>
                        <option value="truck">🚛 Truck</option>
                        <option value="van">🚐 Van</option>
                        <option value="bike">🏍️ Bike</option>
                        <option value="other">🚗 Other</option>
                    </select>
                </div>

                <div class="col-12 d-flex gap-2 justify-content-end">
                    <button class="btn btn-secondary" id="cancelVehicleForm">Cancel</button>
                    <button class="btn btn-success" id="saveVehicleBtn">
                        <i class="bi bi-check-circle me-1"></i>
                        <span id="saveVehicleBtnText">Save Vehicle</span>
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!--- Vehicles Table --->
    <div class="card shadow-sm">
        <div class="card-header bg-dark text-white">
            <i class="bi bi-list-ul me-2"></i>Fleet List
        </div>
        <div class="table-responsive">
            <table class="table table-hover mb-0 align-middle">
                <thead class="table-dark">
                    <tr>
                        <th>Vehicle Name</th>
                        <th>Registration</th>
                        <th>Type</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody id="vehicleTableBody">
                    <tr>
                        <td colspan="5" class="text-center py-4">
                            <div class="spinner-border spinner-border-sm text-primary me-2"></div>
                            Loading vehicles...
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

    /* ── Helper: show message ── */
    function showMsg(success, text){
        var cls  = success ? "success" : "danger";
        var icon = success
            ? '<i class="bi bi-check-circle-fill me-2"></i>'
            : '<i class="bi bi-exclamation-triangle-fill me-2"></i>';
        $("#vehicleMsg").html(
            '<div class="alert alert-' + cls + ' alert-dismissible fade show">'
          + icon + text
          + '<button type="button" class="btn-close" data-bs-dismiss="alert"></button>'
          + '</div>'
        );
        if(success){
            setTimeout(function(){ $("#vehicleMsg .alert").alert("close"); }, 3000);
        }
        $("html,body").animate({ scrollTop: $("#vehicleMsg").offset().top - 20 }, 200);
    }

    /* ── Helper: validate form ── */
    function validateVehicleForm(){
        var errors = [];
        var name   = $("#vehicleName").val().trim();
        var num    = $("#vehicleNumber").val().trim();
        var type   = $("#vehicleType").val();

        if(!name)              errors.push("Vehicle name is required");
        else if(name.length < 2) errors.push("Vehicle name must be at least 2 characters");
        else if(name.length > 100) errors.push("Vehicle name cannot exceed 100 characters");

        if(!num)               errors.push("Registration number is required");
        else if(num.length < 3) errors.push("Registration number seems too short");
        else if(num.length > 50) errors.push("Registration number cannot exceed 50 characters");

        if(!type)              errors.push("Please select a vehicle type");

        return errors;
    }

    /* ── Load vehicles table ── */
    function loadVehicles(){
        $("#vehicleTableBody").html(
            '<tr><td colspan="5" class="text-center py-4">'
          + '<div class="spinner-border spinner-border-sm text-primary me-2"></div>Loading...</td></tr>'
        );
        $.get(CTRL, { method: "getAll" }, function(res){
            if(res.success){
                $("#vehicleTableBody").html(res.data.html);
            } else {
                $("#vehicleTableBody").html(
                    '<tr><td colspan="5" class="text-center text-danger py-3">'
                  + (res.message || "Failed to load") + '</td></tr>'
                );
            }
        }, "json").fail(function(){
            $("#vehicleTableBody").html(
                '<tr><td colspan="5" class="text-center text-danger py-3">Server error</td></tr>'
            );
        });
    }

    /* ── Show add form ── */
    $("#showAddVehicleBtn").on("click", function(){
        $("#vehicleId").val("0");
        $("#vehicleName").val("");
        $("#vehicleNumber").val("");
        $("#vehicleType").val("");
        $("#vehicleFormTitle").html('<i class="bi bi-plus-circle me-2"></i>Add New Vehicle');
        $("#saveVehicleBtnText").text("Save Vehicle");
        $("#vehicleFormCard").slideDown(200);
        $("#vehicleName").focus();
    });

    /* ── Close form ── */
    $("#closeVehicleForm, #cancelVehicleForm").on("click", function(){
        $("#vehicleFormCard").slideUp(200);
    });

    /* ── Save vehicle (add or edit) ── */
    $("#saveVehicleBtn").on("click", function(){
        var errors = validateVehicleForm();
        if(errors.length){
            showMsg(false, errors.join("<br>"));
            return;
        }

        var btn = $(this);
        btn.prop("disabled", true).html(
            '<span class="spinner-border spinner-border-sm me-1"></span>Saving...'
        );

        $.post(CTRL + "?method=save", {
            id             : $("#vehicleId").val(),
            vehicle_name   : $("#vehicleName").val().trim(),
            vehicle_number : $("#vehicleNumber").val().trim().toUpperCase(),
            vehicle_type   : $("#vehicleType").val()
        }, function(res){
            btn.prop("disabled", false).html(
                '<i class="bi bi-check-circle me-1"></i><span id="saveVehicleBtnText">Save Vehicle</span>'
            );
            showMsg(res.success, res.message);
            if(res.success){
                $("#vehicleFormCard").slideUp(200);
                loadVehicles();
            }
        }, "json").fail(function(){
            btn.prop("disabled", false).html(
                '<i class="bi bi-check-circle me-1"></i><span id="saveVehicleBtnText">Save Vehicle</span>'
            );
            showMsg(false, "Server error. Please try again.");
        });
    });

    /* ── Edit vehicle (triggered from table row button) ── */
    $(document).on("click", ".editVehicleBtn", function(){
        var btn  = $(this);
        var id   = btn.data("id");
        var name = btn.data("name");
        var num  = btn.data("number");
        var type = btn.data("type");

        $("#vehicleId").val(id);
        $("#vehicleName").val(name);
        $("#vehicleNumber").val(num);
        $("#vehicleType").val(type);
        $("#vehicleFormTitle").html('<i class="bi bi-pencil-square me-2"></i>Edit Vehicle');
        $("#saveVehicleBtnText").text("Update Vehicle");
        $("#vehicleFormCard").slideDown(200);
        $("html,body").animate({ scrollTop: $("#vehicleFormCard").offset().top - 20 }, 200);
        $("#vehicleName").focus();
    });

    /* ── Toggle active status ── */
    $(document).on("click", ".toggleVehicleBtn", function(){
        var btn = $(this);
        var id  = btn.data("id");
        if(!confirm("Change vehicle status?")) return;

        btn.prop("disabled", true);
        $.post(CTRL + "?method=toggle", { id: id }, function(res){
            btn.prop("disabled", false);
            showMsg(res.success, res.message);
            if(res.success) loadVehicles();
        }, "json").fail(function(){
            btn.prop("disabled", false);
            showMsg(false, "Server error.");
        });
    });

    /* ── Auto-uppercase registration input ── */
    $("#vehicleNumber").on("input", function(){
        var pos = this.selectionStart;
        this.value = this.value.toUpperCase();
        this.setSelectionRange(pos, pos);
    });

    /* ── Initial load ── */
    loadVehicles();
});
</script>
