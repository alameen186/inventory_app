<cfset categoryModel = createObject("component", "models.Category")>
<cfset category = categoryModel.getAllCategories()>
<cfparam name="url.editId" default="0">
<cfparam name="url.showForm" default="0">

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
</div>

<script>
    setTimeout(function () {
        var alertBox = document.getElementById("alertBox");
        if (alertBox) {
            alertBox.style.display = "none";
        }
    }, 5000);   
</script>