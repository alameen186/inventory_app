<cfset orderModel = createObject("component","models.Order")>
<cfif structKeyExists(session,"role_name") AND session.role_name EQ "vendor">
    <cfset vendorFilter = session.user_id>
<cfelse>
    <cfset vendorFilter = "">
</cfif>
<cfparam name="url.search" default="">
<cfparam name="url.p" default="1">
<cfparam name="url.fromDate" default="">
<cfparam name="url.toDate" default="">

<cfset searchValue = trim(url.search)>
<cfset currentPage = val(url.p) GT 0 ? val(url.p) : 1>
<cfset limit = 2>

<cfset orders = orderModel.getAllOrdersWithPagination(
    search=searchValue,
    page=currentPage,
    limit=limit,
    vendor_id=vendorFilter,
    fromDate=url.fromDate,
    toDate=url.toDate
)>

<cfset totalRecords = orderModel.getOrderCount(
    search=searchValue,
    vendor_id=vendorFilter,
    fromDate=url.fromDate,
    toDate=url.toDate
)>
<cfset totalPages = ceiling(totalRecords / limit)>

<div class="container-fluid mt-4">

<div id="ajaxMessage"></div>

<h3 class="mb-3">All Orders</h3>

<!-- SEARCH FORM -->
<form id="orderSearchForm" class="mb-3">
    <div class="row g-2">

        <div class="col-12 col-md-4">
            <cfoutput>
            <input type="text" name="search"
                   value="#encodeForHTMLAttribute(searchValue)#"
                   placeholder="Search Order ID or Username"
                   class="form-control">
            </cfoutput>
        </div>

        <div class="col-6 col-md-3">
            <cfoutput>
            <input type="date" name="fromDate" value="#url.fromDate#" class="form-control">
            </cfoutput>
        </div>

        <div class="col-6 col-md-3">
            <cfoutput>
            <input type="date" name="toDate" value="#url.toDate#" class="form-control">
            </cfoutput>
        </div>

        <div class="col-6 col-md-1 d-grid">
            <button class="btn btn-primary">Apply</button>
        </div>

        <cfif len(searchValue)>
        <div class="col-6 col-md-1 d-grid">
            <button type="button" id="clearSearch" class="btn btn-outline-secondary">Clear</button>
        </div>
        </cfif>

    </div>
</form>

<!-- ORDER CONTAINER -->
<div id="orderContainer">

<cfif orders.recordCount EQ 0>
    <div class="alert alert-info">No orders found matching your criteria.</div>
<cfelse>

<cfset currentGroup = "">
<cfset gTotal = 0>

<cfoutput query="orders">

<cfif currentGroup NEQ order_group_id>

    <cfif currentGroup NEQ "">
        <tr class="table-secondary">
            <td colspan="4" class="text-end"><strong>Total:</strong></td>
            <td><strong>#gTotal#</strong></td>
        </tr>
        </table></div></div>
        <cfset gTotal = 0>
    </cfif>

    <div class="card mb-4 shadow">

        <div class="card-header bg-dark text-white">
            <div class="d-flex flex-column flex-sm-row justify-content-between align-items-start align-items-sm-center gap-2">

                <span style="font-size:0.9rem;">
                    <strong>Order: #order_group_id#</strong><br class="d-sm-none">
                    <span class="ms-sm-2">#dateFormat(created_at, "dd-mmm-yyyy")#</span> |
                    <span>#user_name#</span>
                </span>

                <div class="d-flex align-items-center gap-2 flex-wrap">
                    <a href="../../assets/invoices/invoice_#order_group_id#.pdf"
                       target="_blank"
                       class="btn btn-success btn-sm">PDF</a>

                    <cfif status EQ "cancel_requested">
                        <span class="badge bg-warning text-dark">Cancel Requested</span>
                    <cfelseif status EQ "cancelled">
                        <span class="badge bg-secondary">Cancelled</span>
                    <cfelse>
                        <span class="badge bg-success">Active</span>
                    </cfif>
                </div>

            </div>
        </div>

        <cfif status EQ "cancel_requested">
        <div class="p-3 border-top bg-light">
            <p><strong>Cancel Reason:</strong></p>
            <div class="alert alert-warning">#cancel_reason#</div>
            <button class="approveBtn btn btn-success btn-sm" data-id="#order_group_id#">
                Approve Cancel
            </button>
        </div>
        </cfif>

        <div class="table-responsive">
        <table class="table mb-0">
            <thead class="table-dark">
            <tr>
                <th>Product</th>
                <th>Image</th>
                <th>Price</th>
                <th>Qty</th>
                <th>Total</th>
            </tr>
            </thead>
            <tbody>

    <cfset currentGroup = order_group_id>
</cfif>

<!-- ROW -->
<tr>
    <td>#product_name#</td>
    <td>
        <img src="../../assets/images/products/#image#" width="40"
             style="height:40px;object-fit:cover;"
             onerror="this.src='https://placehold.co/40'">
    </td>
    <td>#price#</td>
    <td>#quantity#</td>
    <td>#total_amount#</td>
</tr>

<cfset gTotal += total_amount>

<cfif currentRow EQ recordCount>
            </tbody>
        </table>
        </div>

        <div class="card-footer text-end">
            <strong>Order Total: #gTotal#</strong>
        </div>

    </div>
</cfif>

</cfoutput>

<!-- PAGINATION -->
<cfset groupSize = 4>
<cfset pageGroup = ceiling(currentPage / groupSize)>
<cfset startPage = (pageGroup - 1) * groupSize + 1>
<cfset endPage = min(startPage + groupSize - 1, totalPages)>

<cfoutput>
<div class="d-flex justify-content-center flex-wrap gap-2 mt-4">

    <cfif startPage GT 1>
        <button class="btn btn-outline-primary btn-sm pageBtn"
                data-page="#startPage - 1#">&laquo; Prev</button>
    </cfif>

    <cfloop from="#startPage#" to="#endPage#" index="i">
        <button class="btn btn-sm pageBtn <cfif i EQ currentPage>btn-primary<cfelse>btn-outline-primary</cfif>"
                data-page="#i#">#i#</button>
    </cfloop>

    <cfif endPage LT totalPages>
        <button class="btn btn-outline-primary btn-sm pageBtn"
                data-page="#endPage + 1#">Next &raquo;</button>
    </cfif>

</div>
</cfoutput>

</cfif>

</div>
</div>


<script>
$(function(){

    function showMessage(res){
        $("#ajaxMessage").html(
            '<div id="msgBox" class="alert alert-'+
            (res.status==="success"?"success":"danger")+
            '">'+res.message+'</div>'
        );
        setTimeout(()=>$("#msgBox").fadeOut(),3000);
    }

    // SEARCH
    $("#orderSearchForm").submit(function(e){
        e.preventDefault();
        $.get("../../controllers/OrderController.cfm",
            "action=search&"+$(this).serialize(),
            function(res){ $("#orderContainer").html(res); }
        );
    });

    // CLEAR
    $("#clearSearch").click(function(){
        $("input[name='search']").val('');
        $("input[name='fromDate']").val('');
        $("input[name='toDate']").val('');
        $("#orderSearchForm").submit();
    });

    // PAGINATION
    $(document).on("click",".pageBtn",function(){
        let page = $(this).data("page");
        let data = $("#orderSearchForm").serialize();
        $.get("../../controllers/OrderController.cfm",
            "action=search&p="+page+"&"+data,
            function(res){ $("#orderContainer").html(res); }
        );
    });

    // APPROVE CANCEL
    $(document).on("click",".approveBtn",function(){
        let id = $(this).data("id");
        $.post("../../controllers/OrderController.cfm",{
            action:"approveCancel",
            order_group_id:id
        },function(res){
            showMessage(res);
            if(res.status==="success") location.reload();
        },"json");
    });

});
</script>