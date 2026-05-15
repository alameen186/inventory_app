<cfif NOT (cgi.remote_addr EQ "127.0.0.1" OR cgi.remote_addr EQ "::1")>
    <cfoutput>Access denied.</cfoutput>
    <cfabort>
</cfif>

<cfset applicationStop()>
<cfoutput>
    ✅ Application restarted successfully!!!!.<br>
    <a href="/">Go home</a>
</cfoutput>