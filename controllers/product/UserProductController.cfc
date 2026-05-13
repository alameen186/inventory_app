<cfcomponent output="false">

    <cffunction name="jsonRes" access="private" returntype="void" output="true">
        <cfargument name="success" type="boolean" required="true">
        <cfargument name="message" type="string"  default="">
        <cfargument name="data"    type="any"     default="">
        <cfcontent type="application/json; charset=utf-8" reset="true">
        <cfoutput>#serializeJSON({
            "success" : arguments.success,
            "message" : arguments.message,
            "data"    : arguments.data
        })#</cfoutput>
    </cffunction>

    <cffunction name="search" access="remote" returntype="void" output="true" httpMethod="GET">
    <cfset createObject("component","models.AuthGuard").checkAuth()>
    <cfset var productModel = createObject("component","models.Product")>

    <cftry>
        <cfset var keyword       = structKeyExists(url,"search")        ? trim(url.search)        : "">
        <cfset var cat_id        = structKeyExists(url,"category_id")   AND isNumeric(url.category_id) ? url.category_id : "">
        <cfset var min_price     = structKeyExists(url,"min_price")     AND isNumeric(url.min_price)   ? url.min_price   : "">
        <cfset var max_price     = structKeyExists(url,"max_price")     AND isNumeric(url.max_price)   ? url.max_price   : "">
        <cfset var sort          = structKeyExists(url,"sort")          ? url.sort                     : "">
        <cfset var expiry_months = structKeyExists(url,"expiry_months") AND isNumeric(url.expiry_months) ? url.expiry_months : "">
        <cfset var limit         = 3>
        <cfset var currentPage   = structKeyExists(url,"p") AND val(url.p) GT 0 ? val(url.p) : 1>

        <!--- Get Products --->
        <cfset var products = productModel.searchProducts(
            keyword       = keyword,
            category_id   = cat_id,
            min_price     = min_price,
            max_price     = max_price,
            sort          = sort,
            page          = currentPage,
            limit         = limit,
            expiry_months = expiry_months
        )>

        <!--- === LOG SEARCH (Your existing code) === --->
        <cfset logModel = createObject("component","models.SearchLog")>

        <cfif products.recordCount GT 0 AND len(keyword)>
            <cfloop query="products">
                <cfset logModel.logSearch(
                    keyword            = keyword,
                    user_id            = session.user_id,
                    result_count       = products.recordCount,
                    matched_product_id = products.id
                )>
            </cfloop>
        <cfelseif len(keyword)>
            <cfset logModel.logSearch(
                keyword      = keyword,
                user_id      = session.user_id,
                result_count = 0
            )>
        </cfif>

        <!--- === ENRICH PRODUCTS WITH OFFER DATA === --->
        <cfset var enrichedProducts = queryNew(
            "id,product_name,price,stock,category_name,avg_rating,review_count,first_image,original_price,offer_price,has_offer,discount_percent",
            "integer,varchar,decimal,integer,varchar,decimal,integer,varchar,decimal,decimal,bit,decimal"
        )>

        <cfloop query="products">
            <cfset var offer = productModel.getActiveOfferForProduct(products.id)>
            
            <cfset var finalPrice = products.price>
            <cfset var discPercent = 0>

            <cfif offer.hasOffer>
                <cfif offer.discount_type EQ "percentage">
                    <cfset discPercent = offer.discount_value>
                    <cfset finalPrice = products.price * (1 - offer.discount_value/100)>
                <cfelse>
                    <cfset finalPrice = max(0, products.price - offer.discount_value)>
                    <cfset discPercent = round((offer.discount_value / products.price) * 100)>
                </cfif>
            </cfif>

            <cfset queryAddRow(enrichedProducts)>
            <cfset querySetCell(enrichedProducts, "id",              products.id)>
            <cfset querySetCell(enrichedProducts, "product_name",    products.product_name)>
            <cfset querySetCell(enrichedProducts, "price",           products.price)>
            <cfset querySetCell(enrichedProducts, "stock",           products.stock)>
            <cfset querySetCell(enrichedProducts, "category_name",   products.category_name)>
            <cfset querySetCell(enrichedProducts, "avg_rating",      products.avg_rating)>
            <cfset querySetCell(enrichedProducts, "review_count",    products.review_count)>
            <cfset querySetCell(enrichedProducts, "first_image",     products.first_image)>
            <cfset querySetCell(enrichedProducts, "original_price",  products.price)>
            <cfset querySetCell(enrichedProducts, "offer_price",     finalPrice)>
            <cfset querySetCell(enrichedProducts, "has_offer",       offer.hasOffer)>
            <cfset querySetCell(enrichedProducts, "discount_percent", discPercent)>
        </cfloop>

        <!--- Total Count for Pagination --->
        <cfset var totalRecords = productModel.getProductCount(
            keyword       = keyword,
            category_id   = cat_id,
            min_price     = min_price,
            max_price     = max_price,
            expiry_months = expiry_months
        )>

        <cfset var totalPages = totalRecords GT 0 ? ceiling(totalRecords / limit) : 0>
        <cfset var groupSize  = 4>
        <cfset var startPage  = ((currentPage - 1) \ groupSize) * groupSize + 1>
        <cfset var endPage    = totalPages GT 0 ? min(startPage + groupSize - 1, totalPages) : 0>
        <cfset var prevPage   = startPage - 1>
        <cfset var nextPage   = endPage + 1>

        <!--- PRODUCT CARDS HTML (Updated with Offer Price) --->
        <cfsavecontent variable="productHTML">
        <cfoutput query="enrichedProducts">
            <div class="col-6 col-md-4 col-lg-3">
                <div class="card h-100 product-card" data-pid="#id#">

                    <cfif len(first_image)>
                        <img src="../../assets/images/products/#first_image#" 
                             class="card-img-top" style="height:180px;object-fit:cover;">
                    <cfelse>
                        <img src="https://via.placeholder.com/200" 
                             class="card-img-top" style="height:180px;object-fit:cover;">
                    </cfif>
                    
                    <div class="card-body d-flex flex-column text-center p-2">
                        <h6 class="card-title mb-1">#product_name#</h6>
                        <p class="text-muted small mb-1">#category_name#</p>
                        
                        <!--- === UPDATED PRICE DISPLAY === --->
<div class="mb-2">
    <cfif has_offer>
        <span class="text-muted text-decoration-line-through small">
            <i class="bi bi-currency-rupee"></i>#numberFormat(original_price, "0.00")#
        </span><br>
        <span class="fw-bold fs-5 text-danger">
            <i class="bi bi-currency-rupee"></i>#numberFormat(offer_price, "0.00")#
        </span>
        <span class="badge bg-danger ms-1">-#discount_percent#%</span>
    <cfelse>
        <span class="fw-bold fs-5">
            <i class="bi bi-currency-rupee"></i>#numberFormat(price, "0.00")# /-
        </span>
    </cfif>
</div>

                        <div class="mb-2">
                            <cfif val(avg_rating) GT 0>
                                <span class="text-warning small">
                                    <cfloop from="1" to="5" index="s">
                                        <cfif s LTE round(avg_rating)>&##9733;<cfelse>&##9734;</cfif>
                                    </cfloop>
                                </span>
                                <small class="text-muted">#avg_rating# (#review_count#)</small>
                            <cfelse>
                                <small class="text-muted">No reviews yet</small>
                            </cfif>
                        </div>

                        <div class="mt-auto" onclick="event.stopPropagation()">
                            <cfif stock LTE 0>
                                <p class="text-danger fw-bold small mb-2">Out of Stock</p>
                                <div id="enqMsg_#id#"></div>
                                <div id="enqBtnArea_#id#">
                                    <form class="enquiryForm">
                                        <input type="hidden" name="product_id" value="#id#">
                                        <button type="submit" class="btn btn-warning btn-sm w-100">Request</button>
                                    </form>
                                </div>
                            <cfelse>
                                <form class="addToCartForm">
                                    <input type="hidden" name="product_id"   value="#id#">
                                    <input type="hidden" name="product_name" value="#product_name#">
                                    <input type="hidden" name="price"        value="#offer_price#">  <!--- Send offer price --->
                                    <input type="hidden" name="image"        value="#first_image#">
                                    <button type="submit" class="btn btn-success btn-sm w-100">Add to Cart</button>
                                </form>
                            </cfif>
                        </div>
                    </div>
                </div>
            </div>
        </cfoutput>
        </cfsavecontent>

        <!--- PAGINATION (unchanged) --->
        <cfsavecontent variable="paginationHTML">
        <cfoutput>
        <cfif totalPages GT 1>
        <div class="d-flex gap-2 justify-content-center mt-3">
            <cfif startPage GT 1>
                <button class="pageBtn btn btn-outline-primary" data-page="#prevPage#">Prev</button>
            </cfif>
            <cfloop from="#startPage#" to="#endPage#" index="i">
                <button class="pageBtn btn btn-sm <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>" data-page="#i#">#i#</button>
            </cfloop>
            <cfif endPage LT totalPages>
                <button class="pageBtn btn btn-outline-primary" data-page="#nextPage#">Next</button>
            </cfif>
        </div>
        </cfif>
        </cfoutput>
        </cfsavecontent>

        <cfset jsonRes(true, "", {
            "products"   : productHTML,
            "pagination" : paginationHTML
        })>

    <cfcatch>
        <cfset jsonRes(false, "Error: #cfcatch.message#")>
    </cfcatch>
    </cftry>
</cffunction>
        
 </cfcomponent>