<cfcomponent output="false">

    <cffunction name="jsonRes" access="private" returntype="void" output="true">
        <cfargument name="success" type="boolean" required="true">
        <cfargument name="message" type="string"  default="">
        <cfargument name="data"    type="any"     default="">
        <cfcontent type="application/json; charset=utf-8" reset="true">
        <cfoutput>#serializeJSON({ "success": arguments.success, "message": arguments.message, "data": arguments.data })#</cfoutput>
        <cfabort>
    </cffunction>

    <cffunction name="requireVendor" access="private" returntype="void" output="false">
        <cfif NOT structKeyExists(session,"user_id") OR session.role_name NEQ "vendor">
            <cfset jsonRes(false,"Unauthorized")>
        </cfif>
    </cffunction>

    <!--- Apply Leave --->
    <cffunction name="apply" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireVendor()>
        <cftry>
            <cfset var model = createObject("component","models.Leave")>
            <cfset var result = model.applyLeave(
                vendor_id     = session.user_id,
                staff_id      = val(form.staff_id),
                leave_type_id = val(form.leave_type_id),
                from_date     = trim(form.from_date),
                to_date       = trim(form.to_date),
                total_days    = val(form.total_days),
                reason        = structKeyExists(form,"reason") ? trim(form.reason) : ""
            )>
            <cfset jsonRes(result.success, result.success ? "Leave applied successfully" : result.message)>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getLeaves" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireVendor()>
        <cftry>
            <cfset var model = createObject("component","models.Leave")>
            <cfset var q = model.getLeaves(
                vendor_id  = session.user_id,
                staff_id   = structKeyExists(url,"staff_id")  ? url.staff_id  : "",
                status     = structKeyExists(url,"status")    ? url.status    : "",
                date_from  = structKeyExists(url,"date_from") ? url.date_from : "",
                date_to    = structKeyExists(url,"date_to")   ? url.date_to   : ""
            )>

            <cfsavecontent variable="local.html">
            <cfoutput>
            <cfif q.recordCount EQ 0>
                <tr><td colspan="8" class="text-center text-muted py-4">No leave records found.</td></tr>
            <cfelse>
                <cfloop query="q">
                <tr>
                    <td>#encodeForHTML(q.staff_name)#<br>
                        <small class="text-muted">#encodeForHTML(q.position)#</small>
                    </td>
                    <td>#encodeForHTML(q.leave_type)#</td>
                    <td>#dateFormat(q.from_date,'dd-mmm-yy')#</td>
                    <td>#dateFormat(q.to_date,'dd-mmm-yy')#</td>
                    <td class="text-center">#q.total_days#</td>
                    <td>#len(q.reason) ? encodeForHTML(q.reason) : '-'#</td>
                    <td class="text-center">
                        <cfif q.status EQ "approved">
                            <span class="badge bg-success">Approved</span>
                        <cfelseif q.status EQ "rejected">
                            <span class="badge bg-danger">Rejected</span>
                            <cfif len(q.reject_reason)>
                                <br><small class="text-muted">#encodeForHTML(q.reject_reason)#</small>
                            </cfif>
                        <cfelse>
                            <span class="badge bg-warning text-dark">Pending</span>
                        </cfif>
                    </td>
                    <td class="text-center">
                        <cfif q.status EQ "pending">
                            <button class="btn btn-sm btn-success approveBtn mb-1" data-id="#q.id#">Approve</button>
                            <button class="btn btn-sm btn-danger rejectBtn"  data-id="#q.id#">Reject</button>
                        <cfelse>
                            <span class="text-muted">—</span>
                        </cfif>
                    </td>
                </tr>
                </cfloop>
            </cfif>
            </cfoutput>
            </cfsavecontent>

            <cfset jsonRes(true,"",{ "html": local.html, "count": q.recordCount })>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="approve" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireVendor()>
        <cftry>
            <cfset var model  = createObject("component","models.Leave")>
            <cfset var result = model.updateStatus(val(form.id), session.user_id, "approved")>
            <cfset jsonRes(result.success, result.success ? "Leave approved" : result.message)>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="reject" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireVendor()>
        <cftry>
            <cfset var model  = createObject("component","models.Leave")>
            <cfset var result = model.updateStatus(
                val(form.id),
                session.user_id,
                "rejected",
                structKeyExists(form,"reject_reason") ? trim(form.reject_reason) : ""
            )>
            <cfset jsonRes(result.success, result.success ? "Leave rejected" : result.message)>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- Leave Balance --->
    <cffunction name="getBalance" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireVendor()>
        <cftry>
            <cfset var model = createObject("component","models.Leave")>
            <cfset var q     = model.getBalance(val(url.staff_id), session.user_id)>

            <cfsavecontent variable="local.html">
            <cfoutput>
            <cfloop query="q">
                <div class="col-md-4">
                    <div class="card text-center border-0 shadow-sm">
                        <div class="card-body py-3">
                            <div class="fw-bold">#encodeForHTML(q.type_name)#</div>
                            <div class="display-6 fw-bold
                                #q.remaining_days LTE 2 ? 'text-danger' : 'text-success'#">
                                #q.remaining_days#
                            </div>
                            <small class="text-muted">remaining of #q.max_days# days</small>
                            <div class="progress mt-2" style="height:6px;">
                                <div class="progress-bar
                                    #q.remaining_days LTE 2 ? 'bg-danger' : 'bg-success'#"
                                    style="width:#(q.used_days/q.max_days)*100#%">
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </cfloop>
            </cfoutput>
            </cfsavecontent>

            <cfset jsonRes(true,"",{ "html": local.html })>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>