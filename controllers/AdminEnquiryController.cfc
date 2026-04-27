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
            <cfset sendJSON({status:"error", message:"Unauthorized", html:"", pagination:""})>
        </cfif>
    </cffunction>

    <cffunction name="getVendorFilter" access="private" returntype="string" output="false">
        <cfif structKeyExists(session,"role_name") AND session.role_name EQ "vendor">
            <cfreturn session.user_id>
        </cfif>
        <cfreturn "">
    </cffunction>

    <!--- SEARCH ENQUIRIES --->
    <cffunction name="searchEnquiries" access="remote" returntype="void" output="true" httpmethod="GET">
    <cfset requireAuth()>
    <cftry>
        <cfset var enquiryModel = createObject("component","models.Enquiry")>
        <cfset var vendorFilter = getVendorFilter()>
        <cfset var srch         = structKeyExists(url,"search")   ? trim(url.search)   : "">
        <cfset var statusFilter = structKeyExists(url,"status")   ? url.status          : "">
        <cfset var fromDate     = structKeyExists(url,"fromDate") ? url.fromDate        : "">
        <cfset var toDate       = structKeyExists(url,"toDate")   ? url.toDate          : "">
        <cfset var currentPage  = structKeyExists(url,"p") AND val(url.p) GT 0 ? val(url.p) : 1>
        <cfset var limit        = 10>

        <cfset var enquiries = enquiryModel.getAllEnquiries(
            search    = srch,
            status    = statusFilter,
            page      = currentPage,
            limit     = limit,
            vendor_id = vendorFilter,
            fromDate  = fromDate,
            toDate    = toDate
        )>
        <cfset var totalRecords = enquiryModel.getEnquiryCount(
            search    = srch,
            status    = statusFilter,
            vendor_id = vendorFilter,
            fromDate  = fromDate,
            toDate    = toDate
        )>
        <cfset var totalPages = ceiling(totalRecords / limit)>

        <cfsavecontent variable="tableHTML">
        <cfif enquiries.recordCount EQ 0>
            <tr><td colspan="8" class="text-center">No data found.</td></tr>
        <cfelse>
            <cfoutput query="enquiries">
            <tr id="row_#enquiries.product_id#">
                <td>#enquiries.user_name#</td>
                <td>#enquiries.product_name#</td>
                <td>
                    <img src="../../assets/images/products/#enquiries.image#"
                         width="50" height="50" style="object-fit:cover;"
                         onerror="this.src='https://placehold.co/50'">
                </td>
                <td>#enquiries.price#</td>
                <td class="stockCell">#enquiries.stock#</td>
                <td class="statusCell">
                    <cfif enquiries.status EQ "pending">
                        <span class="badge bg-warning text-dark">Pending</span>
                    <cfelse>
                        <span class="badge bg-success">Restocked</span>
                    </cfif>
                </td>
                <td>#dateFormat(enquiries.created_at,"dd-mmm-yyyy")#</td>
                <td>
                    <cfif enquiries.status EQ "pending">
                        <button class="btn btn-warning btn-sm restockBtn"
                                data-id="#enquiries.product_id#"
                                data-name="#enquiries.product_name#"
                                data-category="#enquiries.category_name#"
                                data-price="#enquiries.price#"
                                data-stock="#enquiries.stock#">Restock</button>
                    <cfelse>
                        <span class="text-muted">Completed</span>
                    </cfif>
                </td>
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

    <!--- RESTOCK PRODUCT --->
    <cffunction name="restockProduct" access="remote" returntype="void" output="true" httpmethod="POST">
        <cfset requireAuth()>
        <cfif NOT structKeyExists(form,"product_id") OR NOT len(trim(form.product_id))>
            <cfset sendJSON({status:"error", message:"Product ID required", html:"", pagination:""})>
        </cfif>
        <cfif NOT structKeyExists(form,"add_stock") OR NOT val(form.add_stock) GT 0>
            <cfset sendJSON({status:"error", message:"Valid stock quantity required", html:"", pagination:""})>
        </cfif>
        <cftry>
            <cfset var enquiryModel = createObject("component","models.Enquiry")>
            <cfset var result = enquiryModel.restockProduct(
                product_id = form.product_id,
                add_stock  = val(form.add_stock)
            )>
            <cfif result>
                <cfset sendJSON({
                    status     : "success",
                    message    : "Stock updated successfully",
                    product_id : form.product_id,
                    html       : "",
                    pagination : ""
                })>
            <cfelse>
                <cfset sendJSON({status:"error", message:"Could not update stock", html:"", pagination:""})>
            </cfif>
        <cfcatch>
            <cfset sendJSON({status:"error", message:"#cfcatch.message#", html:"", pagination:""})>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>