<cfcomponent output="false">

    <!---
        JwtHelper.cfc
        Handles: token generation, verification, refresh, revocation
        Requires: models/jwt.cfc, refresh_tokens table in DB
    --->

    <!--- getTokenFromRequest --->
    <cffunction name="getTokenFromRequest" access="public" returntype="string" output="false">
        <cfset var headers = getHttpRequestData().headers>
        <cfset var token = "">

        <cfif structKeyExists(headers, "Authorization")>
            <cfset token = trim(ReplaceNoCase(headers["Authorization"], "Bearer ", "", "one"))>
        <cfelseif structKeyExists(url, "token")>
            <cfset token = trim(url.token)>
        </cfif>

        <cfreturn token>
    </cffunction>


    <!--- verifyToken--->
    <cffunction name="verifyToken" access="public" returntype="struct" output="false">
        <cftry>
            <cfset var token = getTokenFromRequest()>

            <cfif NOT len(trim(token))>
                <cfreturn { success: false, message: "No token provided" }>
            </cfif>

            <cfset var jwtObj  = createObject("component", "models.jwt").init(application.jwtSecret)>
            <cfset var payload = jwtObj.decode(token)>

            <cfreturn { success: true, payload: payload }>

        <cfcatch>
            <cfreturn { success: false, message: "Invalid or expired token: #cfcatch.message#" }>
        </cfcatch>
        </cftry>
    </cffunction>


    <!--- generateTokens --->
    <cffunction name="generateTokens" access="public" returntype="struct" output="false">
        <cfargument name="user_id"   type="numeric" required="true">
        <cfargument name="email"     type="string"  required="true">
        <cfargument name="role_id"   type="numeric" required="true">
        <cfargument name="role_name" type="string"  required="true">

        <cftry>
            <cfset var jwtObj = createObject("component", "models.jwt").init(application.jwtSecret)>

            <!--- ACCESS TOKEN — expires in 15 minutes --->
            <cfset var accessPayload = {
                "userid"    : arguments.user_id,
                "email"     : arguments.email,
                "role_id"   : arguments.role_id,
                "role_name" : arguments.role_name,
                "type"      : "access",
                "exp"       : DateDiff("s", CreateDateTime(1970,1,1,0,0,0), DateAdd("n", 15, Now()))
            }>
            <cfset var accessToken = jwtObj.encode(accessPayload)>

            <!--- REFRESH TOKEN — expires in 7 days --->
            <cfset var refreshPayload = {
                "userid"    : arguments.user_id,
                "email"     : arguments.email,
                "role_id"   : arguments.role_id,
                "role_name" : arguments.role_name,
                "type"      : "refresh",
                "exp"       : DateDiff("s", CreateDateTime(1970,1,1,0,0,0), DateAdd("d", 7, Now()))
            }>
            <cfset var refreshToken = jwtObj.encode(refreshPayload)>

            <!--- SAVE REFRESH TOKEN TO DATABASE --->
            <!--- First delete old tokens  --->
            <cfquery datasource="#application.dsn#">
                DELETE FROM refresh_tokens
                WHERE user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
                AND is_revoked = 0
                AND expires_at < NOW()
            </cfquery>

            <!--- Insert new refresh token --->
            <cfquery datasource="#application.dsn#">
                INSERT INTO refresh_tokens (user_id, refresh_token, expires_at)
                VALUES (
                    <cfqueryparam value="#arguments.user_id#"  cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#refreshToken#"       cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#DateAdd('d', 7, Now())#" cfsqltype="cf_sql_timestamp">
                )
            </cfquery>

            <cfreturn {
                access_token  : accessToken,
                refresh_token : refreshToken
            }>

        <cfcatch>
            <cfthrow message="generateTokens failed: #cfcatch.message#">
        </cfcatch>
        </cftry>
    </cffunction>


    <!--- refreshAccessToken --->
    <cffunction name="refreshAccessToken" access="public" returntype="struct" output="false">
        <cfargument name="refreshToken" type="string" required="true">

        <cftry>
            <!--- CHECK TOKEN IN DATABASE --->
            <cfquery name="qToken" datasource="#application.dsn#">
                SELECT rt.*, u.email, r.role_name
                FROM refresh_tokens rt
                JOIN users u ON rt.user_id = u.id
                JOIN roles r ON u.role_id = r.id
                WHERE rt.refresh_token = <cfqueryparam value="#arguments.refreshToken#" cfsqltype="cf_sql_varchar">
                AND rt.is_revoked = 0
                AND rt.expires_at > NOW()
                LIMIT 1
            </cfquery>

            <cfif qToken.recordCount EQ 0>
                <cfreturn { success: false, message: "Refresh token is invalid, expired or revoked" }>
            </cfif>

            <!--- ALSO VERIFY JWT SIGNATURE --->
            <cfset var jwtObj  = createObject("component", "models.jwt").init(application.jwtSecret)>
            <cfset var payload = jwtObj.decode(arguments.refreshToken)>

            <!--- MAKE SURE IT IS A REFRESH TYPE TOKEN --->
            <cfif NOT structKeyExists(payload, "type") OR payload.type NEQ "refresh">
                <cfreturn { success: false, message: "Invalid token type" }>
            </cfif>

            <!--- GENERATE NEW ACCESS TOKEN --->
            <cfset var newAccessPayload = {
                "userid"    : qToken.user_id,
                "email"     : qToken.email,
                "role_id"   : payload.role_id,
                "role_name" : qToken.role_name,
                "type"      : "access",
                "exp"       : DateDiff("s", CreateDateTime(1970,1,1,0,0,0), DateAdd("n", 15, Now()))
            }>
            <cfset var newAccessToken = jwtObj.encode(newAccessPayload)>

            <cfreturn { success: true, access_token: newAccessToken }>

        <cfcatch>
            <cfreturn { success: false, message: "Token refresh failed: #cfcatch.message#" }>
        </cfcatch>
        </cftry>
    </cffunction>


    <!---  revokeToken --->
    <cffunction name="revokeToken" access="public" returntype="boolean" output="false">
        <cfargument name="refreshToken" type="string" required="true">

        <cftry>
            <cfquery datasource="#application.dsn#">
                UPDATE refresh_tokens
                SET is_revoked = 1
                WHERE refresh_token = <cfqueryparam value="#arguments.refreshToken#" cfsqltype="cf_sql_varchar">
            </cfquery>

            <cfreturn true>

        <cfcatch>
            <cfreturn false>
        </cfcatch>
        </cftry>
    </cffunction>


    <!--- revokeAllUserTokens --->
    <cffunction name="revokeAllUserTokens" access="public" returntype="boolean" output="false">
        <cfargument name="user_id" type="numeric" required="true">

        <cftry>
            <cfquery datasource="#application.dsn#">
                UPDATE refresh_tokens
                SET is_revoked = 1
                WHERE user_id = <cfqueryparam value="#arguments.user_id#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfreturn true>

        <cfcatch>
            <cfreturn false>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>
