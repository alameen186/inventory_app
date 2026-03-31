<cfset structClear(session)>

<cflocation url="../index.cfm?page=auth&message=Logged out successfully&type=success&tab=login" addtoken="false">
<cfabort>