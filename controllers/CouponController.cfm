<cfset couponModel = createObject("component", "models.Coupon")>

<!-- add-->
<cfif structKeyExists(form, "action") AND form.action EQ "add">

<cfset codes = trim(form.code)>
<cfset type = form.type>
<cfset value = val(form.value)>
<cfset minimumAmount = val(form.min)>
<cfset minimumDiscount = val(form.max)>
<cfset expiry = form.expiry>

<!-- VALIDATION -->
<cfif NOT len(codes) OR value LTE 0>
<cfcontent type="application/json" reset="true">
<cfoutput>{"status":"error","message":"Missing or invalid fields"}</cfoutput>
<cfabort>

<cfelseif len(codes) GT 20>
<cfcontent type="application/json">
<cfoutput>{"status":"error","message":"Code max 20 chars"}</cfoutput>
<cfabort>

<cfelseif couponModel.isCouponExists(codes)>
<cfcontent type="application/json">
<cfoutput>{"status":"error","message":"Coupon exists"}</cfoutput>
<cfabort>

<cfelseif NOT len(expiry)>
<cfcontent type="application/json">
<cfoutput>{"status":"error","message":"Expiry required"}</cfoutput>
<cfabort>
</cfif>

<cfset result = couponModel.createCoupon(codes,type,value,minimumAmount,minimumDiscount,expiry)>

<cfcontent type="application/json">
<cfoutput>
{"status":"#result?'success':'error'#","message":"#result?'Added':'Error adding'#"}
</cfoutput>
<cfabort>

</cfif>


<!-- update-->
<cfif structKeyExists(form,"action") AND form.action EQ "update">

<cfif couponModel.isCouponUsed(form.code)>
<cfcontent type="application/json">
<cfoutput>{"status":"error","message":"Already used, cannot edit"}</cfoutput>
<cfabort>
</cfif>

<cfset couponModel.updateCoupon(
id=form.id,
code=form.code,
type=form.type,
value=form.value,
min=form.min,
max=form.max,
expiry=form.expiry
)>

<cfcontent type="application/json">
<cfoutput>{"status":"success","message":"Updated"}</cfoutput>
<cfabort>

</cfif>


<!-- toggle -->
<cfif structKeyExists(url,"action") AND url.action EQ "toggle">

<cfset coupon = couponModel.getCouponById(url.id)>

<cfif couponModel.isCouponUsed(coupon.code)>
<cfcontent type="application/json">
<cfoutput>{"status":"error","message":"Used coupon cannot be blocked"}</cfoutput>
<cfabort>
</cfif>

<cfset couponModel.toggleCoupon(url.id)>

<cfcontent type="application/json">
<cfoutput>
{
"status":"success",
"message":"Status updated",
"id":"#url.id#"
}
</cfoutput>
<cfabort>

</cfif>


<!--serch& pagination-->
<cfif structKeyExists(url,"action") AND url.action EQ "search">

<cfparam name="url.search" default="">
<cfparam name="url.status" default="">
<cfparam name="url.p" default="1">

<cfset page = val(url.p)>
<cfset limit = 2>

<cfset coupons = couponModel.getCoupon(
search=url.search,
status=url.status,
page=page,
limit=limit
)>

<cfoutput query="coupons">

<tr>
<td>#id#</td>
<td>#code#</td>
<td>#discount_type#</td>
<td>#discount_value#</td>
<td>#min_amount#</td>
<td>#max_discount#</td>

<td>
<cfif is_active EQ 1>
<span class="text-success">Active</span>
<cfelse>
<span class="text-warning">Blocked</span>
</cfif>
</td>

<td>#dateFormat(expiry_date,"dd-mmm-yyyy")#</td>

<td>
<button class="editBtn btn btn-warning btn-sm" data-id="#id#">Edit</button>

<button class="toggleBtn btn btn-danger btn-sm"
data-id="#id#" data-status="#is_active#">
<cfif is_active EQ 1>Block<cfelse>Unblock</cfif>
</button>
</td>
</tr>

</cfoutput>

<cfabort>

</cfif>