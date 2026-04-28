<cfcomponent output="false">

    <!---
        AuthGuard.cfc
        Single shared auth checker used by ALL controllers.

        Priority order:
          1. Session already exists → pass through
          2. Valid JWT in header/url → restore session from token
          3. Neither → return 401 JSON error and abort
    --->

    <cffunction name="checkAuth" access="public" returntype="void" output="true">

        <!--- SESSION EXISTS - already authenticated --->
        <cfif structKeyExists(session, "user_id") AND len(session.user_id)>
            <cfreturn>
        </cfif>

        <!--- NO SESSION - try JWT --->
        <cfset var helper = createObject("component", "models.JwtHelper")>
        <cfset var result = helper.verifyToken()>

        <cfif result.success>

            <!--- RESTORE SESSION FROM TOKEN PAYLOAD --->
            <cfset var p = result.payload>

            <cfif NOT structKeyExists(p, "userid") OR NOT structKeyExists(p, "role_id")>
                <cfset sendUnauthorized("Token payload is incomplete")>
            </cfif>

            <!--- CHECK TOKEN TYPE - must be access token --->
            <cfif structKeyExists(p, "type") AND p.type NEQ "access">
                <cfset sendUnauthorized("Invalid token type. Use access token.")>
            </cfif>

            <cfset session.user_id    = p.userid>
            <cfset session.user_email = p.email>
            <cfset session.role_id    = p.role_id>
            <cfset session.role_name  = p.role_name>

            <cfreturn>
        </cfif>

        <!--- BOTH FAILED --->
        <cfset sendUnauthorized(result.message)>

    </cffunction>


    <!--- ─────────────────────────────────────────────
        requireRole(roleId)
        Use AFTER checkAuth() when you need a specific role.
        Example: requireRole(1) for admin only
    ───────────────────────────────────────────── --->
    <cffunction name="requireRole" access="public" returntype="void" output="true">
        <cfargument name="role_id" type="numeric" required="true">

        <cfif NOT structKeyExists(session, "role_id") OR session.role_id NEQ arguments.role_id>
            <cfset sendUnauthorized("You do not have permission to perform this action")>
        </cfif>

    </cffunction>


    <!--- ─────────────────────────────────────────────
        sendUnauthorized(message)
        Sends a 401 JSON response and aborts
    ───────────────────────────────────────────── --->
    <cffunction name="sendUnauthorized" access="private" returntype="void" output="true">
        <cfargument name="message" type="string" default="Unauthorized">

        <cfcontent type="application/json; charset=utf-8" reset="true">
        <cfoutput>#serializeJSON({
            "status"  : "error",
            "message" : arguments.message,
            "html"    : "",
            "pagination" : ""
        })#</cfoutput>
        <cfabort>

    </cffunction>

</cfcomponent>
