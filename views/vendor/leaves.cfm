<cfif NOT structKeyExists(session,"user_id") OR session.role_name NEQ "vendor">
    <cfabort>
</cfif>

<!--- Load active staff and leave types for dropdowns --->
<cfset activeStaff  = createObject("component","models.Staff").getActiveStaff(session.user_id)>
<cfset leaveTypes   = createObject("component","models.Leave").getTypes()>

<cfset CTRL = "../../controllers/LeaveController.cfc">

<div class="container-fluid mt-3">

    <h4 class="mb-4">Leave Management</h4>

    <div class="row g-4">

        <!--- LEFT: Apply Leave form --->
        <div class="col-lg-4">
            <div class="card shadow-sm">
                <div class="card-header bg-dark text-white fw-semibold">Apply Leave</div>
                <div class="card-body">

                    <div class="mb-3">
                        <label class="form-label fw-semibold">Staff Member <span class="text-danger">*</span></label>
                        <select class="form-select" id="leaveStaff">
                            <option value="">-- Select Staff --</option>
                            <cfoutput query="activeStaff">
                                <option value="#id#">#encodeForHTML(full_name)#
                                    #len(position) ? '(' & position & ')' : ''#
                                </option>
                            </cfoutput>
                        </select>
                    </div>

                    <!--- Balance cards  --->
                    <div id="balanceWrap" class="row g-2 mb-3" style="display:none;"></div>

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
                            <label class="form-label fw-semibold">From Date <span class="text-danger">*</span></label>
                            <input type="date" class="form-control" id="leaveFrom">
                        </div>
                        <div class="col-6">
                            <label class="form-label fw-semibold">To Date <span class="text-danger">*</span></label>
                            <input type="date" class="form-control" id="leaveTo">
                        </div>
                    </div>

                    <div class="mb-3">
                        <label class="form-label fw-semibold">Total Days</label>
                        <input type="number" class="form-control bg-light" id="totalDays"
                               name="total_days" readonly>
                        <small class="text-muted">Auto calculated from dates</small>
                    </div>

                    <div class="mb-3">
                        <label class="form-label fw-semibold">Reason</label>
                        <textarea class="form-control" id="leaveReason" rows="3"
                                  placeholder="Optional reason for leave"></textarea>
                    </div>

                    <button type="button" class="btn btn-primary w-100" id="applyLeaveBtn">
                        Apply Leave
                    </button>

                </div>
            </div>
        </div>

        <!---  Leave history + filters --->
        <div class="col-lg-8">

            <!--- Filters --->
            <div class="card shadow-sm mb-3">
                <div class="card-body">
                    <div class="row g-2 align-items-end">
                        <div class="col-md-3">
                            <label class="form-label fw-semibold">Staff</label>
                            <select class="form-select form-select-sm" id="filterStaff">
                                <option value="">All Staff</option>
                                <cfoutput query="activeStaff">
                                    <option value="#id#">#encodeForHTML(full_name)#</option>
                                </cfoutput>
                            </select>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label fw-semibold">Status</label>
                            <select class="form-select form-select-sm" id="filterStatus">
                                <option value="">All Status</option>
                                <option value="pending">Pending</option>
                                <option value="approved">Approved</option>
                                <option value="rejected">Rejected</option>
                            </select>
                        </div>
                        <div class="col-md-2">
                            <label class="form-label fw-semibold">From</label>
                            <input type="date" class="form-control form-control-sm" id="filterFrom">
                        </div>
                        <div class="col-md-2">
                            <label class="form-label fw-semibold">To</label>
                            <input type="date" class="form-control form-control-sm" id="filterTo">
                        </div>
                        <div class="col-md-2">
                            <button class="btn btn-primary btn-sm w-100" id="filterBtn">Filter</button>
                        </div>
                    </div>
                </div>
            </div>

            <!--- Leave table --->
            <div class="card shadow-sm">
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-hover mb-0" style="font-size:13px;">
                            <thead class="table-dark">
                                <tr>
                                    <th>Staff</th>
                                    <th>Type</th>
                                    <th>From</th>
                                    <th>To</th>
                                    <th class="text-center">Days</th>
                                    <th>Reason</th>
                                    <th class="text-center">Status</th>
                                    <th class="text-center">Action</th>
                                </tr>
                            </thead>
                            <tbody id="leaveTableBody">
                                <tr>
                                    <td colspan="8" class="text-center py-4">
                                        <div class="spinner-border spinner-border-sm"></div> Loading...
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

        </div>
    </div>
</div>

<!--- Reject Reason Modal --->
<div class="modal fade" id="rejectModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header bg-danger text-white">
                <h5 class="modal-title">Reject Leave</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <input type="hidden" id="rejectLeaveId">
                <label class="form-label fw-semibold">Reason for rejection (optional)</label>
                <textarea class="form-control" id="rejectReason" rows="3"
                          placeholder="Tell the staff why the leave is rejected"></textarea>
            </div>
            <div class="modal-footer">
                <button class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                <button class="btn btn-danger" id="confirmRejectBtn">Confirm Reject</button>
            </div>
        </div>
    </div>
</div>

<script>
(function(){
    var CTRL = "../../controllers/staff/LeaveController.cfc";

    // ── Load leave list
    function loadLeaves(){
        var params = {
            staff_id  : $('#filterStaff').val(),
            status    : $('#filterStatus').val(),
            date_from : $('#filterFrom').val(),
            date_to   : $('#filterTo').val()
        };
        $.ajax({
            url      : CTRL + "?method=getLeaves",
            type     : "GET",
            data     : params,
            dataType : "json",
            success  : function(res){
                if(res.success) $('#leaveTableBody').html(res.data.html);
                else $('#leaveTableBody').html('<tr><td colspan="8" class="text-danger text-center">'+res.message+'</td></tr>');
            }
        });
    }
    loadLeaves();

    // ── Filter button
    $('#filterBtn').on('click', loadLeaves);

    // ── Auto calculate days
    function calcDays(){
        var from = $('#leaveFrom').val();
        var to   = $('#leaveTo').val();
        if(from && to && to >= from){
            var d1   = new Date(from);
            var d2   = new Date(to);
            var days = Math.round((d2 - d1) / (1000*60*60*24)) + 1;
            $('#totalDays').val(days);
        } else {
            $('#totalDays').val('');
        }
    }
    $('#leaveFrom, #leaveTo').on('change', calcDays);

    // ── Load balance when staff selected
    $('#leaveStaff').on('change', function(){
        var id = $(this).val();
        if(!id){ $('#balanceWrap').hide().html(''); return; }
        $.ajax({
            url      : CTRL + "?method=getBalance&staff_id=" + id,
            type     : "GET",
            dataType : "json",
            success  : function(res){
                if(res.success){
                    $('#balanceWrap').html(res.data.html).show();
                }
            }
        });
    });

    // ── Apply leave
    $('#applyLeaveBtn').on('click', function(){
        var staffId  = $('#leaveStaff').val();
        var typeId   = $('#leaveType').val();
        var from     = $('#leaveFrom').val();
        var to       = $('#leaveTo').val();
        var days     = $('#totalDays').val();

        if(!staffId){ alert('Please select a staff member'); return; }
        if(!typeId){  alert('Please select a leave type');   return; }
        if(!from){    alert('Please select from date');      return; }
        if(!to){      alert('Please select to date');        return; }
        if(to < from){ alert('To date cannot be before from date'); return; }

        $.ajax({
            url      : CTRL + "?method=apply",
            type     : "POST",
            dataType : "json",
            data     : {
                staff_id      : staffId,
                leave_type_id : typeId,
                from_date     : from,
                to_date       : to,
                total_days    : days,
                reason        : $('#leaveReason').val()
            },
            success : function(res){
                if(res.success){
                    alert(res.message);
                    $('#leaveStaff, #leaveType, #leaveFrom, #leaveTo, #leaveReason').val('');
                    $('#totalDays').val('');
                    $('#balanceWrap').hide().html('');
                    loadLeaves();
                } else {
                    alert('Error: ' + res.message);
                }
            }
        });
    });

    // ── Approve
    $(document).on('click', '.approveBtn', function(){
        if(!confirm('Approve this leave?')) return;
        var id = $(this).data('id');
        $.ajax({
            url      : CTRL + "?method=approve",
            type     : "POST",
            data     : { id: id },
            dataType : "json",
            success  : function(res){
                if(res.success) loadLeaves();
                else alert('Error: ' + res.message);
            }
        });
    });

    // ── Reject — open modal first
    $(document).on('click', '.rejectBtn', function(){
        $('#rejectLeaveId').val($(this).data('id'));
        $('#rejectReason').val('');
        new bootstrap.Modal($('#rejectModal')[0]).show();
    });

    $('#confirmRejectBtn').on('click', function(){
        $.ajax({
            url      : CTRL + "?method=reject",
            type     : "POST",
            dataType : "json",
            data     : {
                id            : $('#rejectLeaveId').val(),
                reject_reason : $('#rejectReason').val()
            },
            success : function(res){
                bootstrap.Modal.getInstance($('#rejectModal')[0]).hide();
                if(res.success) loadLeaves();
                else alert('Error: ' + res.message);
            }
        });
    });

})();
</script>