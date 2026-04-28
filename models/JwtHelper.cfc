<cfcomponent output="false">

    <cffunction name="getTokenFromRequest" access="public" returntype="string" output="false">
        <cfset var headers = getHttpRequestData().headers>
        <cfset var token = "">

        <!--- Check Authorization header  --->
        <cfif structKeyExists(headers, "Authorization")>
            <cfset token = trim(ReplaceNoCase(headers["Authorization"], "Bearer ", ""))>
        <!---  check URL param --->
        <cfelseif structKeyExists(url, "token")>
            <cfset token = trim(url.token)>
        </cfif>

        <cfreturn token>
    </cffunction>

    <cffunction name="verifyToken" access="public" returntype="struct" output="false">
        <cftry>
            <cfset var token = getTokenFromRequest()>

            <cfif NOT len(token)>
                <cfreturn { success: false, message: "No token provided" }>
            </cfif>

            <cfset var jwtObj  = createObject("component", "models.jwt").init(application.jwtSecret)>
            <cfset var payload = jwtObj.decode(token)>

            <cfreturn { success: true, payload: payload }>

        <cfcatch>
            <cfreturn { success: false, message: "Invalid or expired token" }>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>