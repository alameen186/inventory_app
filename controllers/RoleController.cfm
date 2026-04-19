<cfif NOT structKeyExists(session, "role_id") OR session.role_id NEQ 1>
   <cfabort>
</cfif>

<cfif structKeyExists(url, "action") AND url.action EQ "delete">
      <cfset roleModel = createObject("component","models.Role")>
      <cfset roleModel.deleteRole(url.id)>
        <cfcontent type="application/json" reset="true">
          <cfoutput>
            {
               "status":"success",
               "message":"Role deleted successfully",
               "id":"#url.id#"
            }
          </cfoutput>
          <cfabort>
</cfif>

<cfif structKeyExists(form, "action") AND form.action EQ "update">
      <cfset roleName = trim(form.name)>
      <cfset description = trim(form.description)>

      <cfset baseUrl = "../index.cfm?page=dashboard&section=roles">

      <cfif len(roleName) LT 3>
        <cfcontent type="application/json" reset="true">
          <cfoutput>
            {"status":"error", "message":"Role name must be at least 3 characters"}
          </cfoutput>
        <cfabort>

        <cfelseif len(roleName) GT 20>
        <cfcontent type="application/json" reset="true">
          <cfoutput>
            {"status":"error", "message":"Role name must be less than 20 characters"}
          </cfoutput>
        <cfabort>
      <cfelseif len(description) LT 5>
          <cfcontent type="application/json" reset="true">
          <cfoutput>
            {"status":"error", "message":"Description must be at least 5 characters"}
          </cfoutput>
        <cfabort>
        <cfelseif len(description) GT 100>
         <cfcontent type="application/json" reset="true">
          <cfoutput>
            {"status":"error", "message":"Description must be less than 100 characters"}
          </cfoutput>
        <cfabort>
    <cfelse>
    <cfset roleModel = createObject("component","models.Role")>
        <cfset roleModel.updateRole(form.id, roleName, description)>
     <cfcontent type="application/json" reset="true">
          <cfoutput>
            {"status":"success", "message":"Role updated"}
          </cfoutput>
        <cfabort>
    </cfif>  
</cfif>

<cfif structKeyExists(url,"action") AND url.action EQ "search">

<cfset roleModel = createObject("component","models.Role")>

<cfparam name="url.search" default="">
<cfparam name="url.sort" default="">
<cfparam name="url.p" default="1">

<cfset roles = roleModel.getAllRoles(
    search = trim(url.search),
    sort = url.sort,
    page = val(url.p),
    limit = 2
)>

<cfoutput query="roles">

<tr id="row_#id#">
<td>#id#</td>
<td>#role_name#</td>
<td>#description#</td>

<td>
<button class="btn btn-warning btn-sm editBtn"
data-id="#id#"
data-name="#role_name#"
data-desc="#description#">Edit</button>

<button class="btn btn-danger btn-sm deleteBtn" data-id="#id#">Delete</button>
</td>
</tr>

</cfoutput>

<cfif roles.recordCount EQ 0>
<tr><td colspan="4" class="text-center">No data</td></tr>
</cfif>

<cfabort>
</cfif>