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
<!--- Helper: Create seasonal offers immediately --->
<cffunction name="createSeasonOffers" access="private" returntype="void">
    <cfargument name="product_id" type="numeric" required="true">
    <cfargument name="season_ids" type="array" required="true">

    <cfloop array="#arguments.season_ids#" index="sid">
        <cftry>
            <cfquery name="local.season" datasource="#application.dsn#">
                SELECT season_key, season_name, discount_pct, start_date, end_date
                FROM seasons 
                WHERE id = <cfqueryparam value="#sid#" cfsqltype="cf_sql_integer">
                  AND is_active = 1
            </cfquery>

            <cfif local.season.recordCount>
                <!--- Check if offer already exists --->
                <cfquery name="local.exists" datasource="#application.dsn#">
                    SELECT id FROM offers
                    WHERE product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
                      AND offer_type = 'individual'
                      AND offer_name LIKE <cfqueryparam value="[SEASON]#local.season.season_key#%" cfsqltype="cf_sql_varchar">
                </cfquery>

                <cfif local.exists.recordCount EQ 0>
                    <cfquery datasource="#application.dsn#">
                        INSERT INTO offers 
                        (vendor_id, offer_name, offer_type, product_id, 
                         discount_type, discount_value, start_date, end_date, is_active)
                        VALUES (
                            <cfqueryparam value="#session.user_id#" cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="[SEASON]#local.season.season_key# - #local.season.season_name#" cfsqltype="cf_sql_varchar">,
                            'individual',
                            <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">,
                            'percentage',
                            <cfqueryparam value="#local.season.discount_pct#" cfsqltype="cf_sql_decimal">,
                            <cfqueryparam value="#local.season.start_date#" cfsqltype="cf_sql_date">,
                            <cfqueryparam value="#local.season.end_date#" cfsqltype="cf_sql_date">,
                            1   <!--- IMPORTANT: Set is_active = 1 --->
                        )
                    </cfquery>
                </cfif>
            </cfif>
        <cfcatch>
            <!--- Silent fail --->
        </cfcatch>
        </cftry>
    </cfloop>
</cffunction>
    <!--- ADD --->
<cffunction name="add" access="remote" returntype="void" output="true" httpMethod="POST">
    <cfset createObject("component","models.AuthGuard").checkAuth()>

    <cftry>
        <cfset var productModel   = createObject("component","models.Product")>
        <cfset var imageModel     = createObject("component","models.ProductImage")>

        <!--- Variables --->
        <cfset var productName   = trim(form.product_name)>
        <cfset var price         = val(form.price)>
        <cfset var stock         = val(form.stock)>
        <cfset var categoryId    = val(form.category_id)>
        <cfset var expiryDate    = structKeyExists(form,"expiry_date") ? trim(form.expiry_date) : "">
        <cfset var wholesalePrice  = (structKeyExists(form,"wholesale_price") AND len(trim(form.wholesale_price))) ? trim(form.wholesale_price) : "">
        <cfset var minWholesaleQty = (structKeyExists(form,"min_wholesale_qty") AND len(trim(form.min_wholesale_qty))) ? trim(form.min_wholesale_qty) : "">

        <!--- Basic Validation --->
        <cfif len(productName) LT 2 OR len(productName) GT 100>
            <cfset jsonRes(false,"Product name must be 2-100 characters")>
        </cfif>
        <cfif price LTE 0>
            <cfset jsonRes(false,"Valid price is required")>
        </cfif>
        <cfif stock LT 0>
            <cfset jsonRes(false,"Stock cannot be negative")>
        </cfif>
        <cfif categoryId EQ 0>
            <cfset jsonRes(false,"Please select a category")>
        </cfif>

        <!--- Create Product --->
        <cfset var newId = productModel.addProduct(
            productName,
            price,
            stock,
            categoryId,
            "", "", "",                  <!--- image, image2, image3 --->
            session.user_id,
            expiryDate,
            wholesalePrice,
            minWholesaleQty
        )>

        <cfif NOT newId OR newId EQ 0>
            <cfset jsonRes(false,"Failed to insert product into database. Please check required fields.")>
        </cfif>

        <!--- Save Seasons + Create Offers --->
        <cfset var seasonIds = []>
        <cfif structKeyExists(form,"season_ids") AND len(trim(form.season_ids))>
            <cfloop list="#form.season_ids#" index="sid">
                <cfif isNumeric(trim(sid)) AND val(trim(sid)) GT 0>
                    <cfset arrayAppend(seasonIds, val(trim(sid)))>
                </cfif>
            </cfloop>
        </cfif>

        <cfif arrayLen(seasonIds)>
            <cfset productModel.saveProductSeasons(newId, seasonIds)>
            <cfset createSeasonOffers(newId, seasonIds)>
        </cfif>

        <!--- Upload Images --->
        <cfset var images = uploadImages("product_images", 10)>
        <cfloop from="1" to="#arrayLen(images)#" index="i">
            <cfset imageModel.addImage(product_id = newId, image = images[i], sort_order = i)>
        </cfloop>

        <cfset jsonRes(true, "Product '#productName#' created successfully with season offers!")>

    <cfcatch>
        <cfset jsonRes(false, "Server Error: #cfcatch.message# | Line: #cfcatch.tagContext[1].line#")>
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
<!--- Save season links --->
<cfset var seasonIds = []>
<cfif structKeyExists(form,"season_ids") AND len(trim(form.season_ids))>
    <cfloop list="#form.season_ids#" index="sid">
        <cfif isNumeric(trim(sid)) AND val(trim(sid)) GT 0>
            <cfset arrayAppend(seasonIds, val(trim(sid)))>
        </cfif>
    </cfloop>
</cfif>
<cfset productModel.saveProductSeasons(id, seasonIds)>
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
                            <span class="badge bg-success">#numberFormat(wholesale_price,"0.00")#</span>
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
    <cfif len(trim(season_tags))>
        <cfloop list="#season_tags#" delimiters="|" index="stag">
            <span class="badge bg-info text-dark" style="font-size:0.68rem;">#stag#</span>
        </cfloop>
    <cfelse>
        <span class="text-muted small">—</span>
    </cfif>
</td>
                    <td><input value="#product_name#" class="form-control name" style="min-width:100px;"></td>

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
<cffunction name="getProductSeasons" access="remote" returntype="void"
            output="true" httpMethod="GET">
    <cfset createObject("component","models.AuthGuard").checkAuth()>
    <cftry>
        <cfset var productModel = createObject("component","models.Product")>
        <cfset var ids = productModel.getProductSeasonIds(val(url.product_id))>
        <cfset jsonRes(true, "", ids)>
    <cfcatch>
        <cfset jsonRes(false, "Error: #cfcatch.message#")>
    </cfcatch>
    </cftry>
</cffunction>
</cfcomponent>
