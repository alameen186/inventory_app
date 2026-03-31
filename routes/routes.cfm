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
    <cfif NOT structKeyExists(session, "user_id")>
        <cflocation url="../index.cfm?page=auth&message=Please login first&type=error&tab=login" addtoken="false">
        <cfabort>
    </cfif>

    <cfinclude template="../views/dashboard/dashboard.cfm">
<cfelse>
    <cfinclude template="../views/auth/auth.cfm">
</cfif>