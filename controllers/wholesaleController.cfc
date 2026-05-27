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
        <cfif NOT structKeyExists(session,"user_id")
              OR NOT structKeyExists(session,"role_name")
              OR session.role_name NEQ "vendor">
            <cfset jsonRes(false,"Vendor access required")>
        </cfif>
    </cffunction>

    <!---  GET DISTRICTS  --->
    <cffunction name="getDistricts" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireVendor()>
        <cftry>
            <cfset var model     = createObject("component","models.WholesaleOrder")>
            <cfset var districts = model.getDistricts()>
            <cfset jsonRes(true,"",districts)>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <!---  SEARCH WHOLESALE-ELIGIBLE PRODUCTS--->
    <cffunction name="searchProducts" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireVendor()>
        <cftry>
            <cfset var model    = createObject("component","models.WholesaleOrder")>
            <cfset var keyword  = structKeyExists(url,"keyword") ? trim(url.keyword) : "">
            <cfset var products = model.getWholesaleProducts(session.user_id, keyword)>
            <cfset var list     = []>

            <cfloop query="products">
                <cfset arrayAppend(list, {
                    "id"               : products.id,
                    "product_name"     : products.product_name,
                    "price"            : products.price,
                    "wholesale_price"  : products.wholesale_price,
                    "min_wholesale_qty": products.min_wholesale_qty,
                    "stock"            : products.stock,
                    "category_name"    : products.category_name
                })>
            </cfloop>

            <cfset jsonRes(true,"",list)>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- CREATE WHOLESALE ORDER--->
    <cffunction name="createOrder" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireVendor()>
        <cftry>

            <cfif NOT structKeyExists(form,"first_name") OR NOT len(trim(form.first_name))>
                <cfset jsonRes(false,"Customer first name is required")>
            </cfif>
            <cfif NOT structKeyExists(form,"email") OR NOT len(trim(form.email))>
                <cfset jsonRes(false,"Customer email is required")>
            </cfif>
            <cfif NOT isValid("email", trim(form.email))>
                <cfset jsonRes(false,"Invalid customer email")>
            </cfif>
            <cfif NOT structKeyExists(form,"phone") OR NOT len(trim(form.phone))>
                <cfset jsonRes(false,"Customer phone is required")>
            </cfif>
            <cfif NOT structKeyExists(form,"assigned_staff_id") OR NOT val(form.assigned_staff_id)>
                <cfset jsonRes(false,"Please assign a staff member")>
            </cfif>
            <cfif NOT structKeyExists(form,"vehicle_id") OR NOT val(form.vehicle_id)>
                <cfset jsonRes(false,"Please assign a vehicle")>
            </cfif>
            <cfif NOT structKeyExists(form,"zone_id") OR NOT val(form.zone_id)>
                <cfset jsonRes(false,"Please select a delivery zone")>
            </cfif>
            <cfif NOT structKeyExists(form,"items") OR NOT len(trim(form.items))>
                <cfset jsonRes(false,"No items in the order")>
            </cfif>

            <!--- ── Validate zone and get fee from delivery_zones table ── --->
            <cfset var zoneModel   = createObject("component","models.DeliveryZone")>
            <cfset var zoneRow     = zoneModel.getById(val(form.zone_id), session.user_id)>
            <cfif zoneRow.recordCount EQ 0 OR zoneRow.is_active EQ 0>
                <cfset jsonRes(false,"Invalid or inactive delivery zone selected")>
            </cfif>
            <cfset var deliveryFee  = val(zoneRow.delivery_fee)>
            <cfset var districtName = zoneRow.place_name>   <!--- used as label in PDF/orders --->

            <!--- ── Parse items JSON ── --->
            <cfset var items = deserializeJSON(form.items)>
            <cfif NOT isArray(items) OR arrayLen(items) EQ 0>
                <cfset jsonRes(false,"Order must have at least one item")>
            </cfif>

            <!--- ── Stock check + total unit count ── --->
            <cfset var productModel = createObject("component","models.Product")>
            <cfset var totalUnits   = 0>

            <cfloop array="#items#" index="local.item">
                <cfif NOT structKeyExists(local.item,"product_id") OR NOT val(local.item.product_id)>
                    <cfset jsonRes(false,"Invalid product in order")>
                </cfif>
                <cfif NOT structKeyExists(local.item,"qty") OR val(local.item.qty) LTE 0>
                    <cfset jsonRes(false,"Invalid quantity for a product")>
                </cfif>
                <cfset var available = productModel.getStock(val(local.item.product_id))>
                <cfif val(local.item.qty) GT available>
                    <cfset jsonRes(false,"Not enough stock for <strong>#local.item.product_name#</strong>. Available: #available# units.")>
                </cfif>
                <cfset totalUnits += val(local.item.qty)>
            </cfloop>

            <!--- ── Vehicle capacity check ── --->
            <cfset var vehicleModel    = createObject("component","models.Vehicle")>
            <cfset var vehicleCapacity = vehicleModel.getCapacity(
                id        = val(form.vehicle_id),
                vendor_id = session.user_id
            )>
            <cfif vehicleCapacity GT 0 AND totalUnits GT vehicleCapacity>
                <cfset var overBy = totalUnits - vehicleCapacity>
                <cfset jsonRes(false,
                    "&##x1F69B; Vehicle overloaded! " &
                    "Capacity: <strong>#vehicleCapacity# units</strong> | " &
                    "Your order: <strong>#totalUnits# units</strong> | " &
                    "Over by: <strong>#overBy# units</strong>."
                )>
            </cfif>

            <!--- ── Get or create temp user ── --->
            <cfset var tempUserModel = createObject("component","models.TempUser")>
            <cfset var tempUserId    = tempUserModel.getOrCreateTempUser(
                vendor_id  = session.user_id,
                first_name = trim(form.first_name),
                last_name  = structKeyExists(form,"last_name") ? trim(form.last_name) : "",
                email      = trim(form.email)
            )>
            <cfif len(trim(form.phone))>
                <cfquery datasource="#application.dsn#">
                    UPDATE temp_users
                    SET phone = <cfqueryparam value="#trim(form.phone)#" cfsqltype="cf_sql_varchar">
                    WHERE id  = <cfqueryparam value="#tempUserId#"       cfsqltype="cf_sql_integer">
                </cfquery>
            </cfif>

            <!--- ── Create the order (district_name = zone place_name for compatibility) ── --->
            <cfset var wsModel = createObject("component","models.WholesaleOrder")>
            <cfset var result  = wsModel.createOrder(
                vendor_id         = session.user_id,
                temp_user_id      = tempUserId,
                assigned_staff_id = val(form.assigned_staff_id),
                vehicle_id        = val(form.vehicle_id),
                district_name     = districtName,
                delivery_fee      = deliveryFee,
                notes             = structKeyExists(form,"notes") ? trim(form.notes) : "",
                items             = items
            )>

            <!--- Also save zone_id on the order row --->
            <cfif result.success AND val(form.zone_id) GT 0>
                <cftry>
                    <cfquery datasource="#application.dsn#">
                        UPDATE wholesale_orders
                        SET zone_id = <cfqueryparam value="#val(form.zone_id)#" cfsqltype="cf_sql_integer">
                        WHERE id = <cfqueryparam value="#result.order_id#" cfsqltype="cf_sql_integer">
                    </cfquery>
                <cfcatch></cfcatch>
                </cftry>
            </cfif>

            <cfif NOT result.success>
                <cfset jsonRes(false,"Order failed: " & result.message)>
            </cfif>

            <!--- ── Notify staff ── --->
            <cftry>
                <cfset var notifModel = createObject("component","models.Notification")>
                <cfset notifModel.create(
                    user_id   = val(form.assigned_staff_id),
                    sender_id = session.user_id,
                    type      = "wholesale_assigned",
                    title     = "Wholesale Order Assigned",
                    message   = "You have been assigned wholesale order " & result.group_id &
                                " — Delivery to " & districtName,
                    link      = "index.cfm?page=dashboard&section=wholesaleOrders"
                )>
            <cfcatch></cfcatch>
            </cftry>

            <!--- ── PDF invoice (unchanged from original) ── --->
            <cftry>
<cfset var invoiceDir = expandPath("/assets/invoices/wholesale/")>
                <cfif NOT directoryExists(invoiceDir)>
                    <cfdirectory action="create" directory="#invoiceDir#">
                </cfif>
                <cfset var invoicePath = invoiceDir & "invoice_" & result.group_id & ".pdf">
                <cfset var orderQ      = wsModel.getById(result.order_id, session.user_id)>
                <cfset var itemsQ      = wsModel.getItems(result.order_id)>
                <cfdocument format="pdf" filename="#invoicePath#" overwrite="true">
                <cfoutput>
                <style>
                body{font-family:Arial;font-size:12px;}
                .tc{text-align:center;} .tr{text-align:right;}
                .header{border-bottom:2px solid ##1a1a2e;margin-bottom:15px;padding-bottom:10px;}
                .tbl{width:100%;border-collapse:collapse;margin-top:10px;}
                .tbl th{background:##1a1a2e;color:white;padding:8px;border:1px solid ##ccc;}
                .tbl td{border:1px solid ##ccc;padding:8px;}
                .info-tbl{width:100%;margin-bottom:10px;}
                .info-tbl td{padding:3px 6px;vertical-align:top;}
                .total-box{width:42%;float:right;margin-top:10px;border-collapse:collapse;}
                .total-box td{border:1px solid ##ccc;padding:6px 10px;}
                .delivery-row{background:##f0f7ff;}
                .grand-row{background:##e8f5e9;font-weight:bold;}
                .footer{margin-top:40px;font-size:10px;text-align:center;color:##777;}
                .ws-badge{background:##e8f5e9;color:##2e7d32;padding:2px 8px;border-radius:4px;font-size:11px;}
                </style>
                <div>
                    <div class="header tc">
                        <h2>INVENTORY STORE</h2>
                        <span class="ws-badge">WHOLESALE INVOICE</span>
                    </div>
                    <table class="info-tbl"><tr>
                        <td>
                            <strong>Invoice ID:</strong> #result.group_id#<br>
                            <strong>Date:</strong> #dateFormat(now(),"dd-mmm-yyyy")#<br>
                            <strong>Status:</strong> Pending
                        </td>
                        <td class="tr">
                            <strong>Bill To:</strong><br>
                            #encodeForHTML(trim(form.first_name))# #encodeForHTML(structKeyExists(form,"last_name") ? trim(form.last_name) : "")#<br>
                            #encodeForHTML(trim(form.email))#<br>
                            #encodeForHTML(trim(form.phone))#
                        </td>
                    </tr></table>
                    <table class="info-tbl" style="margin-bottom:10px;"><tr>
                        <td><strong>Staff:</strong> #encodeForHTML(orderQ.staff_name)#</td>
                        <td><strong>Vehicle:</strong> #encodeForHTML(orderQ.vehicle_name)# (#encodeForHTML(orderQ.vehicle_number)#)</td>
                        <td><strong>Delivery Zone:</strong> #encodeForHTML(districtName)#
                            (#zoneRow.distance_km# km &times; &##8377;#numberFormat(zoneRow.km_price,"0.00")#/km)</td>
                    </tr></table>
                    <table class="tbl">
                    <tr><th>Product</th><th class="tr">Unit Price</th><th class="tr">Qty</th><th class="tr">Total</th></tr>
                    <cfset var pdfSubtotal = 0>
                    <cfloop query="itemsQ">
                        <cfset var rowTotal = itemsQ.unit_price * itemsQ.qty>
                        <cfset pdfSubtotal += rowTotal>
                        <tr>
                            <td>#encodeForHTML(itemsQ.product_name)#</td>
                            <td class="tr">#numberFormat(itemsQ.unit_price,"0.00")#</td>
                            <td class="tr">#itemsQ.qty#</td>
                            <td class="tr">#numberFormat(rowTotal,"0.00")#</td>
                        </tr>
                    </cfloop>
                    </table>
                    <table class="total-box">
                    <tr><td>Subtotal</td><td class="tr">#numberFormat(pdfSubtotal,"0.00")#</td></tr>
                    <tr class="delivery-row">
                        <td>Delivery <i class="bi bi-truck"></i> #encodeForHTML(districtName)#</td>
                        <td class="tr">#numberFormat(deliveryFee,"0.00")#</td>
                    </tr>
                    <tr class="grand-row">
                        <td>Grand Total</td>
                        <td class="tr">#numberFormat(pdfSubtotal + deliveryFee,"0.00")#</td>
                    </tr>
                    </table>
                    <div style="clear:both;"></div>
                    <cfif len(trim(structKeyExists(form,"notes") ? form.notes : ""))>
                        <p style="margin-top:15px;"><strong>Notes:</strong> #encodeForHTML(trim(form.notes))#</p>
                    </cfif>
                    <div class="footer"><p>System generated wholesale invoice. No signature required.</p></div>
                </div>
                </cfoutput>
                </cfdocument>
            <cfcatch>
                <cflog file="wholesale_pdf" text="PDF Error: #cfcatch.message# | #cfcatch.detail#">
            </cfcatch>
            </cftry>

            <cfset jsonRes(true,
                "Wholesale order created! Order ID: <strong>" & result.group_id & "</strong>",
                {
                    "group_id"            : result.group_id,
                    "delivery_fee"        : deliveryFee,
                    "total_with_delivery" : result.total_with_delivery
                }
            )>

        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>


    <!--- SEARCH / LIST ORDERS--->
    <cffunction name="searchOrders" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireVendor()>
        <cftry>
            <cfset var model      = createObject("component","models.WholesaleOrder")>
            <cfset var srch       = structKeyExists(url,"search") ? trim(url.search) : "">
            <cfset var status     = structKeyExists(url,"status") ? trim(url.status) : "">
            <cfset var curPage    = structKeyExists(url,"p") AND val(url.p) GT 0 ? val(url.p) : 1>
            <cfset var limit      = 10>
            <cfset var orders     = model.getByVendor(session.user_id, srch, status, curPage, limit)>
            <cfset var total      = model.getByVendorCount(session.user_id, srch, status)>
            <cfset var totalPages = max(1, ceiling(total / limit))>

            <cfsavecontent variable="local.html">
            <cfoutput>
            <cfif orders.recordCount EQ 0>
                <tr><td colspan="8" class="text-center text-muted py-4">No wholesale orders found.</td></tr>
            <cfelse>
                <cfloop query="orders">
                    <cfset var sc = "">
                    <cfswitch expression="#orders.status#">
                        <cfcase value="pending">   <cfset sc="bg-warning text-dark"></cfcase>
                        <cfcase value="confirmed"> <cfset sc="bg-info text-dark"></cfcase>
                        <cfcase value="dispatched"><cfset sc="bg-primary"></cfcase>
                        <cfcase value="delivered"> <cfset sc="bg-success"></cfcase>
                        <cfcase value="cancelled"> <cfset sc="bg-secondary"></cfcase>
                        <cfdefaultcase>            <cfset sc="bg-secondary"></cfdefaultcase>
                    </cfswitch>
                <tr>
                    <td><span class="fw-semibold text-primary small">#orders.group_id#</span></td>
                    <td>
                        #encodeForHTML(orders.customer_name)#<br>
                        <small class="text-muted">#encodeForHTML(orders.customer_email)#</small>
                    </td>
                    <td><small>#encodeForHTML(orders.district_name)#</small></td>
                    <td>#encodeForHTML(orders.staff_name)#</td>
                    <td>
                        #encodeForHTML(orders.vehicle_name)#<br>
                        <small class="text-muted">#encodeForHTML(orders.vehicle_number)#</small>
                    </td>
                    <td>
                        <small class="text-muted">Products: &##8377;#numberFormat(orders.total_amount,"0.00")#</small><br>
                        <small class="text-muted">Delivery: &##8377;#numberFormat(orders.delivery_fee,"0.00")#</small><br>
                        <span class="fw-bold">&##8377;#numberFormat(orders.total_with_delivery,"0.00")#</span>
                    </td>
                    <td><span class="badge #sc#">#uCase(left(orders.status,1))##right(orders.status,len(orders.status)-1)#</span></td>
                    <td>
                        <div class="d-flex gap-1 flex-wrap">
                            <button class="btn btn-sm btn-outline-primary viewOrderBtn"
                                data-id="#orders.id#">View</button>
                            <cfif orders.status NEQ "delivered" AND orders.status NEQ "cancelled">
                                <button class="btn btn-sm btn-outline-success updateStatusBtn"
                                    data-id="#orders.id#"
                                    data-status="#orders.status#">Update</button>
                            </cfif>
                            <a href="../../assets/invoices/wholesale/invoice_#orders.group_id#.pdf"
                               target="_blank" class="btn btn-sm btn-outline-secondary">
                               <i class="bi bi-file-pdf"></i> PDF</a>
                        </div>
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
                <cfset var pGrp  = ceiling(curPage / gSize)>
                <cfset var sPage = (pGrp - 1) * gSize + 1>
                <cfset var ePage = min(sPage + gSize - 1, totalPages)>
                <cfif sPage GT 1>
                    <button class="wsPageBtn btn btn-outline-primary btn-sm"
                        data-page="#sPage-1#">Prev</button>
                </cfif>
                <cfloop from="#sPage#" to="#ePage#" index="i">
                    <button class="wsPageBtn btn btn-sm
                        #i EQ curPage ? 'btn-primary' : 'btn-outline-primary'#"
                        data-page="#i#">#i#</button>
                </cfloop>
                <cfif ePage LT totalPages>
                    <button class="wsPageBtn btn btn-outline-primary btn-sm"
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

    <!--- SINGLE ORDER--->
    <cffunction name="getOrder" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireVendor()>
        <cftry>
            <cfif NOT structKeyExists(url,"id") OR NOT val(url.id)>
                <cfset jsonRes(false,"Invalid order ID")>
            </cfif>
            <cfset var model = createObject("component","models.WholesaleOrder")>
            <cfset var order = model.getById(val(url.id), session.user_id)>
            <cfset var items = model.getItems(val(url.id))>

            <cfif order.recordCount EQ 0>
                <cfset jsonRes(false,"Order not found")>
            </cfif>

            <cfset var itemList = []>
            <cfloop query="items">
                <cfset arrayAppend(itemList,{
                    "product_name": items.product_name,
                    "qty"         : items.qty,
                    "unit_price"  : items.unit_price,
                    "total_price" : items.total_price
                })>
            </cfloop>

            <cfset jsonRes(true,"",{
                "id"                 : order.id,
                "group_id"           : order.group_id,
                "status"             : order.status,
                "total_amount"       : order.total_amount,
                "delivery_fee"       : order.delivery_fee,
                "total_with_delivery": order.total_with_delivery,
                "district_name"      : order.district_name,
                "notes"              : order.notes,
                "created_at"         : dateFormat(order.created_at,"dd-mmm-yyyy"),
                "customer_name"      : order.customer_first_name & " " & order.customer_last_name,
                "customer_email"     : order.customer_email,
                "customer_phone"     : order.customer_phone,
                "staff_name"         : order.staff_name,
                "vehicle_name"       : order.vehicle_name,
                "vehicle_number"     : order.vehicle_number,
                "capacity_units"     : order.capacity_units,
                "items"              : itemList
            })>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- UPDATE STATUS --->
    <cffunction name="updateStatus" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireVendor()>
        <cftry>
            <cfif NOT structKeyExists(form,"id") OR NOT val(form.id)>
                <cfset jsonRes(false,"Invalid order ID")>
            </cfif>
            <cfif NOT structKeyExists(form,"status") OR NOT len(trim(form.status))>
                <cfset jsonRes(false,"Status is required")>
            </cfif>
            <cfif NOT listFind("pending,confirmed,dispatched,delivered,cancelled", trim(form.status))>
                <cfset jsonRes(false,"Invalid status value")>
            </cfif>
            <cfset var model  = createObject("component","models.WholesaleOrder")>
            <cfset var result = model.updateStatus(val(form.id), session.user_id, trim(form.status))>
            <cfset jsonRes(result, result ? "Status updated to " & trim(form.status) : "Failed to update")>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>
