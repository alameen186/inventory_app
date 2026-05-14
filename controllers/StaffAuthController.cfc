<cfcomponent output="false">

    <cffunction name="jsonRes" access="private" returntype="void" output="true">
        <cfargument name="success" type="boolean" required="true">
        <cfargument name="message" type="string"  default="">
        <cfargument name="data"    type="any"     default="">
        <cfcontent type="application/json; charset=utf-8" reset="true">
        <cfoutput>#serializeJSON({ "success": arguments.success, "message": arguments.message, "data": arguments.data })#</cfoutput>
        <cfabort>
    </cffunction>

    <cffunction name="login" access="remote" returntype="void" output="true" httpMethod="POST">
        <cftry>
            <cfif NOT structKeyExists(form,"email") OR NOT len(trim(form.email))>
                <cfset jsonRes(false,"Email is required")>
            </cfif>
            <cfif NOT structKeyExists(form,"password") OR NOT len(trim(form.password))>
                <cfset jsonRes(false,"Password is required")>
            </cfif>

            <cfset var model = createObject("component","models.Staff")>
            <cfset var q     = model.getByEmail(trim(form.email))>

            <cfif q.recordCount EQ 0>
                <cfset jsonRes(false,"No active staff account found with this email")>
            </cfif>

            <!--- Verify password --->
            <cfset var hashed = hash(trim(form.password),"SHA-256")>
            <cfif hashed NEQ q.password>
                <cfset jsonRes(false,"Invalid password")>
            </cfif>

            <!--- Set staff session — separate from vendor session --->
            <cfset session.staff_id     = q.id>
            <cfset session.staff_name   = q.full_name>
            <cfset session.staff_email  = q.email>
            <cfset session.staff_vendor = q.vendor_id>
            <cfset session.is_staff     = true>

            <cfset jsonRes(true,"Login successful",{ "redirect": "../index.cfm?page=staffDashboard" })>
        <cfcatch>
            <cfset jsonRes(false,"Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="logout" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset structDelete(session,"staff_id")>
        <cfset structDelete(session,"staff_name")>
        <cfset structDelete(session,"staff_email")>
        <cfset structDelete(session,"staff_vendor")>
        <cfset structDelete(session,"is_staff")>
        <cflocation url="../index.cfm?page=auth" addtoken="false">
    </cffunction>

</cfcomponent>