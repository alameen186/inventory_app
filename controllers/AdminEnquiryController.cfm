<cfif structKeyExists(url,"action") AND url.action EQ "search">

<cfset enquiryModel = createObject("component","models.Enquiry")>

<cfparam name="url.search" default="">
<cfparam name="url.status" default="">
<cfparam name="url.p" default="1">

<cfset page = val(url.p)>
<cfif page LT 1>
    <cfset page = 1>
</cfif>

<cfset limit = 2>
<cfset offset = (page - 1) * limit>

<!-- IMPORTANT -->
<cfset enquiries = enquiryModel.getAllEnquiries(
    search = url.search,
    status = url.status,
    page = page,
    limit = limit
)

<cfif enquiries.recordCount EQ 0>
<tr>
<td colspan="8" class="text-center">No data found</td>
</tr>
<cfabort>
</cfif>

<cfoutput query="enquiries">

<tr id="row_#product_id#">

<td>#user_name#</td>
<td>#product_name#</td>

<td>
<img src="../../assets/images/products/#image#" width="50">
</td>

<td>#price#</td>
<td class="stockCell">#stock#</td>

<td class="statusCell">
<cfif status EQ "pending">
<span class="badge bg-warning">Pending</span>
<cfelse>
<span class="badge bg-success">Restocked</span>
</cfif>
</td>

<td>#dateFormat(created_at,"dd-mmm-yyyy")#</td>

<td>
<cfif status EQ "pending">
<button class="btn btn-warning btn-sm restockBtn"
data-id="#product_id#">Restock</button>
<cfelse>
<span class="text-muted">Done</span>
</cfif>
</td>

</tr>

</cfoutput>

<cfabort>

</cfif>