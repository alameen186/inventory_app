<cfcomponent output="false">

    <cffunction name="findOrCreate" returntype="numeric" output="false">
        <cfargument name="user_id"   type="numeric" required="true">
        <cfargument name="vendor_id" type="numeric" required="true">

        <cfquery name="existing" datasource="#application.dsn#">
            SELECT id FROM chat
            WHERE user_id   = <cfqueryparam value="#arguments.user_id#"  cfsqltype="cf_sql_integer">
            AND   vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfif existing.recordCount GT 0>
            <cfreturn existing.id>
        </cfif>

        <cfquery datasource="#application.dsn#">
            INSERT INTO chat (user_id, vendor_id)
            VALUES (
                <cfqueryparam value="#arguments.user_id#"  cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            )
        </cfquery>

        <cfquery name="newId" datasource="#application.dsn#">
            SELECT LAST_INSERT_ID() AS new_id
        </cfquery>

        <cfreturn newId.new_id>
    </cffunction>

    <cffunction name="getForUser" returntype="query" output="false">
        <cfargument name="user_id" type="numeric" required="true">

        <cfquery name="q" datasource="#application.dsn#">
            SELECT
                c.id,
                c.vendor_id,
                c.updated_at,
                CONCAT(u.first_name, ' ', u.last_name) AS other_name,
                u.business_name AS business_name,
                (
                    SELECT m.message FROM messages m
                    WHERE  m.chat_id = c.id
                    ORDER  BY m.created_at DESC LIMIT 1
                ) AS last_message,
                (
                    SELECT COUNT(*) FROM messages m
                    WHERE  m.chat_id  = c.id
                    AND    m.sender_id = c.vendor_id
                    AND    m.is_read   = 0
                ) AS unread_count
            FROM chat c
            JOIN users u ON u.id = c.vendor_id
            WHERE c.user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
            ORDER BY c.updated_at DESC
        </cfquery>

        <cfreturn q>
    </cffunction>

    <cffunction name="getForVendor" returntype="query" output="false">
        <cfargument name="vendor_id" type="numeric" required="true">

        <cfquery name="q" datasource="#application.dsn#">
            SELECT
                c.id,
                c.user_id,
                c.updated_at,
                CONCAT(u.first_name, ' ', u.last_name) AS other_name,
                (
                    SELECT m.message FROM messages m
                    WHERE  m.chat_id = c.id
                    ORDER  BY m.created_at DESC LIMIT 1
                ) AS last_message,
                (
                    SELECT COUNT(*) FROM messages m
                    WHERE  m.chat_id  = c.id
                    AND    m.sender_id = c.user_id
                    AND    m.is_read   = 0
                ) AS unread_count
            FROM chat c
            JOIN users u ON u.id = c.user_id
            WHERE c.vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
            ORDER BY c.updated_at DESC
        </cfquery>

        <cfreturn q>
    </cffunction>

    <cffunction name="getAll" returntype="query" output="false">
        <cfquery name="q" datasource="#application.dsn#">
            SELECT
                c.id,
                c.user_id,
                c.vendor_id,
                c.updated_at,
                CONCAT(cu.first_name, ' ', cu.last_name) AS customer_name,
                CONCAT(vu.first_name, ' ', vu.last_name) AS vendor_name,
                (
                    SELECT m.message FROM messages m
                    WHERE  m.chat_id = c.id
                    ORDER  BY m.created_at DESC LIMIT 1
                ) AS last_message
            FROM chat c
            JOIN users cu ON cu.id = c.user_id
            JOIN users vu ON vu.id = c.vendor_id
            ORDER BY c.updated_at DESC
        </cfquery>
        <cfreturn q>
    </cffunction>

    <cffunction name="getById" returntype="query" output="false">
        <cfargument name="id" type="numeric" required="true">

        <cfquery name="q" datasource="#application.dsn#">
            SELECT * FROM chat
            WHERE id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfreturn q>
    </cffunction>

    <cffunction name="touch" returntype="void" output="false">
        <cfargument name="id" type="numeric" required="true">

        <cfquery datasource="#application.dsn#">
            UPDATE chat
            SET updated_at = NOW()
            WHERE id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
        </cfquery>
    </cffunction>

    <cffunction name="getTotalUnread" returntype="numeric" output="false">
        <cfargument name="user_id"   type="numeric" required="false" default="0">
        <cfargument name="vendor_id" type="numeric" required="false" default="0">

        <cfquery name="q" datasource="#application.dsn#">
            SELECT COUNT(*) AS total
            FROM messages m
            JOIN chat c ON c.id = m.chat_id
            WHERE m.is_read = 0
            <cfif arguments.user_id GT 0>
                AND c.user_id   = <cfqueryparam value="#arguments.user_id#"  cfsqltype="cf_sql_integer">
                AND m.sender_id = c.vendor_id
            <cfelseif arguments.vendor_id GT 0>
                AND c.vendor_id = <cfqueryparam value="#arguments.vendor_id#" cfsqltype="cf_sql_integer">
                AND m.sender_id = c.user_id
            </cfif>
        </cfquery>

        <cfreturn q.total>
    </cffunction>

</cfcomponent>