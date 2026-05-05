<cfcomponent output="false">

    <cffunction name="create" access="remote" returntype="void" httpMethod="POST">
        <cfset createObject("component","models.AuthGuard").checkAuth()>
        <cftry>
            <cfset var customer_id  = val(form.customer_id)>
            <cfset var start_date   = trim(form.start_date)>
            <cfset var items        = trim(form.items)>

            <cfif customer_id LTE 0>
                <cfset jsonRes(false,"Please select a customer")><cfreturn>
            </cfif>
            <cfif NOT isDate(start_date)>
                <cfset jsonRes(false,"Invalid start date")><cfreturn>
            </cfif>
            <cfif NOT len(items)>
                <cfset jsonRes(false,"Add at least one product")><cfreturn>
            </cfif>

            <cfset var day_of_month = day(parseDateTime(start_date))>
            <cfset var model        = createObject("component","models.ScheduledOrder")>
            <cfset var result       = model.createSchedule(
                vendor_id   = session.user_id,
                customer_id = customer_id,
                start_date  = start_date,
                day_of_month= day_of_month,
                items       = items
            )>

            <cfif result.success>
    <cfset jsonRes(true, result.message)>
<cfelse>
    <cfset jsonRes(false, result.message)>
</cfif>
        <cfcatch>
            <cfset jsonRes(false,"Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>


    <cffunction name="toggleStatus" access="remote" returntype="void" httpMethod="GET">
    <cfset createObject("component","models.AuthGuard").checkAuth()>
    <cftry>
        <cfset var id        = val(url.id)>
        <cfset var newStatus = (url.currentStatus EQ 1) ? 0 : 1>
        <cfset var model     = createObject("component","models.ScheduledOrder")>
        <cfset var result    = model.toggleSchedule(
            id        = id,
            vendor_id = session.user_id,
            status    = newStatus
        )>

      <cfif result.success>
    <cfset jsonRes(true, newStatus EQ 1 ? "Schedule resumed" : "Schedule stopped", {
        "newStatus": javaCast("int", newStatus)
    })>
<cfelse>
    <cfset jsonRes(false, result.message)>
</cfif>

    <cfcatch>
        <cfset jsonRes(false,"Error: #cfcatch.message#")>
    </cfcatch>
    </cftry>
</cffunction>


    <cffunction name="jsonRes" access="private" returntype="void" output="true">
        <cfargument name="success" type="boolean" required="true">
        <cfargument name="message" type="string"  default="">
        <cfargument name="data"    type="any"     default="">
        <cfcontent type="application/json; charset=utf-8" reset="true">
        <cfoutput>#serializeJSON({
            "success": arguments.success,
            "message": arguments.message,
            "data"   : arguments.data
        })#</cfoutput>
    </cffunction>

    <cffunction name="search" access="remote" returntype="void"
            output="true" httpMethod="GET">
    <cfset createObject("component","models.AuthGuard").checkAuth()>
    <cftry>
        <cfset var model     = createObject("component","models.ScheduledOrder")>
        <cfset var srch      = structKeyExists(url,"search") ? trim(url.search) : "">
        <cfset var sort      = structKeyExists(url,"sort")   ? url.sort         : "">
        <cfset var page      = structKeyExists(url,"p") AND val(url.p) GT 0
                               ? val(url.p) : 1>
        <cfset var limit     = 10>
        <cfset var groupSize = 4>

        <cfset var schedules = model.getByVendor(
            vendor_id = session.user_id,
            search    = srch,
            sort      = sort,
            page      = page,
            limit     = limit
        )>
        <cfset var total      = model.getByVendorCount(
            vendor_id = session.user_id,
            search    = srch
        )>
        <cfset var totalPages = max(1, ceiling(total / limit))>
        <cfset var pageGroup  = ceiling(page / groupSize)>
        <cfset var startPage  = (pageGroup - 1) * groupSize + 1>
        <cfset var endPage    = min(startPage + groupSize - 1, totalPages)>

        <!--- build rows HTML --->
        <cfsavecontent variable="rowsHTML">
        <cfif schedules.recordCount EQ 0>
            <cfoutput>
            <tr>
                <td colspan="8" class="text-center text-muted py-4">
                    No scheduled orders found.
                </td>
            </tr>
            </cfoutput>
        <cfelse>
            <cfset rowNum = (page - 1) * limit>
            <cfoutput query="schedules">
                <cfset rowNum = rowNum + 1>
                <tr>
                    <td>#rowNum#</td>
                    <td>#encodeForHTML(product_name)#</td>
                    <td>#quantity#</td>
                    <td>#encodeForHTML(customer_name)#</td>
                    <td>#dateFormat(start_date,"dd-mmm-yyyy")#</td>
                    <td>Every #day_of_month#<cfif day_of_month EQ 1>st<cfelseif day_of_month EQ 2>nd<cfelseif day_of_month EQ 3>rd<cfelse>th</cfif></td>
                    <td>
                        <cfif is_active>
                            <span class="badge bg-success">Active</span>
                        <cfelse>
                            <span class="badge bg-danger">Stopped</span>
                        </cfif>
                    </td>
                    <td>
                        <button class="toggleSchedBtn btn btn-sm
                            #is_active ? 'btn-danger' : 'btn-success'#"
                            data-id="#id#"
                            data-status="#is_active#">
                            #is_active ? 'Stop' : 'Resume'#
                        </button>
                    </td>
                </tr>
            </cfoutput>
        </cfif>
        </cfsavecontent>

        <!--- build pagination HTML --->
        <cfsavecontent variable="pageHTML">
        <cfoutput>
        <cfif totalPages GT 1>
            <cfif startPage GT 1>
                <button class="schedPageBtn btn btn-outline-primary btn-sm"
                    data-page="#startPage - 1#">&laquo; Prev</button>
            </cfif>
            <cfloop from="#startPage#" to="#endPage#" index="i">
                <button class="schedPageBtn btn btn-sm
                    #i EQ page ? 'btn-primary' : 'btn-outline-primary'#"
                    data-page="#i#">#i#</button>
            </cfloop>
            <cfif endPage LT totalPages>
                <button class="schedPageBtn btn btn-outline-primary btn-sm"
                    data-page="#endPage + 1#">Next &raquo;</button>
            </cfif>
        </cfif>
        </cfoutput>
        </cfsavecontent>

        <cfset jsonRes(true, "", {
            "rows"       : rowsHTML,
            "pagination" : pageHTML
        })>

    <cfcatch>
        <cfset jsonRes(false, "Error: #cfcatch.message#")>
    </cfcatch>
    </cftry>
</cffunction>

</cfcomponent>