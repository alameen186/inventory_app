<cfif structKeyExists(form, "action") AND form.action EQ "addEnquiry">

<cfset enquiryModel = createObject("component","models.Enquiry")>

<cfset result = enquiryModel.addEnquiry(
    session.user_id,
    form.product_id
)>

<cfif result>
    <cflocation url="../index.cfm?page=dashboard&section=productList&message=Product enquiry submitted&type=success">
<cfelse>
    <cflocation url="../index.cfm?page=dashboard&section=productList&message=Unable to submit enquiry&type=error">
</cfif>

<cfabort>

</cfif>