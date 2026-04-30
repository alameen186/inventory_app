<cfcomponent output="false">

    <cffunction name="sendJSON" access="private" returntype="void" output="true">
        <cfargument name="data" type="struct" required="true">
        <cfcontent type="application/json; charset=utf-8" reset="true">
        <cfset var map = structNew("ordered")>
        <cfloop collection="#arguments.data#" item="k">
            <cfset map[lcase(k)] = arguments.data[k]>
        </cfloop>
        <cfoutput>#serializeJSON(map)#</cfoutput>
        <cfabort>
    </cffunction>

    <!--- requireAuth --->
    <cffunction name="requireAuth" access="private" returntype="void" output="false">
        <cfif NOT structKeyExists(session,"user_id")>
            <cfset sendJSON({status:"error", message:"Unauthorized"})>
        </cfif>
    </cffunction>


    <!--- getProductDetail--->
    <cffunction name="getProductDetail" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireAuth()>
        <cftry>
            <cfif NOT structKeyExists(url,"product_id") OR NOT isNumeric(url.product_id)>
                <cfset sendJSON({status:"error", message:"Invalid product ID"})>
            </cfif>

            <cfset var pid          = val(url.product_id)>
            <cfset var currentPage  = structKeyExists(url,"p") AND val(url.p) GT 0 ? val(url.p) : 1>
            <cfset var limit        = 5>
            <cfset var groupSize    = 4>

            <cfset var reviewModel  = createObject("component","models.Review")>
            <cfset var productModel = createObject("component","models.Product")>

            <!--- product name --->
            <cfset var product = productModel.getProductById(pid)>
            <cfif product.recordCount EQ 0>
                <cfset sendJSON({status:"error", message:"Product not found"})>
            </cfif>

            <!--- average rating + total --->
            <cfset var avgData     = reviewModel.getAverageRating(product_id = pid)>
            <cfset var avgRating   = avgData.avg_rating>
            <cfset var totalReviews = avgData.total_reviews>

            <!--- star breakdown  --->
            <cfset var summaryQ    = reviewModel.getRatingSummary(pid)>
           <cfset var starCounts = [0, 0, 0, 0, 0]>
<cfloop query="summaryQ">
    <cfset starCounts[summaryQ.rating] = summaryQ.cnt>
</cfloop>

            <!--- eligibility --->
            <cfset var canReview    = reviewModel.canUserReview(session.user_id, pid)>
            <cfset var hasReviewed  = reviewModel.hasUserReviewed(session.user_id, pid)>

            <!--- reviews paginated --->
            <cfset var reviews     = reviewModel.getProductReviews(
                                         product_id = pid,
                                         page       = currentPage,
                                         limit      = limit
                                     )>
            <cfset var totalRev    = reviewModel.getProductReviewCount(product_id = pid)>
            <cfset var totalPages  = ceiling(totalRev / limit)>

            <!--- ── REVIEWS  ── --->
            <cfsavecontent variable="reviewsHTML">
            <cfif reviews.recordCount EQ 0>
                <p class="text-muted text-center py-3">No reviews yet. Be the first!</p>
            <cfelse>
                <cfoutput query="reviews">
                <div class="border rounded p-3 mb-3">
                    <div class="d-flex justify-content-between align-items-start mb-1">
                        <strong>#encodeForHTML(reviewer_name)#</strong>
                        <small class="text-muted">#dateFormat(created_at,"dd-mmm-yyyy")#</small>
                    </div>
                    <div class="text-warning mb-1" style="font-size:14px;">
                        <cfloop from="1" to="5" index="s">
                            <cfif s LTE rating>&##9733;<cfelse>&##9734;</cfif>
                        </cfloop>
                        <small class="text-muted ms-1">#rating#/5</small>
                    </div>
                    <p class="mb-0 small text-muted">#encodeForHTML(comment)#</p>
                </div>
                </cfoutput>
            </cfif>
            </cfsavecontent>

            <!--- REVIEW PAGINATION --->
            <cfsavecontent variable="paginationHTML">
            <cfoutput>
            <cfif totalPages GT 1>
                <cfset var pageGroup = ceiling(currentPage / groupSize)>
                <cfset var startPage = (pageGroup - 1) * groupSize + 1>
                <!--- FIX: cap endPage --->
                <cfset var endPage   = min(startPage + groupSize - 1, totalPages)>
                <cfset var prevPage  = startPage - 1>
                <cfset var nextPage  = endPage + 1>

                <cfif startPage GT 1>
                    <button class="reviewPageBtn btn btn-outline-primary btn-sm"
                            data-page="#prevPage#"
                            data-pid="#pid#">Prev</button>
                </cfif>

                <cfloop from="#startPage#" to="#endPage#" index="i">
                    <button class="reviewPageBtn btn btn-sm
                        <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
                        data-page="#i#"
                        data-pid="#pid#">#i#</button>
                </cfloop>

                <cfif endPage LT totalPages>
                    <button class="reviewPageBtn btn btn-outline-primary btn-sm"
                            data-page="#nextPage#"
                            data-pid="#pid#">Next</button>
                </cfif>
            </cfif>
            </cfoutput>
            </cfsavecontent>

            <cfset sendJSON({
    status        : "success",
    product_name  : product.product_name,
    category_name : product.category_name,
    business_name : product.business_name,
    price         : product.price,
    stock         : product.stock,
    image         : product.image,
    images        : listToArray(listFilter(
                    "#product.image#,#product.image2#,#product.image3#",
                    function(v){ return len(trim(v)); }
                )),
    expiry_date   : len(trim(product.expiry_date)) ? dateFormat(product.expiry_date, "dd-mmm-yyyy") : "",
    avg_rating    : avgRating,
    total_reviews : totalReviews,
    star_counts   : starCounts,
    can_review    : canReview,
    has_reviewed  : hasReviewed,
    reviews_html  : reviewsHTML,
    pagination    : paginationHTML
})>
            
        <cfcatch>
            <cfset sendJSON({status:"error", message:"#cfcatch.message#"})>
        </cfcatch>
        </cftry>
    </cffunction>


    <!--- addReview --->
    <cffunction name="addReview" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireAuth()>
        <cftry>
            <cfif NOT structKeyExists(form,"product_id") OR NOT isNumeric(form.product_id)>
                <cfset sendJSON({status:"error", message:"Invalid product ID"})>
            </cfif>
            <cfif NOT structKeyExists(form,"rating") OR NOT isNumeric(form.rating)
                  OR val(form.rating) LT 1 OR val(form.rating) GT 5>
                <cfset sendJSON({status:"error", message:"Rating must be between 1 and 5"})>
            </cfif>
            <cfif NOT structKeyExists(form,"comment") OR len(trim(form.comment)) LT 5>
                <cfset sendJSON({status:"error", message:"Comment must be at least 5 characters"})>
            </cfif>
            <cfif len(trim(form.comment)) GT 1000>
                <cfset sendJSON({status:"error", message:"Comment must not exceed 1000 characters"})>
            </cfif>

            <cfset var pid         = val(form.product_id)>
            <cfset var rating      = val(form.rating)>
            <cfset var comment     = trim(form.comment)>
            <cfset var reviewModel = createObject("component","models.Review")>

            <!--- must have purchased at least twice --->
            <cfif NOT reviewModel.canUserReview(session.user_id, pid)>
                <cfset sendJSON({status:"error", message:"You need to purchase this product at least 2 times to write a review"})>
            </cfif>

            <!--- one review per user per product --->
            <cfif reviewModel.hasUserReviewed(session.user_id, pid)>
                <cfset sendJSON({status:"error", message:"You have already reviewed this product"})>
            </cfif>

            <cfset var result = reviewModel.addReview(
                user_id    = session.user_id,
                product_id = pid,
                rating     = rating,
                comment    = comment
            )>

            <cfif result>
                <cfset sendJSON({status:"success", message:"Review submitted successfully!"})>
            <cfelse>
                <cfset sendJSON({status:"error", message:"Could not submit review. Please try again."})>
            </cfif>

        <cfcatch>
            <cfset sendJSON({status:"error", message:"#cfcatch.message#"})>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>
