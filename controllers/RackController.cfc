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

    <cffunction name="requireAdmin" access="private" returntype="void" output="false">
        <cfif NOT structKeyExists(session,"user_id")
              OR NOT structKeyExists(session,"role_id")
              OR session.role_id NEQ 1>
            <cfset jsonRes(false,"Admin access required")>
        </cfif>
    </cffunction>

    <cffunction name="requireAuth" access="private" returntype="void" output="false">
        <cfif NOT structKeyExists(session,"user_id")>
            <cfset jsonRes(false,"Unauthorized")>
        </cfif>
    </cffunction>

    <cffunction name="requireVendor" access="private" returntype="void" output="false">
        <cfif NOT structKeyExists(session,"user_id")
              OR NOT structKeyExists(session,"role_name")
              OR session.role_name NEQ "vendor">
            <cfset jsonRes(false,"Vendor access required")>
        </cfif>
    </cffunction>

    <cffunction name="createRack" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireVendor()>
        <cftry>
            <cfif NOT structKeyExists(form,"rack_code") OR NOT len(trim(form.rack_code))>
                <cfset jsonRes(false,"Rack code is required")>
            </cfif>

            <cfset var model  = createObject("component","models.Rack")>

            <cfset var rackId = model.createRack(
                vendor_id = session.user_id,
                rack_code = trim(form.rack_code),
                rack_name = structKeyExists(form,"rack_name") ? trim(form.rack_name) : ""
            )>

            <cfif NOT rackId>
                <cfset jsonRes(false,"Failed to create rack. Rack code may already exist.")>
            </cfif>

            <cfset var f1 = structKeyExists(form,"cap_f1") ? val(form.cap_f1) : 0>
            <cfset var f2 = structKeyExists(form,"cap_f2") ? val(form.cap_f2) : 0>
            <cfset var f3 = structKeyExists(form,"cap_f3") ? val(form.cap_f3) : 0>
            <cfset var f4 = structKeyExists(form,"cap_f4") ? val(form.cap_f4) : 0>

            <cfif (f1 + f2 + f3 + f4) GT 0>
                <cfset model.saveFaces(
                    rack_id = rackId,
                    f1      = f1,
                    f2      = f2,
                    f3      = f3,
                    f4      = f4
                )>
            </cfif>

            <cfset jsonRes(true,"Rack created successfully", ["rack_id": rackId])>
        <cfcatch>
            <cfset jsonRes(false,"Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getRacks" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireAdmin()>
        <cftry>
            <cfset var model = createObject("component","models.Rack")>
            <cfset var racks = model.getAllRacks()>
            <cfset var html  = "">

            <cfif racks.recordCount EQ 0>
                <cfset html = '<tr><td colspan="5" class="text-center text-muted py-4">No racks created yet.</td></tr>'>
            <cfelse>
                <cfloop query="racks">
                    <cfset var faces = model.getRackFaces(racks.id)>
                    <cfset var faceBadges = "">

                    <cfif faces.recordCount GT 0>
                        <cfloop query="faces">
                            <cfset faceBadges = faceBadges
                                & '<span class="badge bg-secondary me-1">'
                                & faces.face_code & ': ' & faces.capacity
                                & '</span>'>
                        </cfloop>
                    <cfelse>
                        <cfset faceBadges = '<span class="text-muted small">None set</span>'>
                    </cfif>

                    <cfset var statusBadge = racks.is_active EQ 1
                        ? '<span class="badge bg-success">Active</span>'
                        : '<span class="badge bg-secondary">Inactive</span>'>

                    <cfset var btnClass = racks.is_active EQ 1 ? 'btn-warning' : 'btn-success'>
                    <cfset var btnLabel = racks.is_active EQ 1 ? 'Deactivate' : 'Activate'>

                    <cfset html = html & '<tr>
                        <td><span class="fw-semibold text-primary">' & encodeForHTML(racks.rack_code) & '</span></td>
                        <td>' & encodeForHTML(racks.rack_name) & '</td>
                        <td>
                            ' & encodeForHTML(racks.first_name) & ' ' & encodeForHTML(racks.last_name) & '
                            <small class="text-muted d-block">' & encodeForHTML(racks.business_name) & '</small>
                        </td>
                        <td>' & faceBadges & '</td>
                        <td>' & statusBadge & '</td>
                    </tr>'>
                </cfloop>
            </cfif>

            <cfset jsonRes(true,"", ["html": html])>
        <cfcatch>
            <cfset jsonRes(false,"Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getMyRacks" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireVendor()>
        <cftry>
            <cfset var model = createObject("component","models.Rack")>
            <cfset var racks = model.getRacksByVendor(session.user_id)>
            <cfset var list  = []>
            <cfloop query="racks">
                <cfset arrayAppend(list, [
                    "id"        : racks.id,
                    "rack_code" : racks.rack_code,
                    "rack_name" : racks.rack_name
                ])>
            </cfloop>
            <cfset jsonRes(true,"",list)>
        <cfcatch>
            <cfset jsonRes(false,"Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="toggleRack" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireAdmin()>
        <cftry>
            <cfset var model     = createObject("component","models.Rack")>
            <cfset var newStatus = (val(url.status) EQ 1 ? 0 : 1)>
            <cfset model.toggleRack(id=val(url.id), status=newStatus)>
            <cfset jsonRes(true,"Updated", ["newStatus": newStatus])>
        <cfcatch>
            <cfset jsonRes(false,"Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getRacksForVendor" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireAuth()>
        <cftry>
            <cfset var model = createObject("component","models.Rack")>
            <cfset var racks = model.getRacksByVendor(session.user_id)>
            <cfset var list  = []>
            <cfloop query="racks">
                <cfset arrayAppend(list, [
                    "id"        : racks.id,
                    "rack_code" : racks.rack_code,
                    "rack_name" : racks.rack_name
                ])>
            </cfloop>
            <cfset jsonRes(true,"",list)>
        <cfcatch>
            <cfset jsonRes(false,"Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getFacesForRack" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireAuth()>
        <cftry>
            <cfset var model = createObject("component","models.Rack")>
            <cfset var faces = model.getRackFaces(val(url.rack_id))>
            <cfset var list  = []>
            <cfloop query="faces">
                <cfset arrayAppend(list, [
                    "id"         : faces.id,
                    "face_code"  : faces.face_code,
                    "capacity"   : faces.capacity,
                    "used_slots" : faces.used_slots,
                    "available"  : faces.capacity - faces.used_slots
                ])>
            </cfloop>
            <cfset jsonRes(true,"",list)>
        <cfcatch>
            <cfset jsonRes(false,"Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getFaceDetail" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireAuth()>
        <cftry>
            <cfset var model    = createObject("component","models.Rack")>
            <cfset var face     = model.getFaceById(val(url.rack_face_id))>
            <cfset var products = model.getFaceProducts(val(url.rack_face_id))>

            <cfif face.recordCount EQ 0>
                <cfset jsonRes(false,"Face not found")>
            </cfif>

            <cfset var prodList = []>
            <cfloop query="products">
                <cfset arrayAppend(prodList, [
                    "id"           : products.id,
                    "product_name" : products.product_name
                ])>
            </cfloop>

            <cfset jsonRes(true,"", [
                "face_code"  : face.face_code,
                "rack_code"  : face.rack_code,
                "capacity"   : face.capacity,
                "used_slots" : face.used_slots,
                "available"  : face.capacity - face.used_slots,
                "products"   : prodList
            ])>
        <cfcatch>
            <cfset jsonRes(false,"Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="toggleRackByVendor" access="remote" returntype="void" output="true" httpMethod="GET">
    <cfset requireVendor()>
    <cftry>
        <cfset var model     = createObject("component","models.Rack")>
        <cfset var newStatus = (val(url.status) EQ 1 ? 0 : 1)>
        <cfset var result    = model.toggleRackByVendor(
            id        = val(url.id),
            vendor_id = session.user_id,
            status    = newStatus
        )>
        <cfif result>
            <cfset jsonRes(true,"Updated", ["newStatus": newStatus])>
        <cfelse>
            <cfset jsonRes(false,"Rack not found or access denied")>
        </cfif>
    <cfcatch>
        <cfset jsonRes(false,"Error: #cfcatch.message#")>
    </cfcatch>
    </cftry>
</cffunction>

    <cffunction name="getMyRacksTable" access="remote" returntype="void" output="true" httpMethod="GET">
    <cfset requireVendor()>
    <cftry>
        <cfset var model = createObject("component","models.Rack")>
        <cfset var racks = model.getRacksByVendorAll(session.user_id)>
        <cfset var html  = "">

        <cfif racks.recordCount EQ 0>
            <cfset html = '<tr><td colspan="5" class="text-center text-muted py-4">No racks created yet.</td></tr>'>
        <cfelse>
            <cfloop query="racks">
                <cfset var faces     = model.getRackFaces(racks.id)>
                <cfset var faceBadges = "">
                <cfif faces.recordCount GT 0>
                    <cfloop query="faces">
                        <cfset faceBadges = faceBadges
                            & '<span class="badge bg-secondary me-1">'
                            & faces.face_code & ': ' & faces.capacity
                            & '</span>'>
                    </cfloop>
                <cfelse>
                    <cfset faceBadges = '<span class="text-muted small">None set</span>'>
                </cfif>

                <cfset var statusBadge = racks.is_active EQ 1
                    ? '<span class="badge bg-success">Active</span>'
                    : '<span class="badge bg-secondary">Inactive</span>'>

                <cfset var btnClass = racks.is_active EQ 1 ? 'btn-warning' : 'btn-success'>
                <cfset var btnLabel = racks.is_active EQ 1 ? 'Deactivate' : 'Activate'>

                <cfset html = html & '<tr>
                    <td><span class="fw-semibold text-primary">' & encodeForHTML(racks.rack_code) & '</span></td>
                    <td>' & encodeForHTML(racks.rack_name) & '</td>
                    <td>' & faceBadges & '</td>
                    <td>' & statusBadge & '</td>
                    <td>
                        <button class="btn btn-sm ' & btnClass & ' toggleMyRackBtn"
                                data-id="' & racks.id & '"
                                data-status="' & racks.is_active & '">
                            ' & btnLabel & '
                        </button>
                    </td>
                </tr>'>
            </cfloop>
        </cfif>

        <cfset jsonRes(true,"", ["html": html])>
    <cfcatch>
        <cfset jsonRes(false,"Error: #cfcatch.message#")>
    </cfcatch>
    </cftry>
</cffunction>
    

</cfcomponent>