<cfcomponent output="false">

    <cffunction name="sendJSON" access="private" returntype="void" output="true">
        <cfargument name="data" type="struct" required="true">
        <cfcontent type="application/json; charset=utf-8" reset="true">
        <cfset var map = structNew("ordered")>
        <cfloop collection="#arguments.data#" item="k">
            <cfset map[lcase(k)] = arguments.data[k]>
        </cfloop>
        <cfoutput>#serializeJSON(map)#</cfoutput>
        <cfabort>
    </cffunction>

    <cffunction name="requireAuth" access="private" returntype="void" output="false">
        <cfif NOT structKeyExists(session,"user_id")>
            <cfset sendJSON({status:"error", message:"Please login to submit an enquiry"})>
        </cfif>
    </cffunction>

    <!--- GET USER ENQUIRIES WITH PAGINATION --->
    <cffunction name="getUserEnquiries" access="remote" returntype="void" output="true" httpmethod="GET">
    <cfset requireAuth()>
    <cftry>
        <cfset var enquiryModel = createObject("component","models.Enquiry")>
        <cfset var currentPage  = structKeyExists(url,"p") AND val(url.p) GT 0 ? val(url.p) : 1>
        <cfset var limit        = 5>

        <cfset var enquiries    = enquiryModel.getUserEnquiries(
            user_id = session.user_id,
            page    = currentPage,
            limit   = limit
        )>
        <cfset var totalRecords = enquiryModel.getUserEnquiryCount(session.user_id)>
        <cfset var totalPages   = ceiling(totalRecords / limit)>

        <cfsavecontent variable="tableHTML">
        <cfif enquiries.recordCount EQ 0>
            <tr><td colspan="5" class="text-center">No enquiries found.</td></tr>
        <cfelse>
            <cfoutput query="enquiries">
            <tr>
                <td>#enquiries.product_name#</td>
                <td>
                    <img src="../../assets/images/products/#enquiries.image#"
                         width="50" height="50" style="object-fit:cover;"
                         onerror="this.src='https://placehold.co/50'">
                </td>
                <td>#enquiries.price#</td>
                <td>
                    <cfif enquiries.status EQ "pending">
                        <span class="badge bg-warning text-dark">Pending</span>
                    <cfelse>
                        <span class="badge bg-success">Restocked</span>
                    </cfif>
                </td>
                <td>#dateFormat(enquiries.created_at,"dd-mmm-yyyy")#</td>
            </tr>
            </cfoutput>
        </cfif>
        </cfsavecontent>

        <cfsavecontent variable="paginationHTML">
        <cfoutput>
        <cfif totalPages GT 1>
            <cfset var groupSize = 4>
            <cfset var pageGroup = ceiling(currentPage / groupSize)>
            <cfset var startPage = (pageGroup - 1) * groupSize + 1>
            <cfset var endPage   = min(startPage + groupSize - 1, totalPages)>
            <cfif startPage GT 1>
                <button class="btn btn-outline-primary btn-sm pageBtn"
                        data-page="#startPage - 1#">&laquo; Prev</button>
            </cfif>
            <cfloop from="#startPage#" to="#endPage#" index="i">
                <button class="btn btn-sm pageBtn <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
                        data-page="#i#">#i#</button>
            </cfloop>
            <cfif endPage LT totalPages>
                <button class="btn btn-outline-primary btn-sm pageBtn"
                        data-page="#endPage + 1#">Next &raquo;</button>
            </cfif>
        </cfif>
        </cfoutput>
        </cfsavecontent>

        <cfset sendJSON({status:"success", html:tableHTML, pagination:paginationHTML})>

    <cfcatch>
        <cfset sendJSON({status:"error", message:"#cfcatch.message#", html:"", pagination:""})>
    </cfcatch>
    </cftry>
</cffunction>

<!--- ADD ENQUIRY --->
<cffunction name="addEnquiry" access="remote" returntype="void" output="true" httpmethod="POST">
    <cfset requireAuth()>
    <cfif NOT structKeyExists(form,"product_id") OR NOT len(trim(form.product_id))>
        <cfset sendJSON({status:"error", message:"Product ID required"})>
    </cfif>
    <cftry>
        <cfset var enquiryModel = createObject("component","models.Enquiry")>

        <cfset var already = enquiryModel.enquiryExists(
            user_id    = session.user_id,
            product_id = form.product_id
        )>
        <cfif already>
            <cfset sendJSON({status:"error", message:"You have already requested this product."})>
        </cfif>

        <cfset var result = enquiryModel.addEnquiry(
            session.user_id,
            form.product_id
        )>
        <cfif result>
            <cfset sendJSON({status:"success", message:"Enquiry submitted successfully"})>
        <cfelse>
            <cfset sendJSON({status:"error", message:"Could not submit enquiry"})>
        </cfif>
    <cfcatch>
        <cfset sendJSON({status:"error", message:"#cfcatch.message#"})>
    </cfcatch>
    </cftry>
</cffunction>

</cfcomponent>