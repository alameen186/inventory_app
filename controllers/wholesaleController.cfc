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

    <!--- SEARCH WHOLESALE-ELIGIBLE PRODUCTS --->
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

    <!--- CREATE WHOLESALE ORDER --->
    <cffunction name="createOrder" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireVendor()>
        <cftry>
            <!--- Validate customer info --->
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
            <cfif NOT structKeyExists(form,"items") OR NOT len(trim(form.items))>
                <cfset jsonRes(false,"No items in the order")>
            </cfif>

            <!--- Parse items JSON --->
            <cfset var items = deserializeJSON(form.items)>
            <cfif NOT isArray(items) OR arrayLen(items) EQ 0>
                <cfset jsonRes(false,"Order must have at least one item")>
            </cfif>

            <!--- Validate each item stock and qty --->
            <cfset var productModel = createObject("component","models.Product")>
            <cfloop array="#items#" index="local.item">
                <cfif NOT structKeyExists(local.item,"product_id") OR NOT val(local.item.product_id)>
                    <cfset jsonRes(false,"Invalid product in order")>
                </cfif>
                <cfif NOT structKeyExists(local.item,"qty") OR val(local.item.qty) LTE 0>
                    <cfset jsonRes(false,"Invalid quantity for product #local.item.product_id#")>
                </cfif>
                <cfset var available = productModel.getStock(val(local.item.product_id))>
                <cfif val(local.item.qty) GT available>
                    <cfset jsonRes(false,"Not enough stock for #local.item.product_name#. Available: #available#")>
                </cfif>
            </cfloop>

            <!--- Get or create temp user --->
            <cfset var tempUserModel = createObject("component","models.TempUser")>
            <cfset var tempUserId = tempUserModel.getOrCreateTempUser(
                vendor_id  = session.user_id,
                first_name = trim(form.first_name),
                last_name  = structKeyExists(form,"last_name") ? trim(form.last_name) : "",
                email      = trim(form.email)
            )>

            <!--- Update phone if provided (temp_users has phone column) --->
            <cfif len(trim(form.phone))>
                <cfquery datasource="#application.dsn#">
                    UPDATE temp_users
                    SET phone = <cfqueryparam value="#trim(form.phone)#" cfsqltype="cf_sql_varchar">
                    WHERE id  = <cfqueryparam value="#tempUserId#" cfsqltype="cf_sql_integer">
                </cfquery>
            </cfif>

            <!--- Create the order --->
            <cfset var model  = createObject("component","models.WholesaleOrder")>
            <cfset var result = model.createOrder(
                vendor_id         = session.user_id,
                temp_user_id      = tempUserId,
                assigned_staff_id = val(form.assigned_staff_id),
                vehicle_id        = val(form.vehicle_id),
                notes             = structKeyExists(form,"notes") ? trim(form.notes) : "",
                items             = items
            )>

            <cfif NOT result.success>
                <cfset jsonRes(false,"Order failed: " & result.message)>
            </cfif>

            <!--- Notify assigned staff --->
            <cftry>
                <cfset var notifModel = createObject("component","models.Notification")>
                <cfset notifModel.create(
                    user_id   = val(form.assigned_staff_id),
                    sender_id = session.user_id,
                    type      = "wholesale_assigned",
                    title     = "Wholesale Order Assigned",
                    message   = "You have been assigned to wholesale order " & result.group_id,
                    link      = "index.cfm?page=dashboard&section=wholesaleOrders"
                )>
            <cfcatch></cfcatch>
            </cftry>

            <!--- Generate PDF invoice --->
    <!---<cftry>
         <cfset var invoiceDir  = expandPath("../../assets/invoices/wholesale/")>
         <cfif NOT directoryExists(invoiceDir)>
        <cfdirectory action="create" directory="#invoiceDir#">
              </cfif>
              <cfset var invoicePath = invoiceDir & "invoice_" & result.group_id & ".pdf">
          
              <cfset var orderQ = model.getById(result.order_id, session.user_id)>
              <cfset var itemsQ = model.getItems(result.order_id)>
          
              <cfdocument format="pdf" filename="#invoicePath#" overwrite="true">
              <cfoutput>
              <style>
                  body        { font-family: Arial; font-size: 12px; }
                  .tc         { text-align: center; }
                  .tr         { text-align: right; }
                  .header     { border-bottom: 2px solid ##000; margin-bottom: 15px; padding-bottom: 10px; }
                  .tbl        { width: 100%; border-collapse: collapse; margin-top: 10px; }
                  .tbl th     { background: ##f2f2f2; border: 1px solid ##ccc; padding: 8px; }
                  .tbl td     { border: 1px solid ##ccc; padding: 8px; }
                  .info-tbl   { width: 100%; margin-bottom: 10px; font-size: 12px; }
                  .info-tbl td{ padding: 3px 6px; }
                  .total-box  { width: 40%; float: right; margin-top: 10px; border-collapse: collapse; }
                  .total-box td { border: 1px solid ##ccc; padding: 6px 10px; }
                  .footer     { margin-top: 40px; font-size: 10px; text-align: center; color: ##777; }
              </style>
          
              <div>
                  <!--- Header --->
                  <div class="header tc">
                      <h2>INVENTORY STORE</h2>
                      <div style="font-size:11px; color:##555;">Wholesale Invoice</div>
                  </div>
          
                  <!--- Order + Customer Info --->
                  <table class="info-tbl">
                      <tr>
                          <td>
                              <strong>Invoice ID:</strong> #result.group_id#<br>
                              <strong>Date:</strong> #dateFormat(now(),"dd-mmm-yyyy")#<br>
                              <strong>Status:</strong> Pending
                          </td>
                          <td class="tr">
                              <strong>Customer:</strong><br>
                              #encodeForHTML(trim(form.first_name))# #encodeForHTML(structKeyExists(form,"last_name") ? trim(form.last_name) : "")#<br>
                              #encodeForHTML(trim(form.email))#<br>
                              #encodeForHTML(trim(form.phone))#
                          </td>
                      </tr>
                  </table>
          
                  <!--- Staff + Vehicle --->
                  <table class="info-tbl" style="margin-bottom:15px;">
                      <tr>
                          <td><strong>Staff:</strong> #encodeForHTML(orderQ.staff_name)#</td>
                          <td><strong>Vehicle:</strong> #encodeForHTML(orderQ.vehicle_name)# (#encodeForHTML(orderQ.vehicle_number)#)</td>
                      </tr>
                  </table>
          
                  <!--- Items Table --->
                  <table class="tbl">
                      <tr>
                          <th>Product</th>
                          <th class="tr">Unit Price</th>
                          <th class="tr">Qty</th>
                          <th class="tr">Total</th>
                      </tr>
                      <cfset var pdfGrandTotal = 0>
                      <cfloop query="itemsQ">
                          <cfset var rowTotal = itemsQ.unit_price * itemsQ.qty>
                          <cfset pdfGrandTotal += rowTotal>
                          <tr>
                              <td>#encodeForHTML(itemsQ.product_name)#</td>
                              <td class="tr">#numberFormat(itemsQ.unit_price,"0.00")#</td>
                              <td class="tr">#itemsQ.qty#</td>
                              <td class="tr">#numberFormat(rowTotal,"0.00")#</td>
                          </tr>
                      </cfloop>
                  </table>
          
                  <!--- Totals Box (mirrors user order style) --->
                  <table class="total-box">
                      <tr>
                          <td>Subtotal</td>
                          <td class="tr">#numberFormat(pdfGrandTotal,"0.00")#</td>
                      </tr>
                      <tr>
                          <td>Discount</td>
                          <td class="tr">0.00</td>
                      </tr>
                      <tr>
                          <td><strong>Grand Total</strong></td>
                          <td class="tr"><strong>#numberFormat(pdfGrandTotal,"0.00")#</strong></td>
                      </tr>
                  </table>
                  <div style="clear:both;"></div>
          
                  <!--- Notes (if any) --->
                  <cfif len(trim(structKeyExists(form,"notes") ? form.notes : ""))>
                      <p style="margin-top:15px;"><strong>Notes:</strong> #encodeForHTML(trim(form.notes))#</p>
                  </cfif>
          
                  <!--- Footer --->
                  <div class="footer">
                      <p>System generated wholesale invoice. No signature required.</p>
                  </div>
              </div>
              </cfoutput>
              </cfdocument>
                 <cfcatch></cfcatch>
    </cftry> --->

            <cfset jsonRes(true,"Wholesale order created successfully! Order ID: " & result.group_id,{
                "group_id": result.group_id
            })>

        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- SEARCH / LIST ORDERS --->
    <cffunction name="searchOrders" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireVendor()>
        <cftry>
            <cfset var model       = createObject("component","models.WholesaleOrder")>
            <cfset var srch        = structKeyExists(url,"search") ? trim(url.search) : "">
            <cfset var status      = structKeyExists(url,"status") ? trim(url.status) : "">
            <cfset var currentPage = structKeyExists(url,"p") AND val(url.p) GT 0 ? val(url.p) : 1>
            <cfset var limit       = 10>

            <cfset var orders      = model.getByVendor(session.user_id, srch, status, currentPage, limit)>
            <cfset var total       = model.getByVendorCount(session.user_id, srch, status)>
            <cfset var totalPages  = max(1, ceiling(total / limit))>

            <cfsavecontent variable="local.html">
            <cfoutput>
            <cfif orders.recordCount EQ 0>
                <tr><td colspan="7" class="text-center text-muted py-4">No wholesale orders found.</td></tr>
            <cfelse>
                <cfloop query="orders">
                    <cfset var statusClass = "">
                    <cfswitch expression="#orders.status#">
                        <cfcase value="pending">    <cfset statusClass = "bg-warning text-dark"></cfcase>
                        <cfcase value="confirmed">  <cfset statusClass = "bg-info text-dark"></cfcase>
                        <cfcase value="dispatched"> <cfset statusClass = "bg-primary"></cfcase>
                        <cfcase value="delivered">  <cfset statusClass = "bg-success"></cfcase>
                        <cfcase value="cancelled">  <cfset statusClass = "bg-secondary"></cfcase>
                        <cfdefaultcase>             <cfset statusClass = "bg-secondary"></cfdefaultcase>
                    </cfswitch>
                <tr>
                    <td><span class="fw-semibold text-primary small">#orders.group_id#</span></td>
                    <td>#encodeForHTML(orders.customer_name)#<br><small class="text-muted">#encodeForHTML(orders.customer_email)#</small></td>
                    <td>#encodeForHTML(orders.staff_name)#</td>
                    <td>#encodeForHTML(orders.vehicle_name)# <small class="text-muted">(#encodeForHTML(orders.vehicle_number)#)</small></td>
                    <td><span class="fw-bold">&##8377;#numberFormat(orders.total_amount,"0.00")#</span></td>
                    <td><span class="badge #statusClass#">#uCase(left(orders.status,1))##right(orders.status,len(orders.status)-1)#</span></td>
                    <td>
                        <div class="d-flex gap-1 flex-wrap">
                            <button class="btn btn-sm btn-outline-primary viewOrderBtn"
                                data-id="#orders.id#">View</button>
                            <cfif orders.status NEQ "delivered" AND orders.status NEQ "cancelled">
                                <button class="btn btn-sm btn-outline-success updateStatusBtn"
                                    data-id="#orders.id#"
                                    data-status="#orders.status#">Update</button>
                            </cfif>
                            <!---
                            <a href="../../assets/invoices/wholesale/invoice_#orders.group_id#.pdf"
                               target="_blank" class="btn btn-sm btn-outline-secondary">PDF</a> --->
                        </div>
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
                <cfset var pGrp  = ceiling(currentPage / gSize)>
                <cfset var sPage = (pGrp - 1) * gSize + 1>
                <cfset var ePage = min(sPage + gSize - 1, totalPages)>
                <cfif sPage GT 1>
                    <button class="wsPageBtn btn btn-outline-primary btn-sm" data-page="#sPage-1#">Prev</button>
                </cfif>
                <cfloop from="#sPage#" to="#ePage#" index="i">
                    <button class="wsPageBtn btn btn-sm #i EQ currentPage ? 'btn-primary' : 'btn-outline-primary'#"
                        data-page="#i#">#i#</button>
                </cfloop>
                <cfif ePage LT totalPages>
                    <button class="wsPageBtn btn btn-outline-primary btn-sm" data-page="#ePage+1#">Next</button>
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
                "id"             : order.id,
                "group_id"       : order.group_id,
                "status"         : order.status,
                "total_amount"   : order.total_amount,
                "notes"          : order.notes,
                "created_at"     : dateFormat(order.created_at,"dd-mmm-yyyy"),
                "customer_name"  : order.customer_first_name & " " & order.customer_last_name,
                "customer_email" : order.customer_email,
                "customer_phone" : order.customer_phone,
                "staff_name"     : order.staff_name,
                "vehicle_name"   : order.vehicle_name,
                "vehicle_number" : order.vehicle_number,
                "items"          : itemList
            })>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- UPDATE ORDER STATUS --->
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
            <cfset jsonRes(result, result ? "Status updated successfully" : "Failed to update status")>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>
