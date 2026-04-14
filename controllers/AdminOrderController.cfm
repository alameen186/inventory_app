<cfif structKeyExists(form,"action") 
AND form.action EQ "createAdminOrder">

<cfset productModel = createObject("component","models.Product")>
<cfset orderModel = createObject("component","models.Order")>
<cfset couponModel = createObject("component","models.Coupon")>
<cfset userModel = createObject("component","models.User")>

<cfset productId = val(form.product_id)>
<cfset userId = val(form.user_id)>
<cfset qty = val(form.qty)>
<cfset couponId = val(form.coupon_id)>

<!-- qty validation -->
<cfif qty LTE 0>
    <cflocation url="../index.cfm?page=dashboard&section=createOrder&message=Invalid quantity&type=error">
    <cfabort>
</cfif>

<cfif qty GT 3>
    <cflocation url="../index.cfm?page=dashboard&section=createOrder&message=Maximum 3 quantity allowed&type=error">
    <cfabort>
</cfif>

<!-- stock validation -->
<cfset stock = productModel.getStock(productId)>

<cfif qty GT stock>
    <cflocation url="../index.cfm?page=dashboard&section=createOrder&message=Only #stock# items available in stock&type=error">
    <cfabort>
</cfif>

<!-- product -->
<cfset product = productModel.getProductById(productId)>
<cfset total = product.price * qty>

<!-- coupon -->
<cfset couponCode = "">
<cfset discount = 0>
<cfset finalTotal = total>

<cfif couponId GT 0>

    <cfset coupon = couponModel.getCouponById(couponId)>

    <cfif coupon.recordCount>

        <cfif total LT coupon.min_amount>
            <cflocation url="../index.cfm?page=dashboard&section=createOrder&message=Minimum purchase amount is #coupon.min_amount# for this coupon&type=error">
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

<!-- create order -->
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
    <cflocation url="../index.cfm?page=dashboard&section=createOrder&message=Order creation failed&type=error">
    <cfabort>
</cfif>

<!-- reduce stock -->
<cfset productModel.reduceStock(productId, qty)>

<!-- create pdf -->
<cfset invoiceDir = expandPath("../assets/invoices/")>

<!-- chcking folder exists -->
<cfif NOT directoryExists(invoiceDir)>
    <cfdirectory action="create" directory="#invoiceDir#">
</cfif>

<cfset fileName = "invoice_#orderGroupId#.pdf">
<cfset invoicePath = invoiceDir & fileName>

<cfdocument format="pdf" filename="#invoicePath#" overwrite="true">
<cfoutput>
<h2>Invoice</h2>
<p>Order ID: #orderGroupId#</p>

<table border="1" width="100%">
<tr>
<th>Product</th>
<th>Price</th>
<th>Qty</th>
<th>Total</th>
</tr>

<tr>
<td>#product.product_name#</td>
<td>#product.price#</td>
<td>#qty#</td>
<td>#total#</td>
</tr>
</table>

<p>Total: #total#</p>
<p>Discount: #discount#</p>
<h3>Final: #finalTotal#</h3>
</cfoutput>
</cfdocument>

<cflocation url="../index.cfm?page=dashboard&section=allorders&message=Order created successfully&type=success">
<cfabort>

</cfif>