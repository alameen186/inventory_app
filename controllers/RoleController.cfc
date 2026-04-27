<cfcomponent output="false">

    <cffunction name="sendJSON" access="private" returntype="void" output="true">
        <cfargument name="data" type="struct" required="true">
        <cfcontent type="application/json; charset=utf-8" reset="true">
        <cfset var map = structNew("ordered")>
        <cfloop collection="#arguments.data#" item="k">
            <cfset map[lcase(k)] = arguments.data[k]>
        </cfloop>
        <cfoutput>#serializeJSON(map)#</cfoutput>
        <cfabort>
    </cffunction>

    <cffunction name="requireAdmin" access="private" returntype="void" output="false">
        <cfif NOT structKeyExists(session,"role_id") OR session.role_id NEQ 1>
            <cfset sendJSON({status:"error", message:"Unauthorized", html:"", pagination:""})>
        </cfif>
    </cffunction>

    <!--- SEARCH ROLES --->
    <cffunction name="searchRoles" access="remote" returntype="void" output="true" httpmethod="GET">
        <cfset requireAdmin()>
        <cftry>
            <cfset var roleModel   = createObject("component","models.Role")>
            <cfset var srch        = structKeyExists(url,"search") ? trim(url.search) : "">
            <cfset var sort        = structKeyExists(url,"sort")   ? trim(url.sort)   : "">
            <cfset var currentPage = structKeyExists(url,"p") AND val(url.p) GT 0 ? val(url.p) : 1>
            <cfset var limit       = 2>
            <cfset var groupSize   = 4>

            <cfset var roles = roleModel.getAllRoles(
                search = srch,
                sort   = sort,
                page   = currentPage,
                limit  = limit
            )>
            <cfset var totalRecords = roleModel.getRoleCount(search = srch)>
            <cfset var totalPages   = ceiling(totalRecords / limit)>

            <!--- TABLE ROWS HTML --->
            <cfsavecontent variable="tableHTML">
                <cfif roles.recordCount EQ 0>
                    <tr><td colspan="4" class="text-center">No roles found.</td></tr>
                <cfelse>
                    <cfoutput query="roles">
                    <tr id="roleRow_#id#">
                        <td>#id#</td>
                        <td>#encodeForHTML(role_name)#</td>
                        <td>#encodeForHTML(description)#</td>
                        <td>
                            <div class="d-flex flex-wrap gap-1">
                                <button class="btn btn-warning btn-sm editBtn"
                                    data-id="#id#"
                                    data-name="#encodeForHTMLAttribute(role_name)#"
                                    data-desc="#encodeForHTMLAttribute(description)#">Edit</button>
                                <button class="btn btn-danger btn-sm deleteBtn"
                                    data-id="#id#">Delete</button>
                            </div>
                        </td>
                    </tr>
                    </cfoutput>
                </cfif>
            </cfsavecontent>

            <!--- GROUPED PAGINATION HTML --->
            <cfsavecontent variable="paginationHTML">
            <cfif totalPages GT 1>
                <cfoutput>
                <cfset var pageGroup = ceiling(currentPage / groupSize)>
                <cfset var startPage = (pageGroup - 1) * groupSize + 1>
                <cfset var endPage   = min(startPage + groupSize - 1, totalPages)>

                <cfif startPage GT 1>
                    <button class="btn btn-outline-primary btn-sm pageBtn"
                            data-page="#startPage - 1#">&laquo; Prev</button>
                </cfif>

                <cfloop from="#startPage#" to="#endPage#" index="i">
                    <button class="btn btn-sm pageBtn
                        <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
                        data-page="#i#">#i#</button>
                </cfloop>

                <cfif endPage LT totalPages>
                    <button class="btn btn-outline-primary btn-sm pageBtn"
                            data-page="#endPage + 1#">Next &raquo;</button>
                </cfif>
                </cfoutput>
            </cfif>
            </cfsavecontent>

            <cfset sendJSON({
                status     : "success",
                message    : "",
                html       : tableHTML,
                pagination : paginationHTML
            })>

        <cfcatch>
            <cfset sendJSON({status:"error", message:cfcatch.message, html:"", pagination:""})>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- CREATE ROLE --->
    <cffunction name="createRole" access="remote" returntype="void" output="true" httpmethod="POST">
        <cfset requireAdmin()>
        <cftry>
            <cfset var roleName    = structKeyExists(form,"name")        ? trim(form.name)        : "">
            <cfset var description = structKeyExists(form,"description") ? trim(form.description) : "">

            <!--- VALIDATION --->
            <cfif len(roleName) LT 3>
                <cfset sendJSON({status:"error", message:"Role name must be at least 3 characters"})>
            <cfelseif len(roleName) GT 20>
                <cfset sendJSON({status:"error", message:"Role name must be less than 20 characters"})>
            <cfelseif len(description) LT 5>
                <cfset sendJSON({status:"error", message:"Description must be at least 5 characters"})>
            <cfelseif len(description) GT 100>
                <cfset sendJSON({status:"error", message:"Description must be less than 100 characters"})>
            </cfif>

            <cfset var roleModel = createObject("component","models.Role")>
            <cfset roleModel.createRole(roleName, description)>
            <cfset sendJSON({status:"success", message:"Role created successfully"})>

        <cfcatch>
            <cfset sendJSON({status:"error", message:cfcatch.message})>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- UPDATE ROLE --->
    <cffunction name="updateRole" access="remote" returntype="void" output="true" httpmethod="POST">
        <cfset requireAdmin()>
        <cftry>
            <cfset var id          = structKeyExists(form,"id")          ? val(form.id)           : 0>
            <cfset var roleName    = structKeyExists(form,"name")        ? trim(form.name)        : "">
            <cfset var description = structKeyExists(form,"description") ? trim(form.description) : "">

            <!--- VALIDATION --->
            <cfif id LTE 0>
                <cfset sendJSON({status:"error", message:"Invalid role ID"})>
            <cfelseif len(roleName) LT 3>
                <cfset sendJSON({status:"error", message:"Role name must be at least 3 characters"})>
            <cfelseif len(roleName) GT 20>
                <cfset sendJSON({status:"error", message:"Role name must be less than 20 characters"})>
            <cfelseif len(description) LT 5>
                <cfset sendJSON({status:"error", message:"Description must be at least 5 characters"})>
            <cfelseif len(description) GT 100>
                <cfset sendJSON({status:"error", message:"Description must be less than 100 characters"})>
            </cfif>

            <cfset var roleModel = createObject("component","models.Role")>
            <cfset roleModel.updateRole(id, roleName, description)>
            <cfset sendJSON({status:"success", message:"Role updated successfully"})>

        <cfcatch>
            <cfset sendJSON({status:"error", message:cfcatch.message})>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- DELETE ROLE --->
    <cffunction name="deleteRole" access="remote" returntype="void" output="true" httpmethod="GET">
        <cfset requireAdmin()>
        <cftry>
            <cfset var id = structKeyExists(url,"id") ? val(url.id) : 0>
            <cfif id LTE 0>
                <cfset sendJSON({status:"error", message:"Invalid role ID"})>
            </cfif>
            <cfset var roleModel = createObject("component","models.Role")>
            <cfset roleModel.deleteRole(id)>
            <cfset sendJSON({status:"success", message:"Role deleted successfully"})>
        <cfcatch>
            <cfset sendJSON({status:"error", message:cfcatch.message})>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>