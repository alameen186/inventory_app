<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Choose Your Plan</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
</head>
<body class="bg-light">

<cfset planModel = createObject("component","models.Plan")>
<cfset plans     = planModel.getAll()>

<div class="container mt-5">
    <div class="row justify-content-center">
        <div class="col-md-8">

            <div class="text-center mb-4">
                <h3 class="fw-bold">Choose Your Plan</h3>
                <p class="text-muted">Select a plan to access your vendor dashboard.</p>
            </div>

            <div id="planMsg"></div>

            <div class="row g-4">
                <cfoutput query="plans">
                <div class="col-md-6">
                    <div class="card h-100 shadow
                        <cfif plan_name EQ 'Pro'>border border-primary border-2<cfelse>border</cfif>">
                        <div class="card-body p-4">

                            <cfif plan_name EQ "Pro">
                                <div class="text-center mb-2">
                                    <span class="badge bg-primary">Recommended</span>
                                </div>
                            </cfif>

                            <h4 class="fw-bold text-center mb-1">#plan_name#</h4>
                            <p class="text-muted small text-center mb-3">#description#</p>

                            <ul class="list-group list-group-flush mb-4">
                                <li class="list-group-item">
                                    <span class="text-success fw-bold me-2">&##10003;</span>Products &amp; Categories
                                </li>
                                <li class="list-group-item">
                                    <span class="text-success fw-bold me-2">&##10003;</span>Orders &amp; Create Order
                                </li>
                                <cfif plan_name EQ "Pro">
                                    <li class="list-group-item">
                                        <span class="text-success fw-bold me-2">&##10003;</span>Scheduled Orders
                                    </li>
                                    <li class="list-group-item">
                                        <span class="text-success fw-bold me-2">&##10003;</span>Enquiries
                                    </li>
                                    <li class="list-group-item">
                                        <span class="text-success fw-bold me-2">&##10003;</span>Search Analytics
                                    </li>
                                <cfelse>
                                    <li class="list-group-item text-muted">
                                        <span class="text-danger fw-bold me-2">&##10007;</span>Scheduled Orders
                                    </li>
                                    <li class="list-group-item text-muted">
                                        <span class="text-danger fw-bold me-2">&##10007;</span>Enquiries
                                    </li>
                                    <li class="list-group-item text-muted">
                                        <span class="text-danger fw-bold me-2">&##10007;</span>Search Analytics
                                    </li>
                                </cfif>
                            </ul>

                            <div class="d-grid">
                                <button class="btn selectPlanBtn
                                    <cfif plan_name EQ 'Pro'>btn-primary<cfelse>btn-outline-secondary</cfif>"
                                    data-plan-id="#id#">
                                    Select #plan_name#
                                </button>
                            </div>

                        </div>
                    </div>
                </div>
                </cfoutput>
            </div>

        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
$(function(){
    $('.selectPlanBtn').on('click', function(){
        var btn     = $(this);
        var plan_id = btn.data('plan-id');
        btn.prop('disabled', true).text('Saving...');
        $.ajax({
            url      : 'controllers/PlanController.cfc?method=selectPlan',
            type     : 'POST',
            data     : { plan_id: plan_id },
            dataType : 'json',
            success  : function(res){
                if(res.success){
                    window.location.href = 'index.cfm?page=dashboard&section=vendorDashboard';
                } else {
                    $('#planMsg').html(
                        '<div class="alert alert-danger">' + res.message + '</div>'
                    );
                    btn.prop('disabled', false).text('Select Plan');
                }
            },
            error: function(){
                $('#planMsg').html(
                    '<div class="alert alert-danger">Network error. Please try again.</div>'
                );
                btn.prop('disabled', false).text('Select Plan');
            }
        });
    });
});
</script>
</body>
</html>