<cfcomponent output="false">

    <!--- Standard JSON response helper --->
    <cffunction name="jsonRes" access="private" returntype="void" output="true">
        <cfargument name="success" type="boolean" required="true">
        <cfargument name="message" type="string"  default="">
        <cfargument name="data"    type="any"     default="">
        <cfcontent type="application/json; charset=utf-8" reset="true">
        <cfoutput>#serializeJSON({
            "success": arguments.success,
            "message": arguments.message,
            "data"   : arguments.data
        })#</cfoutput>
        <cfabort>
    </cffunction>

    <!--- Auth check helper --->
    <cffunction name="requireAuth" access="private" returntype="void" output="false">
        <cfif NOT structKeyExists(session, "user_id")>
            <cfset jsonRes(false, "Unauthorized")>
        </cfif>
    </cffunction>

    
    <cffunction name="getPreferences" access="remote" returntype="void"
                output="true" httpMethod="GET">
        <cfset requireAuth()>
        <cftry>
            <cfset var engine = createObject("component","models.CustomerNotificationEngine")>
            <cfset var prefs  = engine.getPreferences(session.user_id)>
            <cfset var stats  = engine.getCustomerStats(session.user_id)>
            <cfset var hist   = engine.getNotificationHistory(session.user_id, 5)>

            <!--- Build history array --->
            <cfset var histList = []>
            <cfloop query="hist">
                <cfset arrayAppend(histList, {
                    "id"         : hist.id,
                    "type"       : hist.type,
                    "title"      : hist.title,
                    "message"    : hist.message,
                    "is_read"    : hist.is_read,
                    "created_at" : dateTimeFormat(hist.created_at, "dd-mmm-yyyy HH:mm")
                })>
            </cfloop>

            <cfset jsonRes(true, "", {
                "reorder_reminders"     : val(prefs.reorder_reminders),
                "personalized_offers"   : val(prefs.personalized_offers),
                "smart_recommendations" : val(prefs.smart_recommendations),
                "seasonal_predictions"  : val(prefs.seasonal_predictions),
                "cart_recovery"         : val(prefs.cart_recovery),
                "stats"                 : stats,
                "history"               : histList
            })>
        <cfcatch>
            <cfset jsonRes(false, "Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="savePreferences" access="remote" returntype="void"
                output="true" httpMethod="POST">
        <cfset requireAuth()>
        <cftry>
            <cfset var engine = createObject("component","models.CustomerNotificationEngine")>
            <cfset var result = engine.savePreferences(
                user_id                = session.user_id,
                reorder_reminders      = structKeyExists(form,"reorder_reminders")      ? 1 : 0,
                personalized_offers    = structKeyExists(form,"personalized_offers")    ? 1 : 0,
                smart_recommendations  = structKeyExists(form,"smart_recommendations")  ? 1 : 0,
                seasonal_predictions   = structKeyExists(form,"seasonal_predictions")   ? 1 : 0,
                cart_recovery          = structKeyExists(form,"cart_recovery")          ? 1 : 0
            )>
            <cfset jsonRes(result, result ? "Preferences saved!" : "Could not save preferences.")>
        <cfcatch>
            <cfset jsonRes(false, "Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="saveCartSnapshot" access="remote" returntype="void"
                output="true" httpMethod="POST">
        <cfset requireAuth()>
        <cftry>
            <cfif NOT structKeyExists(session,"cart") OR structIsEmpty(session.cart)>
                <cfset jsonRes(true, "Cart empty — nothing to save")>
            </cfif>
            <cfset var engine = createObject("component","models.CustomerNotificationEngine")>
            <cfset engine.saveCartSnapshot(session.user_id, session.cart)>
            <cfset jsonRes(true, "Cart snapshot saved")>
        <cfcatch>
            <cfset jsonRes(false, "Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="markCartRecovered" access="remote" returntype="void"
                output="true" httpMethod="POST">
        <cfset requireAuth()>
        <cftry>
            <cfset var engine = createObject("component","models.CustomerNotificationEngine")>
            <cfset engine.markCartRecovered(session.user_id)>
            <cfset jsonRes(true, "Cart marked as recovered")>
        <cfcatch>
            <cfset jsonRes(false, "Error: " & cfcatch.message)>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>