<cfif NOT structKeyExists(session,"user_id") OR session.role_id NEQ 1>
    <cfabort>
</cfif>

<div class="container-fluid mt-3">

    <div class="d-flex justify-content-between align-items-center mb-4">
        <h4 class="mb-0">
            <i class="bi bi-grid-3x3-gap-fill me-2 text-primary"></i>Rack Management
        </h4>
        <span class="text-muted small">
            <i class="bi bi-info-circle me-1"></i>Racks are created by vendors
        </span>
    </div>

    <div class="card shadow-sm">
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover mb-0 small">
                    <thead class="table-dark">
                        <tr>
                            <th>Rack Code</th>
                            <th>Rack Name</th>
                            <th>Created By (Vendor)</th>
                            <th>Face Capacities</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody id="rackTableBody">
                        <tr>
                            <td colspan="6" class="text-center py-4">
                                <div class="spinner-border spinner-border-sm me-2"></div>
                                Loading...
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<script>
(function(){
    var RC = '../../controllers/RackController.cfc';

    function loadRacks(){
        $('#rackTableBody').html(
            '<tr><td colspan="6" class="text-center py-4">'
          + '<div class="spinner-border spinner-border-sm me-2"></div>Loading...</td></tr>'
        );
        $.get(RC + '?method=getRacks', function(res){
            $('#rackTableBody').html(
                res.success
                    ? res.data.html
                    : '<tr><td colspan="6" class="text-center text-danger py-4">' + res.message + '</td></tr>'
            );
        }, 'json');
    }

    loadRacks();
})();
</script>
