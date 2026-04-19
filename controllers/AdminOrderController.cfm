<cfif structKeyExists(form,"action") AND form.action EQ "createAdminOrder">

<cfset productModel = createObject("component","models.Product")>
<cfset orderModel = createObject("component","models.Order")>
<cfset couponModel = createObject("component","models.Coupon")>
<cfset userModel = createObject("component","models.User")>

<cfset productId = val(form.product_id)>
<cfset userId = val(form.user_id)>
<cfset qty = val(form.qty)>
<cfset couponId = val(form.coupon_id)>

<!-- VALIDATION -->
<cfif qty LTE 0>
    <cfcontent type="application/json">
    <cfoutput>{"status":"error","message":"Invalid quantity"}</cfoutput>
    <cfabort>
</cfif>

<cfif qty GT 3>
    <cfcontent type="application/json">
    <cfoutput>{"status":"error","message":"Maximum 3 quantity allowed"}</cfoutput>
    <cfabort>
</cfif>

<!-- STOCK -->
<cfset stock = productModel.getStock(productId)>
<cfif qty GT stock>
    <cfcontent type="application/json">
    <cfoutput>{"status":"error","message":"Only #stock# items available"}</cfoutput>
    <cfabort>
</cfif>

<!-- PRODUCT -->
<cfset product = productModel.getProductById(productId)>
<cfset total = product.price * qty>

<!-- COUPON -->
<cfset couponCode = "">
<cfset discount = 0>
<cfset finalTotal = total>

<cfif couponId GT 0>
    <cfset coupon = couponModel.getCouponById(couponId)>

    <cfif coupon.recordCount>

        <cfif total LT coupon.min_amount>
            <cfcontent type="application/json">
            <cfoutput>{"status":"error","message":"Minimum purchase is #coupon.min_amount#"}</cfoutput>
            <cfabort>
        </cfif>

        <cfset couponCode = coupon.code>

        <cfif coupon.discount_type EQ "percent">
            <cfset discount = (total * coupon.discount_value)/100>
        <cfelse>
            <cfset discount = coupon.discount_value>
        </cfif>

        <cfif discount GT coupon.max_discount>
            <cfset discount = coupon.max_discount>
        </cfif>

        <cfset finalTotal = total - discount>
    </cfif>
</cfif>

<!-- ORDER -->
<cfset orderGroupId = createUUID()>

<cfset result = orderModel.addOrder(
    userId,
    productId,
    product.price,
    qty,
    total,
    orderGroupId,
    couponCode,
    discount,
    finalTotal
)>

<cfif NOT result>
    <cfcontent type="application/json">
    <cfoutput>{"status":"error","message":"Order failed"}</cfoutput>
    <cfabort>
</cfif>

<!-- STOCK REDUCE -->
<cfset productModel.reduceStock(productId, qty)>

<!-- SUCCESS -->
<cfcontent type="application/json">
<cfoutput>
{"status":"success","message":"Order created successfully"}
</cfoutput>
<cfabort>

</cfif>