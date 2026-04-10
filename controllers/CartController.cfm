<cfif NOT structKeyExists(session, "cart")>
   <cfset session.cart = structNew()>
</cfif>

<!--- add product --->
<cfif structKeyExists(form, "action") AND Form.action EQ "add">
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
   <cflocation url="../index.cfm?page=dashboard&section=productList&message=Added to cart&type=success" addtoken="false">
    <cfabort>
</cfif>


<!--- update qty --->

<cfif structKeyExists(form, "action") AND form.action EQ "update">
  <cfset productId = form.product_id>
  <cfset qty = val(form.qty)>

  <cfif qty LTE 0>
    <cfset structDelete(session.cart, productId)>
  <cfelse>
    <cfset session.cart[productId].qty = qty>  
  </cfif>

  <cflocation url="../index.cfm?page=dashboard&section=cart" addtoken="false">
    <cfabort>
</cfif>

<!--- coupon apply --->
<cfif structKeyExists(form, "action") AND form.action EQ "applyCoupon">

    <cfset couponModel = createObject("component","models.Coupon")>
    <cfset code = trim(form.coupon_code)>

    <cfset coupon = couponModel.getCouponByCode(code)>

    <cfif NOT coupon.recordCount>
        <cflocation url="../index.cfm?page=dashboard&section=cart&message=Invalid coupon&type=error">
        <cfabort>
    </cfif>

    <!-- calculate cart total -->
    <cfset total = 0>
    <cfloop collection="#session.cart#" item="pid">
        <cfset item = session.cart[pid]>
        <cfset total += item.price * item.qty>
    </cfloop>

    <!-- validate minimum -->
    <cfif total LT coupon.min_amount>
        <cflocation url="../index.cfm?page=dashboard&section=cart&message=Minimum amount is #coupon.min_amount#&type=error">
        <cfabort>
    </cfif>

    <!-- storing in session -->
    <cfset session.coupon = {
        code = coupon.code,
        type = coupon.discount_type,
        value = coupon.discount_value,
        max = coupon.max_discount
    }>

    <cflocation url="../index.cfm?page=dashboard&section=cart&message=Coupon applied&type=success">
    <cfabort>
</cfif>

<cfif structKeyExists(url, "action") AND url.action EQ "remove">
   <cfif structKeyExists(session.cart, url.id)>
        <cfset structDelete(session.cart, url.id)>
    </cfif>

    <cflocation url="../index.cfm?page=dashboard&section=cart" addtoken="false">
    <cfabort>
</cfif>