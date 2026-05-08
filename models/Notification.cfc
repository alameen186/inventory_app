<cfcomponent output="false" displayname="Notification Model">

    <cffunction name="create" returntype="void" output="false">
        <cfargument name="user_id"     type="numeric" required="true">
        <cfargument name="sender_id"   type="numeric" required="false" default="0">
        <cfargument name="type"        type="string"  required="true">
        <cfargument name="title"       type="string"  required="true">
        <cfargument name="message"     type="string"  required="true">
        <cfargument name="link"        type="string"  required="false" default="">

        <cfquery datasource="#application.dsn#">
            INSERT INTO notifications 
            (user_id, sender_id, type, title, message, link)
            VALUES (
                <cfqueryparam value="#arguments.user_id#"   cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#arguments.sender_id#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#arguments.type#"      cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.title#"     cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.message#"   cfsqltype="cf_sql_longvarchar">,
                <cfqueryparam value="#arguments.link#"      cfsqltype="cf_sql_varchar">
            )
        </cfquery>
    </cffunction>

    <cffunction name="getForUser" returntype="query" output="false">
        <cfargument name="user_id" type="numeric" required="true">
        <cfargument name="limit"   type="numeric" required="false" default="20">

        <cfquery name="q" datasource="#application.dsn#">
            SELECT id, type, title, message, link, is_read, created_at
            FROM notifications
            WHERE user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
            ORDER BY created_at DESC
            LIMIT <cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfreturn q>
    </cffunction>

    <cffunction name="countUnread" returntype="numeric" output="false">
        <cfargument name="user_id" type="numeric" required="true">
        <cfquery name="q" datasource="#application.dsn#">
            SELECT COUNT(*) AS total
            FROM notifications
            WHERE user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
              AND is_read = 0
        </cfquery>
        <cfreturn val(q.total)>
    </cffunction>

    <cffunction name="markRead" returntype="void" output="false">
        <cfargument name="id"      type="numeric" required="true">
        <cfargument name="user_id" type="numeric" required="true">
        <cfquery datasource="#application.dsn#">
            UPDATE notifications
            SET is_read = 1
            WHERE id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
              AND user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
        </cfquery>
    </cffunction>

    <cffunction name="markAllRead" returntype="void" output="false">
        <cfargument name="user_id" type="numeric" required="true">
        <cfquery datasource="#application.dsn#">
            UPDATE notifications
            SET is_read = 1
            WHERE user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
              AND is_read = 0
        </cfquery>
    </cffunction>

</cfcomponent>