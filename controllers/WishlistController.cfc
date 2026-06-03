<cfcomponent output="false">

    <cffunction name="jsonRes" access="private" returntype="void" output="true">
        <cfargument name="success" type="boolean" required="true">
        <cfargument name="message" type="string"  default="">
        <cfargument name="data"    type="any"     default="">
        <cfcontent type="application/json; charset=utf-8" reset="true">
        <cfoutput>#serializeJSON({
            "success": arguments.success,
            "message": arguments.message,
            "data"   : arguments.data
        })#</cfoutput>
        <cfabort>
    </cffunction>

    <cffunction name="requireAuth" access="private" returntype="void" output="false">
        <cfif NOT structKeyExists(session, "user_id")>
            <cfset jsonRes(false, "Please login to use wishlist")>
        </cfif>
    </cffunction>

    <!--- TOGGLE WISHLIST (add/remove) --->
    <cffunction name="toggle" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireAuth()>
        <cftry>
            <cfif NOT structKeyExists(form, "product_id") OR NOT val(form.product_id)>
                <cfset jsonRes(false, "Invalid product")>
            </cfif>

            <cfset var pid          = val(form.product_id)>
            <cfset var wishModel    = createObject("component", "models.Wishlist")>
            <cfset var productModel = createObject("component", "models.Product")>
            <cfset var notifModel   = createObject("component", "models.Notification")>
            <cfset var offerModel   = createObject("component", "models.Offer")>

            <!--- Get product info --->
            <cfset var product = productModel.getProductById(pid)>
            <cfif product.recordCount EQ 0>
                <cfset jsonRes(false, "Product not found")>
            </cfif>

            <!--- Toggle --->
            <cfset var result = wishModel.toggle(session.user_id, pid)>

            <!--- If ADDED — fire contextual notifications --->
            <cfif result.wishlisted>

                <!--- 1. Out of stock — notify when back in stock (handled in restock flow) --->
                <cfif product.stock LTE 0>
                    <cfset notifModel.create(
                        user_id   = session.user_id,
                        sender_id = 0,
                        type      = "wishlist_out_of_stock",
                        title     = "Item saved — out of stock",
                        message   = "You wishlisted '" & product.product_name
                                  & "'. We'll notify you when it's back in stock.",
                        link      = "index.cfm?page=dashboard&section=wishlist"
                    )>

                <!--- 2. Low stock warning --->
                <cfelseif product.stock GT 0 AND product.stock LTE 5>
                    <cfset notifModel.create(
                        user_id   = session.user_id,
                        sender_id = 0,
                        type      = "wishlist_low_stock",
                        title     = "Hurry! Low stock on your wishlist item",
                        message   = "Only " & product.stock & " unit(s) left for '"
                                  & product.product_name & "'. Grab it before it runs out!",
                        link      = "index.cfm?page=dashboard&section=wishlist"
                    )>
                </cfif>

                <!--- 3. Active offer on wishlisted product --->
                <cfset var offerInfo = offerModel.getActiveOfferForProduct(pid)>
                <cfif offerInfo.hasOffer>
                    <cfset var discLabel = (offerInfo.discount_type EQ "percentage")
                        ? offerInfo.discount_value & "% OFF"
                        : "Rs." & numberFormat(offerInfo.discount_value, "0.00") & " OFF">
                    <cfset notifModel.create(
                        user_id   = session.user_id,
                        sender_id = 0,
                        type      = "wishlist_offer_active",
                        title     = "Great deal on your wishlist item!",
                        message   = "'" & product.product_name & "' has an active offer: "
                                  & offerInfo.offer_name & " — " & discLabel & ". Shop now!",
                        link      = "index.cfm?page=dashboard&section=wishlist"
                    )>
                </cfif>

            </cfif>

            <cfset jsonRes(true, result.message, {
                "wishlisted": result.wishlisted
            })>

        <cfcatch>
            <cfset jsonRes(false, "Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- CHECK WISHLIST STATUS (single product) --->
    <cffunction name="checkStatus" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireAuth()>
        <cftry>
            <cfset var pid       = val(url.product_id)>
            <cfset var wishModel = createObject("component", "models.Wishlist")>
            <cfset var status    = wishModel.isWishlisted(session.user_id, pid)>
            <cfset jsonRes(true, "", { "wishlisted": status })>
        <cfcatch>
            <cfset jsonRes(false, "Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- GET WISHLIST PAGE (paginated) --->
    <cffunction name="getWishlist" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireAuth()>
        <cftry>
            <cfset var page      = structKeyExists(url, "p") AND val(url.p) GT 0 ? val(url.p) : 1>
            <cfset var limit     = 12>
            <cfset var wishModel = createObject("component", "models.Wishlist")>
            <cfset var offerModel= createObject("component", "models.Offer")>
            <cfset var items     = wishModel.getByUser(session.user_id, page, limit)>
            <cfset var total     = wishModel.countByUser(session.user_id)>
            <cfset var totalPages= max(1, ceiling(total / limit))>
            <cfset var groupSize = 4>
            <cfset var pageGroup = ceiling(page / groupSize)>
            <cfset var startPage = (pageGroup - 1) * groupSize + 1>
            <cfset var endPage   = min(startPage + groupSize - 1, totalPages)>

            <!--- Build HTML --->
            <cfsavecontent variable="local.html">
            <cfoutput>
            <cfif items.recordCount EQ 0>
                <div class="col-12">
                    <div class="text-center py-5 text-muted">
                        <div style="font-size:3rem;">&##10084;&##65039;</div>
                        <h5 class="mt-3">Your wishlist is empty</h5>
                        <p class="small">Save products you love and get notified about deals &amp; restocks.</p>
                        <a href="index.cfm?page=dashboard&section=productList"
                           class="btn btn-primary mt-2">Browse Products</a>
                    </div>
                </div>
            <cfelse>
                <cfloop query="items">
                    <cfset var offerInfo  = offerModel.getActiveOfferForProduct(items.product_id)>
                    <cfset var finalPrice = items.price>
                    <cfset var discLabel  = "">
                    <cfif offerInfo.hasOffer>
                        <cfif offerInfo.discount_type EQ "percentage">
                            <cfset finalPrice = items.price * (1 - offerInfo.discount_value / 100)>
                            <cfset discLabel  = numberFormat(offerInfo.discount_value, "0") & "% OFF">
                        <cfelse>
                            <cfset finalPrice = max(0, items.price - offerInfo.discount_value)>
                            <cfset discLabel  = "Rs." & numberFormat(offerInfo.discount_value, "0.00") & " OFF">
                        </cfif>
                    </cfif>

                    <div class="col-6 col-md-4 col-lg-3" id="wishCard_#items.product_id#">
                        <div class="card h-100 shadow-sm position-relative wishlist-card">

                            <!--- Remove button --->
                            <button class="btn btn-sm btn-danger position-absolute top-0 end-0 m-2
                                           removeWishBtn rounded-circle"
                                    data-product-id="#items.product_id#"
                                    title="Remove from wishlist"
                                    style="width:28px;height:28px;padding:0;z-index:2;font-size:14px;">
                                &##10005;
                            </button>

                            <!--- Offer badge --->
                            <cfif offerInfo.hasOffer>
                                <span class="badge bg-danger position-absolute top-0 start-0 m-2"
                                      style="font-size:11px;z-index:2;">#discLabel#</span>
                            </cfif>

                            <!--- Stock badge --->
                            <cfif items.stock EQ 0>
                                <span class="badge bg-secondary position-absolute"
                                      style="top:32px;left:8px;font-size:10px;z-index:2;">Out of Stock</span>
                            <cfelseif items.stock LTE 5>
                                <span class="badge bg-warning text-dark position-absolute"
                                      style="top:32px;left:8px;font-size:10px;z-index:2;">
                                    Only #items.stock# left!
                                </span>
                            </cfif>

                            <!--- Image --->
                            <cfif len(trim(items.first_image))>
                                <img src="../../assets/images/products/#items.first_image#"
                                     class="card-img-top"
                                     style="height:170px;object-fit:cover;"
                                     alt="#encodeForHTMLAttribute(items.product_name)#">
                            <cfelse>
                                <div class="bg-light d-flex align-items-center justify-content-center"
                                     style="height:170px;font-size:2.5rem;color:##ccc;">&##128247;</div>
                            </cfif>

                            <div class="card-body d-flex flex-column p-2 text-center">
                                <h6 class="card-title mb-1 small fw-semibold">#encodeForHTML(items.product_name)#</h6>
                                <small class="text-muted mb-2">#encodeForHTML(items.category_name)#</small>

                                <!--- Price --->
                                <div class="mb-2">
                                    <cfif offerInfo.hasOffer>
                                        <span class="text-muted text-decoration-line-through small">
                                            <i class="bi bi-currency-rupee"></i>#numberFormat(items.price, "0.00")#
                                        </span><br>
                                        <span class="fw-bold text-danger">
                                            <i class="bi bi-currency-rupee"></i>#numberFormat(finalPrice, "0.00")#
                                        </span>
                                    <cfelse>
                                        <span class="fw-bold">
                                            <i class="bi bi-currency-rupee"></i>#numberFormat(items.price, "0.00")#
                                        </span>
                                    </cfif>
                                </div>

                                <!--- Action --->
                                <div class="mt-auto">
                                    <cfif items.stock GT 0 AND items.is_active EQ 1>
                                        <form class="addToCartForm">
                                            <input type="hidden" name="product_id"   value="#items.product_id#">
                                            <input type="hidden" name="product_name" value="#encodeForHTMLAttribute(items.product_name)#">
                                            <input type="hidden" name="price"        value="#finalPrice#">
                                            <input type="hidden" name="image"        value="#items.first_image#">
                                            <button type="submit" class="btn btn-success btn-sm w-100">
                                                <i class="bi bi-cart-plus"></i> Add to Cart
                                            </button>
                                        </form>
                                    <cfelse>
                                        <button class="btn btn-secondary btn-sm w-100" disabled>
                                            Unavailable
                                        </button>
                                    </cfif>
                                </div>
                            </div>

                        </div>
                    </div>
                </cfloop>
            </cfif>
            </cfoutput>
            </cfsavecontent>

            <!--- Pagination --->
            <cfsavecontent variable="local.pagination">
            <cfoutput>
            <cfif totalPages GT 1>
                <cfif startPage GT 1>
                    <button class="wishPageBtn btn btn-outline-primary btn-sm"
                            data-page="#startPage - 1#">Prev</button>
                </cfif>
                <cfloop from="#startPage#" to="#endPage#" index="i">
                    <button class="wishPageBtn btn btn-sm
                        #i EQ page ? 'btn-primary' : 'btn-outline-primary'#"
                        data-page="#i#">#i#</button>
                </cfloop>
                <cfif endPage LT totalPages>
                    <button class="wishPageBtn btn btn-outline-primary btn-sm"
                            data-page="#endPage + 1#">Next</button>
                </cfif>
            </cfif>
            </cfoutput>
            </cfsavecontent>

            <cfset jsonRes(true, "", {
                "html"       : local.html,
                "pagination" : local.pagination,
                "total"      : total
            })>

        <cfcatch>
            <cfset jsonRes(false, "Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>