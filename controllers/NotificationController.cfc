<cfcomponent output="false">

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

    <cffunction name="requireAuth" access="private" returntype="void" output="false">
        <cfif NOT structKeyExists(session, "user_id")>
            <cfset jsonRes(false, "Unauthorized")>
        </cfif>
    </cffunction>

    <!--- Get Unread Count --->
    <cffunction name="getCount" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireAuth()>
        <cftry>
            <cfset var model = createObject("component", "models.Notification")>
            <cfset var count = model.countUnread(session.user_id)>
            <cfset jsonRes(true, "", { "count": count })>
        <cfcatch>
            <cfset jsonRes(false, "Error fetching count")>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- Get List of Notifications --->
    <cffunction name="getList" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireAuth()>
        <cftry>
            <cfset var model = createObject("component", "models.Notification")>
            <cfset var notifs = model.getForUser(session.user_id, 20)>

            <cfset var result = []>

            <cfloop query="notifs">
                <cfset var row = {
                    "id"       : notifs.id,
                    "type"     : notifs.type,
                    "title"    : notifs.title,
                    "message"  : notifs.message,
                    "link"     : notifs.link,
                    "is_read"  : notifs.is_read,
                    "time"     : dateTimeFormat(notifs.created_at, "dd-mmm-yyyy HH:mm")
                }>
                <cfset arrayAppend(result, row)>
            </cfloop>

            <cfset jsonRes(true, "", result)>
        <cfcatch>
            <cfset jsonRes(false, "Error loading notifications")>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- Mark One as Read --->
    <cffunction name="markRead" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireAuth()>
        <cftry>
            <cfset var model = createObject("component", "models.Notification")>
            <cfset model.markRead(val(form.id), session.user_id)>
            <cfset jsonRes(true, "Notification marked as read")>
        <cfcatch>
            <cfset jsonRes(false, "Failed to mark as read")>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- Mark All as Read --->
    <cffunction name="markAllRead" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireAuth()>
        <cftry>
            <cfset var model = createObject("component", "models.Notification")>
            <cfset model.markAllRead(session.user_id)>
            <cfset jsonRes(true, "All notifications marked as read")>
        <cfcatch>
            <cfset jsonRes(false, "Failed to mark all as read")>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>