<cfif NOT structKeyExists(session, "user_id")>
    <cflocation url="../../index.cfm?page=auth&message=Please login&type=error" addtoken="false">
    <cfabort>
</cfif>
<cfif NOT structKeyExists(session, "cart")>
    <cfset session.cart = structNew()>
</cfif>
<cfset productModel = createObject("component", "models.Product")>

<cfparam name="url.search" default="">

<cfset products = productModel.searchProducts(url.search)>

<div class="container mt-4">
<cfif structKeyExists(url, "message")>
    <div id="alertBox"  class="alert 
        <cfif structKeyExists(url, "type") AND url.type EQ 'success'>
            alert-success
        <cfelse>
            alert-danger
        </cfif>">

        <cfoutput>#url.message#</cfoutput>

    </div>
</cfif>
<form method="get" action="../../index.cfm" class="mb-3">
    <input type="hidden" name="page" value="dashboard">
    <input type="hidden" name="section" value="productList">
    <cfoutput>
    <input type="text" 
           name="search" 
           value="#url.search#" 
           placeholder="Search products..." 
           class="form-control w-25 d-inline">
    </cfoutput>
    
    <button class="btn btn-primary">Search</button>
</form>
    <h3 class="mb-4">Available Products</h3>

    <div class="row">

        <cfoutput query="products">

        <div class="col-md-3 mb-4">
            <div class="card shadow-sm h-100">

                <!-- Image -->
                <cfif len(image)>
                    <img src="../../assets/images/products/#image#" 
                         class="card-img-top" 
                         style="height:200px; object-fit:cover;">
                <cfelse>
                    <img src="https://via.placeholder.com/200x200?text=No+Image"
                         class="card-img-top">
                </cfif>

                <!-- Body -->
                <div class="card-body text-center">
                    <h5 class="card-title">#product_name#</h5>
                    <p class="card-text text-muted">#category_name#</p>
                    <p class="fw-bold">#price#</p>
               <cfif structKeyExists(session.cart, id)>

   
    <a href="../../index.cfm?page=dashboard&section=cart" 
       class="btn btn-success btn-sm w-100">
        Go to Cart
    </a>

<cfelse>
                <form method="post" action="../../controllers/CartController.cfm">
    <input type="hidden" name="action" value="add">
    <input type="hidden" name="product_id" value="#id#">
    <input type="hidden" name="product_name" value="#product_name#">
    <input type="hidden" name="price" value="#price#">
    <input type="hidden" name="image" value="#image#">

    <button class="btn btn-success btn-sm">Add to Cart</button>
</form>
</cfif>
 </div>
            </div>
        </div>  

        </cfoutput>

    </div>
</div>

<script>
    setTimeout(function () {
        var alertBox = document.getElementById("alertBox");
        if (alertBox) {
            alertBox.style.display = "none";
        }
    }, 5000);   
</script>   