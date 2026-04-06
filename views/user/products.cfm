<cfif NOT structKeyExists(session, "user_id")>
    <cflocation url="../../index.cfm?page=auth&message=Please login&type=error" addtoken="false">
    <cfabort>
</cfif>

<cfset productModel = createObject("component", "models.Product")>

<cfset products = productModel.getAllActiveProducts()>

<div class="container mt-4">
    <h3 class="mb-4">Available Products</h3>

    <div class="row">

        <cfoutput query="products">

        <div class="col-md-3 mb-4">
            <div class="card shadow-sm h-100">

                <!-- Image -->
                <cfif structKeyExists(products, "image") AND len(image)>
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
                </div>

            </div>
        </div>  

        </cfoutput>

    </div>
</div>