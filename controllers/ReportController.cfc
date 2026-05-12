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

    <cffunction name="requireVendor" access="private" returntype="void" output="false">
        <cfif NOT structKeyExists(session,"user_id") OR session.role_name NEQ "vendor">
            <cfset jsonRes(false, "Unauthorized")>
        </cfif>
    </cffunction>

    <!--- ── Collect URL filters into a clean struct ── --->
    <cffunction name="getFilters" access="private" returntype="struct" output="false">
        <cfreturn {
            report_type : structKeyExists(url,"report_type") ? trim(url.report_type) : "",
            date_from   : structKeyExists(url,"date_from")   ? trim(url.date_from)   : "",
            date_to     : structKeyExists(url,"date_to")     ? trim(url.date_to)     : "",
            status      : structKeyExists(url,"status")      ? trim(url.status)      : "",
            category_id : structKeyExists(url,"category_id") ? trim(url.category_id) : ""
        }>
    </cffunction>

    <!--- ── Route to correct model method ── --->
    <cffunction name="fetchData" access="private" returntype="query" output="false">
        <cfargument name="f"     type="struct"  required="true"> <!--- filters --->
        <cfargument name="model" type="any"     required="true">

        <cfswitch expression="#arguments.f.report_type#">
            <cfcase value="orders">
                <cfreturn arguments.model.getOrders(
                    vendor_id = session.user_id,
                    date_from = arguments.f.date_from,
                    date_to   = arguments.f.date_to,
                    status    = arguments.f.status
                )>
            </cfcase>
            <cfcase value="products">
                <cfreturn arguments.model.getProducts(
                    vendor_id   = session.user_id,
                    date_from   = arguments.f.date_from,
                    date_to     = arguments.f.date_to,
                    category_id = arguments.f.category_id
                )>
            </cfcase>
            <cfcase value="categories">
                <cfreturn arguments.model.getCategories(
                    vendor_id = session.user_id,
                    date_from = arguments.f.date_from,
                    date_to   = arguments.f.date_to
                )>
            </cfcase>
            <cfcase value="scheduled_orders">
                <cfreturn arguments.model.getScheduledOrders(
                    vendor_id = session.user_id,
                    date_from = arguments.f.date_from,
                    date_to   = arguments.f.date_to
                )>
            </cfcase>
            <cfcase value="customers">
                <cfreturn arguments.model.getCustomers(
                    vendor_id = session.user_id,
                    date_from = arguments.f.date_from,
                    date_to   = arguments.f.date_to
                )>
            </cfcase>
            <cfcase value="revenue">
                <cfreturn arguments.model.getRevenue(
                    vendor_id = session.user_id,
                    date_from = arguments.f.date_from,
                    date_to   = arguments.f.date_to,
                    status    = arguments.f.status
                )>
            </cfcase>
            <cfdefaultcase>
                <cfreturn queryNew("")>
            </cfdefaultcase>
        </cfswitch>
    </cffunction>

    <!--- ── Title map ── --->
    <cffunction name="getTitle" access="private" returntype="string" output="false">
        <cfargument name="report_type" type="string" required="true">
        <cfset var titles = {
            orders           : "Orders Report",
            products         : "Products Report",
            categories       : "Categories Report",
            scheduled_orders : "Scheduled Orders Report",
            customers        : "Customers Report",
            revenue          : "Revenue Summary Report"
        }>
        <cfreturn structKeyExists(titles, arguments.report_type) ? titles[arguments.report_type] : "Report">
    </cffunction>

    <!--- ── Meta string ── --->
    <cffunction name="getMeta" access="private" returntype="string" output="false">
        <cfargument name="f"           type="struct"  required="true">
        <cfargument name="recordCount" type="numeric" required="true">
        <cfset var datePart = "">
        <cfif len(arguments.f.date_from) AND len(arguments.f.date_to)>
            <cfset datePart = "From " & dateFormat(arguments.f.date_from,"dd-mmm-yyyy") & " to " & dateFormat(arguments.f.date_to,"dd-mmm-yyyy")>
        <cfelseif len(arguments.f.date_from)>
            <cfset datePart = "From " & dateFormat(arguments.f.date_from,"dd-mmm-yyyy")>
        <cfelseif len(arguments.f.date_to)>
            <cfset datePart = "Until " & dateFormat(arguments.f.date_to,"dd-mmm-yyyy")>
        <cfelse>
            <cfset datePart = "All time">
        </cfif>
        <cfreturn datePart & " - " & arguments.recordCount & " records">
    </cffunction>

    <!---  HTML TABLE --->
    <cffunction name="buildTableHTML" access="private" returntype="string" output="false">
        <cfargument name="report_type" type="string" required="true">
        <cfargument name="q"           type="query"  required="true">

        <!--- Style constants — ## escapes the # inside cfoutput --->
        <cfset var H  = "background:##1a1a2e;color:##ffffff;">
        <cfset var TP = "padding:7px;">
        <cfset var TD = "padding:6px;border-bottom:1px solid ##eeeeee;">

        <cfsavecontent variable="local.out">
        <cfoutput>
        <cfif arguments.q.recordCount EQ 0>
            <p style="text-align:center;color:##888888;padding:30px;">
                No records found for the selected filters.
            </p>
        <cfelse>

            <!--- ══ ORDERS ══ --->
            <cfif arguments.report_type EQ "orders">
                <cfset local.totFinal = 0>
                <cfset local.totDisc  = 0>
                <cfloop query="arguments.q">
                    <cfset local.totFinal += val(arguments.q.final_amount)>
                    <cfset local.totDisc  += val(arguments.q.discount_amount)>
                </cfloop>
                <table style="width:100%;border-collapse:collapse;font-size:11px;">
                <thead>
                    <tr style="#H#">
                        <th style="#TP#">ID</th>
                        <th style="#TP#text-align:left;">Customer</th>
                        <th style="#TP#text-align:left;">Product</th>
                        <th style="#TP#text-align:center;">Qty</th>
                        <th style="#TP#text-align:right;">Price</th>
                        <th style="#TP#text-align:right;">Total</th>
                        <th style="#TP#text-align:right;">Discount</th>
                        <th style="#TP#text-align:right;">Final</th>
                        <th style="#TP#text-align:center;">Status</th>
                        <th style="#TP#text-align:left;">Date</th>
                    </tr>
                </thead>
                <tbody>
                <cfloop query="arguments.q">
                    <cfset local.bg = (arguments.q.currentRow MOD 2 EQ 0) ? "##f8f9fa" : "##ffffff">
                    <tr style="background:#local.bg#;">
                        <td style="#TD#text-align:center;">#arguments.q.id#</td>
                        <td style="#TD#">#encodeForHTML(arguments.q.customer_name)#</td>
                        <td style="#TD#">#encodeForHTML(arguments.q.product_name)#</td>
                        <td style="#TD#text-align:center;">#arguments.q.quantity#</td>
                        <td style="#TD#text-align:right;">#numberFormat(arguments.q.price,'0.00')#</td>
                        <td style="#TD#text-align:right;">#numberFormat(arguments.q.total_amount,'0.00')#</td>
                        <td style="#TD#text-align:right;">#numberFormat(arguments.q.discount_amount,'0.00')#</td>
                        <td style="#TD#text-align:right;font-weight:bold;">#numberFormat(arguments.q.final_amount,'0.00')#</td>
                        <td style="#TD#text-align:center;">
                            <cfif arguments.q.status EQ "completed">
                                <span style="color:green;font-weight:bold;">Completed</span>
                            <cfelseif arguments.q.status EQ "cancelled">
                                <span style="color:red;">Cancelled</span>
                            <cfelse>
                                <span style="color:darkorange;">Pending</span>
                            </cfif>
                        </td>
                        <td style="#TD#">#dateFormat(arguments.q.created_at,'dd-mmm-yy')#</td>
                    </tr>
                </cfloop>
                </tbody>
                <tfoot>
                    <tr style="#H#font-weight:bold;">
                        <td colspan="7" style="#TP#text-align:right;">
                            Totals (#arguments.q.recordCount# orders):
                        </td>
                        <td style="#TP#text-align:right;">#numberFormat(local.totFinal,'0.00')#</td>
                        <td colspan="2"></td>
                    </tr>
                </tfoot>
                </table>

            <!--- ══ PRODUCTS ══ --->
            <cfelseif arguments.report_type EQ "products">
                <table style="width:100%;border-collapse:collapse;font-size:11px;">
                <thead>
                    <tr style="#H#">
                        <th style="#TP#">No.</th>
                        <th style="#TP#text-align:left;">Product</th>
                        <th style="#TP#text-align:left;">Category</th>
                        <th style="#TP#text-align:right;">Price</th>
                        <th style="#TP#text-align:center;">Stock</th>
                        <th style="#TP#text-align:center;">Expiry</th>
                        <th style="#TP#text-align:center;">Status</th>
                        <th style="#TP#text-align:left;">Created</th>
                    </tr>
                </thead>
                <tbody>
                <cfloop query="arguments.q">
                    <cfset local.bg  = (arguments.q.currentRow MOD 2 EQ 0) ? "##f8f9fa" : "##ffffff">
                    <cfset local.stk = (arguments.q.stock LTE 5) ? "color:red;font-weight:bold;" : "">
                    <tr style="background:#local.bg#;">
                        <td style="#TD#text-align:center;">#arguments.q.currentRow#</td>
                        <td style="#TD#">#encodeForHTML(arguments.q.product_name)#</td>
                        <td style="#TD#">#encodeForHTML(arguments.q.category_name)#</td>
                        <td style="#TD#text-align:right;">#numberFormat(arguments.q.price,'0.00')#</td>
                        <td style="#TD#text-align:center;#local.stk#">#arguments.q.stock#</td>
                        <td style="#TD#text-align:center;">
                            #len(trim(arguments.q.expiry_date)) ? dateFormat(arguments.q.expiry_date,'dd-mmm-yy') : '-'#
                        </td>
                        <td style="#TD#text-align:center;">
                            <cfif arguments.q.is_active>
                                <span style="color:green;">Active</span>
                            <cfelse>
                                <span style="color:red;">Blocked</span>
                            </cfif>
                        </td>
                        <td style="#TD#">#dateFormat(arguments.q.created_at,'dd-mmm-yy')#</td>
                    </tr>
                </cfloop>
                </tbody>
                </table>

            <!--- ══ CATEGORIES ══ --->
            <cfelseif arguments.report_type EQ "categories">
                <table style="width:100%;border-collapse:collapse;font-size:11px;">
                <thead>
                    <tr style="#H#">
                        <th style="#TP#">No.</th>
                        <th style="#TP#text-align:left;">Category</th>
                        <th style="#TP#text-align:left;">Description</th>
                        <th style="#TP#text-align:center;">Products</th>
                        <th style="#TP#text-align:center;">Status</th>
                        <th style="#TP#text-align:left;">Created</th>
                    </tr>
                </thead>
                <tbody>
                <cfloop query="arguments.q">
                    <cfset local.bg = (arguments.q.currentRow MOD 2 EQ 0) ? "##f8f9fa" : "##ffffff">
                    <tr style="background:#local.bg#;">
                        <td style="#TD#text-align:center;">#arguments.q.currentRow#</td>
                        <td style="#TD#">#encodeForHTML(arguments.q.category_name)#</td>
                        <td style="#TD#">#encodeForHTML(arguments.q.description)#</td>
                        <td style="#TD#text-align:center;">#arguments.q.product_count#</td>
                        <td style="#TD#text-align:center;">
                            <cfif arguments.q.is_active>
                                <span style="color:green;">Active</span>
                            <cfelse>
                                <span style="color:red;">Inactive</span>
                            </cfif>
                        </td>
                        <td style="#TD#">#dateFormat(arguments.q.created_at,'dd-mmm-yy')#</td>
                    </tr>
                </cfloop>
                </tbody>
                </table>

            <!--- ══ SCHEDULED ORDERS ══ --->
            <cfelseif arguments.report_type EQ "scheduled_orders">
                <table style="width:100%;border-collapse:collapse;font-size:11px;">
                <thead>
                    <tr style="#H#">
                        <th style="#TP#">No.</th>
                        <th style="#TP#text-align:left;">Customer</th>
                        <th style="#TP#text-align:left;">Product</th>
                        <th style="#TP#text-align:center;">Qty</th>
                        <th style="#TP#text-align:center;">Reserved</th>
                        <th style="#TP#text-align:center;">Day/Month</th>
                        <th style="#TP#text-align:center;">Start Date</th>
                        <th style="#TP#text-align:center;">Status</th>
                    </tr>
                </thead>
                <tbody>
                <cfloop query="arguments.q">
                    <cfset local.bg = (arguments.q.currentRow MOD 2 EQ 0) ? "##f8f9fa" : "##ffffff">
                    <tr style="background:#local.bg#;">
                        <td style="#TD#text-align:center;">#arguments.q.currentRow#</td>
                        <td style="#TD#">#encodeForHTML(arguments.q.customer_name)#</td>
                        <td style="#TD#">#encodeForHTML(arguments.q.product_name)#</td>
                        <td style="#TD#text-align:center;">#arguments.q.quantity#</td>
                        <td style="#TD#text-align:center;">#arguments.q.reserved_qty#</td>
                        <td style="#TD#text-align:center;">#arguments.q.day_of_month#</td>
                        <td style="#TD#text-align:center;">#dateFormat(arguments.q.start_date,'dd-mmm-yy')#</td>
                        <td style="#TD#text-align:center;">
                            <cfif arguments.q.is_active>
                                <span style="color:green;">Active</span>
                            <cfelse>
                                <span style="color:red;">Inactive</span>
                            </cfif>
                        </td>
                    </tr>
                </cfloop>
                </tbody>
                </table>

            <!--- ══ CUSTOMERS ══ --->
            <cfelseif arguments.report_type EQ "customers">
                <table style="width:100%;border-collapse:collapse;font-size:11px;">
                <thead>
                    <tr style="#H#">
                        <th style="#TP#">No.</th>
                        <th style="#TP#text-align:left;">Customer</th>
                        <th style="#TP#text-align:left;">Email</th>
                        <th style="#TP#text-align:center;">Orders</th>
                        <th style="#TP#text-align:right;">Total Spent</th>
                        <th style="#TP#text-align:left;">Last Order</th>
                    </tr>
                </thead>
                <tbody>
                <cfloop query="arguments.q">
                    <cfset local.bg = (arguments.q.currentRow MOD 2 EQ 0) ? "##f8f9fa" : "##ffffff">
                    <tr style="background:#local.bg#;">
                        <td style="#TD#text-align:center;">#arguments.q.currentRow#</td>
                        <td style="#TD#">#encodeForHTML(arguments.q.customer_name)#</td>
                        <td style="#TD#">#encodeForHTML(arguments.q.email)#</td>
                        <td style="#TD#text-align:center;">#arguments.q.total_orders#</td>
                        <td style="#TD#text-align:right;font-weight:bold;">#numberFormat(arguments.q.total_spent,'0.00')#</td>
                        <td style="#TD#">#dateFormat(arguments.q.last_order_date,'dd-mmm-yy')#</td>
                    </tr>
                </cfloop>
                </tbody>
                </table>

            <!--- ══ REVENUE ══ --->
            <cfelseif arguments.report_type EQ "revenue">
                <cfset local.grandNet   = 0>
                <cfset local.grandGross = 0>
                <cfloop query="arguments.q">
                    <cfset local.grandNet   += val(arguments.q.net_revenue)>
                    <cfset local.grandGross += val(arguments.q.gross_revenue)>
                </cfloop>
                <table style="width:100%;border-collapse:collapse;font-size:11px;">
                <thead>
                    <tr style="#H#">
                        <th style="#TP#text-align:left;">Product</th>
                        <th style="#TP#text-align:left;">Category</th>
                        <th style="#TP#text-align:center;">Orders</th>
                        <th style="#TP#text-align:center;">Units Sold</th>
                        <th style="#TP#text-align:right;">Gross</th>
                        <th style="#TP#text-align:right;">Discount</th>
                        <th style="#TP#text-align:right;">Net Revenue</th>
                    </tr>
                </thead>
                <tbody>
                <cfloop query="arguments.q">
                    <cfset local.bg = (arguments.q.currentRow MOD 2 EQ 0) ? "##f8f9fa" : "##ffffff">
                    <tr style="background:#local.bg#;">
                        <td style="#TD#">#encodeForHTML(arguments.q.product_name)#</td>
                        <td style="#TD#">#encodeForHTML(arguments.q.category_name)#</td>
                        <td style="#TD#text-align:center;">#arguments.q.total_orders#</td>
                        <td style="#TD#text-align:center;">#arguments.q.units_sold#</td>
                        <td style="#TD#text-align:right;">#numberFormat(arguments.q.gross_revenue,'0.00')#</td>
                        <td style="#TD#text-align:right;">#numberFormat(arguments.q.total_discount,'0.00')#</td>
                        <td style="#TD#text-align:right;font-weight:bold;color:green;">#numberFormat(arguments.q.net_revenue,'0.00')#</td>
                    </tr>
                </cfloop>
                </tbody>
                <tfoot>
                    <tr style="#H#font-weight:bold;">
                        <td colspan="4" style="#TP#text-align:right;">Grand Total:</td>
                        <td style="#TP#text-align:right;">#numberFormat(local.grandGross,'0.00')#</td>
                        <td></td>
                        <td style="#TP#text-align:right;">#numberFormat(local.grandNet,'0.00')#</td>
                    </tr>
                </tfoot>
                </table>
            </cfif>

        </cfif>
        </cfoutput>
        </cfsavecontent>

        <cfreturn local.out>
    </cffunction>

    <cffunction name="getPreview" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireVendor()>
        <cftry>
            <cfset var f     = getFilters()>
            <cfset var model = createObject("component","models.Report")>
            <cfset var q     = fetchData(f, model)>
            <cfset var html  = buildTableHTML(f.report_type, q)>

            <cfset jsonRes(true, "", {
                "title" : getTitle(f.report_type),
                "meta"  : getMeta(f, q.recordCount),
                "html"  : html
            })>
        <cfcatch>
            <cfset jsonRes(false, "Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="generatePDF" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfif NOT structKeyExists(session,"user_id") OR session.role_name NEQ "vendor">
            <cfabort>
        </cfif>
        <cftry>
            <cfset var f        = getFilters()>
            <cfset var model    = createObject("component","models.Report")>
            <cfset var q        = fetchData(f, model)>
            <cfset var html     = buildTableHTML(f.report_type, q)>
            <cfset var title    = getTitle(f.report_type)>
            <cfset var bizName  = model.getVendorName(session.user_id)>
            <cfset var genAt    = dateFormat(now(),'dd-mmm-yyyy') & " " & timeFormat(now(),'HH:mm')>
            <cfset var fileName = title & " - " & dateFormat(now(),'dd-mmm-yyyy') & ".pdf">

            <cfdocument format="PDF"
                        name="pdfBinary"
                        orientation="landscape"
                        marginTop="1.5" marginBottom="1.5"
                        marginLeft="1.5" marginRight="1.5"
                        unit="cm" localUrl="true">
                <html>
                <head>
                <meta charset="utf-8">
                <style>
                    body { font-family:Arial,sans-serif; font-size:11px; color:##333333; }
                    .rh  { margin-bottom:14px; border-bottom:2px solid ##1a1a2e; padding-bottom:8px; }
                    .rh h2 { margin:0 0 4px; font-size:15px; color:##1a1a2e; }
                    .rh p  { margin:0; font-size:10px; color:##666666; }
                    .rf  { margin-top:14px; font-size:9px; color:##999999;
                           text-align:center; border-top:1px solid ##dddddd; padding-top:6px; }
                </style>
                </head>
                <body>
                    <div class="rh">
                        <cfoutput>
                        <h2>#encodeForHTML(title)#</h2>
                        <p>
                            Vendor: #encodeForHTML(bizName)# &nbsp;|&nbsp;
                            #getMeta(f, q.recordCount)# &nbsp;|&nbsp;
                            Generated: #genAt#
                        </p>
                        </cfoutput>
                    </div>

                    <cfoutput>#html#</cfoutput>

                    <div class="rf">
                        <cfoutput>#encodeForHTML(title)# | #encodeForHTML(bizName)#
                        | Page <cfdocumentitem type="pagenumber"> of
                        <cfdocumentitem type="totalpages"></cfoutput>
                    </div>
                </body>
                </html>
            </cfdocument>

            <cfheader name="Content-Disposition"
                      value="attachment; filename=""#fileName#""">
            <cfcontent type="application/pdf" variable="#pdfBinary#" reset="true">
        <cfcatch>
            <cfoutput>PDF Error: #cfcatch.message#</cfoutput>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>