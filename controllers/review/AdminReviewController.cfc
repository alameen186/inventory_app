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

    <cffunction name="searchReviews" access="remote" returntype="void"
                output="true" httpmethod="GET">

        <cfset createObject("component","models.AuthGuard").checkAuth()>

        <cftry>
            <cfset var reviewModel = createObject("component","models.Review")>
            <cfset var srch        = structKeyExists(url,"search") ? trim(url.search) : "">
            <cfset var rating      = structKeyExists(url,"rating") ? trim(url.rating) : "">
            <cfset var status      = structKeyExists(url,"status") ? trim(url.status) : "">
            <cfset var currentPage = structKeyExists(url,"p") AND val(url.p) GT 0 ? val(url.p) : 1>
            <cfset var limit       = 10>

            <cfset var reviews = reviewModel.getAllReviews(
                search = srch,
                rating = rating,
                status = status,
                page   = currentPage,
                limit  = limit
            )>
            <cfset var totalRecords = reviewModel.getAllReviewCount(
                search = srch,
                rating = rating,
                status = status
            )>
            <cfset var totalPages = totalRecords GT 0 ? ceiling(totalRecords / limit) : 0>

            <!--- TABLE HTML --->
            <cfsavecontent variable="tableHTML">
            <cfif reviews.recordCount EQ 0>
                <cfoutput>
                <tr>
                    <td colspan="7" class="text-center py-4 text-muted">
                        No reviews found.
                    </td>
                </tr>
                </cfoutput>
            <cfelse>
                <cfoutput query="reviews">
                <tr class="#reviews.is_active EQ 0 ? 'table-secondary text-muted' : ''#">
                    <td>#encodeForHTML(product_name)#</td>
                    <td>#encodeForHTML(user_name)#</td>
                    <td>
                        <span class="text-warning">
                            <cfloop from="1" to="5" index="s">
                                <cfif s LTE reviews.rating>&##9733;<cfelse>&##9734;</cfif>
                            </cfloop>
                        </span>
                        <small class="ms-1">(#reviews.rating#/5)</small>
                    </td>
                    <td style="max-width:300px;">
                        <span class="d-inline-block text-truncate" style="max-width:280px;"
                              title="#encodeForHTMLAttribute(comment)#">
                            #encodeForHTML(comment)#
                        </span>
                    </td>
                    <td>
                        <cfif reviews.is_active EQ 1>
                            <span class="badge bg-success">Active</span>
                        <cfelse>
                            <span class="badge bg-danger">Removed</span>
                        </cfif>
                    </td>
                    <td>#dateFormat(created_at,"dd-mmm-yyyy")#</td>
                    <td>
                        <button class="btn btn-sm toggleReviewBtn
                            #reviews.is_active EQ 1 ? 'btn-danger' : 'btn-success'#"
                            data-id="#id#">
                            #reviews.is_active EQ 1 ? 'Remove' : 'Restore'#
                        </button>
                    </td>
                </tr>
                </cfoutput>
            </cfif>
            </cfsavecontent>

            <!--- PAGINATION HTML --->
            <cfsavecontent variable="paginationHTML">
            <cfoutput>
            <cfif totalPages GT 1>
                <cfset var groupSize = 4>
                <cfset var pageGroup = ceiling(currentPage / groupSize)>
                <cfset var startPage = (pageGroup - 1) * groupSize + 1>
                <cfset var endPage   = min(startPage + groupSize - 1, totalPages)>
                <cfif startPage GT 1>
                    <button class="btn btn-outline-primary btn-sm pageBtn"
                            data-page="#startPage - 1#">Prev</button>
                </cfif>
                <cfloop from="#startPage#" to="#endPage#" index="i">
                    <button class="btn btn-sm pageBtn
                        #i EQ currentPage ? 'btn-primary' : 'btn-outline-primary'#"
                        data-page="#i#">#i#</button>
                </cfloop>
                <cfif endPage LT totalPages>
                    <button class="btn btn-outline-primary btn-sm pageBtn"
                            data-page="#endPage + 1#">Next</button>
                </cfif>
            </cfif>
            </cfoutput>
            </cfsavecontent>

            <cfset sendJSON({
                status     : "success",
                html       : tableHTML,
                pagination : paginationHTML,
                total      : totalRecords
            })>

        <cfcatch>
            <cfset sendJSON({
                status     : "error",
                message    : cfcatch.message,
                html       : "",
                pagination : ""
            })>
        </cfcatch>
        </cftry>
    </cffunction>


    <cffunction name="toggleReview" access="remote" returntype="void"
                output="true" httpmethod="POST">

        <cfset createObject("component","models.AuthGuard").checkAuth()>

        <cfif NOT structKeyExists(form,"id") OR NOT val(form.id)>
            <cfset sendJSON({status:"error", message:"Invalid review ID"})>
        </cfif>

        <cftry>
            <cfset var reviewModel = createObject("component","models.Review")>
            <cfset var result      = reviewModel.toggleReview(val(form.id))>

            <cfif result>
                <cfset sendJSON({status:"success", message:"Review status updated"})>
            <cfelse>
                <cfset sendJSON({status:"error", message:"Could not update review"})>
            </cfif>

        <cfcatch>
            <cfset sendJSON({status:"error", message:cfcatch.message})>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>