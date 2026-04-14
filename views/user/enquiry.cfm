<cfset enquiryModel = createObject("component","models.Enquiry")>

<cfset enquiries = enquiryModel.getUserEnquiries(session.user_id)>

<div class="container mt-4">

<h3>My Product Enquiries</h3>

<table class="table table-bordered mt-3">
<thead class="table-dark">
<tr>
    <th>Product</th>
    <th>Image</th>
    <th>Price</th>
    <th>Status</th>
    <th>Date</th>
</tr>
</thead>

<tbody>
<cfoutput query="enquiries">
<tr>
    <td>#product_name#</td>
    <td>
        <img src="../../assets/images/products/#image#" width="50">
    </td>
    <td>#price#</td>
    <td>
        <cfif status EQ "pending">
            <span class="badge bg-warning">Pending</span>
        <cfelse>
            <span class="badge bg-success">Fulfilled</span>
        </cfif>
    </td>
    <td>#dateFormat(created_at,"dd-mmm-yyyy")#</td>
</tr>
</cfoutput>
</tbody>
</table>

</div>