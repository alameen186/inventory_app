<!---Add category--->

<cfif structKeyExists(form, "action") AND form.action EQ "add">

    <cfset categoryModel = createObject("component","models.Category")>

    <cfset category_name = trim(form.category_name)>
    <cfset description = trim(form.description)>

    <cfset baseUrl = "../index.cfm?page=dashboard&section=category">

    <cfif len(category_name) LT 3>

        <cflocation url="#baseUrl#&message=Category name must be at least 3 characters&type=error&showForm=1" addtoken="false">
        <cfabort>

    <cfelseif len(category_name) GT 20>

        <cflocation url="#baseUrl#&message=Category name must be less than 20 characters&type=error&showForm=1" addtoken="false">
        <cfabort>

    <cfelseif len(description) LT 5>

        <cflocation url="#baseUrl#&message=Description must be at least 5 characters&type=error&showForm=1" addtoken="false">
        <cfabort>

    <cfelseif len(description) GT 255>

        <cflocation url="#baseUrl#&message=Description must be less than 255 characters&type=error&showForm=1" addtoken="false">
        <cfabort>

    <cfelse>

       <cfset category = CategoryModel.getAllCategories()>
       <cfif category_name EQ category.category_name>

        <cflocation url="#baseUrl#&message=Category already exist&type=error&showForm=1" addtoken="false">
        <cfabort>

        </cfif>


        <cfset categoryModel.addCategory(category_name, description)>

        <cflocation url="#baseUrl#&message=Category Added successfully&type=success" addtoken="false">
        <cfabort>

    </cfif>

</cfif>

<!---edit--->

<cfif structKeyExists(form, "action") AND form.action EQ "update">

    <cfset category_name = trim(form.category_name)>
    <cfset description = trim(form.description)>

    <cfset baseUrl = "../index.cfm?page=dashboard&section=category">

    <cfif len(category_name) LT 3>
        <cflocation url="#baseUrl#&message=category name must be at least 3 characters&type=error&editId=#form.id#" addtoken="false">
        <cfabort>

    <cfelseif len(category_name) GT 20>
        <cflocation url="#baseUrl#&message=category name must be less than 20 characters&type=error&editId=#form.id#" addtoken="false">
        <cfabort>

    <cfelseif len(description) LT 5>
        <cflocation url="#baseUrl#&message=Description name must be at least 5 character&type=error&editId=#form.id#" addtoken="false">
        <cfabort>

    <cfelseif len(description) GT 255>
        <cflocation url="#baseUrl#&message=Description name must be less than 255 characters&type=error&editId=#form.id#" addtoken="false">
        <cfabort>

    <cfelse>

        <cfset CategoryModel = createObject("component","models.Category")>

        <cfset categoryModel.update_category(
            form.id,
            category_name,
            description
        )>

        <cflocation url="#baseUrl#&message=Category updated successfully&type=success" addtoken="false">
        <cfabort>

    </cfif>

</cfif>

<!---toggle status--->
<cfif structKeyExists(url, "action") AND url.action EQ "block">

    <cfif NOT structKeyExists(url, "id") OR NOT isNumeric(url.id)>
        <cfabort>
    </cfif>
    <cfif NOT structKeyExists(url, "currentStatus") OR NOT isNumeric(url.currentStatus)>
        <cfabort>
    </cfif>

    <cfset categoryModel = createObject("component", "models.Category")>

    <cfset newStatus = (url.currentStatus EQ 1 ? 0 : 1)>

    <cfset categoryModel.toggleStatus(url.id, newStatus)>

    <cflocation url="../index.cfm?page=dashboard&section=category&message=Updated&type=success" addtoken="false">
    <cfabort>
</cfif>

