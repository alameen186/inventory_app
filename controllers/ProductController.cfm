<!-- ADD PRODUCT -->
<cfif structKeyExists(form, "action") AND form.action EQ "add">

<cfset productModel = createObject("component","models.Product")>

<cfset productName = trim(form.product_name)>
<cfset price = val(form.price)>
<cfset stock = val(form.stock)>
<cfset category_id = val(form.category_id)>

<!-- VALIDATION -->
<cfif len(productName) LT 3>
<cfcontent type="application/json" reset="true">
<cfoutput>{"status":"error","message":"Product name must be at least 3 characters"}</cfoutput>
<cfabort>

<cfelseif len(productName) GT 50>
<cfcontent type="application/json" reset="true">
<cfoutput>{"status":"error","message":"Product name too long"}</cfoutput>
<cfabort>

<cfelseif price LTE 0>
<cfcontent type="application/json" reset="true">
<cfoutput>{"status":"error","message":"Invalid price"}</cfoutput>
<cfabort>

<cfelseif stock LT 0>
<cfcontent type="application/json" reset="true">
<cfoutput>{"status":"error","message":"Invalid stock"}</cfoutput>
<cfabort>

<cfelseif category_id LTE 0>
<cfcontent type="application/json" reset="true">
<cfoutput>{"status":"error","message":"Invalid category"}</cfoutput>
<cfabort>
</cfif>

<!-- DUPLICATE CHECK -->
<cfset qAllProducts = productModel.getAllProducts()>
<cfset existingNames = valueList(qAllProducts.product_name)>

<cfif listFindNoCase(existingNames, productName)>
<cfcontent type="application/json" reset="true">
<cfoutput>{"status":"error","message":"Product name already exists"}</cfoutput>
<cfabort>
</cfif>

<cfset imageName = "">

<cftry>

<cfif structKeyExists(form, "product_image") AND len(form.product_image)>
    <cfset uploadPath = expandPath('../assets/images/products/')>

    <cffile action="upload"
        filefield="product_image"
        destination="#uploadPath#"
        nameconflict="makeunique"
        accept="image/jpeg,image/png,image/jpg">

    <cfset imageName = cffile.serverFile>
</cfif>

<cfset result = productModel.addProduct(productName, price, stock, category_id, imageName)>

<cfif result>
    <cfcontent type="application/json" reset="true">
    <cfoutput>{"status":"success","message":"Product added successfully"}</cfoutput>
<cfelse>
    <cfcontent type="application/json" reset="true">
    <cfoutput>{"status":"error","message":"Insert failed"}</cfoutput>
</cfif>

<cfabort>

<cfcatch>
<cfcontent type="application/json" reset="true">
<cfoutput>{"status":"error","message":"#cfcatch.message#"}</cfoutput>
<cfabort>
</cfcatch>

</cftry>

</cfif>

<!-- UPDATE PRODUCT -->
<cfif structKeyExists(form, "action") AND form.action EQ "update">

<cfset productModel = createObject("component","models.Product")>

<cfset productName = trim(form.product_name)>
<cfset price = val(form.price)>
<cfset stock = val(form.stock)>
<cfset category_id = val(form.category_id)>
<cfset id = val(form.id)>

<!-- VALIDATION -->
<cfif len(productName) LT 3>
<cfcontent type="application/json" reset="true">
<cfoutput>{"status":"error","message":"Product name must be at least 3 characters"}</cfoutput>
<cfabort>

<cfelseif price LTE 0>
<cfcontent type="application/json" reset="true">
<cfoutput>{"status":"error","message":"Invalid price"}</cfoutput>
<cfabort>

<cfelseif stock LT 0>
<cfcontent type="application/json" reset="true">
<cfoutput>{"status":"error","message":"Invalid stock"}</cfoutput>
<cfabort>

<cfelseif category_id LTE 0>
<cfcontent type="application/json" reset="true">
<cfoutput>{"status":"error","message":"Invalid category"}</cfoutput>
<cfabort>
</cfif>

<cfset imageName = "">
<cfset oldProduct = productModel.getProductById(id)>
<cfset imageName = oldProduct.image>

<cftry>

<cfif structKeyExists(form, "product_image") AND len(form.product_image)>
    <cffile action="upload"
        filefield="product_image"
        destination="#expandPath('../assets/images/products/')#"
        nameconflict="makeunique"
        accept="image/jpeg,image/png,image/jpg">
    <cfset imageName = cffile.serverFile>
</cfif>

<cfset result = productModel.updateProduct(id, productName, price, stock, category_id, imageName)>

<cfif result>
    <cfcontent type="application/json" reset="true">
    <cfoutput>{"status":"success","message":"Product updated successfully"}</cfoutput>
<cfelse>
    <cfcontent type="application/json" reset="true">
    <cfoutput>{"status":"error","message":"Update failed"}</cfoutput>
</cfif>

<cfabort>

<cfcatch>
<cfcontent type="application/json" reset="true">
<cfoutput>{"status":"error","message":"Something went wrong"}</cfoutput>
<cfabort>
</cfcatch>

</cftry>

</cfif>


<!-- TOGGLE -->
<cfif structKeyExists(url, "action") AND url.action EQ "block">

<cfset productModel = createObject("component", "models.Product")>

<cfset newStatus = (url.currentStatus EQ 1 ? 0 : 1)>
<cfset productModel.toggleStatus(url.id, newStatus)>

<cfcontent type="application/json" reset="true">
<cfoutput>
{
    "status":"success",
    "message":"Status updated",
    "id":"#url.id#",
    "newStatus":"#newStatus#"
}
</cfoutput>
<cfabort>

</cfif>
<!-- search -->
<cfif structKeyExists(url,"action") AND url.action EQ "search">

    <cfset productModel = createObject("component","models.Product")>

    <cfparam name="url.p" default="1">
    <cfparam name="url.search" default="">
    <cfparam name="url.sort" default="">
    <cfparam name="url.category_id" default="">

    <cfset q = productModel.getAllProductsAdmin(
        search=url.search,
        sort=url.sort,
        category_id=url.category_id,
        page=url.p,
        limit=3
    )>

    <cfoutput query="q">
        <tr>
            <td>#id#</td>
            <td>#product_name#</td>
            <td>#price#</td>
            <td>#stock#</td>
            <td>#category_name#</td>
            <td>
                <cfif len(image)>
                    <img src="../../assets/images/products/#image#" width="50">
                <cfelse>
                    No Image
                </cfif>
            </td>
            <td>
                <cfif is_active EQ 1>
                    <span class="badge bg-success">Active</span>
                <cfelse>
                    <span class="badge bg-warning">Blocked</span>
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

<cfabort>
</cfif>