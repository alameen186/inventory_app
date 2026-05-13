<cfcomponent output="false">

    <!--- ── HELPERS ── --->
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
            <cfset jsonRes(false,"Unauthorized")>
        </cfif>
    </cffunction>

    <cffunction name="getAll" access="remote" returntype="void" output="true" httpMethod="GET">
    <cfset requireVendor()>
    <cftry>
        <cfset var model      = createObject("component","models.Offer")>
        <cfset var offerType  = structKeyExists(url,"offer_type") ? trim(url.offer_type) : "">
        <cfset var q          = model.getAll(session.user_id, offerType)>

        <cfsavecontent variable="local.html">
        <cfoutput>
        <cfif q.recordCount EQ 0>
            <tr>
                <td colspan="8">
                    <div class="offer-empty-state">
                        <span class="offer-empty-state-icon">🏷️</span>
                        <p class="mb-0">No offers found. Create your first offer!</p>
                    </div>
                </td>
            </tr>
        <cfelse>
            <cfloop query="q">
            <tr class="#q.offer_status EQ 'expired' ? 'offer-expired' : ''#">
                <td class="fw-semibold">#encodeForHTML(q.offer_name)#</td>
                <td>
                    <span class="offer-badge-#q.offer_type#">
                        #q.offer_type EQ 'seasonal' ? 'Seasonal' : 'Individual'#
                    </span>
                </td>
                <td>
                    <cfif q.offer_type EQ "seasonal">
                        #encodeForHTML(q.category_name)#
                    <cfelse>
                        #encodeForHTML(q.product_name)#
                    </cfif>
                </td>
                <td>
                    <span class="discount-pill">
                        <cfif q.discount_type EQ "percentage">
                            #q.discount_value#% OFF
                        <cfelse>
                          <i class="bi bi-currency-rupee"></i>#q.discount_value# OFF
                        </cfif>
                    </span>
                </td>
                <td>
                    <span class="date-range">
                        #dateFormat(q.start_date,'dd-mmm-yy')# <i class="bi bi-arrow-right"></i>
                        #dateFormat(q.end_date,'dd-mmm-yy')#
                    </span>
                </td>
                <td class="text-center">
                    <span class="affected-count">#q.affected_count# product#q.affected_count NEQ 1 ? 's' : ''#</span>
                </td>
                <td class="text-center">
                    <cfif q.offer_status EQ "expired">
                        <span class="badge bg-secondary">Expired</span>
                    <cfelseif q.offer_status EQ "upcoming">
                        <span class="badge bg-info text-dark">Upcoming</span>
                    <cfelse>
                        <div class="form-check form-switch d-flex justify-content-center mb-0">
                            <input class="form-check-input offer-toggle toggleOffer"
                                   type="checkbox"
                                   data-id="#q.id#"
                                   #q.is_active ? 'checked' : ''#>
                        </div>
                    </cfif>
                </td>
                <td class="text-center">
                    <button class="btn btn-sm btn-outline-primary editOfferBtn me-1"
                            data-id="#q.id#">Edit</button>
                    <button class="btn btn-sm btn-outline-danger deleteOfferBtn"
                            data-id="#q.id#">Delete</button>
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

    <!--- ── GET OFFER FOR EDIT ── --->
    <cffunction name="getOne" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireVendor()>
        <cftry>
            <cfset var model = createObject("component","models.Offer")>
            <cfset var q     = model.getById(val(url.id), session.user_id)>

            <cfif q.recordCount EQ 0>
                <cfset jsonRes(false,"Offer not found")>
            </cfif>

            <cfset jsonRes(true,"",{
                "id"             : q.id,
                "offer_name"     : q.offer_name,
                "offer_type"     : q.offer_type,
                "category_id"    : q.category_id,
                "product_id"     : q.product_id,
                "discount_type"  : q.discount_type,
                "discount_value" : q.discount_value,
                "start_date"     : len(q.start_date) ? dateFormat(q.start_date,"yyyy-mm-dd") : "",
                "end_date"       : len(q.end_date)   ? dateFormat(q.end_date,  "yyyy-mm-dd") : "",
                "is_active"      : q.is_active
            })>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

<<!--- save (add,edit) --->
<cffunction name="save" access="remote" returntype="void" output="true" httpMethod="POST">
    <cfset requireVendor()>
    <cftry>
        <!--- Validation --->
        <cfif NOT structKeyExists(form,"offer_name") OR NOT len(trim(form.offer_name))>
            <cfset jsonRes(false,"Offer name is required")>
        </cfif>
        <cfif NOT structKeyExists(form,"discount_value") OR NOT isNumeric(form.discount_value)>
            <cfset jsonRes(false,"Valid discount value is required")>
        </cfif>
        <cfif NOT structKeyExists(form,"start_date") OR NOT len(trim(form.start_date))>
            <cfset jsonRes(false,"Start date is required")>
        </cfif>
        <cfif NOT structKeyExists(form,"end_date") OR NOT len(trim(form.end_date))>
            <cfset jsonRes(false,"End date is required")>
        </cfif>
        <cfif form.start_date GT form.end_date>
            <cfset jsonRes(false,"Start date cannot be after end date")>
        </cfif>
        <cfif form.offer_type EQ "seasonal" AND (NOT structKeyExists(form,"category_id") OR NOT val(form.category_id))>
            <cfset jsonRes(false,"Please select a category for seasonal offer")>
        </cfif>
        <cfif form.offer_type EQ "individual" AND (NOT structKeyExists(form,"product_id") OR NOT val(form.product_id))>
            <cfset jsonRes(false,"Please select a product for individual offer")>
        </cfif>
        <cfif form.discount_type EQ "percentage" AND val(form.discount_value) GT 100>
            <cfset jsonRes(false,"Percentage discount cannot exceed 100%")>
        </cfif>

        <!--- ── SAVE OFFER ── --->
        <cfset var model = createObject("component","models.Offer")>
        <cfset var id    = structKeyExists(form,"id") ? val(form.id) : 0>

        <cfset var args = {
            vendor_id      : session.user_id,
            offer_name     : trim(form.offer_name),
            offer_type     : trim(form.offer_type),
            category_id    : structKeyExists(form,"category_id") ? trim(form.category_id) : "",
            product_id     : structKeyExists(form,"product_id")  ? trim(form.product_id)  : "",
            discount_type  : trim(form.discount_type),
            discount_value : val(form.discount_value),
            start_date     : trim(form.start_date),
            end_date       : trim(form.end_date),
            is_active      : structKeyExists(form,"is_active") ? 1 : 0
        }>

        <cfif id GT 0>
            <cfset args.id = id>
            <cfset var result = model.update(argumentCollection=args)>
        <cfelse>
            <cfset var result = model.add(argumentCollection=args)>
        </cfif>

        <cfif NOT result.success>
            <cfset jsonRes(false, "DB Save Failed: " & result.message)>
        </cfif>

        <!--- ── EMAIL + CHAT — only on NEW offer ── --->
        <cfif id EQ 0 AND result.success>
            <cftry>

                <!--- STEP 1: Load customers --->
                <cfset var customers  = model.getCustomerEmails()>
                <cfset var vendorName = model.getVendorName(session.user_id)>
                <cfset var vendorId   = session.user_id>

                <!--- DEBUG: No customers found --->
                <cfif customers.recordCount EQ 0>
                    <cfset jsonRes(true, "Offer created. WARNING: No customers found to notify.")>
                </cfif>

                <!--- STEP 2: Build discount display --->
                <cfset var discountDisplay = "">
                <cfif trim(form.discount_type) EQ "percentage">
                    <cfset var dv = val(form.discount_value)>
                    <cfset discountDisplay = (dv EQ int(dv) ? numberFormat(dv,"0") : numberFormat(dv,"0.00")) & "% OFF">
                <cfelse>
                    <cfset discountDisplay = "Rs." & numberFormat(val(form.discount_value),"0.00") & " OFF">
                </cfif>

                <!--- STEP 3: Build offer scope label --->
                <cfset var offerScopeLabel = "">
                <cfif trim(form.offer_type) EQ "seasonal">
                    <cfquery name="local.catQ" datasource="#application.dsn#">
                        SELECT category_name FROM categories
                        WHERE id = <cfqueryparam value="#val(form.category_id)#" cfsqltype="cf_sql_integer">
                    </cfquery>
                    <cfset offerScopeLabel = local.catQ.recordCount ? local.catQ.category_name : "Selected Category">
                <cfelse>
                    <cfquery name="local.prodQ" datasource="#application.dsn#">
                        SELECT product_name FROM products
                        WHERE id = <cfqueryparam value="#val(form.product_id)#" cfsqltype="cf_sql_integer">
                    </cfquery>
                    <cfset offerScopeLabel = local.prodQ.recordCount ? local.prodQ.product_name : "Selected Product">
                </cfif>

                <cfset var offerTypeLabel      = trim(form.offer_type) EQ "seasonal" ? "Seasonal Offer" : "Individual Product Offer">
                <cfset var validFrom           = dateFormat(trim(form.start_date),"dd-mmm-yyyy")>
                <cfset var validUntil          = dateFormat(trim(form.end_date),  "dd-mmm-yyyy")>
                <cfset var currentYear         = year(now())>
                <cfset var vendorNameClean     = encodeForHTML(vendorName)>
                <cfset var offerNameClean      = encodeForHTML(trim(form.offer_name))>
                <cfset var offerScopeLabelClean = encodeForHTML(offerScopeLabel)>

                <!--- STEP 4: Build HTML email template ONCE --->
                <!--- IMPORTANT: cfoutput inside cfsavecontent makes ## render as # in CSS --->
                <cfsavecontent variable="local.emailTemplate">
                <cfoutput><!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
</head>
<body style="margin:0;padding:0;background-color:##f4f4f4;font-family:Arial,Helvetica,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:##f4f4f4;padding:24px 0;">
<tr><td align="center">
<table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background:##ffffff;border-radius:8px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.10);">

  <tr>
    <td style="background:##1a1a2e;padding:28px 32px;text-align:center;">
      <p style="margin:0 0 4px;color:##aaaacc;font-size:12px;letter-spacing:3px;text-transform:uppercase;">#vendorNameClean#</p>
      <h1 style="margin:0;color:##ffffff;font-size:26px;font-weight:700;">New Offer!</h1>
    </td>
  </tr>

  <tr>
    <td style="padding:28px 32px 16px;">
      <p style="margin:0 0 6px;font-size:16px;color:##212121;">Hi <strong>%%FIRST_NAME%%</strong>,</p>
      <p style="margin:0;font-size:14px;color:##555555;line-height:1.7;"><strong>#vendorNameClean#</strong> has launched a new offer just for you!</p>
    </td>
  </tr>

  <tr>
    <td style="padding:0 32px 24px;">
      <table width="100%" cellpadding="0" cellspacing="0" style="background:##fff8e1;border:1.5px solid ##ffc107;border-radius:8px;">
        <tr>
          <td style="padding:24px;text-align:center;">
            <h2 style="margin:0 0 8px;font-size:20px;color:##212121;font-weight:700;">#offerNameClean#</h2>
            <p style="margin:0;font-size:22px;font-weight:700;color:##e53935;">#discountDisplay#</p>
          </td>
        </tr>
      </table>
    </td>
  </tr>

  <tr>
    <td style="padding:0 32px 24px;">
      <table width="100%" cellpadding="0" cellspacing="0" style="font-size:14px;border-collapse:collapse;">
        <tr>
          <td style="padding:10px 14px;color:##757575;width:38%;border-bottom:1px solid ##eeeeee;">Offer Type</td>
          <td style="padding:10px 14px;font-weight:600;color:##212121;border-bottom:1px solid ##eeeeee;">#offerTypeLabel#</td>
        </tr>
        <tr style="background:##fafafa;">
          <td style="padding:10px 14px;color:##757575;border-bottom:1px solid ##eeeeee;">Applies To</td>
          <td style="padding:10px 14px;font-weight:600;color:##212121;border-bottom:1px solid ##eeeeee;">#offerScopeLabelClean#</td>
        </tr>
        <tr>
          <td style="padding:10px 14px;color:##757575;border-bottom:1px solid ##eeeeee;">Valid From</td>
          <td style="padding:10px 14px;font-weight:600;color:##212121;border-bottom:1px solid ##eeeeee;">#validFrom#</td>
        </tr>
        <tr style="background:##fafafa;">
          <td style="padding:10px 14px;color:##757575;">Valid Until</td>
          <td style="padding:10px 14px;font-weight:700;color:##e53935;">#validUntil#</td>
        </tr>
      </table>
    </td>
  </tr>

  <tr>
    <td style="padding:0 32px 24px;">
      <table width="100%" cellpadding="0" cellspacing="0" style="background:##fff3e0;border-left:4px solid ##ff6f00;border-radius:4px;">
        <tr>
          <td style="padding:12px 16px;font-size:13px;color:##e65100;">
            Hurry! This offer expires on <strong>#validUntil#</strong>. Limited time only.
          </td>
        </tr>
      </table>
    </td>
  </tr>

  <tr>
    <td style="padding:0 32px 28px;border-top:1px solid ##eeeeee;">
      <p style="margin:16px 0 4px;font-size:12px;color:##9e9e9e;text-align:center;">You are receiving this because you are a registered customer.</p>
      <p style="margin:0;font-size:12px;color:##bdbdbd;text-align:center;">&copy; #currentYear# #vendorNameClean#. All rights reserved.</p>
    </td>
  </tr>

</table>
</td></tr>
</table>
</body>
</html></cfoutput>
                </cfsavecontent>

                <!--- STEP 5: Send emails + track results --->
                <cfset var sent       = 0>
                <cfset var emailFails = 0>
                <cfset var emailErrors = "">

                <cfloop query="customers">
                    <cfif len(trim(customers.email))>
                        <cftry>
                            <cfset var personalizedBody = replaceNoCase(
                                local.emailTemplate,
                                "%%FIRST_NAME%%",
                                encodeForHTML(customers.first_name),
                                "all"
                            )>

                            <cfmail
                                to       = "#trim(customers.email)#"
                                from     = "ameenalalameen8086@gmail.com"
                                subject  = "New Offer: #trim(form.offer_name)# from #vendorName#"
                                type     = "html"
                                server   = "smtp.gmail.com"
                                username = "ameenalalameen8086@gmail.com"
                                password = "zxqe zcle jnbl mgdf"
                                port     = "587"
                                useTLS   = "true">#personalizedBody#</cfmail>

                            <cfset sent++>
                            <cfset sleep(500)>
                        <cfcatch>
                            <cfset emailFails++>
                            <cfset emailErrors = emailErrors & " | " & trim(customers.email) & ": " & cfcatch.message>
                        </cfcatch>
                        </cftry>
                    </cfif>
                </cfloop>

                <!--- STEP 6: Send chat messages --->
                <cfset var chatSent  = 0>
                <cfset var chatFails = 0>
                <cfset var chatErrors = "">

                <cftry>
                    <cfset var convModel = createObject("component","models.Conversation")>
                    <cfset var msgModel  = createObject("component","models.Message")>

                    <cfset var chatMsg = "Hi! We have a new offer for you." & chr(10)
                                       & "Offer    : " & trim(form.offer_name) & chr(10)
                                       & "Discount : " & discountDisplay & chr(10)
                                       & "Applies  : " & offerScopeLabel & chr(10)
                                       & "Valid    : " & validFrom & " to " & validUntil & chr(10)
                                       & "Login to check it out!">

                    <cfloop query="customers">
                        <cftry>
                            <cfquery name="local.userQ" datasource="#application.dsn#">
                                SELECT id FROM users
                                WHERE email = <cfqueryparam value="#trim(customers.email)#" cfsqltype="cf_sql_varchar">
                                LIMIT 1
                            </cfquery>

                            <cfif local.userQ.recordCount GT 0>
                                <cfset var customerId = local.userQ.id>
                                <cfset var existing   = convModel.existsByUserAndVendor(customerId, vendorId)>
                                <cfset var chatId     = existing.recordCount GT 0
                                                        ? existing.id
                                                        : convModel.findOrCreate(customerId, vendorId)>

                                <cfset msgModel.send(
                                    chat_id   = chatId,
                                    sender_id = vendorId,
                                    message   = chatMsg
                                )>
                                <cfset convModel.touch(chatId)>
                                <cfset chatSent++>
                            <cfelse>
                                <!--- Customer email not found in users table — skip silently --->
                                <cfset chatFails++>
                                <cfset chatErrors = chatErrors & " | No user row for: " & trim(customers.email)>
                            </cfif>
                        <cfcatch>
                            <cfset chatFails++>
                            <cfset chatErrors = chatErrors & " | " & trim(customers.email) & ": " & cfcatch.message>
                        </cfcatch>
                        </cftry>
                    </cfloop>
                <cfcatch>
                    <cfset chatErrors = "Chat bulk error: " & cfcatch.message>
                </cfcatch>
                </cftry>

                <!--- STEP 7: Build detailed response message --->
                <cfset var finalMsg = "Offer created!">
                <cfset var finalMsg = finalMsg & " Email: " & sent & " sent">
                <cfif emailFails GT 0>
                    <cfset finalMsg = finalMsg & ", " & emailFails & " failed [" & emailErrors & "]">
                </cfif>
                <cfset finalMsg = finalMsg & ". Chat: " & chatSent & " sent">
                <cfif chatFails GT 0>
                    <cfset finalMsg = finalMsg & ", " & chatFails & " failed [" & chatErrors & "]">
                </cfif>

                <cfset jsonRes(true, finalMsg)>

            <cfcatch>
                <!--- Outer catch — something crashed before/during setup --->
                <cfset jsonRes(true, "Offer created but notification error: " & cfcatch.message & " | Line: " & cfcatch.tagContext[1].line)>
            </cfcatch>
            </cftry>

        <cfelse>
            <!--- EDIT — no email sent --->
            <cfset jsonRes(true, "Offer updated successfully.")>
        </cfif>

    <cfcatch>
        <cfset jsonRes(false, "Save error: " & cfcatch.message & " | Line: " & cfcatch.tagContext[1].line)>
    </cfcatch>
    </cftry>
</cffunction>

    <cffunction name="toggleStatus" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireVendor()>
        <cftry>
            <cfset var model  = createObject("component","models.Offer")>
            <cfset var result = model.toggleStatus(val(form.id), session.user_id)>
            <cfset jsonRes(result.success,"",{ "is_active": result.is_active })>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="delete" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireVendor()>
        <cftry>
            <cfset var model  = createObject("component","models.Offer")>
            <cfset var result = model.delete(val(form.id), session.user_id)>
            <cfset jsonRes(result.success, result.success ? "Offer deleted" : result.message)>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>