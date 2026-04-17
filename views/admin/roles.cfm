<cfset roleModel = createObject("component", "models.Role")>

<cfparam name="url.editId" default="0">

<cfparam name="url.search" default="">
<cfparam name="url.sort" default="">
<cfparam name="url.p" default="1">

<cfset currentPage = val(url.p)>
<cfif currentPage LT 1>
    <cfset currentPage = 1>
</cfif>

<cfset limit = 2>

<cfset roles = roleModel.getAllRoles(
    search = trim(url.search),
    sort = url.sort,
    page = currentPage,
    limit = limit
)>

<cfset totalRecords = roleModel.getRoleCount(
    search = trim(url.search)
)>

<cfset totalPages = ceiling(totalRecords / limit)>

<div class="container mt-4">
    <h3 class="mb-3">Role Management</h3>
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
         <input type="hidden" name="section" value="roles">

         <input type="text" name="search" values="#url.search#"
                placeholder="search role...."
                class="form-control w-25 d-inline">
         <select name="sort" class="form-control w-25 d-inline">
           <option value="">Sort</option>
           <option value="a_z" <cfif url.sort EQ "a_z">selected</cfif>>A-Z</option>
           <option value="z_a" <cfif url.sort EQ "z_a">selected</cfif>>Z-A</option>
         </select>   
         <button class="btn btn-primary btn-sm">Apply</button>
      </form>
   </cfoutput>
<div id="ajaxMessage"></div>
    <table class="table table-bordered table-striped table-hover shadow-sm mt-3">
        <thead class="table-dark">
            <tr>
                <th>ID</th>
                <th>Name</th>
                <th>description</th>
                <th>Actions</th>
            </tr>
        </thead>

        <tbody>
            <cfoutput query="roles">

            <cfif url.editId EQ id>
                 <form class="updateRoleForm" method="post" >

                        <td>#id#</td>

                        <td>
                            <input type="text" name="name" value="#role_name#" class="form-control">
                        </td>

                        <td>
                            <input type="text" name="description" value="#description#" class="form-control">
                        </td>
                        <td>
                            <input type="hidden" name="id" value="#id#">
                            <input type="hidden" name="action" value="update">

                            <button class="btn btn-success btn-sm">Save</button>

                            <a href="../../index.cfm?page=dashboard&section=roles" 
                               class="btn btn-secondary btn-sm">Cancel</a>
                        </td>

                    </form>
            
            <cfelse>
                <tr id="roleRow_#id#">
                    <td>#id#</td>
                    <td>#role_name#</td>
                    <td>#description#</td>
                    <td>
                        <a href="../../index.cfm?page=dashboard&section=roles&editId=#id#" 
                           class="btn btn-warning btn-sm">Edit</a>
                        <button class="btn btn-danger btn-sm deleteBtn" data-id="#id#">
                         Delete
                        </button>
                    </td>
                </tr>
            </cfif>    
            </cfoutput>
        </tbody>
    </table>

    <cfoutput>
<div class="mt-4">

<cfloop from="1" to="#totalPages#" index="i">

    <a href="?page=dashboard&section=roles&p=#i#&search=#url.search#&sort=#url.sort#"
       class="btn btn-sm <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>">

        #i#

    </a>

</cfloop>

</div>
</cfoutput>
</div>

<script>
$(document).ready(function(){

$(document).on("submit", ".updateRoleForm", function(e){
    e.preventDefault();

    $.ajax({
        url: "../../controllers/RoleController.cfm",
        type: "POST",
        data: $(this).serialize(),
        dataType: "json",

        success: function(res){

                $("#ajaxMessage").html(
                    '<div id="msgBox" class="alert alert-' +
                    (res.status === "success" ? "success" : "danger") +
                    '">' + res.message + '</div>'
                );

                setTimeout(function(){
                    $("#msgBox").fadeOut();
                }, 5000);

                if(res.status === "success"){
                    $("#updateUserForm")[0].reset();
                }
            },

            error: function(xhr){
                console.log(xhr.responseText);

                $("#ajaxMessage").html(
                    '<div id="msgBox" class="alert alert-danger">Something went wrong</div>'
                );

                setTimeout(function(){
                    $("#msgBox").fadeOut();
                }, 5000);
            }
    });
});

$(document).on("click",".deleteBtn", function() {
        let roleId  = $(this).data("id");
        if(confirm("Delete this Role?")) {
            $.ajax({
                url:"../../controllers/RoleController.cfm",
                type:"GET",
                data: {
                    action:"delete",
                    id:roleId 
                },
                dataType:"json",

                success: function(res) {
                    $("#userRow_" + res.id).remove()

                    $("#ajaxMessage").html(
                        '<div class="alert alert-success">' 
                        + res.message + 
                        '</div>'
                    )
                    setTimeout(function(){
                    $("#ajaxMessage").fadeOut();
                },5000);
                }
            })
        }

})
   
})
</script>