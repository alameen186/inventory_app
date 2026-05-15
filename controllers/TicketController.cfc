<cfcomponent output="false">

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
        <cfabort>
    </cffunction>

    <cffunction name="requireAuth" access="private" returntype="void" output="false">
        <cfif NOT structKeyExists(session,"user_id")>
            <cfset jsonRes(false,"Unauthorized")>
        </cfif>
    </cffunction>

    <cffunction name="submit" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireAuth()>
        <cftry>
            <!--- Validate --->
            <cfif NOT structKeyExists(form,"subject") OR NOT len(trim(form.subject))>
                <cfset jsonRes(false,"Subject is required")>
            </cfif>
            <cfif NOT structKeyExists(form,"description") OR len(trim(form.description)) LT 10>
                <cfset jsonRes(false,"Description must be at least 10 characters")>
            </cfif>

            <cfset var model    = createObject("component","models.Ticket")>
            <cfset var result   = model.create(
                user_id     = session.user_id,
                page_name   = structKeyExists(form,"page_name")  ? trim(form.page_name)  : "General",
                subject     = trim(form.subject),
                description = trim(form.description),
                priority    = structKeyExists(form,"priority")   ? trim(form.priority)   : "medium"
            )>

            <cfif NOT result.success>
                <cfset jsonRes(false, result.message)>
            </cfif>

            <cfset user = model.getuser(session.user_id)>
            <cfset var userName  = user.first_name & " " & user.last_name>
            <cfset var adminEmail = model.getAdminEmail()>

            <!--- Send email to admin --->
            <cftry>
                <cfif len(adminEmail)>
                    <cfmail
                        to      = "#adminEmail#"
                        from    = "ameenalalameen8086@gmail.com"
                        subject = "New Support Ticket [#result.ticket_ref#] — #trim(form.subject)#"
                        type    = "html"
                        server  = "smtp.gmail.com"
                        username= "ameenalalameen8086@gmail.com"
                        password= "zxqe zcle jnbl mgdf"
                        port    = "587"
                        useTLS  = "true">
                        <!DOCTYPE html>
                        <html>
                        <body style="font-family:Arial,sans-serif;background:##f4f4f4;padding:20px;">
                        <table width="600" style="background:##fff;border-radius:8px;overflow:hidden;
                               box-shadow:0 2px 8px rgba(0,0,0,0.08);margin:0 auto;">
                            <tr>
                                <td style="background:##1a1a2e;padding:20px 28px;">
                                    <h2 style="color:##fff;margin:0;font-size:20px;">
                                        New Support Ticket
                                    </h2>
                                    <p style="color:##aab;margin:4px 0 0;font-size:13px;">
                                        <cfoutput>#result.ticket_ref#</cfoutput>
                                    </p>
                                </td>
                            </tr>
                            <tr>
                                <td style="padding:24px 28px;">
                                    <table width="100%" style="font-size:14px;border-collapse:collapse;">
                                        <tr>
                                            <td style="padding:8px 12px;color:##666;width:35%;
                                                        border-bottom:1px solid ##eee;">From</td>
                                            <td style="padding:8px 12px;font-weight:600;
                                                        border-bottom:1px solid ##eee;">
                                                <cfoutput>#encodeForHTML(userName)# (#encodeForHTML(user.email)#)</cfoutput>
                                            </td>
                                        </tr>
                                        <tr style="background:##fafafa;">
                                            <td style="padding:8px 12px;color:##666;
                                                        border-bottom:1px solid ##eee;">Page</td>
                                            <td style="padding:8px 12px;font-weight:600;
                                                        border-bottom:1px solid ##eee;">
                                                <cfoutput>#encodeForHTML(structKeyExists(form,"page_name") ? form.page_name : "General")#</cfoutput>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td style="padding:8px 12px;color:##666;
                                                        border-bottom:1px solid ##eee;">Subject</td>
                                            <td style="padding:8px 12px;font-weight:600;
                                                        border-bottom:1px solid ##eee;">
                                                <cfoutput>#encodeForHTML(trim(form.subject))#</cfoutput>
                                            </td>
                                        </tr>
                                        <tr style="background:##fafafa;">
                                            <td style="padding:8px 12px;color:##666;
                                                        border-bottom:1px solid ##eee;">Priority</td>
                                            <td style="padding:8px 12px;font-weight:600;
                                                        border-bottom:1px solid ##eee;">
                                                <cfoutput>#ucase(structKeyExists(form,"priority") ? form.priority : "medium")#</cfoutput>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td style="padding:8px 12px;color:##666;">Description</td>
                                            <td style="padding:8px 12px;">
                                                <cfoutput>#encodeForHTML(trim(form.description))#</cfoutput>
                                            </td>
                                        </tr>
                                    </table>
                                </td>
                            </tr>
                            <tr>
                                <td style="padding:14px 28px;background:##f8f9fa;
                                            text-align:center;font-size:12px;color:##999;">
                                    Login to admin panel to manage this ticket.
                                </td>
                            </tr>
                        </table>
                        </body>
                        </html>
                    </cfmail>
                </cfif>
            <cfcatch></cfcatch>
            </cftry>

            <cfset jsonRes(true,
                "Ticket raised successfully! Your reference: " & result.ticket_ref,
                { "ticket_ref": result.ticket_ref }
            )>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- ── GET USER TICKETS ── --->
    <cffunction name="getUserTickets" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireAuth()>
        <cftry>
            <cfset var model = createObject("component","models.Ticket")>
            <cfset var page  = structKeyExists(url,"p") AND val(url.p) GT 0 ? val(url.p) : 1>
            <cfset var limit = 10>
            <cfset var q     = model.getForUser(session.user_id, page, limit)>
            <cfset var total = model.countForUser(session.user_id)>
            <cfset var totalPages = ceiling(total / limit)>

            <cfsavecontent variable="local.html">
            <cfoutput>
            <cfif q.recordCount EQ 0>
                <tr>
                    <td colspan="6" class="text-center text-muted py-5">
                        No tickets raised yet.
                    </td>
                </tr>
            <cfelse>
                <cfloop query="q">
                <tr>
                    <td>
                        <span class="fw-semibold text-primary">#q.ticket_ref#</span>
                    </td>
                    <td>#encodeForHTML(q.page_name)#</td>
                    <td>#encodeForHTML(q.subject)#</td>
                    <td>
                        <cfif q.priority EQ "high">
                            <span class="badge bg-danger">High</span>
                        <cfelseif q.priority EQ "medium">
                            <span class="badge bg-warning text-dark">Medium</span>
                        <cfelse>
                            <span class="badge bg-secondary">Low</span>
                        </cfif>
                    </td>
                    <td>
                        <cfif q.status EQ "pending">
                            <span class="badge bg-warning text-dark">Pending</span>
                        <cfelseif q.status EQ "in_progress">
                            <span class="badge bg-info text-dark">In Progress</span>
                        <cfelseif q.status EQ "resolved">
                            <span class="badge bg-success">Resolved</span>
                        <cfelse>
                            <span class="badge bg-secondary">Closed</span>
                        </cfif>
                        <cfif len(trim(q.admin_note))>
                            <br>
                            <small class="text-muted fst-italic mt-1 d-block">
                                Note: #encodeForHTML(q.admin_note)#
                            </small>
                        </cfif>
                    </td>
                    <td>
                        <small class="text-muted">#dateFormat(q.created_at,"dd-mmm-yy")#</small>
                    </td>
                </tr>
                </cfloop>
            </cfif>
            </cfoutput>
            </cfsavecontent>

            <!--- Pagination --->
            <cfsavecontent variable="local.pagination">
            <cfoutput>
            <cfif totalPages GT 1>
                <cfset var gSize = 4>
                <cfset var pGrp  = ceiling(page / gSize)>
                <cfset var sPage = (pGrp - 1) * gSize + 1>
                <cfset var ePage = min(sPage + gSize - 1, totalPages)>
                <cfif sPage GT 1>
                    <button class="tktPageBtn btn btn-outline-primary btn-sm"
                            data-page="#sPage-1#">Prev</button>
                </cfif>
                <cfloop from="#sPage#" to="#ePage#" index="i">
                    <button class="tktPageBtn btn btn-sm #i EQ page ? 'btn-primary' : 'btn-outline-primary'#"
                            data-page="#i#">#i#</button>
                </cfloop>
                <cfif ePage LT totalPages>
                    <button class="tktPageBtn btn btn-outline-primary btn-sm"
                            data-page="#ePage+1#">Next</button>
                </cfif>
            </cfif>
            </cfoutput>
            </cfsavecontent>

            <cfset jsonRes(true,"",{ "html": local.html, "pagination": local.pagination })>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- ── GET ALL TICKETS  ── --->
    <cffunction name="getAll" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireAuth()>
        <cfif NOT structKeyExists(session,"role_id") OR session.role_id NEQ 1>
            <cfset jsonRes(false,"Admin only")>
        </cfif>
        <cftry>
            <cfset var model    = createObject("component","models.Ticket")>
            <cfset var page     = structKeyExists(url,"p")        AND val(url.p) GT 0  ? val(url.p) : 1>
            <cfset var status   = structKeyExists(url,"status")   ? trim(url.status)   : "">
            <cfset var priority = structKeyExists(url,"priority") ? trim(url.priority) : "">
            <cfset var search   = structKeyExists(url,"search")   ? trim(url.search)   : "">
            <cfset var limit    = 15>
            <cfset var q        = model.getAll(status, priority, search, page, limit)>
            <cfset var total    = model.countAll(status, priority, search)>
            <cfset var totalPages = ceiling(total / limit)>

            <cfsavecontent variable="local.html">
            <cfoutput>
            <cfif q.recordCount EQ 0>
                <tr>
                    <td colspan="8" class="text-center text-muted py-5">No tickets found.</td>
                </tr>
            <cfelse>
                <cfloop query="q">
                <tr>
                    <td><span class="fw-semibold text-primary small">#q.ticket_ref#</span></td>
                    <td>
                        <div class="fw-semibold small">#encodeForHTML(q.user_name)#</div>
                        <small class="text-muted">#encodeForHTML(q.user_email)#</small>
                    </td>
                    <td><small>#encodeForHTML(q.page_name)#</small></td>
                    <td>
                        <div class="small fw-semibold">#encodeForHTML(q.subject)#</div>
                        <small class="text-muted">#left(encodeForHTML(q.description),60)#...</small>
                    </td>
                    <td>
                        <cfif q.priority EQ "high">
                            <span class="badge bg-danger">High</span>
                        <cfelseif q.priority EQ "medium">
                            <span class="badge bg-warning text-dark">Medium</span>
                        <cfelse>
                            <span class="badge bg-secondary">Low</span>
                        </cfif>
                    </td>
                    <td>
                        <cfif q.status EQ "pending">
                            <span class="badge bg-warning text-dark">Pending</span>
                        <cfelseif q.status EQ "in_progress">
                            <span class="badge bg-info text-dark">In Progress</span>
                        <cfelseif q.status EQ "resolved">
                            <span class="badge bg-success">Resolved</span>
                        <cfelse>
                            <span class="badge bg-secondary">Closed</span>
                        </cfif>
                    </td>
                    <td><small class="text-muted">#dateFormat(q.created_at,"dd-mmm-yy")#</small></td>
                    <td>
                        <button class="btn btn-sm btn-outline-primary manageTicketBtn"
                                data-id="#q.id#"
                                data-ref="#q.ticket_ref#"
                                data-status="#q.status#"
                                data-note="#encodeForHTMLAttribute(q.admin_note)#"
                                data-subject="#encodeForHTMLAttribute(q.subject)#"
                                data-desc="#encodeForHTMLAttribute(q.description)#">
                            Manage
                        </button>
                    </td>
                </tr>
                </cfloop>
            </cfif>
            </cfoutput>
            </cfsavecontent>

            <cfsavecontent variable="local.pagination">
            <cfoutput>
            <cfif totalPages GT 1>
                <cfset var gSize = 4>
                <cfset var pGrp  = ceiling(page / gSize)>
                <cfset var sPage = (pGrp - 1) * gSize + 1>
                <cfset var ePage = min(sPage + gSize - 1, totalPages)>
                <cfif sPage GT 1>
                    <button class="adminTktPageBtn btn btn-outline-primary btn-sm"
                            data-page="#sPage-1#">Prev</button>
                </cfif>
                <cfloop from="#sPage#" to="#ePage#" index="i">
                    <button class="adminTktPageBtn btn btn-sm #i EQ page ? 'btn-primary' : 'btn-outline-primary'#"
                            data-page="#i#">#i#</button>
                </cfloop>
                <cfif ePage LT totalPages>
                    <button class="adminTktPageBtn btn btn-outline-primary btn-sm"
                            data-page="#ePage+1#">Next</button>
                </cfif>
            </cfif>
            </cfoutput>
            </cfsavecontent>

            <cfset jsonRes(true,"",{ "html": local.html, "pagination": local.pagination, "total": total })>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="updateStatus" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireAuth()>
        <cfif NOT structKeyExists(session,"role_id") OR session.role_id NEQ 1>
            <cfset jsonRes(false,"Admin only")>
        </cfif>
        <cftry>
            <cfset var model  = createObject("component","models.Ticket")>
            <cfset var result = model.updateStatus(
                id         = val(form.id),
                status     = trim(form.status),
                admin_note = structKeyExists(form,"admin_note") ? trim(form.admin_note) : ""
            )>
            <cfset jsonRes(result.success, result.success ? "Ticket updated" : result.message)>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>