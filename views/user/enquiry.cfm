<cfif NOT structKeyExists(session, "user_id")>
    <cfabort>
</cfif>

<div class="container mt-4">
<h3>My Product Enquiries</h3>
<div id="ajaxMessage"></div>

<table class="table table-bordered mt-3">
<thead class="table-dark">
<tr>
    <th>Product</th>
    <th>Image</th>
    <th>Price</th>
    <th>Status</th>
    <th>Date</th>
</tr>
</thead>
<tbody id="enqTableBody"></tbody>
</table>

<div id="paginationContainer" class="d-flex justify-content-center flex-wrap gap-2 mt-3"></div>
</div>

<script>
$(function(){
    var ENQ_CTRL = "../../controllers/EnquiryController.cfc";

    function loadEnquiries(page){
        $.ajax({
            url      : ENQ_CTRL,
            type     : "GET",
            data     : { method: "getUserEnquiries", p: page },
            dataType : "json",
            success  : function(res){
                if(res.status === "success"){
                    $("#enqTableBody").html(res.html);
                    $("#paginationContainer").html(res.pagination);
                }
            },
            error : function(xhr){
                console.log("Load error:", xhr.responseText);
            }
        });
    }

    $(document).on("click", ".pageBtn", function(){
        loadEnquiries($(this).data("page"));
    });

    loadEnquiries(1);
});
</script>