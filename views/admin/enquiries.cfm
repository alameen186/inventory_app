<cfset enquiryModel = createObject("component","models.Enquiry")>
<cfset productModel = createObject("component","models.Product")>

<!-- URL params -->
<cfparam name="url.restockId" default="0">
<cfparam name="url.search" default="">
<cfparam name="url.status" default="">
<cfparam name="url.p" default="1">

<!-- pagination -->
<cfset currentPage = val(url.p)>
<cfif currentPage LT 1>
    <cfset currentPage = 1>
</cfif>

<cfset limit = 5>

<!-- fetch enquiries -->
<cfset enquiries = enquiryModel.getAllEnquiries(
    search = url.search,
    status = url.status,
    page = currentPage,
    limit = limit
)>

<!-- total count -->
<cfset totalRecords = enquiryModel.getEnquiryCount(
    search = url.search,
    status = url.status
)>

<cfset totalPages = ceiling(totalRecords / limit)>

<div class="container mt-4">

<h3>Product Enquiries</h3>

<!-- message -->
<cfif structKeyExists(url,"message")>
<div class="alert 
<cfif structKeyExists(url,"type") AND url.type EQ "success">
alert-success
<cfelse>
alert-danger
</cfif>">
<cfoutput>#url.message#</cfoutput>
</div>
</cfif>

<!-- SEARCH + FILTER -->
<cfoutput>
<form method="get" action="../../index.cfm" class="mb-3">

    <input type="hidden" name="page" value="dashboard">
    <input type="hidden" name="section" value="adminEnquiries">

    <input type="text"
           name="search"
           value="#url.search#"
           placeholder="Search product or user"
           class="form-control w-25 d-inline">

    <select name="status" class="form-control w-25 d-inline">
        <option value="">All Status</option>
        <option value="pending"
            <cfif url.status EQ "pending">selected</cfif>>
            Pending
        </option>
        <option value="fulfilled"
            <cfif url.status EQ "fulfilled">selected</cfif>>
            Fulfilled
        </option>
    </select>

    <button class="btn btn-primary btn-sm">
        Search
    </button>

    <a href="../../index.cfm?page=dashboard&section=adminEnquiries"
       class="btn btn-secondary btn-sm">
       Reset
    </a>

</form>
</cfoutput>

<!-- enquiry table -->
<table class="table table-bordered mt-3">
<thead class="table-dark">
<tr>
    <th>User</th>
    <th>Product</th>
    <th>Image</th>
    <th>Price</th>
    <th>Stock</th>
    <th>Status</th>
    <th>Date</th>
    <th>Action</th>
</tr>
</thead>

<tbody>

<cfif enquiries.recordCount EQ 0>
<tr>
<td colspan="8" class="text-center text-muted">
No enquiries found
</td>
</tr>
<cfelse>

<cfoutput query="enquiries">
<tr>
    <td>#user_name#</td>
    <td>#product_name#</td>
    <td>
        <img src="../../assets/images/products/#image#" width="50">
    </td>
    <td>#price#</td>
    <td>#stock#</td>
    <td>
        <cfif status EQ "pending">
            <span class="badge bg-warning text-dark">Pending</span>
        <cfelse>
            <span class="badge bg-success">Fulfilled</span>
        </cfif>
    </td>
    <td>#dateFormat(created_at,"dd-mmm-yyyy")#</td>
    <td>
        <cfif status EQ "pending">
            <a href="../../index.cfm?page=dashboard&section=adminEnquiries&restockId=#product_id#&search=#urlEncodedFormat(url.search)#&status=#url.status#&p=#currentPage#"
               class="btn btn-warning btn-sm">
               Restock Product
            </a>
        <cfelse>
            <span class="text-muted">Completed</span>
        </cfif>
    </td>
</tr>
</cfoutput>

</cfif>

</tbody>
</table>

<!-- pagination -->
<cfif totalPages GT 1>
<cfoutput>
<div class="mt-4">

<cfloop from="1" to="#totalPages#" index="i">

<a href="?page=dashboard&section=adminEnquiries&p=#i#&search=#urlEncodedFormat(url.search)#&status=#url.status#"
class="btn btn-sm <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>">

#i#

</a>

</cfloop>

</div>
</cfoutput>
</cfif>

<!-- restock form -->
<cfif url.restockId GT 0>

<cfset product = productModel.getProductById(url.restockId)>

<cfoutput query="product">
<div class="card shadow-sm p-4 mt-4">

<h5>Restock Product</h5>

<form method="post" action="../../controllers/AdminEnquiryController.cfm">

<input type="hidden" name="action" value="restockProduct">
<input type="hidden" name="product_id" value="#id#">

<div class="mb-3">
<label>Product Name</label>
<input type="text" class="form-control" value="#product_name#" readonly>
</div>

<div class="mb-3">
<label>Category</label>
<input type="text" class="form-control" value="#category_name#" readonly>
</div>

<div class="mb-3">
<label>Price</label>
<input type="text" class="form-control" value="#price#" readonly>
</div>

<div class="mb-3">
<label>Current Stock</label>
<input type="text" class="form-control" value="#stock#" readonly>
</div>

<div class="mb-3">
<label>Add New Stock</label>
<input type="number"
       name="add_stock"
       class="form-control"
       required
       min="1">
</div>

<button class="btn btn-success">
Update Stock
</button>

<a href="../../index.cfm?page=dashboard&section=adminEnquiries&search=#urlEncodedFormat(url.search)#&status=#url.status#&p=#currentPage#"
class="btn btn-secondary">
Cancel
</a>

</form>
</div>
</cfoutput>

</cfif>

</div>