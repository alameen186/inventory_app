<!-- ADD -->
<cfif structKeyExists(form, "action") AND form.action EQ "add">

    <cfset categoryModel = createObject("component","models.Category")>

    <cfset category_name = trim(form.category_name)>
    <cfset description = trim(form.description)>

    <!-- VALIDATION -->
    <cfif len(category_name) LT 3>
        <cfcontent type="application/json" reset="true">
        <cfoutput>{"status":"error","message":"Category name must be at least 3 characters"}</cfoutput>
        <cfabort>
    </cfif>

    <cfif len(description) LT 5>
        <cfcontent type="application/json" reset="true">
        <cfoutput>{"status":"error","message":"Description must be at least 5 characters"}</cfoutput>
        <cfabort>
    </cfif>

    <cfif categoryModel.isCategoryExists(category_name)>
        <cfcontent type="application/json" reset="true">
        <cfoutput>{"status":"error","message":"Category already exists"}</cfoutput>
        <cfabort>
    </cfif>

    <!-- INSERT -->
   <cfset vendorId = session.user_id>

<cfset newId = categoryModel.addCategory(
    category_name,
    description,
    vendorId
)>

    <cfcontent type="application/json" reset="true">
    <cfoutput>
    {
        "status":"success",
        "message":"Category added",
        "id":"#newId#",
        "category_name":"#category_name#",
        "description":"#description#"
    }
    </cfoutput>
    <cfabort>
</cfif>



<!-- UPDATE -->
<cfif structKeyExists(form, "action") AND form.action EQ "update">

    <cfset categoryModel = createObject("component","models.Category")>

    <cfset category_name = trim(form.category_name)>
    <cfset description = trim(form.description)>

    <!-- VALIDATION -->
    <cfif len(category_name) LT 3>
        <cfcontent type="application/json" reset="true">
        <cfoutput>{"status":"error","message":"Category name must be at least 3 characters"}</cfoutput>
        <cfabort>
    </cfif>

    <cfif len(description) LT 5>
        <cfcontent type="application/json" reset="true">
        <cfoutput>{"status":"error","message":"Description must be at least 5 characters"}</cfoutput>
        <cfabort>
    </cfif>

    <!-- UPDATE -->
    <cfset categoryModel.update_category(form.id, category_name, description)>

    <cfcontent type="application/json" reset="true">
    <cfoutput>
    {
        "status":"success",
        "message":"Updated successfully",
        "id":"#form.id#",
        "category_name":"#category_name#",
        "description":"#description#"
    }
    </cfoutput>
    <cfabort>
</cfif>



<!-- TOGGLE -->
<cfif structKeyExists(url,"action") AND url.action EQ "block">

    <cfset categoryModel = createObject("component","models.Category")>

    <cfset newStatus = (url.currentStatus EQ 1 ? 0 : 1)>
    <cfset categoryModel.toggleStatus(url.id, newStatus)>

    <cfcontent type="application/json" reset="true">
    <cfoutput>
    {
        "status":"success",
        "id":"#url.id#",
        "newStatus":"#newStatus#"
    }
    </cfoutput>
    <cfabort>
</cfif>



<!-- SEARCH -->
<cfif structKeyExists(url,"action") AND url.action EQ "search">

    <cfset categoryModel = createObject("component","models.Category")>

    <cfparam name="url.p" default="1">
    <cfparam name="url.search" default="">
    <cfparam name="url.sort" default="">

    <cfset page = val(url.p)>
    <cfif page LT 1><cfset page = 1></cfif>

    <cfset limit = 5>


    <cfif structKeyExists(session,"role_name") AND session.role_name EQ "vendor">
        <cfset vendorFilter = session.user_id>
    <cfelse>
        <cfset vendorFilter = "">
    </cfif>

    <cfset q = categoryModel.getAllCategories(
        search = trim(url.search),
        sort = url.sort,
        page = page,
        limit = limit,
        vendor_id = vendorFilter
    )>

    <cfoutput query="q">
        <tr id="categoryRow_#id#">
            <td>#id#</td>
            <td>#category_name#</td>
            <td>#description#</td>
            <td>
                <cfif is_active EQ 1>
                    <p class="text-success">Active</p>
                <cfelse>
                    <p class="text-warning">Blocked</p>
                </cfif>
            </td>
            <td>
                <button class="editBtn btn btn-warning btn-sm" data-id="#id#">Edit</button>
                <button class="toggleStatusBtn btn btn-danger btn-sm"
                        data-id="#id#" data-status="#is_active#">
                    <cfif is_active EQ 1>Block<cfelse>Unblock</cfif>
                </button>
            </td>
        </tr>
    </cfoutput>

    <cfif q.recordCount EQ 0>
        <tr><td colspan="5" class="text-center text-danger">No records found</td></tr>
    </cfif>

    <cfabort>
</cfif>