<cfif NOT structKeyExists(session,"is_staff") OR NOT session.is_staff>
    <cflocation url="../index.cfm?page=auth" addtoken="false">
</cfif>

<cfset CTRL = "../controllers/staff/LeaveController.cfc">
<cfset leaveTypes = createObject("component","models.Leave").getTypes()>

<!DOCTYPE html>
<html>
<head>
    <title>Staff Portal</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
</head>
<body class="bg-light">

<nav class="navbar navbar-dark bg-dark px-4">
    <span class="navbar-brand fw-bold">
        <i class="bi bi-person-badge me-2"></i>Staff Portal
    </span>
    <div class="d-flex align-items-center gap-3">
        <span class="text-white small">
            <cfoutput>Welcome, #encodeForHTML(session.staff_name)#</cfoutput>
        </span>
        <a href="../controllers/StaffAuthController.cfc?method=logout" class="btn btn-danger btn-sm">Logout</a>
    </div>
</nav>

<div class="container mt-4">
    <div class="row g-4">
<!--- Staff Leave Balance --->
<div class="col-12">
    <div class="card shadow-sm mb-2">
        <div class="card-header bg-dark text-white fw-semibold">
            <i class="bi bi-bar-chart-fill me-2"></i>My Leave Balance
        </div>
        <div class="card-body">
            <div class="row g-3" id="staffBalanceWrap">
                <div class="col-12 text-center text-muted py-2">
                    <div class="spinner-border spinner-border-sm"></div> Loading...
                </div>
            </div>
        </div>
    </div>
</div>
        <!--- Apply Leave --->
        <div class="col-lg-4">
            <div class="card shadow-sm">
                <div class="card-header bg-dark text-white fw-semibold">Apply for Leave</div>
                <div class="card-body">

                    <div class="mb-3">
                        <label class="form-label fw-semibold">Leave Type <span class="text-danger">*</span></label>
                        <select class="form-select" id="leaveType">
                            <option value="">-- Select Type --</option>
                            <cfoutput query="leaveTypes">
                                <option value="#id#">#encodeForHTML(type_name)# (max #max_days# days/yr)</option>
                            </cfoutput>
                        </select>
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-6">
                            <label class="form-label fw-semibold">From <span class="text-danger">*</span></label>
                            <input type="date" class="form-control" id="leaveFrom">
                        </div>
                        <div class="col-6">
                            <label class="form-label fw-semibold">To <span class="text-danger">*</span></label>
                            <input type="date" class="form-control" id="leaveTo">
                        </div>
                    </div>

                    <div class="mb-3">
                        <label class="form-label fw-semibold">Total Days</label>
                        <input type="number" class="form-control bg-light" id="totalDays" readonly>
                        <small class="text-muted">Auto calculated</small>
                    </div>

                    <div class="mb-3">
                        <label class="form-label fw-semibold">Reason</label>
                        <textarea class="form-control" id="leaveReason" rows="3" placeholder="Optional"></textarea>
                    </div>

                    <button class="btn btn-primary w-100" id="applyBtn">Apply Leave</button>

                </div>
            </div>
        </div>

        <!--- Leave History --->
        <div class="col-lg-8">
            <div class="card shadow-sm">
                <div class="card-header bg-dark text-white fw-semibold"><i class="bi bi-clock-history"></i> My Leave History</div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-hover mb-0" style="font-size:13px;">
                            <thead class="table-dark">
                                <tr>
                                    <th>Type</th>
                                    <th>From</th>
                                    <th>To</th>
                                    <th class="text-center">Days</th>
                                    <th>Reason</th>
                                    <th class="text-center">Status</th>
                                </tr>
                            </thead>
                            <tbody id="myLeaveBody">
                                <tr><td colspan="6" class="text-center py-3">
                                    <div class="spinner-border spinner-border-sm"></div> Loading...
                                </td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>

    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
(function(){
    var CTRL = "../controllers/staff/LeaveController.cfc";

    // Auto calc days
    $('#leaveFrom, #leaveTo').on('change', function(){
        var f = $('#leaveFrom').val(), t = $('#leaveTo').val();
        if(f && t && t >= f){
            $('#totalDays').val(Math.round((new Date(t)-new Date(f))/(864e5))+1);
        } else {
            $('#totalDays').val('');
        }
    });

    // Load my leaves
    function loadMyLeaves(){
        $.ajax({
            url: CTRL + "?method=getMyLeaves",
            type: "GET", dataType: "json",
            success: function(res){
                if(res.success) $('#myLeaveBody').html(res.data.html);
                else $('#myLeaveBody').html('<tr><td colspan="6" class="text-danger text-center">'+res.message+'</td></tr>');
            }
        });
    }
    loadMyLeaves();

    // Apply leave
    $('#applyBtn').on('click', function(){
        var typeId = $('#leaveType').val();
        var from   = $('#leaveFrom').val();
        var to     = $('#leaveTo').val();
        var days   = $('#totalDays').val();

        if(!typeId){ alert('Please select a leave type'); return; }
        if(!from){ alert('Please select from date'); return; }
        if(!to){ alert('Please select to date'); return; }
        if(to < from){ alert('To date cannot be before from date'); return; }

        $.ajax({
            url: CTRL + "?method=applyByStaff",
            type: "POST", dataType: "json",
            data: {
                leave_type_id : typeId,
                from_date     : from,
                to_date       : to,
                total_days    : days,
                reason        : $('#leaveReason').val()
            },
            success: function(res){
                if(res.success){
                    alert(res.message);
                    $('#leaveType, #leaveFrom, #leaveTo, #leaveReason').val('');
                    $('#totalDays').val('');
                    loadMyLeaves();
                } else {
                    alert('Error: ' + res.message);
                }
            }
        });
    });


    // Load staff's own leave balance
function loadMyBalance(){
    $.ajax({
        url: CTRL + "?method=getMyBalance",
        type: "GET", dataType: "json",
        success: function(res){
            if(res.success) $('#staffBalanceWrap').html(res.data.html);
            else $('#staffBalanceWrap').html('<p class="text-muted mb-0">Balance unavailable.</p>');
        }
    });
}
loadMyBalance();

// Also refresh balance after applying leave
// In the applyBtn success callback, add:
loadMyBalance();

})();
</script>
</body>
</html>