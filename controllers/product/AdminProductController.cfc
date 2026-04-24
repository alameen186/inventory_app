<cfcomponent output="false">

    <cffunction name="jsonRes" access="private" returntype="void" output="true">
        <cfargument name="success"  type="boolean" required="true">
        <cfargument name="message"  type="string"  default="">
        <cfargument name="data"     type="any"     default="">
        <cfcontent type="application/json; charset=utf-8" reset="true">
        <cfoutput>#serializeJSON({
            "success" : arguments.success,
            "message" : arguments.message,
            "data"    : arguments.data
        })#</cfoutput>
    </cffunction>

    <!--- vendor filter --->
    <cffunction name="getVendorFilter" access="private" returntype="string">
        <cfif structKeyExists(session,"role_name") AND session.role_name EQ "vendor">
            <cfreturn session.user_id>
        </cfif>
        <cfreturn "">
    </cffunction>

    <!---  auth check helper  --->
    <cffunction name="checkAuth" access="private" returntype="void" output="true">
        <cfif NOT structKeyExists(session,"user_id")>
            <cfset jsonRes(false, "Session expired. Please login.")>
            <cfabort>
        </cfif>
    </cffunction>

    <!--- ADD PRODUCT --->
    <cffunction name="add" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset checkAuth()>
        <cfset var productModel = createObject("component","models.Product")>

        <cftry>
            <cfset var productName  = trim(form.product_name)>
            <cfset var price        = val(form.price)>
            <cfset var stock        = val(form.stock)>
            <cfset var category_id  = val(form.category_id)>
            <cfset var expiry_date  = trim(form.expiry_date)>

            <!--- validation --->
            <cfif len(productName) LT 3>
                <cfset jsonRes(false, "Product name must be at least 3 characters")><cfreturn>
            </cfif>
            <cfif len(productName) GT 50>
                <cfset jsonRes(false, "Product name too long")><cfreturn>
            </cfif>
            <cfif price LTE 0>
                <cfset jsonRes(false, "Invalid price")><cfreturn>
            </cfif>
            <cfif stock LT 0>
                <cfset jsonRes(false, "Invalid stock")><cfreturn>
            </cfif>
            <cfif category_id LTE 0>
                <cfset jsonRes(false, "Invalid category")><cfreturn>
            </cfif>

            <!--- duplicate check --->
            <cfset var existing = productModel.getAllProducts()>
            <cfif listFindNoCase(valueList(existing.product_name), productName)>
                <cfset jsonRes(false, "Product name already exists")><cfreturn>
            </cfif>

            <!--- image upload --->
            <cfset var imageName = "">
            <cfif structKeyExists(form,"product_image") AND len(form.product_image)>
                <cffile action="upload"
                    filefield="product_image"
                    destination="#expandPath('../../assets/images/products/')#"
                    nameconflict="makeunique"
                    accept="image/jpeg,image/png,image/jpg">
                <cfset imageName = cffile.serverFile>
            </cfif>

            <!--- insert --->
            <cfset var result = productModel.addProduct(
                productName, price, stock,
                category_id, imageName,
                session.user_id, expiry_date
            )>

            <cfif result>
                <cfset jsonRes(true, "Product added successfully")>
            <cfelse>
                <cfset jsonRes(false, "Insert failed")>
            </cfif>

        <cfcatch>
            <cfset jsonRes(false, "Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- UPDATE PRODUCT --->
    <cffunction name="update" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset checkAuth()>
        <cfset var productModel = createObject("component","models.Product")>

        <cftry>
            <cfset var id          = val(form.id)>
            <cfset var productName = trim(form.product_name)>
            <cfset var price       = val(form.price)>
            <cfset var stock       = val(form.stock)>
            <cfset var category_id = val(form.category_id)>
            <cfset var expiry_date = trim(form.expiry_date)>

            <!--- validation --->
            <cfif len(productName) LT 3>
                <cfset jsonRes(false, "Product name must be at least 3 characters")><cfreturn>
            </cfif>
            <cfif price LTE 0>
                <cfset jsonRes(false, "Invalid price")><cfreturn>
            </cfif>
            <cfif stock LT 0>
                <cfset jsonRes(false, "Invalid stock")><cfreturn>
            </cfif>
            <cfif category_id LTE 0>
                <cfset jsonRes(false, "Invalid category")><cfreturn>
            </cfif>

            <!--- keep existing image by default --->
            <cfset var oldProduct = productModel.getProductById(id)>
            <cfset var imageName  = oldProduct.image>

            <!--- image update if new file uploaded --->
            <cfif structKeyExists(form,"product_image") AND len(form.product_image)>
                <cffile action="upload"
                    filefield="product_image"
                    destination="#expandPath('../../assets/images/products/')#"
                    nameconflict="makeunique"
                    accept="image/jpeg,image/png,image/jpg">
                <cfset imageName = cffile.serverFile>
            </cfif>

            <cfset var result = productModel.updateProduct(
                id, productName, price, stock,
                category_id, imageName, expiry_date
            )>

            <cfif result>
                <cfset jsonRes(true, "Product updated successfully")>
            <cfelse>
                <cfset jsonRes(false, "Update failed")>
            </cfif>

        <cfcatch>
            <cfset jsonRes(false, "Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- TOGGLE STATUS --->
    <cffunction name="toggleStatus" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset checkAuth()>
        <cfset var productModel = createObject("component","models.Product")>

        <cftry>
            <cfset var id        = val(url.id)>
            <cfset var newStatus = (url.currentStatus EQ 1 ? 0 : 1)>

            <cfset productModel.toggleStatus(id, newStatus)>

            <cfset jsonRes(true, "Status updated", {
                "id"        : id,
                "newStatus" : newStatus
            })>

        <cfcatch>
            <cfset jsonRes(false, "Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- SEARCH / PAGINATION --->
    <cffunction name="search" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset checkAuth()>
        <cfset var productModel  = createObject("component","models.Product")>
        <cfset var categoryModel = createObject("component","models.Category")>
        <cfset var vendorFilter  = getVendorFilter()>

        <cftry>
            <cfset var srch        = structKeyExists(url,"search")      ? trim(url.search)      : "">
            <cfset var sort        = structKeyExists(url,"sort")        ? url.sort              : "">
            <cfset var cat_id      = structKeyExists(url,"category_id") ? url.category_id       : "">
            <cfset var page        = structKeyExists(url,"p")           ? val(url.p)            : 1>
            <cfset var limit       = 2>

            <cfif page LT 1><cfset page = 1></cfif>

            <cfset var categories = categoryModel.getAllActiveCategory(vendorFilter)>

            <cfset var products = productModel.getAllProductsAdmin(
                search      = srch,
                sort        = sort,
                category_id = cat_id,
                page        = page,
                limit       = limit,
                vendor_id   = vendorFilter
            )>

            <cfset var totalRecords = productModel.getProductCountAdmin(
                search      = srch,
                category_id = cat_id,
                vendor_id   = vendorFilter
            )>
            <cfset var totalPages = ceiling(totalRecords / limit)>

            <!--- pagination math --->
            <cfset var groupSize = 4>
            <cfset var pageGroup = ceiling(page / groupSize)>
            <cfset var startPage = (pageGroup - 1) * groupSize + 1>
            <cfset var endPage   = min(startPage + groupSize - 1, totalPages)>
            <cfset var prevPage  = startPage - 1>
            <cfset var nextPage  = endPage + 1>

            <!--- build rows HTML --->
            <cfsavecontent variable="rowsHTML">
            <cfoutput query="products">
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
                            <button class="toggleBtn btn btn-sm #iif(is_active EQ 1,de('btn-danger'),de('btn-success'))#"
                                data-id="#id#" data-status="#is_active#">
                                <cfif is_active EQ 1>Block<cfelse>Unblock</cfif>
                            </button>
                        </div>
                    </td>
                </tr>
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

            <!--- build pagination HTML --->
            <cfsavecontent variable="paginationHTML">
            <cfoutput>
            <div class="d-flex justify-content-center flex-wrap gap-2 mt-3">
                <cfif startPage GT 1>
                    <button class="pageBtn btn btn-outline-primary btn-sm" data-page="#prevPage#">&laquo; Prev</button>
                </cfif>
                <cfloop from="#startPage#" to="#endPage#" index="i">
                    <button class="pageBtn btn btn-sm <cfif i EQ page>btn-primary<cfelse>btn-outline-primary</cfif>"
                        data-page="#i#">#i#</button>
                </cfloop>
                <cfif endPage LT totalPages>
                    <button class="pageBtn btn btn-outline-primary btn-sm" data-page="#nextPage#">Next &raquo;</button>
                </cfif>
            </div>
            </cfoutput>
            </cfsavecontent>

            <cfset jsonRes(true, "", {
                "rows"       : rowsHTML,
                "pagination" : paginationHTML
            })>

        <cfcatch>
            <cfset jsonRes(false, "Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>