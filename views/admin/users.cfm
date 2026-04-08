<cfset userModel = createObject("component", "models.User")>
<cfparam name="url.editId" default="0">

<cfparam name="url.search" default="">
<cfparam name="url.sort" default="">
<cfparam name="url.p" default="1">

<cfset currentPage = val(url.p)>
<cfif currentPage LT 1>
    <cfset currentPage = 1>
</cfif>

<cfset limit = 2>


<cfset users = userModel.getAllUsers(
    search = trim(url.search),
    sort = url.sort,
    page = currentPage,
    limit = limit
)>

<cfset totalRecords = userModel.getUserCount(
    search = trim(url.search)
)>

<cfset totalPages = ceiling(totalRecords / limit)>

<div class="container mt-4">
    <h3 class="mb-3">Users Management</h3>
      <cfif structKeyExists(url, "message")>
                        <div id="alertBox" class="alert 
                            <cfif structKeyExists(url, "type") AND url.type EQ 'success'>
                                alert-success
                            <cfelse>
                                alert-danger
                            </cfif>">
                    
                            <cfoutput>#url.message#</cfoutput>
                        </div>
                    </cfif>

  <cfoutput>
     <form method="get" action="../../index.cfm" class="mb-3">
        <input type="hidden" name="page" value="dashboard">
        <input type="hidden" name="section" value="users">

          <!-- search -->
        <input type="text" name="search" value="#url.search#" 
           placeholder="Search user..." 
           class="form-control w-25 d-inline">

           <!-- sort -->
        <select name="sort" class="form-control w-25 d-inline">
         <option value="">Sort</option>
         <option value="a_z" <cfif url.sort EQ "a_z">selected</cfif>>A-Z</option>
         <option value="z_a" <cfif url.sort EQ "z_a">selected</cfif>>Z-A</option>
        </select>

    <button class="btn btn-primary btn-sm">Apply</button>
     </form>
  </cfoutput>

    <table class="table table-bordered table-striped table-hover shadow-sm mt-3">
        <thead class="table-dark">
            <tr>
                <th>ID</th>
                <th>First Name</th>
                <th>Last Name</th>
                <th>Email</th>
                <th>Role</th>
                <th>Actions</th>
            </tr>
        </thead>

        <tbody>
            <cfoutput query="users">

            <cfif url.editId EQ id>
                 <form method="post" action="../../controllers/UserController.cfm">

                        <td>#id#</td>

                        <td>
                            <input type="text" name="first_name" value="#first_name#" class="form-control">
                        </td>

                        <td>
                            <input type="text" name="last_name" value="#last_name#" class="form-control">
                        </td>

                        <td>
                            <input type="email" name="email" value="#email#" class="form-control">
                        </td>

                        <td>#role_name#</td>

                        <td>
                            <input type="hidden" name="id" value="#id#">
                            <input type="hidden" name="action" value="update">

                            <button class="btn btn-success btn-sm">Save</button>

                            <a href="../../index.cfm?page=dashboard&section=users" 
                               class="btn btn-secondary btn-sm">Cancel</a>
                        </td>

                    </form>
            
            <cfelse>
                <tr>
                    <td>#id#</td>
                    <td>#first_name#</td>
                    <td>#last_name#</td>
                    <td>#email#</td>
                    <td>#role_name#</td>
                    <td>
                      <cfif role_id NEQ 1>
                      <a href="../../index.cfm?page=dashboard&section=users&editId=#id#" 
                           class="btn btn-warning btn-sm">Edit</a>
                        <a href="../../controllers/UserController.cfm?action=delete&id=#id#" 
                           class="btn btn-sm btn-danger"
                           onclick="return confirm('Delete this user?')">
                           Delete
                        </a>
                        <cfelse>
                                 Restricted
                      </cfif>
                    </td>
                </tr>
            </cfif>    
            </cfoutput>
        </tbody>
    </table>
    <cfoutput>
<div class="mt-4">

<cfloop from="1" to="#totalPages#" index="i">

    <a href="?page=dashboard&section=users&p=#i#&search=#url.search#&sort=#url.sort#"
       class="btn btn-sm <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>">

        #i#

    </a>

</cfloop>

</div>
</cfoutput>
</div>

<script>
    setTimeout(function () {
        var alertBox = document.getElementById("alertBox");
        if (alertBox) {
            alertBox.style.display = "none";
        }
    }, 5000);   
</script>