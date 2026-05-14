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
            <cfset jsonRes(false,"Unauthorized Access")>
        </cfif>
    </cffunction>

    <cffunction name="uploadFile" access="private" returntype="struct" output="false">
        <cfargument name="fieldName" type="string" required="true">
        <cfargument name="uploadDir" type="string" required="true">

        <cfset var result = { success: false, filename: "", error: "" }>

        <cfif NOT directoryExists(arguments.uploadDir)>
            <cfdirectory action="create" directory="#arguments.uploadDir#" mode="777">
        </cfif>

        <cftry>
            <cffile action="upload"
                    filefield="#arguments.fieldName#"
                    destination="#arguments.uploadDir#"
                    nameconflict="makeunique"
                    accept="image/jpeg,image/png,image/jpg,image/webp"
                    result="local.ur">

            <cfset result.success  = true>
            <cfset result.filename = local.ur.serverFile>

        <cfcatch>
            <cfif NOT (
                findNoCase("no file",          cfcatch.message) OR
                findNoCase("is required",      cfcatch.message) OR
                findNoCase("was not submitted",cfcatch.message) OR
                findNoCase("is not a file",    cfcatch.message) OR
                cfcatch.type EQ "Application"
            )>
                <cfset result.error = cfcatch.message>
            </cfif>
        </cfcatch>
        </cftry>

        <cfreturn result>
    </cffunction>

    <cffunction name="save" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireVendor()>
        <cftry>
            <!--- Same expandPath pattern as working product controller --->
            <cfset var profileDir = expandPath("../../assets/images/staff/profiles/")>
            <cfset var aadhaarDir = expandPath("../../assets/images/staff/aadhaar/")>

            <!--- Upload files --->
            <cfset var profileResult = uploadFile("profile_image", profileDir)>
            <cfset var aadhaarResult = uploadFile("aadhaar_front",  aadhaarDir)>

            <cfset var model = createObject("component","models.Staff")>
            <cfset var id    = structKeyExists(form,"id") ? val(form.id) : 0>

            <cfset var args = {
                vendor_id      : session.user_id,
                full_name      : trim(structKeyExists(form,"full_name")      ? form.full_name      : ""),
                phone          : trim(structKeyExists(form,"phone")          ? form.phone          : ""),
                email          : trim(structKeyExists(form,"email")          ? form.email          : ""),
                gender         : trim(structKeyExists(form,"gender")         ? form.gender         : ""),
                date_of_birth  : trim(structKeyExists(form,"date_of_birth")  ? form.date_of_birth  : ""),
                address        : trim(structKeyExists(form,"address")        ? form.address        : ""),
                position       : trim(structKeyExists(form,"position")       ? form.position       : ""),
                department : trim(structKeyExists(form,"department") ? form.department : ""),
                password   : trim(structKeyExists(form,"password")   ? form.password   : ""),
                salary         : trim(structKeyExists(form,"salary")         ? form.salary         : ""),
                join_date      : trim(structKeyExists(form,"join_date")      ? form.join_date      : ""),
                aadhaar_number : trim(structKeyExists(form,"aadhaar_number") ? form.aadhaar_number : ""),
                profile_image  : profileResult.filename,
                aadhaar_image  : aadhaarResult.filename
            }>

            <cfif id GT 0>
                <cfset args.id = id>
                <cfset var result = model.update(argumentCollection=args)>
            <cfelse>
                <cfset var result = model.add(argumentCollection=args)>
            </cfif>

            <cfif result.success>
                <cfset jsonRes(true, id GT 0 ? "Staff updated successfully" : "Staff added successfully")>
            <cfelse>
                <cfset jsonRes(false, result.message)>
            </cfif>

        <cfcatch>
            <cfset jsonRes(false, "Server Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- ── GET ALL ── --->
    <cffunction name="getAll" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireVendor()>
        <cftry>
            <cfset var model = createObject("component","models.Staff")>
            <cfset var q     = model.getAll(session.user_id)>

            <cfsavecontent variable="local.html">
            <cfoutput>
            <cfif q.recordCount EQ 0>
                <tr>
                    <td colspan="7" class="text-center text-muted py-4">
                        No staff found. Add your first staff member.
                    </td>
                </tr>
            <cfelse>
                <cfloop query="q">
                <tr>
                    <td>
                        <cfif len(trim(q.profile_image))>
                            <img src="assets/images/staff/profiles/#q.profile_image#"
                                 onerror="this.src='https://placehold.co/40x40?text=No'"
                                 width="40" height="40"
                                 style="border-radius:50%;object-fit:cover;">
                        <cfelse>
                            <img src="https://placehold.co/40x40?text=No"
                                 width="40" height="40"
                                 style="border-radius:50%;object-fit:cover;">
                        </cfif>
                    </td>
                    <td>#encodeForHTML(q.full_name)#</td>
                    <td>#encodeForHTML(q.phone)#</td>
                    <td>#len(trim(q.position)) ? encodeForHTML(q.position) : '-'#</td>
                    <td>#len(q.join_date) ? dateFormat(q.join_date,'dd-mmm-yyyy') : '-'#</td>
                    <td class="text-center">
                        <div class="form-check form-switch d-flex justify-content-center">
                            <input class="form-check-input toggleStatus"
                                   type="checkbox"
                                   data-id="#q.id#"
                                   #q.is_active ? 'checked' : ''#>
                        </div>
                    </td>
                    <td class="text-center">
                        <button class="btn btn-sm btn-outline-primary editBtn me-1"
                                data-id="#q.id#">Edit</button>
                        <button class="btn btn-sm btn-outline-info docsBtn me-1"
                                data-id="#q.id#">Docs</button>
                        <button class="btn btn-sm btn-outline-danger deleteBtn"
                                data-id="#q.id#">Delete</button>
                    </td>
                </tr>
                </cfloop>
            </cfif>
            </cfoutput>
            </cfsavecontent>

            <cfset jsonRes(true,"",{ "html": local.html })>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- for edit modal --->
    <cffunction name="getOne" access="remote" returntype="void" output="true" httpMethod="GET">
    <cfset requireVendor()>
    <cftry>
        <cfset var model = createObject("component","models.Staff")>
        <cfset var q     = model.getById(val(url.id), session.user_id)>

        <cfif q.recordCount EQ 0>
            <cfset jsonRes(false,"Staff not found")>
        </cfif>

        <cfset jsonRes(true,"",{
            "id"             : q.id,
            "full_name"      : q.full_name,
            "phone"          : q.phone,
            "email"          : q.email,
            "gender"         : q.gender,
            "date_of_birth"  : len(q.date_of_birth) ? dateFormat(q.date_of_birth,"yyyy-mm-dd") : "",
            "address"        : q.address,
            "position"       : q.position,
            "department"     : q.department,
            "salary"         : q.salary,
            "join_date"      : len(q.join_date) ? dateFormat(q.join_date,"yyyy-mm-dd") : "",
            "profile_image"  : q.profile_image,
            "aadhaar_number" : q.aadhaar_number,
            "aadhaar_image"  : q.aadhaar_front,
            "is_active"      : q.is_active
        })>
    <cfcatch>
        <cfset jsonRes(false,"Error: " & cfcatch.message)>
    </cfcatch>
    </cftry>
</cffunction>

    <!---  TOGGLE STATUS  --->
    <cffunction name="toggleStatus" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireVendor()>
        <cftry>
            <cfset var model  = createObject("component","models.Staff")>
            <cfset var result = model.toggleStatus(val(form.id), session.user_id)>
            <cfset jsonRes(result.success,"",{ "is_active": result.is_active })>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <!---  DELETE  --->
    <cffunction name="delete" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireVendor()>
        <cftry>
            <cfset var model  = createObject("component","models.Staff")>
            <cfset var result = model.delete(val(form.id), session.user_id)>
            <cfset jsonRes(result.success, result.success ? "Staff deleted" : result.message)>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <!---  GET DOCS  --->
    <cffunction name="getDocs" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireVendor()>
        <cftry>
            <cfset var model = createObject("component","models.Staff")>
            <cfset var q     = model.getById(val(url.id), session.user_id)>
            <cfif q.recordCount EQ 0>
                <cfset jsonRes(false,"Not found")>
            </cfif>
            <cfset jsonRes(true,"",{
                "full_name"      : q.full_name,
                "aadhaar_number" : q.aadhaar_number,
                "profile_image"  : q.profile_image,
                "aadhaar_image"  : q.aadhaar_front
            })>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>