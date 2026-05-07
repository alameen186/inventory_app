<cfcomponent output="false">

    <cffunction name="send" returntype="numeric" output="false">
        <cfargument name="chat_id"   type="numeric" required="true">
        <cfargument name="sender_id" type="numeric" required="true">
        <cfargument name="message"   type="string"  required="true">

        <cfquery datasource="#application.dsn#">
            INSERT INTO messages (chat_id, sender_id, message)
            VALUES (
                <cfqueryparam value="#arguments.chat_id#"   cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#arguments.sender_id#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#arguments.message#"   cfsqltype="cf_sql_longvarchar">
            )
        </cfquery>

        <cfquery name="newId" datasource="#application.dsn#">
            SELECT LAST_INSERT_ID() AS new_id
        </cfquery>

        <cfreturn newId.new_id>
    </cffunction>

    <cffunction name="getByConversation" returntype="query" output="false">
        <cfargument name="chat_id"  type="numeric" required="true">
        <cfargument name="after_id" type="numeric" required="false" default="0">

        <cfquery name="q" datasource="#application.dsn#">
            SELECT
                m.id,
                m.sender_id,
                m.message,
                m.is_read,
                m.created_at,
                CONCAT(u.first_name, ' ', u.last_name) AS sender_name
            FROM messages m
            JOIN users u ON u.id = m.sender_id
            WHERE m.chat_id = <cfqueryparam value="#arguments.chat_id#" cfsqltype="cf_sql_integer">
            <cfif arguments.after_id GT 0>
                AND m.id > <cfqueryparam value="#arguments.after_id#" cfsqltype="cf_sql_integer">
            </cfif>
            ORDER BY m.created_at ASC
        </cfquery>

        <cfreturn q>
    </cffunction>

    <cffunction name="markRead" returntype="void" output="false">
        <cfargument name="chat_id"    type="numeric" required="true">
        <cfargument name="reader_id"  type="numeric" required="true">

        <cfquery datasource="#application.dsn#">
            UPDATE messages
            SET    is_read  = 1
            WHERE  chat_id  = <cfqueryparam value="#arguments.chat_id#"   cfsqltype="cf_sql_integer">
            AND    sender_id != <cfqueryparam value="#arguments.reader_id#" cfsqltype="cf_sql_integer">
            AND    is_read   = 0
        </cfquery>
    </cffunction>

</cfcomponent>