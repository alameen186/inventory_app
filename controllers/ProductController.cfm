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
            session.user_id,
            trim(form.expiry_date)
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
        <cfset result = productModel.updateProduct(id, productName, price, stock, category_id, imageName, trim(form.expiry_date))>

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

    <cfparam name="url.p"           default="1">
    <cfparam name="url.search"      default="">
    <cfparam name="url.sort"        default="">
    <cfparam name="url.category_id" default="">

    <cfset page  = val(url.p) GT 0 ? val(url.p) : 1>
    <cfset limit = 2>

    <cfset categoryModel = createObject("component","models.Category")>
    <cfset categories    = categoryModel.getAllActiveCategory(vendorFilter)>

    <cfset products = productModel.getAllProductsAdmin(
        search      = trim(url.search),
        sort        = url.sort,
        category_id = url.category_id,
        page        = page,
        limit       = limit,
        vendor_id   = vendorFilter
    )>

    <!--- GET TOTAL FOR PAGINATION --->
    <cfset totalRecords = productModel.getProductCountAdmin(
        search      = trim(url.search),
        category_id = url.category_id,
        vendor_id   = vendorFilter
    )>
    <cfset totalPages = ceiling(totalRecords / limit)>

    <!--- PAGINATION MATH --->
    <cfset groupSize = 4>
    <cfset pageGroup = ceiling(page / groupSize)>
    <cfset startPage = (pageGroup - 1) * groupSize + 1>
    <cfset endPage   = min(startPage + groupSize - 1, totalPages)>
    <cfset prevPage  = startPage - 1>
    <cfset nextPage  = endPage + 1>

    <!--- ROWS HTML --->
    <cfsavecontent variable="rowsHTML">
    <cfoutput query="products">

        <!--- VIEW ROW --->
        <tr id="viewRow_#id#">
            <td>#id#</td>
            <td>#product_name#</td>
            <td>#price#</td>
            <td>#stock#</td>
            <td>#category_name#</td>
            <td><cfif len(trim(expiry_date))>#dateFormat(expiry_date,"dd-mmm-yyyy")#<cfelse>-</cfif></td>
            <td>
                <cfif len(image)>
                    <img src="../../assets/images/products/#image#" width="50">
                <cfelse>No Image</cfif>
            </td>
            <td>
                <cfif is_active EQ 1>
                    <span class="badge bg-success">Active</span>
                <cfelse>
                    <span class="badge bg-warning text-dark">Blocked</span>
                </cfif>
            </td>
            <td>
                <div class="d-flex flex-wrap gap-1">
                    <button class="editBtn btn btn-warning btn-sm" data-id="#id#">Edit</button>
                    <button class="toggleBtn btn btn-sm #iif(is_active EQ 1, de('btn-danger'), de('btn-success'))#"
                        data-id="#id#" data-status="#is_active#">
                        <cfif is_active EQ 1>Block<cfelse>Unblock</cfif>
                    </button>
                </div>
            </td>
        </tr>

        <!--- EDIT ROW --->
        <tr id="editRow_#id#" style="display:none;">
            <td>#id#</td>
            <td><input value="#product_name#" class="form-control name" style="min-width:100px;"></td>
            <td><input value="#price#" class="form-control price" style="min-width:80px;"></td>
            <td><input value="#stock#" class="form-control stock" style="min-width:70px;"></td>
            <td>
                <select class="form-control category" style="min-width:110px;">
                    <cfloop query="categories">
                    <option value="#categories.id#"
                        <cfif categories.id EQ products.category_id>selected</cfif>>
                        #categories.category_name#
                    </option>
                    </cfloop>
                </select>
            </td>
            <td><input type="date" value="#expiry_date#" class="form-control expiry"></td>
            <td><input type="file" class="form-control image" style="min-width:120px;"></td>
            <td>
                <cfif is_active EQ 1>
                    <span class="badge bg-success">Active</span>
                <cfelse>
                    <span class="badge bg-warning text-dark">Blocked</span>
                </cfif>
            </td>
            <td>
                <div class="d-flex flex-wrap gap-1">
                    <button class="saveBtn btn btn-success btn-sm" data-id="#id#">Save</button>
                    <button class="cancelBtn btn btn-secondary btn-sm" data-id="#id#">Cancel</button>
                </div>
            </td>
        </tr>

    </cfoutput>
    </cfsavecontent>

    <!--- PAGINATION HTML --->
    <cfsavecontent variable="paginationHTML">
    <cfoutput>
    <div class="d-flex justify-content-center flex-wrap gap-2 mt-3">

        <cfif startPage GT 1>
            <button class="pageBtn btn btn-outline-primary btn-sm"
                data-page="#prevPage#">&laquo; Prev</button>
        </cfif>

        <cfloop from="#startPage#" to="#endPage#" index="i">
            <button class="pageBtn btn btn-sm
                <cfif i EQ page>btn-primary<cfelse>btn-outline-primary</cfif>"
                data-page="#i#">#i#</button>
        </cfloop>

        <cfif endPage LT totalPages>
            <button class="pageBtn btn btn-outline-primary btn-sm"
                data-page="#nextPage#">Next &raquo;</button>
        </cfif>

    </div>
    </cfoutput>
    </cfsavecontent>

    <!--- RETURN JSON WITH ROWS AND PAGINATION --->
    <cfcontent type="application/json">
    <cfoutput>
    {
        "rows": #serializeJSON(rowsHTML)#,
        "pagination": #serializeJSON(paginationHTML)#
    }
    </cfoutput>
    <cfabort>

</cfif>


<!-- USER SECTION -->
 
 <cfif structKeyExists(url,"action") AND url.action EQ "userSearch">

    <cfset productModel = createObject("component","models.Product")>

    <cfparam name="url.search"        default="">
    <cfparam name="url.category_id"   default="">
    <cfparam name="url.min_price"     default="">
    <cfparam name="url.max_price"     default="">
    <cfparam name="url.sort"          default="">
    <cfparam name="url.p"             default="1">
    <cfparam name="url.expiry_months" default="">

    <cfset limit       = 3>
    <cfset currentPage = val(url.p) GT 0 ? val(url.p) : 1>

    <!--- FETCH PRODUCTS --->
    <cfset products = productModel.searchProducts(
        keyword       = url.search,
        category_id   = isNumeric(url.category_id) ? url.category_id : javacast("null",""),
        min_price     = isNumeric(url.min_price) ? url.min_price : javacast("null",""),
        max_price     = isNumeric(url.max_price) ? url.max_price : javacast("null",""),
        sort          = url.sort,
        page          = currentPage,
        limit         = limit,
        expiry_months = url.expiry_months
    )>

    <!--- GET TOTAL COUNT FOR PAGINATION --->
    <cfset totalRecords = productModel.getProductCount(
        keyword       = url.search,
        category_id   = isNumeric(url.category_id) ? url.category_id : javacast("null",""),
        min_price     = isNumeric(url.min_price) ? url.min_price : javacast("null",""),
        max_price     = isNumeric(url.max_price) ? url.max_price : javacast("null",""),
        expiry_months = isNumeric(url.expiry_months) ? url.expiry_months : ""
    )>

    <!--- PAGINATION MATH --->
    <cfset totalPages = ceiling(totalRecords / limit)>
    <cfset groupSize  = 4>
    <cfset startPage  = ((currentPage - 1) \ groupSize) * groupSize + 1>
    <cfset endPage    = startPage + groupSize - 1>
    <cfif endPage GT totalPages>
        <cfset endPage = totalPages>
    </cfif>
    <cfset prevPage = startPage - 1>
    <cfset nextPage = endPage + 1>

    <!--- PRODUCT CARDS --->
    <cfsavecontent variable="productHTML">
        <cfoutput query="products">

            <div class="col-6 col-md-4 col-lg-3 mb-3 d-flex">
                <div class="card w-100">

                    <!--- IMAGE --->
                    <cfif len(image)>
                        <img src="../../assets/images/products/#image#"
                             class="img-fluid" style="height:180px; object-fit:cover;">
                    <cfelse>
                        <img src="https://via.placeholder.com/200"
                             class="card-img-top" style="height:200px; object-fit:cover;">
                    </cfif>

                    <!--- BODY --->
                    <div class="card-body text-center d-flex flex-column justify-content-between p-2">
                        <div>
                            <h5 class="card-title">#product_name#</h5>
                            <p class="small text-muted mb-1">
                                Sold by: <strong>#business_name#</strong>
                            </p>
                            <cfif len(trim(expiry_date))>
                                <p class="small text-muted mb-1">
                                    Expires: #dateFormat(expiry_date,"dd-mmm-yyyy")#
                                </p>
                            </cfif>
                            <p class="mb-1">#category_name#</p>
                            <p class="mb-2">#price# /-</p>
                        </div>

                        <div>
                            <cfif stock LTE 0>
                                <p class="text-danger fw-bold mb-2">Out of Stock</p>
                                <form class="enquiryForm" method="post">
                                    <input type="hidden" name="action" value="addEnquiry">
                                    <input type="hidden" name="product_id" value="#id#">
                                    <button class="btn btn-warning btn-sm w-100">Request Product</button>
                                </form>
                            <cfelse>
                                <form class="addToCartForm" method="post">
                                    <input type="hidden" name="action" value="add">
                                    <input type="hidden" name="product_id" value="#id#">
                                    <input type="hidden" name="product_name" value="#product_name#">
                                    <input type="hidden" name="price" value="#price#">
                                    <input type="hidden" name="image" value="#image#">
                                    <button class="btn btn-success btn-sm w-100">Add</button>
                                </form>
                            </cfif>
                        </div>
                    </div>

                </div>
            </div>

        </cfoutput>
    </cfsavecontent>

    <!--- PAGINATION BUTTONS --->
    <cfsavecontent variable="paginationHTML">
        <cfoutput>
        <div class="d-flex gap-2 justify-content-center mt-3">

            <!--- PREV --->
            <cfif startPage GT 1>
                <button class="pageBtn btn btn-outline-primary"
                    data-page="#prevPage#">Prev</button>
            </cfif>

            <!--- PAGE NUMBERS --->
            <cfloop from="#startPage#" to="#endPage#" index="i">
                <button class="pageBtn btn btn-sm
                    <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
                    data-page="#i#">#i#</button>
            </cfloop>

            <!--- NEXT --->
            <cfif endPage LT totalPages>
                <button class="pageBtn btn btn-outline-primary"
                    data-page="#nextPage#">Next</button>
            </cfif>

        </div>
        </cfoutput>
    </cfsavecontent>

    <!--- RETURN BOTH PRODUCTS AND PAGINATION AS JSON --->
    <cfcontent type="application/json">
    <cfoutput>
    {
        "products": #serializeJSON(productHTML)#,
        "pagination": #serializeJSON(paginationHTML)#
    }
    </cfoutput>
    <cfabort>

</cfif>