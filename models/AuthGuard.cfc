<cfcomponent output="false">

    <cffunction name="checkAuth" access="public" returntype="void" output="true">

        <!--- SESSION EXISTS - already authenticated --->
        <cfif structKeyExists(session, "user_id") AND len(session.user_id)>
            <cfreturn>
        </cfif>

        <cfset var helper = createObject("component", "models.JwtHelper")>
        <cfset var result = helper.verifyToken()>

        <cfif result.success>

            <!--- RESTORE SESSION FROM TOKEN PAYLOAD --->
            <cfset var p = result.payload>

            <cfif NOT structKeyExists(p, "userid") OR NOT structKeyExists(p, "role_id")>
                <cfset sendUnauthorized("Token payload is incomplete")>
            </cfif>

            <!--- CHECK TOKEN  --->
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


    <!--- requireRole --->
    <cffunction name="requireRole" access="public" returntype="void" output="true">
        <cfargument name="role_id" type="numeric" required="true">

        <cfif NOT structKeyExists(session, "role_id") OR session.role_id NEQ arguments.role_id>
            <cfset sendUnauthorized("You do not have permission to perform this action")>
        </cfif>

    </cffunction>


    <!---  sendUnauthorized --->
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
