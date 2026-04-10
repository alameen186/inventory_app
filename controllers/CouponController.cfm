<cfset couponModel = createObject("component", "models.Coupon")>
<cfset allCoupon = couponModel.getCoupon()>
<cfif NOT structKeyExists(form, "action") AND NOT structKeyExists(url, "action")>
    <cflocation url="../index.cfm?page=dashboard&section=coupons">
    <cfabort>
</cfif>

      <!-- add coupon --->
      <cfif structKeyExists(form, "action") AND form.action EQ "add">
      <cfset codes = trim(form.code)>
      <cfset type = form.type>
      <cfset value = val(trim(form.value))>
      <cfset minimumAmount = val(form.min)>
      <cfset minimumDiscount = val(form.max)>
      <cfset expiry = len(form.expiry)> 
      
      <cfif NOT len(codes) OR NOT len(value)>
          <cflocation url="../index.cfm?page=dashboard&section=coupons&message=Missing required fields&type=error&showForm=1" addtoken="false">
          <cfabort>
      
      <cfelseif len(codes) GT 20>
          <cflocation url="../index.cfm?page=dashboard&section=coupons&message=Code must be 20 characters or less&type=error&showForm=1" addtoken="false">
          <cfabort>   
      
      <cfelseif value LTE 0>
          <cflocation url="../index.cfm?page=dashboard&section=coupons&message=Discount value must be greater than zero&type=error&showForm=1" addtoken="false">
          <cfabort>   
      
      <cfelseif minimumAmount LT 0>
          <cflocation url="../index.cfm?page=dashboard&section=coupons&message=Minimum amount cannot be negative&type=error&showForm=1" addtoken="false">
          <cfabort>     
      
      <cfelseif minimumDiscount LT 0>
          <cflocation url="../index.cfm?page=dashboard&section=coupons&message=Maximum discount cannot be negative&type=error&showForm=1" addtoken="false">
          <cfabort>   
 
      <cfelseif listFindNoCase(valueList(allCoupon.code), codes)>
          <cflocation url="../index.cfm?page=dashboard&section=coupons&message=The coupon code already exist&type=error&showForm=1" addtoken="false">
          <cfabort>   
      <cfelseif NOT len(trim(form.expiry))>
          <cflocation url="../index.cfm?page=dashboard&section=coupons&message=expiry date required&type=error&showForm=1" addtoken="false">
          <cfabort>   
      </cfif>
      
    <cfset result = couponModel.createCoupon(codes, type, value, minimumAmount, minimumDiscount, expiry)>

    <cfif result>
        <cflocation url="../index.cfm?page=dashboard&section=coupons&message=Coupon added&type=success">
    <cfelse>
        <cflocation url="../index.cfm?page=dashboard&section=coupons&message=Error adding coupon&type=error">
    </cfif>

    <cfabort>
</cfif>

<!-- update coupon -->
<cfif structKeyExists(form, "action") AND form.action EQ "update">

    <cfset codes = trim(form.code)>
    <cfset type = form.type>
    <cfset value = val(trim(form.value))>
    <cfset minimumAmount = val(form.min)>
    <cfset minimumDiscount = val(form.max)>
    <cfset expiry = form.expiry>

   <cfif NOT len(codes) OR NOT len(value)>
          <cflocation url="../index.cfm?page=dashboard&section=coupons&message=Missing required fields&type=error&editId=#form.id#" addtoken="false">
          <cfabort>
      
      <cfelseif len(codes) GT 20>
          <cflocation url="../index.cfm?page=dashboard&section=coupons&message=Code must be 20 characters or less&type=error&editId=#form.id#" addtoken="false">
          <cfabort>   
      
      <cfelseif value LTE 0>
          <cflocation url="../index.cfm?page=dashboard&section=coupons&message=Discount value must be greater than zero&type=error&editId=#form.id#" addtoken="false">
          <cfabort>   
      
      <cfelseif minimumAmount LT 0>
          <cflocation url="../index.cfm?page=dashboard&section=coupons&message=Minimum amount cannot be negative&type=error&editId=#form.id#" addtoken="false">
          <cfabort>     
      
      <cfelseif minimumDiscount LT 0>
          <cflocation url="../index.cfm?page=dashboard&section=coupons&message=Maximum discount cannot be negative&type=error&editId=#form.id#" addtoken="false">
          <cfabort>   
 
      <cfelseif NOT len(trim(form.expiry))>
          <cflocation url="../index.cfm?page=dashboard&section=coupons&message=expiry date required&type=error&editId=#form.id#" addtoken="false">
          <cfabort>   
      </cfif>

    <!-- TRY BLOCK -->
    <cftry>

        <cfset couponModel.updateCoupon(
            id = form.id,
            code = codes,
            type = type,
            value = value,
            min = minimumAmount,
            max = minimumDiscount,
            expiry = expiry
        )>

        <cflocation url="../index.cfm?page=dashboard&section=coupons&message=Updated&type=success">

    <cfcatch>
        <cflocation url="../index.cfm?page=dashboard&section=coupons&message=Update failed&type=error">
    </cfcatch>

    </cftry>

    <cfabort>
</cfif>

<!-- toggle -->
<cfif structKeyExists(url, "action") AND url.action EQ "toggle">

    <cfif NOT structKeyExists(url, "id")>
        <cflocation url="../index.cfm?page=dashboard&section=coupons&message=Invalid request&type=error">
        <cfabort>
    </cfif>

    <cftry>

        <cfset couponModel.toggleCoupon(url.id)>

        <cflocation url="../index.cfm?page=dashboard&section=coupons&message=Status updated&type=success">

    <cfcatch>
        <cflocation url="../index.cfm?page=dashboard&section=coupons&message=Error updating status&type=error">
    </cfcatch>

    </cftry>

    <cfabort>
</cfif>