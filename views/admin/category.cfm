<cfset categoryModel = createObject("component", "models.Category")>

<cfparam name="url.editId" default="0">
<cfparam name="url.showForm" default="0">
<cfparam name="url.search" default="">
<cfparam name="url.sort" default="">
<cfparam name="url.p" default="1">

<cfset currentPage = val(url.p)>
<cfif currentPage LT 1>
    <cfset currentPage = 1>
</cfif>

<cfset limit = 2>

<cfset category = categoryModel.getAllCategories(
    search = trim(url.search),
    sort = url.sort,
    page = currentPage,
    limit = limit
)>

<cfset totalRecords = categoryModel.getCategoryCount(
    search = trim(url.search)
)>

<cfset totalPages = ceiling(totalRecords / limit)>

<div class="container mt-4">
    <h3 class="mb-3">Category Management</h3>
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
    <button class="btn btn-primary mb-3" onclick="document.getElementById('addForm').style.display='block'">
    Add Category
    </button>
     <div id="addForm" style="display:<cfif url.showForm EQ 1>block<cfelse>none</cfif>;">
           <form method="post" action="../../controllers/CategoryController.cfm" class="mb-4">

    <input type="hidden" name="action" value="add">

    <div class="row">
    
        <div class="col-md-4">
            <input type="text" 
             name="category_name" 
             class="form-control" 
             placeholder="Category Name" 
             required>
        </div>

        <div class="col-md-4">
            <input type="text" 
            name="description" 
            class="form-control" 
            placeholder="Description" 
            required>
        </div>

        <div class="col-md-2">
            <button type="submit" class="btn btn-primary w-100">Add Category</button>
            <button type="button" class="btn btn-secondary btn-sm mt-2" onclick="document.getElementById('addForm').style.display='none'">
    Cancel
</button>        
        </div>
    </div>


</form>
     </div>

      <cfoutput>
      <form method="get" action="../../index.cfm" class="mb-3">
         <input type="hidden" name="page" value="dashboard">
         <input type="hidden" name="section" value="category">

         <input type="text" name="search" values="#url.search#"
                placeholder="search categories...."
                class="form-control w-25 d-inline">
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
                <th>Name</th>
                <th>Description</th>
                <th>status</th>
                <th>Actions</th>
            </tr>
        </thead>

        <tbody>
            <cfoutput query="category">

            <cfif url.editId EQ id>
                 <form method="post" action="../../controllers/CategoryController.cfm">

                        <td>#id#</td>

                        <td>
                            <input type="text" name="category_name" value="#category_name#" class="form-control">
                        </td>

                        <td>
                            <input type="text" name="description" value="#description#" class="form-control">
                        </td>

                        <td>
                             <cfif is_active EQ 1>
                               <span class="badge bg-success">Active</span>
                             <cfelse>
                               <span class="badge bg-warning">Blocked</span>
                             </cfif>
                        </td>

                        <td>
                            <input type="hidden" name="id" value="#id#">
                            <input type="hidden" name="action" value="update">

                            <button class="btn btn-success btn-sm">Save</button>

                            <a href="../../index.cfm?page=dashboard&section=category" 
                               class="btn btn-secondary btn-sm">Cancel</a>
                        </td>

                    </form>
            
            <cfelse>
                <tr>
                    <td>#id#</td>
                    <td>#category_name#</td>
                    <td>#description#</td>
                    <cfif is_active EQ 1>
                    <td><p class="text-success">Active</p></td>
                    <cfelse>
                    <td><p class="text-warning">Blocked</p></td>
                    </cfif>
                    <td>
                        <a href="../../index.cfm?page=dashboard&section=category&editId=#id#" 
                           class="btn btn-warning btn-sm">Edit</a>
                        <a href="../../controllers/CategoryController.cfm?action=block&id=#id#&currentStatus=#is_active#"
   class="btn btn-sm btn-danger"
   onclick="return confirm('Are you sure?')">
   <cfif is_active EQ 1>Block<cfelse>Unblock</cfif>
</a>
                    </td>
                </tr>
            </cfif>    
            </cfoutput>
        </tbody>
    </table>

     <cfoutput>
<div class="mt-4">

<cfloop from="1" to="#totalPages#" index="i">

    <a href="?page=dashboard&section=category&p=#i#&search=#url.search#&sort=#url.sort#"
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