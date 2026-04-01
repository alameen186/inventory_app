<cfif NOT structKeyExists(session, "role_id") OR session.role_id NEQ 1>
   <cfabort>
</cfif>

<cfif structKeyExists(url, "action") AND url.action EQ "delete">
      <cfset roleModel = createObject("component","models.Role")>
      <cfset roleModel.deleteRole(url.id)>

      <cflocation url="../index.cfm?page=dashboard&section=roles&message=Role deleted&type=success" addtoken="false">
    <cfabort>
</cfif>

<cfif structKeyExists(form, "action") AND form.action EQ "update">
      <cfset roleName = trim(form.name)>
      <cfset description = trim(form.description)>

      <cfset baseUrl = "../index.cfm?page=dashboard&section=roles">

      <cfif len(roleName) LT 3>
        <cflocation url="#baseUrl#&message=Role name must be at least 3 characters&type=error&editId=#form.id#" addtoken="false">
        <cfabort>

        <cfelseif len(roleName) GT 20>
        <cflocation url="#baseUrl#&message=Role name must be less than 20 characters&type=error&editId=#form.id#" addtoken="false">
        
        <cfabort>
      <cfelseif len(description) LT 5>
        <cflocation url="#baseUrl#&message=Description must be at least 5 characters&type=error&editId=#form.id#" addtoken="false">
        <cfabort>

        <cfelseif len(description) GT 100>
        <cflocation url="#baseUrl#&message=Description must be less than 100 characters&type=error&editId=#form.id#" addtoken="false">
        <cfabort>

    <cfelse>
    <cfset roleModel = createObject("component","models.Role")>
        <cfset roleModel.updateRole(form.id, roleName, description)>

    <cflocation url="../index.cfm?page=dashboard&section=roles&message=Role updated&type=success" addtoken="false">
    <cfabort>
    </cfif>  
</cfif>