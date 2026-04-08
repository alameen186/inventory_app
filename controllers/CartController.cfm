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

<cfif structKeyExists(url, "action") AND url.action EQ "remove">
   <cfif structKeyExists(session.cart, url.id)>
        <cfset structDelete(session.cart, url.id)>
    </cfif>

    <cflocation url="../index.cfm?page=dashboard&section=cart" addtoken="false">
    <cfabort>
</cfif>