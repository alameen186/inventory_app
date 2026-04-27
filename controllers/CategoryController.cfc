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

    <cffunction name="requireAuth" access="private" returntype="void" output="false">
        <cfif NOT structKeyExists(session,"user_id")>
            <cfset sendJSON({status:"error", message:"Unauthorized", html:"", pagination:""})>
        </cfif>
    </cffunction>

    <cffunction name="getVendorFilter" access="private" returntype="string" output="false">
        <cfif structKeyExists(session,"role_name") AND session.role_name EQ "vendor">
            <cfreturn session.user_id>
        </cfif>
        <cfreturn "">
    </cffunction>

    <!--- SEARCH CATEGORIES --->
    <cffunction name="searchCategories" access="remote" returntype="void" output="true" httpmethod="GET">
        <cfset requireAuth()>
        <cftry>
            <cfset var categoryModel = createObject("component","models.Category")>
            <cfset var vendorFilter  = getVendorFilter()>
            <cfset var srch          = structKeyExists(url,"search") ? trim(url.search) : "">
            <cfset var sort          = structKeyExists(url,"sort")   ? url.sort         : "">
            <cfset var currentPage   = structKeyExists(url,"p") AND val(url.p) GT 0 ? val(url.p) : 1>
            <cfset var limit         = 2>

            <cfset var totalRecords = categoryModel.getCategoryCount(
                search    = srch,
                vendor_id = vendorFilter
            )>
            <cfset var totalPages = ceiling(totalRecords / limit)>

            <cfset var categories = categoryModel.getAllCategories(
                search    = srch,
                sort      = sort,
                page      = currentPage,
                limit     = limit,
                vendor_id = vendorFilter
            )>

            <!--- TABLE ROWS HTML --->
            <cfsavecontent variable="tableHTML">
            <cfif categories.recordCount EQ 0>
                <tr><td colspan="5" class="text-center">No categories found.</td></tr>
            <cfelse>
                <cfoutput query="categories">
                <tr id="categoryRow_#id#">
                    <td>#id#</td>
                    <td>#category_name#</td>
                    <td>#description#</td>
                    <td>
                        <cfif is_active EQ 1>
                            <span class="text-success">Active</span>
                        <cfelse>
                            <span class="text-warning">Blocked</span>
                        </cfif>
                    </td>
                    <td>
                        <div class="d-flex flex-wrap gap-1">
                            <button class="editBtn btn btn-warning btn-sm" data-id="#id#">Edit</button>
                            <button class="toggleStatusBtn btn btn-sm #iif(is_active EQ 1, de('btn-danger'), de('btn-success'))#"
                                    data-id="#id#" data-status="#is_active#">
                                <cfif is_active EQ 1>Block<cfelse>Unblock</cfif>
                            </button>
                        </div>
                    </td>
                </tr>
                <tr id="editCategoryRow_#id#" style="display:none;">
                    <td>#id#</td>
                    <td><input value="#category_name#" class="form-control editName"></td>
                    <td><input value="#description#" class="form-control editDesc"></td>
                    <td>
                        <cfif is_active EQ 1>
                            <span class="text-success">Active</span>
                        <cfelse>
                            <span class="text-warning">Blocked</span>
                        </cfif>
                    </td>
                    <td>
                        <div class="d-flex flex-wrap gap-1">
                            <button class="saveEdit btn btn-success btn-sm" data-id="#id#">Save</button>
                            <button class="cancelEdit btn btn-secondary btn-sm" data-id="#id#">Cancel</button>
                        </div>
                    </td>
                </tr>
                </cfoutput>
            </cfif>
            </cfsavecontent>

            <!--- PAGINATION HTML --->
            <cfsavecontent variable="paginationHTML">
            <cfoutput>
            <cfif totalPages GT 1>
                <cfset var groupSize = 4>
                <cfset var pageGroup = ceiling(currentPage / groupSize)>
                <cfset var startPage = (pageGroup - 1) * groupSize + 1>
                <cfset var endPage   = min(startPage + groupSize - 1, totalPages)>
                <cfif startPage GT 1>
                    <button class="btn btn-outline-primary btn-sm pageBtn"
                            data-page="#startPage - 1#">&laquo; Prev</button>
                </cfif>
                <cfloop from="#startPage#" to="#endPage#" index="i">
                    <button class="btn btn-sm pageBtn <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
                            data-page="#i#">#i#</button>
                </cfloop>
                <cfif endPage LT totalPages>
                    <button class="btn btn-outline-primary btn-sm pageBtn"
                            data-page="#endPage + 1#">Next &raquo;</button>
                </cfif>
            </cfif>
            </cfoutput>
            </cfsavecontent>

            <cfset sendJSON({status:"success", html:tableHTML, pagination:paginationHTML})>

        <cfcatch>
            <cfset sendJSON({status:"error", message:"#cfcatch.message#", html:"", pagination:""})>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- ADD CATEGORY --->
    <cffunction name="addCategory" access="remote" returntype="void" output="true" httpmethod="POST">
        <cfset requireAuth()>
        <cfif NOT structKeyExists(form,"category_name") OR NOT len(trim(form.category_name))>
            <cfset sendJSON({status:"error", message:"Category name required", html:"", pagination:""})>
        </cfif>
        <cftry>
            <cfset var categoryModel = createObject("component","models.Category")>
            <cfset var vendorFilter  = getVendorFilter()>
            <cfset var result = categoryModel.addCategory(
                category_name = trim(form.category_name),
                description   = structKeyExists(form,"description") ? trim(form.description) : "",
                vendor_id     = vendorFilter
            )>
            <cfif result>
                <cfset sendJSON({status:"success", message:"Category added successfully", html:"", pagination:""})>
            <cfelse>
                <cfset sendJSON({status:"error", message:"Could not add category", html:"", pagination:""})>
            </cfif>
        <cfcatch>
            <cfset sendJSON({status:"error", message:"#cfcatch.message#", html:"", pagination:""})>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- UPDATE CATEGORY --->
    <cffunction name="updateCategory" access="remote" returntype="void" output="true" httpmethod="POST">
        <cfset requireAuth()>
        <cfif NOT structKeyExists(form,"id") OR NOT len(trim(form.id))>
            <cfset sendJSON({status:"error", message:"ID required", html:"", pagination:""})>
        </cfif>
        <cftry>
            <cfset var categoryModel = createObject("component","models.Category")>
            <cfset var result = categoryModel.updateCategory(
                id            = form.id,
                category_name = trim(form.category_name),
                description   = trim(form.description)
            )>
            <cfif result>
                <cfset sendJSON({
                    status        : "success",
                    message       : "Category updated",
                    id            : form.id,
                    category_name : trim(form.category_name),
                    description   : trim(form.description),
                    html          : "",
                    pagination    : ""
                })>
            <cfelse>
                <cfset sendJSON({status:"error", message:"Could not update", html:"", pagination:""})>
            </cfif>
        <cfcatch>
            <cfset sendJSON({status:"error", message:"#cfcatch.message#", html:"", pagination:""})>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- TOGGLE STATUS --->
    <cffunction name="toggleStatus" access="remote" returntype="void" output="true" httpmethod="GET">
        <cfset requireAuth()>
        <cfif NOT structKeyExists(url,"id")>
            <cfset sendJSON({status:"error", message:"ID required", html:"", pagination:""})>
        </cfif>
        <cftry>
            <cfset var categoryModel = createObject("component","models.Category")>
            <cfset var newStatus     = url.currentStatus EQ 1 ? 0 : 1>
            <cfset var result        = categoryModel.toggleStatus(id=url.id, status=newStatus)>
            <cfif result>
                <cfset sendJSON({
                    status    : "success",
                    message   : "Status updated",
                    id        : url.id,
                    newStatus : newStatus,
                    html      : "",
                    pagination: ""
                })>
            <cfelse>
                <cfset sendJSON({status:"error", message:"Could not update status", html:"", pagination:""})>
            </cfif>
        <cfcatch>
            <cfset sendJSON({status:"error", message:"#cfcatch.message#", html:"", pagination:""})>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>