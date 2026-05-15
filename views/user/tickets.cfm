<cfif NOT structKeyExists(session,"user_id")>
    <cfabort>
</cfif>

<div class="container-fluid mt-3">

    <div class="d-flex justify-content-between align-items-center mb-4">
        <h4 class="mb-0">
            My Tickets
        </h4>
        <button class="btn btn-danger" onclick="openTicketModal()">
            <i class="bi bi-plus-lg me-1"></i>Raise New Ticket
        </button>
    </div>

    <div class="card shadow-sm">
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover mb-0 small">
                    <thead class="table-dark">
                        <tr>
                            <th>Ticket Ref</th>
                            <th>Page</th>
                            <th>Subject</th>
                            <th>Priority</th>
                            <th>Status / Admin Note</th>
                            <th>Date</th>
                        </tr>
                    </thead>
                    <tbody id="ticketTableBody">
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

    <div id="ticketPagination" class="d-flex justify-content-center gap-2 mt-3 flex-wrap"></div>

</div>

<script>
(function(){
    var TCTRL = '../../controllers/TicketController.cfc';

    function loadTickets(page){
        $('#ticketTableBody').html(
            '<tr><td colspan="6" class="text-center py-4">'
          + '<div class="spinner-border spinner-border-sm me-2"></div>Loading...</td></tr>'
        );
        $.ajax({
            url      : TCTRL + '?method=getUserTickets',
            type     : 'GET',
            data     : { p: page || 1 },
            dataType : 'json',
            success  : function(res){
                if(res.success){
                    $('#ticketTableBody').html(res.data.html);
                    $('#ticketPagination').html(res.data.pagination);
                } else {
                    $('#ticketTableBody').html(
                        '<tr><td colspan="6" class="text-center text-danger py-4">'
                      + res.message + '</td></tr>'
                    );
                }
            }
        });
    }

    $(document).on('click', '.tktPageBtn', function(){
        loadTickets($(this).data('page'));
    });

    loadTickets(1);
})();
</script>