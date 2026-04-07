<!--- ================= SECURITY ================= --->
<cfif NOT structKeyExists(session, "role_id") OR session.role_id NEQ 1>
    <cfabort>
</cfif>


<!--- ADD PRODUCT --->
<cfif structKeyExists(form, "action") AND form.action EQ "add">

    <cfset productModel = createObject("component","models.Product")>
    
    <cfset productName = trim(form.product_name)>
    <cfset price = val(form.price)>
    <cfset category_id = val(form.category_id)>
    <cfset baseUrl = "../index.cfm?page=dashboard&section=products">

    <cfset qAllProducts = productModel.getAllProducts()>
    <cfset existingNames = valueList(qAllProducts.product_name)>

    <cfif len(productName) LT 3>
        <cflocation url="#baseUrl#&message=Product name must be at least 3 characters&type=error&showForm=1" addtoken="false">
        <cfabort>
    <cfelseif len(productName) GT 50>
        <cflocation url="#baseUrl#&message=Product name too long&type=error&showForm=1" addtoken="false">
        <cfabort>
    <!--- FIXED: This now checks every existing product name, not just the first one --->
    <cfelseif listFindNoCase(existingNames, productName)>
        <cflocation url="#baseUrl#&message=Product name already exists&type=error&showForm=1" addtoken="false">
        <cfabort>
    <cfelseif price LTE 0>
        <cflocation url="#baseUrl#&message=Invalid price&type=error&showForm=1" addtoken="false">
        <cfabort>
    <cfelseif category_id LTE 0>
        <cflocation url="#baseUrl#&message=Invalid category&type=error&showForm=1" addtoken="false">
        <cfabort>
    </cfif>

    <cfset imageName = "">

    <cftry>
        <cfif structKeyExists(form, "product_image") AND len(form.product_image)>
            <cfset uploadPath = expandPath('../assets/images/products/')>
            
            <cfif NOT directoryExists(uploadPath)>
                <cfdirectory action="create" directory="#uploadPath#">
            </cfif>

            <cffile 
                action="upload"
                filefield="product_image"
                destination="#uploadPath#"
                nameconflict="makeunique"
                accept="image/jpeg,image/png,image/jpg">
            <cfset imageName = cffile.serverFile>
        </cfif>

        <cfset result = productModel.addProduct(productName, price, category_id, imageName)>

        <cfif result>
            <cflocation url="#baseUrl#&message=Product added successfully&type=success" addtoken="false">
        <cfelse>
            <cfif len(imageName)>
                <cffile action="delete" file="#uploadPath##imageName#">
            </cfif>
            <cflocation url="#baseUrl#&message=Insert failed&type=error&showForm=1" addtoken="false">
        </cfif>
        <cfabort>

    <cfcatch>
        <cfif len(imageName) AND fileExists(uploadPath & imageName)>
            <cffile action="delete" file="#uploadPath##imageName#">
        </cfif>
        <cflocation url="#baseUrl#&message=Something went wrong: #cfcatch.message#&type=error&showForm=1" addtoken="false">
        <cfabort>
    </cfcatch>

    </cftry>

</cfif>




<!--- UPDATE PRODUCT --->
<cfif structKeyExists(form, "action") AND form.action EQ "update">

    <cfset productModel = createObject("component","models.Product")>

    <cfset productName = trim(form.product_name)>
    <cfset price = val(form.price)>
    <cfset category_id = val(form.category_id)>
    <cfset id = val(form.id)>

    <cfset baseUrl = "../index.cfm?page=dashboard&section=products">

    <!--- VALIDATION --->
    <cfif len(productName) LT 3>
        <cflocation url="#baseUrl#&message=Product name must be at least 3 characters&type=error&editId=#id#" addtoken="false">
        <cfabort>

    <cfelseif price LTE 0>
        <cflocation url="#baseUrl#&message=Invalid price&type=error&editId=#id#" addtoken="false">
        <cfabort>

    <cfelseif category_id LTE 0>
        <cflocation url="#baseUrl#&message=Invalid category&type=error&editId=#id#" addtoken="false">
        <cfabort>
    </cfif>

    <cfset imageName = "">

    <cfset oldProduct = productModel.getProductById(id)>
    <cfset imageName = oldProduct.image>

    <cftry>

        <cfif structKeyExists(form, "product_image") AND len(form.product_image)>
            <cffile 
                action="upload"
                filefield="product_image"
                destination="#expandPath('../assets/images/products/')#"
                nameconflict="makeunique"
                accept="image/jpeg,image/png,image/jpg">
            <cfset imageName = cffile.serverFile>
        </cfif>

        <cfset result = productModel.updateProduct(id, productName, price, category_id, imageName)>

        <cfif result>
            <cflocation url="#baseUrl#&message=Product updated successfully&type=success" addtoken="false">
        <cfelse>
            <cflocation url="#baseUrl#&message=Update failed&type=error&editId=#id#" addtoken="false">
        </cfif>
        <cfabort>

    <cfcatch>
        <cflocation url="#baseUrl#&message=Something went wrong&type=error&editId=#id#" addtoken="false">
        <cfabort>
    </cfcatch>

    </cftry>

</cfif>



<!--- TOGGLE STATUS --->
<cfif structKeyExists(url, "action") AND url.action EQ "block">

    <cfif NOT structKeyExists(url, "id") OR NOT isNumeric(url.id)>
        <cfabort>
    </cfif>

    <cfif NOT structKeyExists(url, "currentStatus") OR NOT isNumeric(url.currentStatus)>
        <cfabort>
    </cfif>

    <cfset productModel = createObject("component", "models.Product")>

    <cfset newStatus = (url.currentStatus EQ 1 ? 0 : 1)>

    <cfset productModel.toggleStatus(url.id, newStatus)>

    <cflocation url="../index.cfm?page=dashboard&section=products&message=Updated&type=success" addtoken="false">
    <cfabort>

</cfif>