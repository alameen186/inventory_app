<cfcomponent output="false">

    <cffunction name="selectPlan" access="remote" returntype="void" httpMethod="POST">
        <cfset createObject("component","models.AuthGuard").checkAuth()>
        <cftry>
            <cfset var plan_id = val(form.plan_id)>
            <cfif plan_id LTE 0>
                <cfset jsonRes(false,"Please select a plan")><cfreturn>
            </cfif>
            <cfset var model  = createObject("component","models.Plan")>
            <cfset var result = model.assignPlan(session.user_id, plan_id)>
            <cfif result>
                <!--- Store plan in session so we don't query every request --->
                <cfset var planQ = model.getVendorPlan(session.user_id)>
                <cfset session.plan_id   = planQ.id>
                <cfset session.plan_name = lcase(planQ.plan_name)>
                <cfset jsonRes(true,"Plan selected successfully")>
            <cfelse>
                <cfset jsonRes(false,"Could not assign plan")>
            </cfif>
        <cfcatch>
            <cfset jsonRes(false,"Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="jsonRes" access="private" returntype="void" output="true">
        <cfargument name="success" type="boolean" required="true">
        <cfargument name="message" type="string"  default="">
        <cfcontent type="application/json; charset=utf-8" reset="true">
        <cfoutput>#serializeJSON({"success":arguments.success,"message":arguments.message})#</cfoutput>
    </cffunction>

</cfcomponent>