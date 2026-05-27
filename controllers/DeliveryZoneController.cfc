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

    <!--- GET ALL zones for this vendor --->
    <cffunction name="getAll" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireVendor()>
        <cftry>
            <cfset var model  = createObject("component","models.DeliveryZone")>
            <cfset var zones  = model.getByVendor(session.user_id)>
            <cfset var html   = "">

            <cfif zones.recordCount EQ 0>
                <cfset html = '<tr><td colspan="6" class="text-center text-muted py-4">No delivery zones added yet.</td></tr>'>
            <cfelse>
                <cfloop query="zones">
                    <cfset var statusBadge = zones.is_active EQ 1
                        ? '<span class="badge bg-success">Active</span>'
                        : '<span class="badge bg-secondary">Inactive</span>'>

                    <cfset html = html & '<tr>
                        <td class="fw-semibold">' & encodeForHTML(zones.place_name) & '</td>
                        <td class="text-center">' & zones.distance_km & ' km</td>
                        <td class="text-center">&##8377;' & numberFormat(zones.km_price,"0.00") & ' / km</td>
                        <td class="text-center fw-semibold text-success">&##8377;' & numberFormat(zones.delivery_fee,"0.00") & '</td>
                        <td>' & statusBadge & '</td>
                        <td>
                            <button class="btn btn-sm btn-warning editZoneBtn me-1"
                                data-id="'          & zones.id          & '"
                                data-place="'       & encodeForHTMLAttribute(zones.place_name) & '"
                                data-km="'          & zones.distance_km & '"
                                data-kmprice="'     & zones.km_price    & '"
                                >Edit</button>
                            <button class="btn btn-sm ' & (zones.is_active EQ 1 ? 'btn-danger' : 'btn-success') & ' toggleZoneBtn"
                                data-id="' & zones.id & '">
                                ' & (zones.is_active EQ 1 ? 'Deactivate' : 'Activate') & '
                            </button>
                            <button class="btn btn-sm btn-outline-danger deleteZoneBtn ms-1"
                                data-id="' & zones.id & '"
                                data-place="' & encodeForHTMLAttribute(zones.place_name) & '">
                                <i class="bi bi-trash"></i>
                            </button>
                        </td>
                    </tr>'>
                </cfloop>
            </cfif>

            <cfset jsonRes(true,"",{ "html": html })>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- CALCULATE fee preview  --->
    <cffunction name="calcFee" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireVendor()>
        <cfset var km    = structKeyExists(url,"km")       ? val(url.km)       : 0>
        <cfset var price = structKeyExists(url,"km_price") ? val(url.km_price) : 0>
        <cfset var fee   = (km GT 0 AND price GT 0) ? km * price : 0>
        <cfset jsonRes(true,"",{ "fee": fee })>
    </cffunction>

    <!--- SAVE (add or edit) --->
    <cffunction name="save" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireVendor()>
        <cftry>
            <cfif NOT structKeyExists(form,"place_name") OR NOT len(trim(form.place_name))>
                <cfset jsonRes(false,"Place name is required")>
            </cfif>
            <cfif len(trim(form.place_name)) LT 2>
                <cfset jsonRes(false,"Place name must be at least 2 characters")>
            </cfif>
            <cfif len(trim(form.place_name)) GT 100>
                <cfset jsonRes(false,"Place name cannot exceed 100 characters")>
            </cfif>
            <cfif NOT structKeyExists(form,"distance_km") OR NOT isNumeric(form.distance_km) OR val(form.distance_km) LTE 0>
                <cfset jsonRes(false,"Distance must be a positive number")>
            </cfif>
            <cfif val(form.distance_km) GT 9999>
                <cfset jsonRes(false,"Distance seems too large (max 9999 km)")>
            </cfif>
            <cfif NOT structKeyExists(form,"km_price") OR NOT isNumeric(form.km_price) OR val(form.km_price) LTE 0>
                <cfset jsonRes(false,"Price per km must be a positive number")>
            </cfif>
            <cfif val(form.km_price) GT 9999>
                <cfset jsonRes(false,"Price per km seems too large")>
            </cfif>

            <cfset var model  = createObject("component","models.DeliveryZone")>
            <cfset var id     = structKeyExists(form,"id") ? val(form.id) : 0>
            <cfset var result = model.save(
                vendor_id   = session.user_id,
                place_name  = trim(form.place_name),
                distance_km = val(form.distance_km),
                km_price    = val(form.km_price),
                id          = id
            )>

            <cfset var fee = val(form.distance_km) * val(form.km_price)>

            <cfif result>
    <cfset successMessage = (id gt 0 ? "zone updated" : "zone added") & "  delivery fee: " & NumberFormat(fee, "0.00")>
    <cfset jsonres(true, successMessage, { "fee": fee })>
<cfelse>
    <cfset jsonres(false, "failed to save zone")>
</cfif>

        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- TOGGLE active status --->
    <cffunction name="toggle" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireVendor()>
        <cftry>
            <cfif NOT structKeyExists(form,"id") OR NOT val(form.id)>
                <cfset jsonRes(false,"Invelid Zone Id")>
            </cfif>
            <cfset var model  = createObject("component","models.DeliveryZone")>
            <cfset var result = model.toggle(val(form.id), session.user_id)>
            <cfset jsonRes(result, result ? "Zone status updated" : "Failed to update")>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- DELETE a zone --->
    <cffunction name="delete" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireVendor()>
        <cftry>
            <cfif NOT structKeyExists(form,"id") OR NOT val(form.id)>
                <cfset jsonRes(false,"Invalid zone ID")>
            </cfif>
            <cfset var model  = createObject("component","models.DeliveryZone")>
            <cfset var result = model.delete(val(form.id), session.user_id)>
            <cfset jsonRes(result, result ? "Zone deleted" : "Failed to delete")>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- GET ACTIVE ZONES  --->
    <cffunction name="getActive" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireVendor()>
        <cftry>
            <cfset var model = createObject("component","models.DeliveryZone")>
            <cfset var zones = model.getActiveByVendor(session.user_id)>
            <cfset var list  = []>
            <cfloop query="zones">
                <cfset arrayAppend(list,{
                    "id"          : zones.id,
                    "place_name"  : zones.place_name,
                    "distance_km" : zones.distance_km,
                    "km_price"    : zones.km_price,
                    "delivery_fee": zones.delivery_fee
                })>
            </cfloop>
            <cfset jsonRes(true,"",list)>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>
