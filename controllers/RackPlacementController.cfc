<cfcomponent output="false">

    <cffunction name="jsonRes" access="private" returntype="void" output="true">
        <cfargument name="success" type="boolean" required="true">
        <cfargument name="message" type="string"  default="">
        <cfargument name="data"    type="any"     default="">

        <cfset var map = [:]>
        <cfset map["success"] = arguments.success>
        <cfset map["message"] = arguments.message>
        <cfset map["data"]    = arguments.data>

        <cfcontent type="application/json; charset=utf-8" reset="true">
        <cfoutput>#serializeJSON(map)#</cfoutput>
        <cfabort>
    </cffunction>

    <cffunction name="requireVendor" access="private" returntype="void" output="false">
        <cfif NOT structKeyExists(session,"user_id")
              OR NOT structKeyExists(session,"role_name")
              OR session.role_name NEQ "vendor">
            <cfset jsonRes(false,"Vendor access required")>
        </cfif>
    </cffunction>

    <cffunction name="getRackView" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireVendor()>
        <cftry>
            <cfset var rackModel = createObject("component","models.Rack")>
            <cfset var racks     = rackModel.getRacksByVendor(session.user_id)>
            <cfset var html      = "">

            <cfif racks.recordCount EQ 0>
                <cfset html = '<div class="alert alert-info">No racks assigned to you yet. Create a rack first.</div>'>
            <cfelse>
                <cfloop query="racks">
                    <cfset var faces = rackModel.getRackFaces(racks.id)>
                    <cfset var facesHtml = "">

                    <cfif faces.recordCount EQ 0>
                        <cfset facesHtml = '<div class="col-12"><p class="text-muted small">No faces configured.</p></div>'>
                    <cfelse>
                        <cfloop query="faces">
                            <cfset var faceProds = rackModel.getFaceProducts(faces.id)>
                            <cfset var pct = faces.capacity GT 0
                                            ? int((faces.used_slots / faces.capacity) * 100)
                                            : 0>
                            <cfset var barCol = pct GTE 100
                                               ? 'bg-danger'
                                               : (pct GTE 75 ? 'bg-warning' : 'bg-success')>

                            <cfset var productsHtml = "">
                            <cfif faceProds.recordCount EQ 0>
                                <cfset productsHtml = '<li class="text-muted fst-italic">Empty</li>'>
                            <cfelse>
                                <cfloop query="faceProds">
                                    <cfset productsHtml = productsHtml
                                        & '<li class="d-flex justify-content-between align-items-center py-1 border-bottom">'
                                        & '<span><i class="bi bi-box-seam me-1 text-secondary"></i>'
                                        & encodeForHTML(faceProds.product_name)
                                        & '</span>'
                                        & '<button class="btn btn-link btn-sm p-0 text-danger removeProductBtn"'
                                        & ' data-product-id="' & faceProds.id & '" title="Remove">'
                                        & '<i class="bi bi-x-circle-fill"></i></button>'
                                        & '</li>'>
                                </cfloop>
                            </cfif>

                            <cfset facesHtml = facesHtml
                                & '<div class="col-6 col-md-3">'
                                & '<div class="border rounded p-3 h-100 bg-light">'
                                & '<div class="d-flex justify-content-between align-items-center mb-2">'
                                & '<span class="fw-bold fs-5">' & faces.face_code & '</span>'
                                & '<span class="badge ' & barCol & '">' & faces.used_slots & ' / ' & faces.capacity & '</span>'
                                & '</div>'
                                & '<div class="progress mb-3" style="height:5px;">'
                                & '<div class="progress-bar ' & barCol & '" style="width:' & pct & '%;"></div>'
                                & '</div>'
                                & '<ul class="list-unstyled small mb-0">' & productsHtml & '</ul>'
                                & '</div></div>'>
                        </cfloop>
                    </cfif>

                    <cfset var rackNameDisplay = len(trim(racks.rack_name))
                        ? ' <span class="text-secondary ms-2 small">' & encodeForHTML(racks.rack_name) & '</span>'
                        : "">

                    <cfset html = html
                        & '<div class="card mb-4 shadow-sm">'
                        & '<div class="card-header bg-dark text-white">'
                        & '<i class="bi bi-grid-3x3-gap-fill me-2"></i>'
                        & '<strong>' & encodeForHTML(racks.rack_code) & '</strong>'
                        & rackNameDisplay
                        & '</div>'
                        & '<div class="card-body">'
                        & '<div class="row g-3">' & facesHtml & '</div>'
                        & '</div></div>'>
                </cfloop>
            </cfif>

            <cfset jsonRes(true,"", ["html": html])>
        <cfcatch>
            <cfset jsonRes(false,"Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="removeProduct" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireVendor()>
        <cftry>
            <cfset var model  = createObject("component","models.RackPlacement")>
            <cfset var result = model.removeProduct(val(form.product_id))>
            <cfset jsonRes(result, result ? "Product removed" : "Failed to remove")>
        <cfcatch>
            <cfset jsonRes(false,"Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="swapProducts" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireVendor()>
        <cftry>
            <cfset var model  = createObject("component","models.RackPlacement")>
            <cfset var result = model.swapProducts(
                product1_id = val(form.product1_id),
                product2_id = val(form.product2_id),
                vendor_id   = session.user_id
            )>

            <cfif result.success>
                <cfset var msg = "Products swapped successfully. "
                    & "Swaps used this month: " & result.swaps_used
                    & " / " & result.swaps_allowed
                    & ". Remaining: " & result.swaps_remaining & ".">
                <cfset jsonRes(true, msg, [
                    "swaps_used"      : result.swaps_used,
                    "swaps_allowed"   : result.swaps_allowed,
                    "swaps_remaining" : result.swaps_remaining
                ])>
            <cfelse>
                <cfset jsonRes(false, result.message)>
            </cfif>
        <cfcatch>
            <cfset jsonRes(false,"Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getSwapUsage" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireVendor()>
        <cftry>
            <cfset var model      = createObject("component","models.RackPlacement")>
            <cfset var used       = model.getMonthlySwapCount(session.user_id)>
            <cfset var SWAP_LIMIT = 3>
            <cfset jsonRes(true,"", [
                "used"      : used,
                "allowed"   : SWAP_LIMIT,
                "remaining" : max(0, SWAP_LIMIT - used)
            ])>
        <cfcatch>
            <cfset jsonRes(false,"Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getPlacedProducts" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireVendor()>
        <cftry>
            <cfset var model    = createObject("component","models.RackPlacement")>
            <cfset var products = model.getPlacedProducts(session.user_id)>
            <cfset var list     = []>
            <cfloop query="products">
                <cfset arrayAppend(list, [
                    "id"           : products.id,
                    "product_name" : products.product_name,
                    "rack_code"    : products.rack_code,
                    "face_code"    : products.face_code,
                    "rack_face_id" : products.rack_face_id
                ])>
            </cfloop>
            <cfset jsonRes(true,"",list)>
        <cfcatch>
            <cfset jsonRes(false,"Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="searchProducts" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireVendor()>
        <cftry>
            <cfset var keyword = structKeyExists(url,"keyword") ? trim(url.keyword) : "">
            <cfif NOT len(keyword)>
                <cfset jsonRes(false,"Please enter a search keyword")>
            </cfif>
            <cfset var model    = createObject("component","models.RackPlacement")>
            <cfset var products = model.searchVendorProducts(
                vendor_id = session.user_id,
                keyword   = keyword
            )>
            <cfset var list = []>
            <cfloop query="products">
                <cfset arrayAppend(list, [
                    "id"               : products.id,
                    "product_name"     : products.product_name,
                    "stock_quantity"   : products.stock_quantity,
                    "rack_code"        : products.rack_code,
                    "rack_name"        : products.rack_name,
                    "face_code"        : products.face_code,
                    "placement_status" : products.placement_status
                ])>
            </cfloop>
            <cfset jsonRes(true,"",list)>
        <cfcatch>
            <cfset jsonRes(false,"Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getSwapAlerts" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireVendor()>
        <cftry>
            <cfset var model  = createObject("component","models.RackPlacement")>
            <cfset var alerts = model.getSwapAlerts(vendor_id=session.user_id, threshold=2)>
            <cfset var count  = model.getAlertCount(vendor_id=session.user_id,  threshold=2)>
            <cfsavecontent variable="local.html">
            <cfoutput>
            <cfif alerts.recordCount EQ 0>
                <div class="alert alert-success">
                    <i class="bi bi-check-circle-fill me-2"></i>No swap suggestions right now.
                </div>
            <cfelse>
                <cfloop query="alerts">
                <div class="card mb-3 border-warning shadow-sm">
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-start gap-3">
                            <div>
                                <span class="badge bg-warning text-dark mb-2">
                                    <i class="bi bi-cart-fill me-1"></i>
                                    Bought together #alert_count# times
                                </span>
                                <div class="fw-semibold mb-1">
                                    #encodeForHTML(product1_name)#
                                    <span class="text-muted mx-2">+</span>
                                    #encodeForHTML(product2_name)#
                                </div>
                                <small class="text-muted">
                                    #encodeForHTML(product1_name)#:
                                    <cfif len(trim(rack1_code))>
                                        <span class="badge bg-secondary">#rack1_code# #face1_code#</span>
                                    <cfelse>
                                        <span class="text-danger">Not placed</span>
                                    </cfif>
                                    &nbsp;&nbsp;
                                    #encodeForHTML(product2_name)#:
                                    <cfif len(trim(rack2_code))>
                                        <span class="badge bg-secondary">#rack2_code# #face2_code#</span>
                                    <cfelse>
                                        <span class="text-danger">Not placed</span>
                                    </cfif>
                                </small>
                                <div class="mt-2 small text-muted fst-italic">
                                    Consider placing these products on the same rack face or adjacent faces.
                                </div>
                            </div>
                            <button class="btn btn-sm btn-outline-secondary flex-shrink-0 markAlertSeenBtn"
                                    data-id="#id#">
                                <i class="bi bi-check2"></i> Dismiss
                            </button>
                        </div>
                    </div>
                </div>
                </cfloop>
            </cfif>
            </cfoutput>
            </cfsavecontent>
            <cfset jsonRes(true,"", [
                "html"  : local.html,
                "count" : count
            ])>
        <cfcatch>
            <cfset jsonRes(false,"Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="markAlertSeen" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireVendor()>
        <cftry>
            <cfset var model  = createObject("component","models.RackPlacement")>
            <cfset var result = model.markAlertSeen(id=val(form.id), vendor_id=session.user_id)>
            <cfset jsonRes(result,"")>
        <cfcatch>
            <cfset jsonRes(false,"Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>