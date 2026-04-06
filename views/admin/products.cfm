<cfset productModel = createObject("component", "models.Product")>
<cfset categoryModel = createObject("component", "models.Category")>

<cfset products = productModel.getAllProducts()>
<cfset categories = categoryModel.getAllActiveCategory()>

<cfparam name="url.editId" default="0">
<cfparam name="url.showForm" default="0">

<div class="container mt-4">
    <h3 class="mb-3">Product Management</h3>

        <!--- message --->
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
    Add Product
    </button>

    <div id="addForm" style="display:<cfif url.showForm EQ 1>block<cfelse>none</cfif>;"> <!---gpt--->
           <form method="post" enctype="multipart/form-data" action="../../controllers/ProductController.cfm" class="mb-4">

    <input type="hidden" name="action" value="add">

    <div class="row g-3"> 
    
    <div class="col-md-3">
        <input type="text" name="product_name" class="form-control" placeholder="Product Name" required>
    </div>

    <div class="col-md-2">
        <input type="number" step="0.01" name="price" class="form-control" placeholder="Price" required>
    </div>

    <div class="col-md-3">
      <select name="category_id" class="form-control" required>
    <option value="">Select Category</option>

    <cfoutput query="categories">
        <option value="#id#">#category_name#</option>
    </cfoutput>

</select>
    </div>

    <!-- Image -->
    <div class="col-md-2">
        <input type="file" name="product_image" class="form-control" accept="image/*" required>
    </div>

    <!-- actions -->
    <div class="col-md-2">
        <button type="submit" class="btn btn-primary btn-block">Add Product</button>
        <button class="btn btn-link btn-sm w-100" onclick="document.getElementById('addForm').style.display='none'">
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
                <th>Price</th>
                <th>Category</th>
                <th>Image</th>
                <th>status</th>
                <th>Actions</th>
            </tr>
        </thead>

        <tbody>
            <cfoutput query="products">

<cfif url.editId EQ id>

<tr>
<form method="post" enctype="multipart/form-data" action="../../controllers/ProductController.cfm">

    <td>#id#</td>

    <td>
        <input type="text" name="product_name" value="#product_name#" class="form-control">
    </td>

    <td>
        <input type="number" step="0.01" name="price" value="#price#" class="form-control">
    </td>

    <td>
        <select name="category_id" class="form-control">
            <cfloop query="categories">
    <option value="#categories.id#"
        <cfif categories.id EQ products.category_id>selected</cfif>>
        #categories.category_name#
    </option>
</cfloop>
        </select>
    </td>

    <td>
        <cfif len(image)>
            <img src="../../assets/images/products/#image#" width="40"><br>
        </cfif>
        <input type="file" name="product_image" class="form-control">
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

        <a href="../../index.cfm?page=dashboard&section=product" 
           class="btn btn-secondary btn-sm">Cancel</a>
    </td>

</form>
</tr>

<cfelse>

<tr>
    <td>#id#</td>
    <td>#product_name#</td>
    <td>#price#</td>
    <td>#category_name#</td>

    <td>
        <cfif len(image)>
            <img src="../../assets/images/products/#image#" width="50">
        <cfelse>
            No Image
        </cfif>
    </td>

    <td>
        <cfif is_active EQ 1>
            <span class="badge bg-success">Active</span>
        <cfelse>
            <span class="badge bg-warning">Blocked</span>
        </cfif>
    </td>

    <td>
        <a href="../../index.cfm?page=dashboard&section=products&editId=#id#" class="btn btn-danger btn-sm">Edit</a>

        <a href="../../controllers/ProductController.cfm?action=block&id=#id#&currentStatus=#is_active#"
           class="btn btn-danger btn-sm">
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