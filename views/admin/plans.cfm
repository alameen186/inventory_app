<cfset planModel = createObject("component","models.Plan")>
<cfset plans     = planModel.getAll()>

<h4 class="mb-4">Plans</h4>

<table class="table table-bordered table-hover">
    <thead class="table-dark">
        <tr><th>ID</th><th>Plan Name</th><th>Description</th><th>Status</th></tr>
    </thead>
    <tbody>
    <cfoutput query="plans">
        <tr>
            <td>#id#</td>
            <td><strong>#plan_name#</strong></td>
            <td>#description#</td>
            <td><span class="badge bg-success">Active</span></td>
        </tr>
    </cfoutput>
    </tbody>
</table>
<p class="text-muted small">Plans are managed directly in the database. Contact your developer to add or modify plans.</p>