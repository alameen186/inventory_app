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
        <cflocation url="../index.cfm?page=auth" addtoken="false">
        <cfabort>
    </cfif>

    <cfinclude template="../views/dashboard/dashboard.cfm">

<cfelseif page EQ "staffDashboard">

    <!--- Staff portal — uses staff session, not user session --->
    <cfif NOT structKeyExists(session,"is_staff") OR NOT session.is_staff>
        <cflocation url="../index.cfm?page=auth" addtoken="false">
        <cfabort>
    </cfif>

    <cfinclude template="../views/staff/staffDashboard.cfm">

<cfelseif page EQ "users">

    <cfif NOT structKeyExists(session, "user_id") OR session.role_id NEQ 1>
        <cflocation url="../index.cfm?page=dashboard" addtoken="false">
        <cfabort>
    </cfif>

    <cfinclude template="../views/admin/users.cfm">

<cfelse>

    <cfinclude template="../views/auth/auth.cfm">

</cfif>