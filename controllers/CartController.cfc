<cfcomponent output="false">

    <!-- INIT -->
    <cffunction name="initCart" access="private">
        <cfif NOT structKeyExists(session, "cart")>
            <cfset session.cart = structNew()>
        </cfif>
    </cffunction>

    <!-- ADD -->
    <cffunction name="add" access="remote" returntype="any" output="true" httpMethod="POST">

        <cfset initCart()>

        <cfset var productId = form.product_id>

        <cfif structKeyExists(session.cart, productId)>

    <cfif session.cart[productId].qty GTE 3>
        <cfcontent type="application/json">
        <cfoutput>#serializeJSON({
            "status":"error",
            "message":"Maximum 3 quantity allowed"
        })#</cfoutput>
        <cfreturn>
    </cfif>

    <cfset session.cart[productId].qty += 1>

<cfelse>

    <cfset session.cart[productId] = {
        name  = form.product_name,
        price = form.price,
        qty   = 1,
        image = form.image
    }>

</cfif>

        <cfcontent type="application/json">
        <cfoutput>#serializeJSON({
            "status":"success",
            "message":"Added to cart"
        })#</cfoutput>
    </cffunction>


    <!-- UPDATE -->
    <cffunction name="update" access="remote" returntype="any" output="true" httpMethod="POST">

        <cfset initCart()>

        <cfset var productId = form.product_id>
        <cfset var qty = val(form.qty)>

        <cfif qty GT 3>
    <cfcontent type="application/json">
    <cfoutput>#serializeJSON({
        "status":"error",
        "message":"Maximum 3 quantity allowed"
    })#</cfoutput>
    <cfreturn>
</cfif>

        <cfif qty LTE 0>
            <cfset structDelete(session.cart, productId)>
        <cfelse>
            <cfset session.cart[productId].qty = qty>
        </cfif>

        <cfcontent type="application/json">
        <cfoutput>#serializeJSON({
            "status":"success",
            "message":"Cart updated"
        })#</cfoutput>
    </cffunction>


    <!-- REMOVE -->
    <cffunction name="remove" access="remote" returntype="any" output="true" httpMethod="GET">

        <cfset initCart()>

        <cfif structKeyExists(session.cart, url.id)>
            <cfset structDelete(session.cart, url.id)>
        </cfif>

        <cfif structKeyExists(session,"coupon")>
            <cfset structDelete(session,"coupon")>
        </cfif>

        <cfcontent type="application/json">
        <cfoutput>#serializeJSON({
            "status":"success",
            "message":"Item removed",
            "id":url.id
        })#</cfoutput>
    </cffunction>


    <!-- COUPON -->
    <cffunction name="applyCoupon" access="remote" returntype="any" output="true" httpMethod="POST">

        <cfset initCart()>

        <cfset var couponModel = createObject("component","models.Coupon")>
        <cfset var code = trim(form.coupon_code)>
        <cfset var coupon = couponModel.getCouponByCode(code)>

        <cfif NOT coupon.recordCount>
            <cfcontent type="application/json">
            <cfoutput>#serializeJSON({
                "status":"error",
                "message":"Invalid coupon"
            })#</cfoutput>
            <cfreturn>
        </cfif>

        <cfset var total = 0>

        <cfloop collection="#session.cart#" item="pid">
            <cfset var item = session.cart[pid]>
            <cfset total += item.price * item.qty>
        </cfloop>

        <cfif total LT coupon.min_amount>
            <cfcontent type="application/json">
            <cfoutput>#serializeJSON({
                "status":"error",
                "message":"Minimum amount is #coupon.min_amount#"
            })#</cfoutput>
            <cfreturn>
        </cfif>

        <cfset session.coupon = {
            code  = coupon.code,
            type  = coupon.discount_type,
            value = coupon.discount_value,
            max   = coupon.max_discount
        }>

        <cfcontent type="application/json">
        <cfoutput>#serializeJSON({
            "status":"success",
            "message":"Coupon applied",
            "type":coupon.discount_type,
            "value":coupon.discount_value,
            "max":coupon.max_discount
        })#</cfoutput>
    </cffunction>

</cfcomponent>