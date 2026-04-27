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

    <cffunction name="requireAdmin" access="private" returntype="void" output="false">
        <cfif NOT structKeyExists(session,"role_id") OR session.role_id NEQ 1>
            <cfset sendJSON({status:"error", message:"Unauthorized", html:"", pagination:""})>
        </cfif>
    </cffunction>

    <!--- SEARCH COUPONS --->
    <cffunction name="searchCoupons" access="remote" returntype="void" output="true" httpmethod="GET">
        <cfset requireAdmin()>
        <cftry>
            <cfset var couponModel = createObject("component","models.Coupon")>
            <cfset var srch        = structKeyExists(url,"search") ? trim(url.search) : "">
            <cfset var status      = structKeyExists(url,"status") ? trim(url.status) : "">
            <cfset var currentPage = structKeyExists(url,"p") AND val(url.p) GT 0 ? val(url.p) : 1>
            <cfset var limit       = 2>
            <cfset var groupSize   = 4>

            <cfset var coupons = couponModel.getCoupon(
                search = srch,
                status = status,
                page   = currentPage,
                limit  = limit
            )>
            <cfset var totalRecords = couponModel.getCouponCount(search=srch, status=status)>
            <cfset var totalPages   = ceiling(totalRecords / limit)>

            <!--- TABLE HTML --->
            <cfsavecontent variable="tableHTML">
                <cfif coupons.recordCount EQ 0>
                    <tr><td colspan="9" class="text-center">No coupons found.</td></tr>
                <cfelse>
                    <cfoutput query="coupons">
                    <tr id="couponRow_#id#">
                        <td>#id#</td>
                        <td>#encodeForHTML(code)#</td>
                        <td>#discount_type#</td>
                        <td>#discount_value#</td>
                        <td>#min_amount#</td>
                        <td>#max_discount#</td>
                        <td>
                            <cfif is_active EQ 1>
                                <span class="badge bg-success">Active</span>
                            <cfelse>
                                <span class="badge bg-warning text-dark">Blocked</span>
                            </cfif>
                        </td>
                        <td>#dateFormat(expiry_date,"dd-mmm-yyyy")#</td>
                        <td>
                            <div class="d-flex flex-wrap gap-1">
                                <button class="btn btn-warning btn-sm editBtn"
                                    data-id="#id#"
                                    data-code="#encodeForHTMLAttribute(code)#"
                                    data-type="#discount_type#"
                                    data-value="#discount_value#"
                                    data-min="#min_amount#"
                                    data-max="#max_discount#"
                                    data-expiry="#dateFormat(expiry_date,'yyyy-mm-dd')#"
                                    data-active="#is_active#">Edit</button>
                                <button class="btn btn-sm toggleBtn
                                    #is_active EQ 1 ? 'btn-danger' : 'btn-success'#"
                                    data-id="#id#"
                                    data-code="#encodeForHTMLAttribute(code)#">
                                    #is_active EQ 1 ? 'Block' : 'Unblock'#
                                </button>
                            </div>
                        </td>
                    </tr>
                    </cfoutput>
                </cfif>
            </cfsavecontent>

            <!--- GROUPED PAGINATION HTML --->
            <cfsavecontent variable="paginationHTML">
            <cfif totalPages GT 1>
                <cfoutput>
                <cfset var pageGroup = ceiling(currentPage / groupSize)>
                <cfset var startPage = (pageGroup - 1) * groupSize + 1>
                <cfset var endPage   = min(startPage + groupSize - 1, totalPages)>

                <cfif startPage GT 1>
                    <button class="btn btn-outline-primary btn-sm pageBtn"
                            data-page="#startPage - 1#">&laquo; Prev</button>
                </cfif>
                <cfloop from="#startPage#" to="#endPage#" index="i">
                    <button class="btn btn-sm pageBtn
                        <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
                        data-page="#i#">#i#</button>
                </cfloop>
                <cfif endPage LT totalPages>
                    <button class="btn btn-outline-primary btn-sm pageBtn"
                            data-page="#endPage + 1#">Next &raquo;</button>
                </cfif>
                </cfoutput>
            </cfif>
            </cfsavecontent>

            <cfset sendJSON({
                status     : "success",
                message    : "",
                html       : tableHTML,
                pagination : paginationHTML
            })>

        <cfcatch>
            <cfset sendJSON({status:"error", message:cfcatch.message, html:"", pagination:""})>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- CREATE COUPON --->
    <cffunction name="createCoupon" access="remote" returntype="void" output="true" httpmethod="POST">
        <cfset requireAdmin()>
        <cftry>
            <cfset var code   = structKeyExists(form,"code")   ? trim(uCase(form.code)) : "">
            <cfset var type   = structKeyExists(form,"type")   ? trim(form.type)        : "">
            <cfset var value  = structKeyExists(form,"value")  ? val(form.value)        : 0>
            <cfset var min    = structKeyExists(form,"min")    ? val(form.min)          : 0>
            <cfset var max    = structKeyExists(form,"max")    ? val(form.max)          : 0>
            <cfset var expiry = structKeyExists(form,"expiry") ? trim(form.expiry)      : "">

            <!--- VALIDATION --->
            <cfif NOT len(code)>
                <cfset sendJSON({status:"error", message:"Coupon code is required"})>
            <cfelseif len(code) GT 20>
                <cfset sendJSON({status:"error", message:"Code must be 20 characters or less"})>
            <cfelseif NOT reFind("^[A-Z0-9_-]+$", code)>
                <cfset sendJSON({status:"error", message:"Code may only contain letters, numbers, - and _"})>
            <cfelseif type NEQ "percent" AND type NEQ "fixed">
                <cfset sendJSON({status:"error", message:"Invalid discount type"})>
            <cfelseif value LTE 0>
                <cfset sendJSON({status:"error", message:"Discount value must be greater than 0"})>
            <cfelseif type EQ "percent" AND value GT 100>
                <cfset sendJSON({status:"error", message:"Percent discount cannot exceed 100"})>
            <cfelseif min LT 0>
                <cfset sendJSON({status:"error", message:"Minimum amount cannot be negative"})>
            <cfelseif max LT 0>
                <cfset sendJSON({status:"error", message:"Max discount cannot be negative"})>
            <cfelseif max GT 0 AND type EQ "fixed" AND max LT value>
                <cfset sendJSON({status:"error", message:"Max discount cannot be less than discount value"})>
            <cfelseif NOT len(expiry)>
                <cfset sendJSON({status:"error", message:"Expiry date is required"})>
            <cfelseif dateCompare(expiry, dateFormat(now(),"yyyy-mm-dd")) LTE 0>
                <cfset sendJSON({status:"error", message:"Expiry date must be in the future"})>
            </cfif>

            <cfset var couponModel = createObject("component","models.Coupon")>

            <cfif couponModel.isCouponExists(code)>
                <cfset sendJSON({status:"error", message:"Coupon code already exists"})>
            </cfif>

            <cfset var result = couponModel.createCoupon(code, type, value, min, max, expiry)>
            <cfif result>
                <cfset sendJSON({status:"success", message:"Coupon created successfully"})>
            <cfelse>
                <cfset sendJSON({status:"error", message:"Failed to create coupon"})>
            </cfif>

        <cfcatch>
            <cfset sendJSON({status:"error", message:cfcatch.message})>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- UPDATE COUPON --->
    <cffunction name="updateCoupon" access="remote" returntype="void" output="true" httpmethod="POST">
        <cfset requireAdmin()>
        <cftry>
            <cfset var id     = structKeyExists(form,"id")     ? val(form.id)           : 0>
            <cfset var code   = structKeyExists(form,"code")   ? trim(uCase(form.code)) : "">
            <cfset var type   = structKeyExists(form,"type")   ? trim(form.type)        : "">
            <cfset var value  = structKeyExists(form,"value")  ? val(form.value)        : 0>
            <cfset var min    = structKeyExists(form,"min")    ? val(form.min)          : 0>
            <cfset var max    = structKeyExists(form,"max")    ? val(form.max)          : 0>
            <cfset var expiry = structKeyExists(form,"expiry") ? trim(form.expiry)      : "">

            <!--- VALIDATION --->
            <cfif id LTE 0>
                <cfset sendJSON({status:"error", message:"Invalid coupon ID"})>
            <cfelseif NOT len(code)>
                <cfset sendJSON({status:"error", message:"Coupon code is required"})>
            <cfelseif len(code) GT 20>
                <cfset sendJSON({status:"error", message:"Code must be 20 characters or less"})>
            <cfelseif NOT reFind("^[A-Z0-9_-]+$", code)>
                <cfset sendJSON({status:"error", message:"Code may only contain letters, numbers, - and _"})>
            <cfelseif type NEQ "percent" AND type NEQ "fixed">
                <cfset sendJSON({status:"error", message:"Invalid discount type"})>
            <cfelseif value LTE 0>
                <cfset sendJSON({status:"error", message:"Discount value must be greater than 0"})>
            <cfelseif type EQ "percent" AND value GT 100>
                <cfset sendJSON({status:"error", message:"Percent discount cannot exceed 100"})>
            <cfelseif min LT 0>
                <cfset sendJSON({status:"error", message:"Minimum amount cannot be negative"})>
            <cfelseif max LT 0>
                <cfset sendJSON({status:"error", message:"Max discount cannot be negative"})>
            <cfelseif NOT len(expiry)>
                <cfset sendJSON({status:"error", message:"Expiry date is required"})>
            </cfif>

            <cfset var couponModel = createObject("component","models.Coupon")>

            <!--- CHECK IF USED - block code change only --->
            <cfset var existing = couponModel.getCouponById(id)>
            <cfif existing.recordCount EQ 0>
                <cfset sendJSON({status:"error", message:"Coupon not found"})>
            </cfif>
            <cfif couponModel.isCouponUsed(existing.code) AND code NEQ existing.code>
                <cfset sendJSON({status:"error", message:"This coupon has been used in orders — the code cannot be changed"})>
            </cfif>

            <cfset couponModel.updateCoupon(
                id     = id,
                code   = code,
                type   = type,
                value  = value,
                min    = min,
                max    = max,
                expiry = expiry
            )>
            <cfset sendJSON({status:"success", message:"Coupon updated successfully"})>

        <cfcatch>
            <cfset sendJSON({status:"error", message:cfcatch.message})>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- TOGGLE COUPON --->
    <cffunction name="toggleCoupon" access="remote" returntype="void" output="true" httpmethod="GET">
        <cfset requireAdmin()>
        <cftry>
            <cfset var id = structKeyExists(url,"id") ? val(url.id) : 0>
            <cfif id LTE 0>
                <cfset sendJSON({status:"error", message:"Invalid coupon ID"})>
            </cfif>

            <cfset var couponModel = createObject("component","models.Coupon")>
            <cfset var coupon      = couponModel.getCouponById(id)>

            <cfif coupon.recordCount EQ 0>
                <cfset sendJSON({status:"error", message:"Coupon not found"})>
            </cfif>

            <!--- ONLY block used coupons - allow unblocking freely --->
            <cfif coupon.is_active EQ 1 AND couponModel.isCouponUsed(coupon.code)>
                <cfset sendJSON({status:"error", message:"Cannot block a coupon that has been used in orders"})>
            </cfif>

            <cfset couponModel.toggleCoupon(id)>
            <cfset sendJSON({status:"success", message:"Coupon status updated successfully"})>

        <cfcatch>
            <cfset sendJSON({status:"error", message:cfcatch.message})>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>