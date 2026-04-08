<!-- check login -->
<cfif NOT structKeyExists(session, "user_id")>
    <cflocation url="../../index.cfm?page=auth&message=Please login&type=error" addtoken="false">
    <cfabort>
</cfif>

<!-- create cart if not exists -->
<cfif NOT structKeyExists(session, "cart")>
    <cfset session.cart = structNew()>
</cfif>

<cfparam name="url.search" default="">
<cfparam name="url.category_id" default="">
<cfparam name="url.min_price" default="">
<cfparam name="url.max_price" default="">
<cfparam name="url.sort" default="">
<cfparam name="url.p" default="1">

<!-- models -->
<cfset productModel = createObject("component", "models.Product")>
<cfset categoryModel = createObject("component", "models.Category")>

<!-- categories -->
<cfset categories = categoryModel.getAllActiveCategory()>

<!-- fetch products -->
<cfset products = productModel.searchProducts(
    keyword = url.search,
    category_id = isNumeric(url.category_id) ? url.category_id : javacast("null", ""),
    min_price = isNumeric(url.min_price) ? url.min_price : javacast("null", ""),
    max_price = isNumeric(url.max_price) ? url.max_price : javacast("null", ""),
    sort = url.sort,
    page = val(url.p)
)>

<!-- total count for pagination -->
<cfset totalRecords = productModel.getProductCount(
    keyword = url.search,
    category_id = isNumeric(url.category_id) ? url.category_id : javacast("null",""),
    min_price = isNumeric(url.min_price) ? url.min_price : javacast("null",""),
    max_price = isNumeric(url.max_price) ? url.max_price : javacast("null","")
)>

<!-- pagination math -->
<cfset limit = 2> 
<cfset totalPages = ceiling(totalRecords / limit)>
<cfset currentPage = val(url.p)>

<div class="container mt-4">
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
           <script>
    setTimeout(function () {
        var alertBox = document.getElementById("alertBox");
        if (alertBox) {
            alertBox.style.display = "none";
        }
    }, 5000);   
</script>

<!-- search + filters -->
<form method="get" action="../../index.cfm" class="mb-3">
    <input type="hidden" name="page" value="dashboard">
    <input type="hidden" name="section" value="productList">
<cfoutput>
    <input type="text" name="search" value="#url.search#" placeholder="Search..." class="form-control w-25 d-inline">
</cfoutput>

    <input type="number" name="min_price" value="#url.min_price#" placeholder="Min Price">
    <input type="number" name="max_price" value="#url.max_price#" placeholder="Max Price">

    <select name="sort">
        <option value="">Sort</option>
        <option value="price_low" <cfif url.sort EQ "price_low">selected</cfif>>Low to High</option>
        <option value="price_high" <cfif url.sort EQ "price_high">selected</cfif>>High to Low</option>
        <option value="a_z" <cfif url.sort EQ "a_z">selected</cfif>>A-Z</option>
        <option value="z_a" <cfif url.sort EQ "z_a">selected</cfif>>Z-A</option>
    </select>

    <!-- category dropdown -->
    <select name="category_id">
        <option value="">All</option>
        <cfoutput query="categories">
            <option value="#id#" <cfif url.category_id EQ id>selected</cfif>>
                #category_name#
            </option>
        </cfoutput>
    </select>

    <button class="btn btn-primary">Search</button>
</form>

<h3>Products</h3>

<div class="row">

<cfoutput query="products">
    <div class="col-md-3 mb-3">
        <div class="card">

            <!-- image -->
            <cfif len(image)>
                <img src="../../assets/images/products/#image#" style="height:200px; object-fit:cover;">
            <cfelse>
                <img src="https://via.placeholder.com/200">
            </cfif>

            <div class="card-body text-center">
                <h5>#product_name#</h5>
                <p>#category_name#</p>
                <p>#price#</p>

                <!-- cart button -->
                <cfif structKeyExists(session.cart, id)>
                    <a href="../../index.cfm?page=dashboard&section=cart" class="btn btn-success btn-sm">Go to Cart</a>
                <cfelse>
                    <form method="post" action="../../controllers/CartController.cfm">
                        <input type="hidden" name="action" value="add">
                        <input type="hidden" name="product_id" value="#id#">
                        <input type="hidden" name="product_name" value="#product_name#">
                        <input type="hidden" name="price" value="#price#">
                        <input type="hidden" name="image" value="#image#">
                        <button class="btn btn-success btn-sm">Add</button>
                    </form>
                </cfif>

            </div>
        </div>
    </div>
</cfoutput>

</div>

<!-- pagination numbers -->
<cfoutput>
<div class="mt-3">

<cfloop from="1" to="#totalPages#" index="i">

    <a href="?page=dashboard&section=productList&p=#i#&search=#url.search#&category_id=#url.category_id#&min_price=#url.min_price#&max_price=#url.max_price#&sort=#url.sort#"
class="btn btn-sm <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>">
    #i#
</a>
</cfloop>

</div>
</cfoutput>

</div>