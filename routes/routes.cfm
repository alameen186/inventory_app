<cfif structKeyExists(form, "action")>
    <cfinclude template="../controllers/AuthController.cfm">
    <cfabort>
</cfif>

<cfif structKeyExists(url, "page")>
    <cfset page = url.page>
<cfelse>
    <cfset page = "auth">
</cfif>

<cfif page EQ "dashboard">
    <cfinclude template="../views/dashboard/dashboard.cfm">
<cfelse>
    <cfinclude template="../views/auth/auth.cfm">
</cfif>