<cfcomponent output="false">

    <cffunction name="create" returntype="struct" output="false">
        <cfargument name="user_id"     type="numeric" required="true">
        <cfargument name="page_name"   type="string"  required="true">
        <cfargument name="subject"     type="string"  required="true">
        <cfargument name="description" type="string"  required="true">
        <cfargument name="priority"    type="string"  required="false" default="medium">

        <cftry>
            <!--- Generate unique reference --->
            <cfset var ref = "TKT-" & dateFormat(now(),"yyyymmdd") & "-" & randRange(1000,9999)>

            <cfquery datasource="#application.dsn#">
                INSERT INTO tickets (ticket_ref, user_id, page_name, subject, description, priority)
                VALUES (
                    <cfqueryparam value="#ref#"                  cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#arguments.user_id#"    cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#arguments.page_name#"  cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#arguments.subject#"    cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#arguments.description#" cfsqltype="cf_sql_longvarchar">,
                    <cfqueryparam value="#arguments.priority#"   cfsqltype="cf_sql_varchar">
                )
            </cfquery>

            <cfreturn { success: true, ticket_ref: ref }>
        <cfcatch>
            <cfreturn { success: false, message: cfcatch.message }>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getForUser" returntype="query" output="false">
        <cfargument name="user_id" type="numeric" required="true">
        <cfargument name="page"    type="numeric" required="false" default="1">
        <cfargument name="limit"   type="numeric" required="false" default="10">

        <cfset var offset = (arguments.page - 1) * arguments.limit>

        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT id, ticket_ref, page_name, subject, priority,
                   status, admin_note, created_at, updated_at
            FROM tickets
            WHERE user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
            ORDER BY created_at DESC
            LIMIT  <cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer">
            OFFSET <cfqueryparam value="#offset#"          cfsqltype="cf_sql_integer">
        </cfquery>

        <cfreturn local.q>
    </cffunction>

    <cffunction name="countForUser" returntype="numeric" output="false">
        <cfargument name="user_id" type="numeric" required="true">

        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT COUNT(*) AS total FROM tickets
            WHERE user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfreturn local.q.total>
    </cffunction>

    <cffunction name="getAll" returntype="query" output="false">
        <cfargument name="status"   type="string"  required="false" default="">
        <cfargument name="priority" type="string"  required="false" default="">
        <cfargument name="search"   type="string"  required="false" default="">
        <cfargument name="page"     type="numeric" required="false" default="1">
        <cfargument name="limit"    type="numeric" required="false" default="15">

        <cfset var offset = (arguments.page - 1) * arguments.limit>

        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT
                t.id,
                t.ticket_ref,
                t.page_name,
                t.subject,
                t.description,
                t.priority,
                t.status,
                t.admin_note,
                t.created_at,
                t.updated_at,
                CONCAT(u.first_name,' ',u.last_name) AS user_name,
                u.email AS user_email
            FROM tickets t
            JOIN users u ON u.id = t.user_id
            WHERE 1=1
            <cfif len(trim(arguments.status))>
                AND t.status = <cfqueryparam value="#arguments.status#" cfsqltype="cf_sql_varchar">
            </cfif>
            <cfif len(trim(arguments.priority))>
                AND t.priority = <cfqueryparam value="#arguments.priority#" cfsqltype="cf_sql_varchar">
            </cfif>
            <cfif len(trim(arguments.search))>
                AND (
                    t.ticket_ref LIKE <cfqueryparam value="%#trim(arguments.search)#%" cfsqltype="cf_sql_varchar">
                    OR t.subject LIKE <cfqueryparam value="%#trim(arguments.search)#%" cfsqltype="cf_sql_varchar">
                    OR CONCAT(u.first_name,' ',u.last_name) LIKE <cfqueryparam value="%#trim(arguments.search)#%" cfsqltype="cf_sql_varchar">
                )
            </cfif>
            ORDER BY
                FIELD(t.status,'pending','in_progress','resolved','closed'),
                FIELD(t.priority,'high','medium','low'),
                t.created_at DESC
            LIMIT  <cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer">
            OFFSET <cfqueryparam value="#offset#"          cfsqltype="cf_sql_integer">
        </cfquery>

        <cfreturn local.q>
    </cffunction>

    <cffunction name="countAll" returntype="numeric" output="false">
        <cfargument name="status"   type="string" required="false" default="">
        <cfargument name="priority" type="string" required="false" default="">
        <cfargument name="search"   type="string" required="false" default="">

        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT COUNT(*) AS total
            FROM tickets t
            JOIN users u ON u.id = t.user_id
            WHERE 1=1
            <cfif len(trim(arguments.status))>
                AND t.status = <cfqueryparam value="#arguments.status#" cfsqltype="cf_sql_varchar">
            </cfif>
            <cfif len(trim(arguments.priority))>
                AND t.priority = <cfqueryparam value="#arguments.priority#" cfsqltype="cf_sql_varchar">
            </cfif>
            <cfif len(trim(arguments.search))>
                AND (
                    t.ticket_ref LIKE <cfqueryparam value="%#trim(arguments.search)#%" cfsqltype="cf_sql_varchar">
                    OR t.subject LIKE <cfqueryparam value="%#trim(arguments.search)#%" cfsqltype="cf_sql_varchar">
                    OR CONCAT(u.first_name,' ',u.last_name) LIKE <cfqueryparam value="%#trim(arguments.search)#%" cfsqltype="cf_sql_varchar">
                )
            </cfif>
        </cfquery>

        <cfreturn local.q.total>
    </cffunction>

    <cffunction name="updateStatus" returntype="struct" output="false">
        <cfargument name="id"         type="numeric" required="true">
        <cfargument name="status"     type="string"  required="true">
        <cfargument name="admin_note" type="string"  required="false" default="">

        <cftry>
            <cfquery datasource="#application.dsn#">
                UPDATE tickets SET
                    status     = <cfqueryparam value="#arguments.status#"     cfsqltype="cf_sql_varchar">,
                    admin_note = <cfqueryparam value="#arguments.admin_note#" cfsqltype="cf_sql_longvarchar"
                                  null="#NOT len(trim(arguments.admin_note))#">
                WHERE id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfreturn { success: true }>
        <cfcatch>
            <cfreturn { success: false, message: cfcatch.message }>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getAdminEmail" returntype="string" output="false">
        <cfquery name="local.q" datasource="#application.dsn#">
            SELECT email FROM users
            WHERE role_id = 1
            LIMIT 1
        </cfquery>
        <cfreturn local.q.recordCount ? local.q.email : "">
    </cffunction>

    <cffunction name="getUser" returntype="struct" output="false">
     <cfargument name="user_id" type="numeric" required="true">

     <cfquery name="local.uQ" datasource="#application.dsn#">
        SELECT first_name, last_name, email
        FROM users
        WHERE id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
     </cfquery>

     <cfif local.uQ.recordCount>
        <cfreturn {
            first_name = local.uQ.first_name[1],
            last_name  = local.uQ.last_name[1],
            email      = local.uQ.email[1]
        }>
     </cfif>

     <cfreturn {}>
    </cffunction>

</cfcomponent>