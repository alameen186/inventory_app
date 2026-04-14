<cfif structKeyExists(form,"action") AND form.action EQ "restockProduct">

    <cfset productModel = createObject("component","models.Product")>
    <cfset enquiryModel = createObject("component","models.Enquiry")>

    <cfset productId = val(form.product_id)>
    <cfset addStock = val(form.add_stock)>

    <cfif addStock LTE 0>
        <cflocation url="../index.cfm?page=dashboard&section=adminEnquiries&message=Invalid stock value&type=error" addtoken="false">
        <cfabort>
    </cfif>

    <!-- update stock -->
    <cfset productModel.addStock(productId, addStock)>

    <!-- mark enquiry fulfilled -->
    <cfset enquiryModel.markFulfilled(productId)>

    <cflocation url="../index.cfm?page=dashboard&section=adminEnquiries&message=Stock updated successfully&type=success" addtoken="false">
    <cfabort>

</cfif>