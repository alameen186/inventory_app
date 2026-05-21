<cfcomponent output="false">

    <cffunction name="jsonRes" access="private" returntype="void" output="true">
    <cfargument name="success" type="boolean" required="true">
    <cfargument name="message" type="string"  default="">
    <cfargument name="data"    type="any"     default="">

    <cfset var map = createObject("java","java.util.LinkedHashMap").init()>
    <cfset map["success"] = arguments.success>
    <cfset map["message"] = arguments.message>
    <cfset map["data"]    = arguments.data>

    <cfcontent type="application/json; charset=utf-8" reset="true">
    <cfoutput>#serializeJSON(map)#</cfoutput>
    <cfabort>
</cffunction>

<cffunction name="uploadImages" access="private" returntype="array">
    <cfargument name="fieldName" type="string" required="true">
    <cfargument name="maxImages" type="numeric" required="false" default="10">

    <cfset var result = []>
    <cfset var dest = expandPath("../../assets/images/products/")>

    <cftry>
        <cffile action="uploadAll"
                fileField="#arguments.fieldName#"
                destination="#dest#"
                nameConflict="makeunique"
                accept="image/jpeg,image/png,image/jpg,image/webp,image/gif">

            <cfif isStruct(cffile)>
            <cfif structKeyExists(cffile, "serverFile") AND len(trim(cffile.serverFile))>
                <cfset arrayAppend(result, cffile.serverFile)>
            </cfif>

        <cfelseif isQuery(cffile)>
            <cfloop query="cffile">
                <cfif len(trim(cffile.serverFile))>
                    <cfset arrayAppend(result, cffile.serverFile)>
                </cfif>
            </cfloop>

        <cfelseif isArray(cffile)>
            <cfloop array="#cffile#" index="f">
                <cfif isStruct(f) AND structKeyExists(f,"serverFile") AND len(trim(f.serverFile))>
                    <cfset arrayAppend(result, f.serverFile)>
                </cfif>
            </cfloop>
        </cfif>

        <cfif arrayLen(result) LTE 1>
            <cfdirectory action="list" directory="#dest#" name="uploadedFiles" sort="dateLastModified DESC">
            <cfloop query="uploadedFiles" endrow="10">
                <cfif uploadedFiles.type EQ "file" AND 
                      (uploadedFiles.name CONTAINS "Screenshot" OR uploadedFiles.name CONTAINS ".png" OR uploadedFiles.name CONTAINS ".jpg")>
                    <cfif NOT listFind(arrayToList(result), uploadedFiles.name)>
                        <cfset arrayAppend(result, uploadedFiles.name)>
                    </cfif>
                </cfif>
            </cfloop>
        </cfif>

        <cfcatch>
            <cfset jsonRes(false, "Upload Error: #cfcatch.message#")>
        </cfcatch>
    </cftry>

    <cfreturn result>
</cffunction>

    <cffunction name="getVendorFilter" access="private" returntype="string">
        <cfif structKeyExists(session,"role_name") AND session.role_name EQ "vendor">
            <cfreturn session.user_id>
        </cfif>
        <cfreturn "">
    </cffunction>

    <!--- ADD --->
<cffunction name="add" access="remote" returntype="void" output="true" httpMethod="POST">
    <cfset createObject("component","models.AuthGuard").checkAuth()>

    <cftry>
        <cfset var productModel   = createObject("component","models.Product")>
        <cfset var imageModel     = createObject("component","models.ProductImage")>
        <cfset var rackModel      = createObject("component","models.Rack")>
        <cfset var placementModel = createObject("component","models.RackPlacement")>
        <cfset var wholesalePrice  = (structKeyExists(form,"wholesale_price")   AND len(trim(form.wholesale_price)))   ? trim(form.wholesale_price)   : "">
        <cfset var minWholesaleQty = (structKeyExists(form,"min_wholesale_qty") AND len(trim(form.min_wholesale_qty))) ? trim(form.min_wholesale_qty) : "">

        <!--- ── SERVER-SIDE VALIDATION ── --->

        <!--- Product Name --->
        <cfif NOT structKeyExists(form,"product_name") OR NOT len(trim(form.product_name))>
            <cfset jsonRes(false,"Product name is required")>
        </cfif>
        <cfif len(trim(form.product_name)) LT 2>
            <cfset jsonRes(false,"Product name must be at least 2 characters")>
        </cfif>
        <cfif len(trim(form.product_name)) GT 100>
            <cfset jsonRes(false,"Product name cannot exceed 100 characters")>
        </cfif>

        <!--- Price --->
        <cfif NOT structKeyExists(form,"price") OR NOT len(trim(form.price))>
            <cfset jsonRes(false,"Price is required")>
        </cfif>
        <cfif NOT isNumeric(form.price) OR val(form.price) LTE 0>
            <cfset jsonRes(false,"Price must be a number greater than 0")>
        </cfif>
        <cfif val(form.price) GT 999999>
            <cfset jsonRes(false,"Price cannot exceed 999999")>
        </cfif>

        <!--- Stock --->
        <cfif NOT structKeyExists(form,"stock") OR NOT len(trim(form.stock))>
            <cfset jsonRes(false,"Stock quantity is required")>
        </cfif>
        <cfif NOT isNumeric(form.stock) OR val(form.stock) LT 0>
            <cfset jsonRes(false,"Stock must be 0 or greater")>
        </cfif>
        <cfif val(form.stock) GT 99999>
            <cfset jsonRes(false,"Stock cannot exceed 99999")>
        </cfif>

        <!--- Category --->
        <cfif NOT structKeyExists(form,"category_id") OR NOT val(form.category_id)>
            <cfset jsonRes(false,"Please select a category")>
        </cfif>

        <!--- Expiry Date — optional but if provided must be valid and future --->
        <cfset var expiryDate = structKeyExists(form,"expiry_date") ? trim(form.expiry_date) : "">
        <cfif len(expiryDate)>
            <cfif NOT isDate(expiryDate)>
                <cfset jsonRes(false,"Expiry date is not a valid date")>
            </cfif>
            <cfif dateCompare(expiryDate, now()) LT 0>
                <cfset jsonRes(false,"Expiry date cannot be in the past")>
            </cfif>
        </cfif>

        <!--- Rack face capacity check — server side --->
        <cfset var raceFaceId = structKeyExists(form,"rack_face_id") ? val(form.rack_face_id) : 0>
        <cfif raceFaceId GT 0>
            <cfset var faceInfo = rackModel.getFaceWithUsage(raceFaceId)>
            <cfif faceInfo.recordCount EQ 0>
                <cfset jsonRes(false,"Selected rack face does not exist")>
            </cfif>
            <cfif faceInfo.used_slots GTE faceInfo.capacity>
                <cfset jsonRes(false,"Selected face (#faceInfo.face_code#) is full (#faceInfo.used_slots#/#faceInfo.capacity#). Please choose another face.")>
            </cfif>
        </cfif>

        <!--- Wholesale validation (server-side) --->
<cfif structKeyExists(form,"enable_wholesale") AND len(trim(form.enable_wholesale))>
    <cfif NOT isNumeric(wholesalePrice) OR val(wholesalePrice) LTE 0>
        <cfset jsonRes(false,"Wholesale price is required when wholesale is enabled")>
    </cfif>
    <cfif val(wholesalePrice) GTE val(form.price)>
        <cfset jsonRes(false,"Wholesale price must be lower than retail price")>
    </cfif>
    <cfif NOT isNumeric(minWholesaleQty) OR val(minWholesaleQty) LT 1>
        <cfset jsonRes(false,"Minimum wholesale quantity must be at least 1")>
    </cfif>
</cfif>

        
<cfset var newId = productModel.addProduct(
    trim(form.product_name),
    val(form.price),
    val(form.stock),
    val(form.category_id),
    "", "", "",
    session.user_id,
    expiryDate,
    wholesalePrice,
    minWholesaleQty
)>

        <cfif NOT newId>
            <cfset jsonRes(false,"Failed to create product. Please try again.")>
        </cfif>

        <!--- ── UPLOAD IMAGES ── --->
        <cfset var images   = uploadImages("product_images", 10)>
        <cfset var inserted = 0>

        <cfloop from="1" to="#arrayLen(images)#" index="i">
            <cfset var imgName = images[i]>
            <cfset var imgOk   = imageModel.addImage(
                product_id = newId,
                image      = imgName,
                sort_order = i
            )>
            <cfif imgOk>
                <cfset inserted++>
            </cfif>
        </cfloop>

        <!--- ── RACK PLACEMENT ── --->
        <cfif raceFaceId GT 0>
            <cfset var placeResult = placementModel.placeProduct(
                product_id   = newId,
                rack_face_id = raceFaceId
            )>
            <cfif NOT placeResult.success>
                <cfset jsonRes(true,
                    "Product created successfully but rack placement failed: "
                    & placeResult.message
                    & ". You can assign it from Rack Placement page.")>
            </cfif>
        </cfif>

        <!--- ── SUCCESS ── --->
        <cfset var successMsg = "Product '" & trim(form.product_name) & "' created successfully">
        <cfif raceFaceId GT 0>
            <cfset successMsg = successMsg & " and placed in rack face">
        </cfif>

        <cfset jsonRes(true, successMsg)>

    <cfcatch>
        <cfset jsonRes(false,"Server Error: #cfcatch.message#")>
    </cfcatch>
    </cftry>
</cffunction>

    <!--- UPDATE --->
    <cffunction name="update" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset createObject("component","models.AuthGuard").checkAuth()>
        <cftry>
            <cfset var productModel = createObject("component","models.Product")>
            <cfset var imageModel   = createObject("component","models.ProductImage")>

            <cfset var id          = val(form.id)>
            <cfset var productName = trim(form.product_name)>
            <cfset var price       = val(form.price)>
            <cfset var stock       = val(form.stock)>
            <cfset var category_id = val(form.category_id)>
            <cfset var expiry_date = trim(form.expiry_date)>
            <cfset var wholesale_price = val(form.wholesale_price)>
            <cfset var min_wholesale_qty = val(form.min_wholesale_qty) >


            <cfif len(productName) LT 3>
                <cfset jsonRes(false,"Product name must be at least 3 characters")><cfreturn>
            </cfif>
            <cfif price LTE 0>
                <cfset jsonRes(false,"Invalid price")><cfreturn>
            </cfif>

            <cfset productModel.updateProduct(
                 id, productName, price, stock,
                 category_id, "", "", "", expiry_date,wholesale_price,min_wholesale_qty
            )>

            <cfset var currentCount = imageModel.getCount(id)>
            <cfset var slotsLeft    = 10 - currentCount>

            <cfif slotsLeft GT 0>
                <cfset var newImages = uploadImages("product_images", slotsLeft)>
                <cfloop from="1" to="#arrayLen(newImages)#" index="i">
                    <cfset imageModel.addImage(
                        product_id = id,
                        image      = newImages[i],
                        sort_order = currentCount + i
                    )>
                </cfloop>
            </cfif>

            <cfset jsonRes(true, "Product updated successfully")>
        <cfcatch>
            <cfset jsonRes(false, "Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- TOGGLE STATUS --->
    <cffunction name="toggleStatus" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset createObject("component","models.AuthGuard").checkAuth()>
        <cfset var productModel = createObject("component","models.Product")>
        <cftry>
            <cfset var id        = val(url.id)>
            <cfset var newStatus = (url.currentStatus EQ 1 ? 0 : 1)>
            <cfset productModel.toggleStatus(id, newStatus)>
            <cfset jsonRes(true,"Status updated",{"id":id,"newStatus":newStatus})>
        <cfcatch>
            <cfset jsonRes(false,"Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- SEARCH / PAGINATION --->
    <cffunction name="search" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset createObject("component","models.AuthGuard").checkAuth()>
        <cfset var productModel  = createObject("component","models.Product")>
        <cfset var categoryModel = createObject("component","models.Category")>
        <cfset var vendorFilter  = getVendorFilter()>

        <cftry>
            <cfset var srch   = structKeyExists(url,"search")      ? trim(url.search)  : "">
            <cfset var sort   = structKeyExists(url,"sort")        ? url.sort          : "">
            <cfset var cat_id = structKeyExists(url,"category_id") ? url.category_id   : "">
            <cfset var page   = structKeyExists(url,"p")           ? val(url.p)        : 1>
            <cfset var limit  = 2>
            <cfif page LT 1><cfset page = 1></cfif>

            <cfset var categories = categoryModel.getAllActiveCategory(vendorFilter)>

            <cfset var products = productModel.getAllProductsAdmin(
                search=srch, sort=sort, category_id=cat_id,
                page=page, limit=limit, vendor_id=vendorFilter
            )>
            <cfset var totalRecords = productModel.getProductCountAdmin(
                search=srch, category_id=cat_id, vendor_id=vendorFilter
            )>
            <cfset var totalPages = ceiling(totalRecords / limit)>

            <cfset var groupSize = 4>
            <cfset var pageGroup = ceiling(page / groupSize)>
            <cfset var startPage = (pageGroup - 1) * groupSize + 1>
            <cfset var endPage   = min(startPage + groupSize - 1, totalPages)>
            <cfset var prevPage  = startPage - 1>
            <cfset var nextPage  = endPage + 1>

            <cfsavecontent variable="rowsHTML">
            <cfoutput query="products">
                <tr id="viewRow_#id#">
                    <td>#id#</td>
                    <td>#product_name#</td>
                    <td>#price#</td>
                    <td>
                        <cfif len(trim(wholesale_price)) AND wholesale_price GT 0>
                            <span class="badge bg-success">₹#numberFormat(wholesale_price,"0.00")#</span>
                        <cfelse>
                            <span class="text-muted small">—</span>
                        </cfif>
                    </td>
                    <td>
                        <cfif len(trim(min_wholesale_qty)) AND min_wholesale_qty GT 0>
                            <span class="badge bg-secondary">#min_wholesale_qty#</span>
                        <cfelse>
                            <span class="text-muted small">—</span>
                        </cfif>
                    </td>
                    <td>#stock#</td>
                    <td>#category_name#</td>
                    <td><cfif len(trim(expiry_date))>#dateFormat(expiry_date,"dd-mmm-yyyy")#<cfelse>-</cfif></td>
                    <td>
                        <cfif len(trim(first_image))>
                            <img src="../../assets/images/products/#first_image#" width="40">
                        <cfelse>
                            No Image
                        </cfif>
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
                    <td>
                        <div id="existingImgs_#id#" class="d-flex flex-wrap gap-1 mb-2"></div>
                        <input type="file" name="product_images" class="form-control"
                               multiple accept="image/*">
                        <small class="text-muted">Add more images (max 10 total)</small>
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
                            <button class="saveBtn btn btn-success btn-sm" data-id="#id#">Save</button>
                            <button class="cancelBtn btn btn-secondary btn-sm" data-id="#id#">Cancel</button>
                        </div>
                    </td>
                </tr>
            </cfoutput>
            </cfsavecontent>

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

            <cfset jsonRes(true,"",{"rows":rowsHTML,"pagination":paginationHTML})>
        <cfcatch>
            <cfset jsonRes(false,"Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- DELETE single image --->
    <cffunction name="deleteImage" access="remote" returntype="void" httpMethod="GET">
        <cfset createObject("component","models.AuthGuard").checkAuth()>
        <cftry>
            <cfset var imageModel = createObject("component","models.ProductImage")>
            <cfset imageModel.deleteImage(
                id         = val(url.image_id),
                product_id = val(url.product_id)
            )>
            <cfset jsonRes(true, "Image deleted")>
        <cfcatch>
            <cfset jsonRes(false, "Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

    <!---
        GET all images for a product.
        Returns a JSON array of {id, image} objects — used by the admin
        edit row to render thumbnails with individual delete buttons.
        Uses Java ArrayList so serializeJSON always produces a true JSON array.
    --->
    <cffunction name="getImages" access="remote" returntype="void" httpMethod="GET">
        <cfset createObject("component","models.AuthGuard").checkAuth()>
        <cftry>
            <cfset var imageModel = createObject("component","models.ProductImage")>
            <cfset var imgs       = imageModel.getByProduct(val(url.product_id))>

            <!--- Build a Java ArrayList of structs — guaranteed JSON array output --->
            <cfset var result = createObject("java","java.util.ArrayList").init()>
            <cfloop query="imgs">
                <cfset var entry = structNew("ordered")>
                <cfset entry["id"]    = imgs.id>
                <cfset entry["image"] = trim(imgs.image)>
                <cfset result.add(entry)>
            </cfloop>

            <cfset jsonRes(true, "", result)>
        <cfcatch>
            <cfset jsonRes(false, "Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>
