<!-- INIT -->
<cfif NOT structKeyExists(session, "cart")>
   <cfset session.cart = structNew()>
</cfif>

<!-- ADD -->
<cfif structKeyExists(form, "action") AND form.action EQ "add">

<cfset productId = form.product_id>

<cfif structKeyExists(session.cart, productId)>
    <cfset session.cart[productId].qty += 1>
<cfelse>
    <cfset session.cart[productId] = {
        name=form.product_name,
        price=form.price,
        qty=1,
        image=form.image
    }>
</cfif>

<cfcontent type="application/json">
<cfoutput>{"status":"success","message":"Added to cart"}</cfoutput>
<cfabort>
</cfif>


<!-- UPDATE -->
<cfif structKeyExists(form, "action") AND form.action EQ "update">

<cfset productId = form.product_id>
<cfset qty = val(form.qty)>

<cfif qty LTE 0>
    <cfset structDelete(session.cart, productId)>
<cfelse>
    <cfset session.cart[productId].qty = qty>
</cfif>

<cfcontent type="application/json">
<cfoutput>{"status":"success","message":"Cart updated"}</cfoutput>
<cfabort>
</cfif>


<!-- REMOVE -->
<cfif structKeyExists(url, "action") AND url.action EQ "remove">

<cfif structKeyExists(session.cart, url.id)>
    <cfset structDelete(session.cart, url.id)>
</cfif>
<cfif structKeyExists(session,"coupon")>
<cfset structDelete(session,"coupon")>
</cfif>
<cfcontent type="application/json">
<cfoutput>{"status":"success","message":"Item removed","id":"#url.id#"}</cfoutput>
<cfabort>
</cfif>


<!-- COUPON -->
<cfif structKeyExists(form, "action") AND form.action EQ "applyCoupon">

<cfset couponModel = createObject("component","models.Coupon")>
<cfset code = trim(form.coupon_code)>
<cfset coupon = couponModel.getCouponByCode(code)>

<cfif NOT coupon.recordCount>
    <cfcontent type="application/json">
    <cfoutput>{"status":"error","message":"Invalid coupon"}</cfoutput>
    <cfabort>
</cfif>

<cfset total = 0>
<cfloop collection="#session.cart#" item="pid">
    <cfset item = session.cart[pid]>
    <cfset total += item.price * item.qty>
</cfloop>

<cfif total LT coupon.min_amount>
    <cfcontent type="application/json">
    <cfoutput>{"status":"error","message":"Minimum amount is #coupon.min_amount#"}</cfoutput>
    <cfabort>
</cfif>

<cfset session.coupon = {
    code = coupon.code,
    type = coupon.discount_type,
    value = coupon.discount_value,
    max = coupon.max_discount
}>

<cfcontent type="application/json">
<cfoutput>
{
    "status":"success",
    "message":"Coupon applied",
    "type":"#coupon.discount_type#",
    "value":"#coupon.discount_value#",
    "max":"#coupon.max_discount#"
}
</cfoutput>
<cfabort>
</cfif>