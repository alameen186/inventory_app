<cfif NOT structKeyExists(session, "user_id")>
    <cfabort>
</cfif>

<div class="container-fluid mt-4">

<div id="ajaxMessage"></div>

<h3 class="mb-3">All Orders</h3>

<!-- SEARCH FORM -->
<form id="orderSearchForm" class="mb-3">
    <div class="row g-2">

        <div class="col-12 col-md-4">
            <input type="text" name="search"
                   placeholder="Search Order ID or Username"
                   class="form-control">
        </div>

        <div class="col-6 col-md-3">
            <input type="date" name="fromDate" class="form-control">
        </div>

        <div class="col-6 col-md-3">
            <input type="date" name="toDate" class="form-control">
        </div>

        <div class="col-6 col-md-1 d-grid">
            <button type="submit" class="btn btn-primary">Apply</button>
        </div>

        <div class="col-6 col-md-1 d-grid">
            <button type="button" id="clearSearch" class="btn btn-outline-secondary">Clear</button>
        </div>

    </div>
</form>

<!-- ORDER CONTAINER -->
<div id="orderContainer"></div>

<!-- PAGINATION CONTAINER -->
<div id="paginationContainer" class="d-flex justify-content-center flex-wrap gap-2 mt-4"></div>

</div>

<script>
$(function(){

    var ORDER_CTRL = "../../controllers/orders/AdminOrderController.cfc";

    // MESSAGE
    function showMsg(res){
        $("#ajaxMessage").html(
            '<div class="alert alert-'+(res.status==="success"?"success":"danger")+'">'+
            (res.message||"")+'</div>'
        );
        setTimeout(()=>$("#ajaxMessage").html(""), 3000);
    }

    // LOAD ORDERS
    function loadOrders(page){
        let formData = $("#orderSearchForm").serialize();
        formData = formData.replace(/(&|^)p=\d+/,"");
        let finalData = "method=searchOrders&p=" + page + "&" + formData;

        $.ajax({
            url      : ORDER_CTRL,
            type     : "GET",
            data     : finalData,
            dataType : "json",
            success  : function(res){
                if(res.status === "success"){
                    $("#orderContainer").html(res.html);
                    $("#paginationContainer").html(res.pagination);
                } else {
                    showMsg(res);
                }
            },
            error : function(xhr){
                console.log("Load error:", xhr.responseText);
            }
        });
    }

    // SEARCH
    $("#orderSearchForm").submit(function(e){
        e.preventDefault();
        loadOrders(1);
    });

    // CLEAR
    $("#clearSearch").click(function(){
        $("input[name='search']").val('');
        $("input[name='fromDate']").val('');
        $("input[name='toDate']").val('');
        loadOrders(1);
    });

    // PAGINATION
    $(document).on("click", ".pageBtn", function(){
        loadOrders($(this).data("page"));
    });

    // APPROVE CANCEL
    $(document).on("click", ".approveBtn", function(){
        let id = $(this).data("id");
        $.ajax({
            url      : ORDER_CTRL + "?method=approveCancel",
            type     : "POST",
            data     : { order_group_id: id },
            dataType : "json",
            success  : function(res){
                showMsg(res);
                if(res.status === "success") loadOrders(1);
            },
            error : function(xhr){
                console.log("Approve error:", xhr.responseText);
            }
        });
    });

    // INITIAL LOAD
    loadOrders(1);

});
</script>