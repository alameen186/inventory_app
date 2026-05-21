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

    <!--- GET ALL VEHICLES FOR THIS VENDOR --->
    <cffunction name="getAll" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireVendor()>
        <cftry>
            <cfset var model    = createObject("component","models.Vehicle")>
            <cfset var vehicles = model.getByVendor(session.user_id)>
            <cfset var html     = "">

            <cfif vehicles.recordCount EQ 0>
                <cfset html = '<tr><td colspan="5" class="text-center text-muted py-4">No vehicles added yet.</td></tr>'>
            <cfelse>
                <cfloop query="vehicles">
                    <cfset var statusBadge = vehicles.is_active EQ 1
                        ? '<span class="badge bg-success">Active</span>'
                        : '<span class="badge bg-secondary">Inactive</span>'>
                    <cfset var typeLabel = "">
                    <cfswitch expression="#vehicles.vehicle_type#">
                        <cfcase value="truck"><cfset typeLabel = "🚛 Truck"></cfcase>
                        <cfcase value="van"><cfset typeLabel = "🚐 Van"></cfcase>
                        <cfcase value="bike"><cfset typeLabel = "🏍️ Bike"></cfcase>
                        <cfdefaultcase><cfset typeLabel = "🚗 Other"></cfdefaultcase>
                    </cfswitch>
                    <cfset html = html & '<tr>
                        <td class="fw-semibold">' & encodeForHTML(vehicles.vehicle_name) & '</td>
                        <td><span class="badge bg-dark">' & encodeForHTML(vehicles.vehicle_number) & '</span></td>
                        <td>' & typeLabel & '</td>
                        <td>' & statusBadge & '</td>
                        <td>
                            <button class="btn btn-sm btn-warning editVehicleBtn me-1"
                                data-id="' & vehicles.id & '"
                                data-name="' & encodeForHTMLAttribute(vehicles.vehicle_name) & '"
                                data-number="' & encodeForHTMLAttribute(vehicles.vehicle_number) & '"
                                data-type="' & vehicles.vehicle_type & '">Edit</button>
                            <button class="btn btn-sm ' & (vehicles.is_active EQ 1 ? 'btn-danger' : 'btn-success') & ' toggleVehicleBtn"
                                data-id="' & vehicles.id & '">
                                ' & (vehicles.is_active EQ 1 ? 'Deactivate' : 'Activate') & '
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

    <!--- SAVE  --->
    <cffunction name="save" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireVendor()>
        <cftry>
            <!--- Validation --->
            <cfif NOT structKeyExists(form,"vehicle_name") OR NOT len(trim(form.vehicle_name))>
                <cfset jsonRes(false,"Vehicle name is required")>
            </cfif>
            <cfif NOT structKeyExists(form,"vehicle_number") OR NOT len(trim(form.vehicle_number))>
                <cfset jsonRes(false,"Vehicle registration number is required")>
            </cfif>
            <cfif NOT structKeyExists(form,"vehicle_type") OR NOT len(trim(form.vehicle_type))>
                <cfset jsonRes(false,"Vehicle type is required")>
            </cfif>
            <cfif NOT listFind("truck,van,bike,other", trim(form.vehicle_type))>
                <cfset jsonRes(false,"Invalid vehicle type")>
            </cfif>

            <cfset var model  = createObject("component","models.Vehicle")>
            <cfset var id     = structKeyExists(form,"id") ? val(form.id) : 0>
            <cfset var result = model.save(
                vendor_id      = session.user_id,
                vehicle_name   = trim(form.vehicle_name),
                vehicle_number = uCase(trim(form.vehicle_number)),
                vehicle_type   = trim(form.vehicle_type),
                id             = id
            )>

            <cfif result>
                <cfset jsonRes(true, id GT 0 ? "Vehicle updated successfully" : "Vehicle added successfully")>
            <cfelse>
                <cfset jsonRes(false,"Failed to save vehicle")>
            </cfif>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="toggle" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireVendor()>
        <cftry>
            <cfif NOT structKeyExists(form,"id") OR NOT val(form.id)>
                <cfset jsonRes(false,"Invalid vehicle ID")>
            </cfif>
            <cfset var model  = createObject("component","models.Vehicle")>
            <cfset var result = model.toggle(val(form.id), session.user_id)>
            <cfset jsonRes(result, result ? "Status updated" : "Failed to update")>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>
