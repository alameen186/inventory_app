<cfif NOT structKeyExists(session,"user_id") OR session.role_name NEQ "vendor">
    <cfabort>
</cfif>

<cfset CTRL = "../../controllers/staff/LeaveController.cfc">

<div class="container-fluid mt-3">

    <h4 class="mb-4">Leave Management</h4>

    <!--- Filters --->
    <div class="card shadow-sm mb-3">
        <div class="card-body">
            <div class="row g-2 align-items-end">
                <div class="col-md-3">
                    <label class="form-label fw-semibold">Staff</label>
                    <cfset activeStaff = createObject("component","models.Staff").getActiveStaff(session.user_id)>
                    <select class="form-select form-select-sm" id="filterStaff">
                        <option value="">All Staff</option>
                        <cfoutput query="activeStaff">
                            <option value="#id#">#encodeForHTML(full_name)#</option>
                        </cfoutput>
                    </select>
                </div>
                <div class="col-md-2">
                    <label class="form-label fw-semibold">Status</label>
                    <select class="form-select form-select-sm" id="filterStatus">
                        <option value="">All</option>
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
                            <th>Department</th>
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
                            <td colspan="9" class="text-center py-4">
                                <div class="spinner-border spinner-border-sm"></div> Loading...
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

</div>

<!--- Reject Modal --->
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

<!--- Department Conflict Modal --->
<div class="modal fade" id="conflictModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header bg-warning">
                <h5 class="modal-title">
                    <i class="bi bi-exclamation-triangle-fill me-2"></i>Department Conflict
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <div id="conflictDetails"></div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                <button class="btn btn-warning" id="forceApproveBtn">Approve Anyway</button>
            </div>
        </div>
    </div>
</div>

<script>
(function(){
    var CTRL = "../../controllers/staff/LeaveController.cfc";
    var pendingApproveId = null;

    // ── Safe modal helper — prevents backdrop freeze
    function safeHideModal(modalId) {
        var el = document.getElementById(modalId);
        var instance = bootstrap.Modal.getInstance(el);
        if(instance) {
            instance.hide();
        }
        // Force cleanup after hide animation completes
        el.addEventListener('hidden.bs.modal', function handler(){
            el.removeEventListener('hidden.bs.modal', handler);
            // Remove any stuck backdrop
            document.querySelectorAll('.modal-backdrop').forEach(function(el){ el.remove(); });
            document.body.classList.remove('modal-open');
            document.body.style.removeProperty('overflow');
            document.body.style.removeProperty('padding-right');
        }, { once: true });
    }

    function safeShowModal(modalId) {
        // Clean up any leftover backdrop before showing
        document.querySelectorAll('.modal-backdrop').forEach(function(el){ el.remove(); });
        document.body.classList.remove('modal-open');
        document.body.style.removeProperty('overflow');
        document.body.style.removeProperty('padding-right');

        var el = document.getElementById(modalId);
        var instance = bootstrap.Modal.getInstance(el);
        if(instance) {
            instance.dispose();
        }
        new bootstrap.Modal(el).show();
    }

    function loadLeaves(){
        var params = {
            staff_id  : $('#filterStaff').val(),
            status    : $('#filterStatus').val(),
            date_from : $('#filterFrom').val(),
            date_to   : $('#filterTo').val()
        };
        $.ajax({
            url: CTRL + "?method=getLeaves", type: "GET",
            data: params, dataType: "json",
            success: function(res){
                if(res.success) $('#leaveTableBody').html(res.data.html);
                else $('#leaveTableBody').html(
                    '<tr><td colspan="9" class="text-danger text-center">' + res.message + '</td></tr>'
                );
            }
        });
    }
    loadLeaves();

    $('#filterBtn').on('click', loadLeaves);

    // Approve button
    $(document).on('click', '.approveBtn', function(){
        doApprove($(this).data('id'), false);
    });

    function doApprove(id, force){
        $.ajax({
            url: CTRL + "?method=approve", type: "POST",
            data: { id: id, force_approve: force ? "1" : "0" },
            dataType: "json",
            success: function(res){
                if(res.success){
                    loadLeaves();
                } else if(res.data && res.data.conflict){
                    pendingApproveId = id;
                    var d = res.data;
                    $('#conflictDetails').html(
                        '<div class="alert alert-warning mb-3">' +
                            '<i class="bi bi-exclamation-triangle-fill me-2"></i>' +
                            '<strong>Limit reached:</strong> Department <strong>"' +
                            $('<div>').text(d.department).html() +
                            '"</strong> allows max <strong>' + d.max_on_leave +
                            ' staff</strong> on leave at the same time.' +
                        '</div>' +
                        '<p class="mb-2">Already approved on overlapping dates ' +
                        '<strong>(' + d.conflict_count + ' staff):</strong></p>' +
                        '<ul>' +
                            d.names.split(',').map(function(n){
                                return '<li>' + $('<div>').text(n.trim()).html() + '</li>';
                            }).join('') +
                        '</ul>' +
                        '<p class="text-muted small mb-0">' +
                            'You can still approve — this is a warning, not a hard block.' +
                        '</p>'
                    );
                    safeShowModal('conflictModal');
                } else {
                    alert('Error: ' + res.message);
                }
            }
        });
    }

    // Force approve
    $('#forceApproveBtn').on('click', function(){
        safeHideModal('conflictModal');
        // Wait for modal to fully close before approving
        document.getElementById('conflictModal').addEventListener('hidden.bs.modal', function handler(){
            document.getElementById('conflictModal').removeEventListener('hidden.bs.modal', handler);
            if(pendingApproveId) {
                doApprove(pendingApproveId, true);
                pendingApproveId = null;
            }
        }, { once: true });
    });

    // Reject button
    $(document).on('click', '.rejectBtn', function(){
        $('#rejectLeaveId').val($(this).data('id'));
        $('#rejectReason').val('');
        safeShowModal('rejectModal');
    });

    // Confirm reject
    $('#confirmRejectBtn').on('click', function(){
        $.ajax({
            url: CTRL + "?method=reject", type: "POST",
            dataType: "json",
            data: {
                id            : $('#rejectLeaveId').val(),
                reject_reason : $('#rejectReason').val()
            },
            success: function(res){
                safeHideModal('rejectModal');
                document.getElementById('rejectModal').addEventListener('hidden.bs.modal', function handler(){
                    document.getElementById('rejectModal').removeEventListener('hidden.bs.modal', handler);
                    if(res.success) loadLeaves();
                    else alert('Error: ' + res.message);
                }, { once: true });
            }
        });
    });

})();
</script>
