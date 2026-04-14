<cfif structKeyExists(form, "action") AND form.action EQ "addEnquiry">

<cfset enquiryModel = createObject("component","models.Enquiry")>
<cfoutput>
inside controller
</cfoutput>
<cfset result = enquiryModel.addEnquiry(
    session.user_id,
    form.product_id
)>
<cfoutput>
inside controller result after
</cfoutput>
<cfif result>
    <cflocation url="../index.cfm?page=dashboard&section=productList&message=Product enquiry submitted&type=success">
<cfelse>
    <cflocation url="../index.cfm?page=dashboard&section=productList&message=Unable to submit enquiry&type=error">
</cfif>
<cfoutput>
inside controller before abort
</cfoutput>
<cfabort>

</cfif>