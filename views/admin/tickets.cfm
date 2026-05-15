<cfif NOT structKeyExists(session,"user_id") OR session.role_id NEQ 1>
    <cfabort>
</cfif>

<div class="container-fluid mt-3">

    <h4 class="mb-4">
     Tickets
    </h4>

    <!--- FILTERS --->
    <div class="card shadow-sm mb-3">
        <div class="card-body py-2">
            <div class="row g-2 align-items-end">
                <div class="col-md-3">
                    <input type="text" id="adminTktSearch" class="form-control form-control-sm"
                           placeholder="Search ref, subject, user...">
                </div>
                <div class="col-md-2">
                    <select id="adminTktStatus" class="form-select form-select-sm">
                        <option value="">All Status</option>
                        <option value="pending">Pending</option>
                        <option value="in_progress">In Progress</option>
                        <option value="resolved">Resolved</option>
                        <option value="closed">Closed</option>
                    </select>
                </div>
                <div class="col-md-2">
                    <select id="adminTktPriority" class="form-select form-select-sm">
                        <option value="">All Priority</option>
                        <option value="high">High</option>
                        <option value="medium">Medium</option>
                        <option value="low">Low</option>
                    </select>
                </div>
                <div class="col-md-2">
                    <button class="btn btn-primary btn-sm w-100" id="adminTktFilterBtn">Filter</button>
                </div>
                <div class="col-md-2">
                    <button class="btn btn-secondary btn-sm w-100" id="adminTktClearBtn">Clear</button>
                </div>
            </div>
        </div>
    </div>

    <!--- TABLE --->
    <div class="card shadow-sm">
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover mb-0 small">
                    <thead class="table-dark">
                        <tr>
                            <th>Ref</th>
                            <th>User</th>
                            <th>Page</th>
                            <th>Subject / Description</th>
                            <th>Priority</th>
                            <th>Status</th>
                            <th>Date</th>
                            <th class="text-center">Action</th>
                        </tr>
                    </thead>
                    <tbody id="adminTicketBody">
                        <tr>
                            <td colspan="8" class="text-center py-4">
                                <div class="spinner-border spinner-border-sm me-2"></div>Loading...
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <div id="adminTicketPagination" class="d-flex justify-content-center gap-2 mt-3 flex-wrap"></div>

</div>

<!--- MANAGE MODAL --->
<div class="modal fade" id="manageTicketModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header bg-dark text-white">
                <h5 class="modal-title">
                   </i>Manage Ticket
                    <small id="manageTicketRef" class="text-secondary ms-2"></small>
                </h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <div id="manageTicketMsg"></div>

                <!--- Issue details --->
                <div class="mb-3 p-3 bg-light rounded border">
                    <small class="text-muted fw-semibold d-block mb-1">Subject</small>
                    <div id="viewSubject" class="fw-semibold"></div>
                    <small class="text-muted fw-semibold d-block mt-2 mb-1">Description</small>
                    <div id="viewDesc" class="small text-muted"></div>
                </div>

                <input type="hidden" id="manageTicketId">

                <div class="mb-3">
                    <label class="form-label fw-semibold">Update Status</label>
                    <select class="form-select" id="manageStatus">
                        <option value="pending">Pending</option>
                        <option value="in_progress">In Progress</option>
                        <option value="resolved">Resolved</option>
                        <option value="closed">Closed</option>
                    </select>
                </div>

                <div class="mb-3">
                    <label class="form-label fw-semibold">Admin Note
                        <small class="text-muted fw-normal">(shown to user)</small>
                    </label>
                    <textarea class="form-control" id="manageNote" rows="3"
                              placeholder="Add a note or resolution details..."></textarea>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                <button type="button" class="btn btn-primary" id="saveTicketStatusBtn">
                    <i class="bi bi-save-fill me-1"></i>Save Changes
                </button>
            </div>
        </div>
    </div>
</div>

<script>
(function(){
    var TCTRL   = '../../controllers/TicketController.cfc';
    var curPage = 1;

    function loadTickets(page){
        curPage = page || 1;
        $('#adminTicketBody').html(
            '<tr><td colspan="8" class="text-center py-4">'
          + '<div class="spinner-border spinner-border-sm me-2"></div>Loading...</td></tr>'
        );
        $.ajax({
            url  : TCTRL + '?method=getAll',
            type : 'GET',
            data : {
                p        : curPage,
                status   : $('#adminTktStatus').val(),
                priority : $('#adminTktPriority').val(),
                search   : $('#adminTktSearch').val()
            },
            dataType : 'json',
            success  : function(res){
                if(res.success){
                    $('#adminTicketBody').html(res.data.html);
                    $('#adminTicketPagination').html(res.data.pagination);
                } else {
                    $('#adminTicketBody').html(
                        '<tr><td colspan="8" class="text-center text-danger py-4">'
                      + res.message + '</td></tr>'
                    );
                }
            }
        });
    }

    /* Filters */
    $('#adminTktFilterBtn').on('click', function(){ loadTickets(1); });
    $('#adminTktClearBtn').on('click', function(){
        $('#adminTktSearch, #adminTktStatus, #adminTktPriority').val('');
        loadTickets(1);
    });
    $('#adminTktSearch').on('keydown', function(e){
        if(e.key === 'Enter') loadTickets(1);
    });

    /* Pagination */
    $(document).on('click', '.adminTktPageBtn', function(){
        loadTickets($(this).data('page'));
    });

    /* Open manage modal */
    $(document).on('click', '.manageTicketBtn', function(){
        var btn = $(this);
        $('#manageTicketId').val(btn.data('id'));
        $('#manageTicketRef').text(btn.data('ref'));
        $('#manageStatus').val(btn.data('status'));
        $('#manageNote').val(btn.data('note'));
        $('#viewSubject').text(btn.data('subject'));
        $('#viewDesc').text(btn.data('desc'));
        $('#manageTicketMsg').html('');
        new bootstrap.Modal(document.getElementById('manageTicketModal')).show();
    });

    /* Save status */
    $('#saveTicketStatusBtn').on('click', function(){
        var btn = $(this);
        btn.prop('disabled', true).html('<span class="spinner-border spinner-border-sm me-1"></span>Saving...');

        $.ajax({
            url      : TCTRL + '?method=updateStatus',
            type     : 'POST',
            data     : {
                id         : $('#manageTicketId').val(),
                status     : $('#manageStatus').val(),
                admin_note : $('#manageNote').val()
            },
            dataType : 'json',
            success  : function(res){
                btn.prop('disabled', false).html('<i class="bi bi-save-fill me-1"></i>Save Changes');
                if(res.success){
                    $('#manageTicketMsg').html(
                        '<div class="alert alert-success py-2">'
                      + '<i class="bi bi-check-circle-fill me-2"></i>Updated successfully!'
                      + '</div>'
                    );
                    setTimeout(function(){
                        bootstrap.Modal.getInstance(document.getElementById('manageTicketModal')).hide();
                        loadTickets(curPage);
                    }, 1000);
                } else {
                    $('#manageTicketMsg').html(
                        '<div class="alert alert-danger py-2">' + res.message + '</div>'
                    );
                }
            }
        });
    });

    loadTickets(1);
})();
</script>