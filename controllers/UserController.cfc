    <cfcomponent output="false">

        <cffunction name="sendJSON" access="private" returntype="void" output="true">
            <cfargument name="data" type="struct" required="true">
            <cfcontent type="application/json; charset=utf-8" reset="true">
            <cfset var map = createObject("java","java.util.LinkedHashMap").init()>
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

        <!--- SEARCH USERS --->
        <cffunction name="searchUsers" access="remote" returntype="void" output="true" httpmethod="GET">
            <cfset requireAdmin()>
            <cftry>
                <cfset var userModel    = createObject("component","models.User")>
                <cfset var srch         = structKeyExists(url,"search") ? trim(url.search) : "">
                <cfset var sort         = structKeyExists(url,"sort")   ? trim(url.sort)   : "">
                <cfset var currentPage  = structKeyExists(url,"p") AND val(url.p) GT 0 ? val(url.p) : 1>
                <cfset var limit        = 2>
                <cfset var groupSize    = 4>

                <cfset var users = userModel.getAllUsers(
                    search = srch,
                    sort   = sort,
                    page   = currentPage,
                    limit  = limit
                )>
                <cfset var totalRecords = userModel.getUserCount(search = srch)>
                <cfset var totalPages   = ceiling(totalRecords / limit)>

                <!--- TABLE ROWS HTML --->
                <cfsavecontent variable="tableHTML">
                    <cfif users.recordCount EQ 0>
                        <tr><td colspan="5" class="text-center">No users found.</td></tr>
                    <cfelse>
                        <cfoutput query="users">
                        <tr id="row_#id#">
                            <td>#id#</td>
                            <td>#first_name# #last_name#</td>
                            <td class="text-break">#email#</td>
                            <td>#role_name#</td>
                            <<td class="d-flex flex-wrap gap-1">
    <cfif role_id EQ 1>
        <span class="badge bg-secondary">Action Restricted</span>
    <cfelse>
        <button class="btn btn-warning btn-sm editBtn"
            data-id="#id#"
            data-first="#encodeForHTMLAttribute(first_name)#"
            data-last="#encodeForHTMLAttribute(last_name)#"
            data-email="#encodeForHTMLAttribute(email)#">
            Edit
        </button>

        <button class="btn btn-danger btn-sm deleteBtn"
            data-id="#id#">
            Delete
        </button>
    </cfif>
</td>
                        </tr>
                        </cfoutput>
                    </cfif>
                </cfsavecontent>

                <!--- GROUPED PAGINATION HTML --->
                <cfsavecontent variable="paginationHTML">
                <cfif totalPages GT 1>
                    <cfoutput>
                    <cfset var pageGroup  = ceiling(currentPage / groupSize)>
                    <cfset var startPage  = (pageGroup - 1) * groupSize + 1>
                    <cfset var endPage    = min(startPage + groupSize - 1, totalPages)>

                    <!--- PREV GROUP BUTTON --->
                    <cfif startPage GT 1>
                        <button class="btn btn-outline-primary btn-sm pageBtn"
                                data-page="#startPage - 1#">&laquo; Prev</button>
                    </cfif>

                    <!--- PAGE NUMBERS --->
                    <cfloop from="#startPage#" to="#endPage#" index="i">
                        <button class="btn btn-sm pageBtn
                            <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
                            data-page="#i#">#i#</button>
                    </cfloop>

                    <!--- NEXT GROUP BUTTON --->
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

        <!--- CREATE USER --->
        <cffunction name="createUser" access="remote" returntype="void" output="true" httpmethod="POST">
            <cfset requireAdmin()>
            <cftry>
                <cfset var first_name = structKeyExists(form,"first_name") ? trim(form.first_name) : "">
                <cfset var last_name  = structKeyExists(form,"last_name")  ? trim(form.last_name)  : "">
                <cfset var email      = structKeyExists(form,"email")      ? trim(form.email)      : "">
                <cfset var password   = structKeyExists(form,"password")   ? trim(form.password)   : "">
                <cfset var confirm    = structKeyExists(form,"confirm")    ? trim(form.confirm)    : "">
                <cfset var role_id    = structKeyExists(form,"role_id")    ? val(form.role_id)     : 0>

                <!--- VALIDATION --->
                <cfif len(first_name) LT 3>
                    <cfset sendJSON({status:"error", message:"First name must be at least 3 characters"})>
                <cfelseif len(first_name) GT 100>
                    <cfset sendJSON({status:"error", message:"First name max 100 characters"})>
                <cfelseif len(last_name) LT 1>
                    <cfset sendJSON({status:"error", message:"Last name required"})>
                <cfelseif len(last_name) GT 100>
                    <cfset sendJSON({status:"error", message:"Last name max 100 characters"})>
                <cfelseif NOT isValid("email", email)>
                    <cfset sendJSON({status:"error", message:"Invalid email format"})>
                <cfelseif len(email) GT 100>
                    <cfset sendJSON({status:"error", message:"Email too long"})>
                <cfelseif len(password) LT 8 OR len(password) GT 20>
                    <cfset sendJSON({status:"error", message:"Password must be 8–20 characters"})>
                <cfelseif NOT reFind("^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])", password)>
                    <cfset sendJSON({status:"error", message:"Password needs uppercase, lowercase, number & special character"})>
                <cfelseif password NEQ confirm>
                    <cfset sendJSON({status:"error", message:"Passwords do not match"})>
                <cfelseif role_id LTE 0>
                    <cfset sendJSON({status:"error", message:"Invalid role"})>
                </cfif>

                <cfset var userModel = createObject("component","models.User")>
                <cfset userModel.create_user(first_name, last_name, email, password, role_id)>
                <cfset sendJSON({status:"success", message:"User created successfully"})>

            <cfcatch>
                <cfset sendJSON({status:"error", message:cfcatch.message})>
            </cfcatch>
            </cftry>
        </cffunction>

        <!--- UPDATE USER --->
        <cffunction name="updateUser" access="remote" returntype="void" output="true" httpmethod="POST">
            <cfset requireAdmin()>
            <cftry>
                <cfset var id         = structKeyExists(form,"id")         ? val(form.id)          : 0>
                <cfset var first_name = structKeyExists(form,"first_name") ? trim(form.first_name) : "">
                <cfset var last_name  = structKeyExists(form,"last_name")  ? trim(form.last_name)  : "">
                <cfset var email      = structKeyExists(form,"email")      ? trim(form.email)      : "">

                <!--- VALIDATION --->
                <cfif id LTE 0>
                    <cfset sendJSON({status:"error", message:"Invalid user ID"})>
                <cfelseif len(first_name) LT 3>
                    <cfset sendJSON({status:"error", message:"First name must be at least 3 characters"})>
                <cfelseif len(first_name) GT 100>
                    <cfset sendJSON({status:"error", message:"First name max 100 characters"})>
                <cfelseif len(last_name) LT 1>
                    <cfset sendJSON({status:"error", message:"Last name required"})>
                <cfelseif len(last_name) GT 100>
                    <cfset sendJSON({status:"error", message:"Last name max 100 characters"})>
                <cfelseif NOT isValid("email", email)>
                    <cfset sendJSON({status:"error", message:"Invalid email format"})>
                <cfelseif len(email) GT 100>
                    <cfset sendJSON({status:"error", message:"Email too long"})>
                </cfif>

                <cfset var userModel = createObject("component","models.User")>
                <cfset userModel.updateUser(id, first_name, last_name, email)>
                <cfset sendJSON({status:"success", message:"User updated successfully"})>

            <cfcatch>
                <cfset sendJSON({status:"error", message:cfcatch.message})>
            </cfcatch>
            </cftry>
        </cffunction>

        <!--- DELETE USER --->
        <cffunction name="deleteUser" access="remote" returntype="void" output="true" httpmethod="GET">
            <cfset requireAdmin()>
            <cftry>
                <cfset var id = structKeyExists(url,"id") ? val(url.id) : 0>
                <cfif id LTE 0>
                    <cfset sendJSON({status:"error", message:"Invalid user ID"})>
                </cfif>
                <cfset var userModel = createObject("component","models.User")>
                <cfset userModel.deleteUser(id)>
                <cfset sendJSON({status:"success", message:"User deleted successfully"})>
            <cfcatch>
                <cfset sendJSON({status:"error", message:cfcatch.message})>
            </cfcatch>
            </cftry>
        </cffunction>

        <!--- SEARCH VENDORS --->
<cffunction name="searchVendors" access="remote" returntype="void" output="true" httpmethod="GET">
    <cfset requireAdmin()>
    <cftry>
        <cfset var userModel   = createObject("component","models.User")>
        <cfset var srch        = structKeyExists(url,"search") ? trim(url.search) : "">
        <cfset var sort        = structKeyExists(url,"sort")   ? trim(url.sort)   : "">
        <cfset var currentPage = structKeyExists(url,"p") AND val(url.p) GT 0 ? val(url.p) : 1>
        <cfset var limit       = 5>
        <cfset var groupSize   = 4>

        <cfset var vendors = userModel.getAllVendors(
            search = srch,
            sort   = sort,
            page   = currentPage,
            limit  = limit
        )>
        <cfset var totalRecords = userModel.getVendorCount(search = srch)>
        <cfset var totalPages   = ceiling(totalRecords / limit)>

        <!--- TABLE ROWS HTML --->
        <cfsavecontent variable="tableHTML">
            <cfif vendors.recordCount EQ 0>
                <tr><td colspan="5" class="text-center">No vendors found.</td></tr>
            <cfelse>
                <cfoutput query="vendors">
                <tr id="vrow_#id#">
                    <td>#id#</td>
                    <td>#encodeForHTML(first_name)# #encodeForHTML(last_name)#</td>
                    <td class="text-break">#encodeForHTML(email)#</td>
                    <td>#role_name#</td>
                    <td>
                        <button class="btn btn-danger btn-sm deleteVendorBtn"
                                data-id="#id#">Delete</button>
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
                <button class="btn btn-outline-primary btn-sm vendorPageBtn"
                        data-page="#startPage - 1#">&laquo; Prev</button>
            </cfif>

            <cfloop from="#startPage#" to="#endPage#" index="i">
                <button class="btn btn-sm vendorPageBtn
                    <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
                    data-page="#i#">#i#</button>
            </cfloop>

            <cfif endPage LT totalPages>
                <button class="btn btn-outline-primary btn-sm vendorPageBtn"
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

<!--- DELETE VENDOR --->
<cffunction name="deleteVendor" access="remote" returntype="void" output="true" httpmethod="GET">
    <cfset requireAdmin()>
    <cftry>
        <cfset var id = structKeyExists(url,"id") ? val(url.id) : 0>
        <cfif id LTE 0>
            <cfset sendJSON({status:"error", message:"Invalid vendor ID"})>
        </cfif>
        <cfset var userModel = createObject("component","models.User")>
        <cfset userModel.deleteUser(id)>
        <cfset sendJSON({status:"success", message:"Vendor deleted successfully"})>
    <cfcatch>
        <cfset sendJSON({status:"error", message:cfcatch.message})>
    </cfcatch>
    </cftry>
</cffunction>

    </cfcomponent>