<!-- Vendor filter -->
<cfif structKeyExists(session,"role_name") AND session.role_name EQ "vendor">
    <cfset vendorFilter = session.user_id>
<cfelse>
    <cfset vendorFilter = "">
</cfif>

<cfset productModel = createObject("component","models.Product")>


<!-- ADMIN SECTION -->


<!--  ADD PRODUCT  -->
<cfif structKeyExists(form, "action") AND form.action EQ "add">

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

        <!-- IMAGE UPLOAD -->
        <cfif structKeyExists(form, "product_image") AND len(form.product_image)>
            <cffile action="upload"
                filefield="product_image"
                destination="#expandPath('../assets/images/products/')#"
                nameconflict="makeunique"
                accept="image/jpeg,image/png,image/jpg">
            <cfset imageName = cffile.serverFile>
        </cfif>

        <!-- SESSION CHECK -->
        <cfif NOT structKeyExists(session, "user_id")>
            <cfcontent type="application/json" reset="true">
            <cfoutput>{"status":"error","message":"Session expired"}</cfoutput>
            <cfabort>
        </cfif>

        <!-- INSERT -->
        <cfset result = productModel.addProduct(
            productName,
            price,
            stock,
            category_id,
            imageName,
            session.user_id
        )>

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



<!--  UPDATE PRODUCT  -->
<cfif structKeyExists(form, "action") AND form.action EQ "update">

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

    <!-- EXISTING IMAGE -->
    <cfset oldProduct = productModel.getProductById(id)>
    <cfset imageName = oldProduct.image>

    <cftry>

        <!-- IMAGE UPDATE -->
        <cfif structKeyExists(form, "product_image") AND len(form.product_image)>
            <cffile action="upload"
                filefield="product_image"
                destination="#expandPath('../assets/images/products/')#"
                nameconflict="makeunique"
                accept="image/jpeg,image/png,image/jpg">
            <cfset imageName = cffile.serverFile>
        </cfif>

        <!-- UPDATE -->
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



<!--  TOGGLE STATUS  -->
<cfif structKeyExists(url, "action") AND url.action EQ "block">

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



<!--  ADMIN SEARCH  -->
<cfif structKeyExists(url,"action") AND url.action EQ "search">

    <cfparam name="url.p" default="1">
    <cfparam name="url.search" default="">
    <cfparam name="url.sort" default="">
    <cfparam name="url.category_id" default="">

    <cfset page = val(url.p)>
    <cfif page LT 1><cfset page = 1></cfif>

    <cfset limit = 3>

    <cfset products = productModel.getAllProductsAdmin(
        search = trim(url.search),
        sort = url.sort,
        category_id = url.category_id,
        page = page,
        limit = limit,
        vendor_id = vendorFilter
    )>

    <!-- RETURN TABLE ROWS -->
    <cfoutput query="products">
        <tr>
            <td>#id#</td>
            <td>#product_name#</td>
            <td>#price#</td>
            <td>#stock#</td>
            <td>#category_name#</td>
            <td>
                <cfif len(image)>
                    <img src="../../assets/images/products/#image#" width="50">
                <cfelse>No Image</cfif>
            </td>
            <td>
                <cfif is_active EQ 1>
                    <span class="badge bg-success">Active</span>
                <cfelse>
                    <span class="badge bg-warning">Blocked</span>
                </cfif>
            </td>
            <td>...</td>
        </tr>
    </cfoutput>

    <cfabort>
</cfif>



<!-- USER SECTION -->

<!--  USER SEARCH  -->
<cfif structKeyExists(url,"action") AND url.action EQ "userSearch">

    <cfset productModel = createObject("component","models.Product")>

    <cfparam name="url.search" default="">
    <cfparam name="url.category_id" default="">
    <cfparam name="url.min_price" default="">
    <cfparam name="url.max_price" default="">
    <cfparam name="url.sort" default="">
    <cfparam name="url.p" default="1">

    <!-- FETCH DATA -->
    <cfset products = productModel.searchProducts(
        keyword = url.search,
        category_id = isNumeric(url.category_id) ? url.category_id : javacast("null",""),
        min_price = isNumeric(url.min_price) ? url.min_price : javacast("null",""),
        max_price = isNumeric(url.max_price) ? url.max_price : javacast("null",""),
        sort = url.sort,
        page = val(url.p),
        limit = 3 
    )>

    <!-- CAPTURE HTML -->
    <cfsavecontent variable="productHTML">
        <cfoutput query="products">

            <div class="col-6 col-md-4 col-lg-3 mb-3 d-flex">
                <div class="card w-100">

                    <!-- IMAGE -->
                    <cfif len(image)>
                        <img src="../../assets/images/products/#image#" class="img-fluid" style="height:180px; object-fit:cover;">
                    <cfelse>
                        <img src="https://via.placeholder.com/200" class="card-img-top" style="height:200px; object-fit:cover;">
                    </cfif>

                    <!-- BODY -->
                    <div class="card-body text-center d-flex flex-column justify-content-between p-2">

                        <div>
                            <h5 class="card-title">#product_name#</h5>
                            <p class="mb-1">#category_name#</p>
                            <p class="mb-2">#price# /-</p>
                        </div>

                        <div>
                            <cfif stock LTE 0>
                                <p class="text-danger fw-bold mb-2">Out of Stock</p>
                            <cfelse>
                                <button class="btn btn-success btn-sm w-100">Add</button>
                            </cfif>
                        </div>

                    </div>

                </div>
            </div>

        </cfoutput>
    </cfsavecontent>

    <!-- RETURN RESPONSE -->
    <cfoutput>#productHTML#</cfoutput>
    <cfabort>

</cfif>