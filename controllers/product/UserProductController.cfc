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

    <cffunction name="checkAuth" access="private" returntype="void" output="true">
        <cfif NOT structKeyExists(session,"user_id")>
            <cfset jsonRes(false, "Session expired. Please login.")>
            <cfabort>
        </cfif>
    </cffunction>

    <!--- SEARCH PRODUCTS --->
    <cffunction name="search" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset checkAuth()>
        <cfset var productModel = createObject("component","models.Product")>

        <cftry>
            <cfset var keyword       = structKeyExists(url,"search")        ? trim(url.search)        : "">
            <cfset var cat_id        = structKeyExists(url,"category_id")   AND isNumeric(url.category_id) ? url.category_id : "">
            <cfset var min_price     = structKeyExists(url,"min_price")     AND isNumeric(url.min_price)   ? url.min_price   : "">
            <cfset var max_price     = structKeyExists(url,"max_price")     AND isNumeric(url.max_price)   ? url.max_price   : "">
            <cfset var sort          = structKeyExists(url,"sort")          ? url.sort                : "">
            <cfset var expiry_months = structKeyExists(url,"expiry_months") AND isNumeric(url.expiry_months) ? url.expiry_months : "">
            <cfset var limit         = 3>
            <cfset var currentPage   = structKeyExists(url,"p") AND val(url.p) GT 0 ? val(url.p) : 1>

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

            <cfset var totalRecords = productModel.getProductCount(
                keyword       = keyword,
                category_id   = cat_id,
                min_price     = min_price,
                max_price     = max_price,
                expiry_months = expiry_months
            )>

            <!--- pagination calculation --->
            <cfset var totalPages = ceiling(totalRecords / limit)>
            <cfset var groupSize  = 4>
            <cfset var startPage  = ((currentPage - 1) \ groupSize) * groupSize + 1>
            <cfset var endPage    = min(startPage + groupSize - 1, totalPages)>
            <cfset var prevPage   = startPage - 1>
            <cfset var nextPage   = endPage + 1>

            <!--- product cards HTML --->
            <cfsavecontent variable="productHTML">
            <cfoutput query="products">
                <div class="col-6 col-md-4 col-lg-3 mb-3 d-flex">
                    <div class="card w-100">
                        <cfif len(image)>
                            <img src="../../assets/images/products/#image#"
                                class="img-fluid" style="height:180px;object-fit:cover;">
                        <cfelse>
                            <img src="https://via.placeholder.com/200"
                                class="card-img-top" style="height:200px;object-fit:cover;">
                        </cfif>
                        <div class="card-body text-center d-flex flex-column justify-content-between p-2">
                            <div>
                                <h5 class="card-title">#product_name#</h5>
                                <p class="small text-muted mb-1">Sold by: <strong>#business_name#</strong></p>
                                <cfif len(trim(expiry_date))>
                                    <p class="small text-muted mb-1">Expires: #dateFormat(expiry_date,"dd-mmm-yyyy")#</p>
                                </cfif>
                                <p class="mb-1">#category_name#</p>
                                <p class="mb-2">#price# /-</p>
                            </div>
                            <div>
                                <cfif stock LTE 0>
                                    <p class="text-danger fw-bold mb-2">Out of Stock</p>
                                    <form class="enquiryForm">
                                        <input type="hidden" name="product_id" value="#id#">
                                        <button class="btn btn-warning btn-sm w-100">Request Product</button>
                                    </form>
                                <cfelse>
                                    <form class="addToCartForm">
                                        <input type="hidden" name="product_id" value="#id#">
                                        <input type="hidden" name="product_name" value="#product_name#">
                                        <input type="hidden" name="price" value="#price#">
                                        <input type="hidden" name="image" value="#image#">
                                        <button class="btn btn-success btn-sm w-100">Add to Cart</button>
                                    </form>
                                </cfif>
                            </div>
                        </div>
                    </div>
                </div>
            </cfoutput>
            </cfsavecontent>

            <!--- pagination HTML --->
            <cfsavecontent variable="paginationHTML">
            <cfoutput>
            <div class="d-flex gap-2 justify-content-center mt-3">
                <cfif startPage GT 1>
                    <button class="pageBtn btn btn-outline-primary" data-page="#prevPage#">Prev</button>
                </cfif>
                <cfloop from="#startPage#" to="#endPage#" index="i">
                    <button class="pageBtn btn btn-sm <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
                        data-page="#i#">#i#</button>
                </cfloop>
                <cfif endPage LT totalPages>
                    <button class="pageBtn btn btn-outline-primary" data-page="#nextPage#">Next</button>
                </cfif>
            </div>
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