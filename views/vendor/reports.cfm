<cfif NOT structKeyExists(session, "user_id") OR session.role_name NEQ "vendor">
    <cfabort>
</cfif>

<cfset vendorCategories = createObject("component","models.Category").getByVendor(session.user_id)>

<div class="container-fluid mt-3">

    <h4 class="mb-4">Reports</h4>

    <!--- FILTER CARD --->
    <div class="card mb-4 shadow-sm">
        <div class="card-body">
            <div class="row g-3 align-items-end">

                <div class="col-12 col-md-3">
                    <label class="form-label fw-semibold">Report Type</label>
                    <select id="reportType" class="form-select">
                        <option value="">-- Select Report --</option>
                        <option value="orders">Orders</option>
                        <option value="products">Products</option>
                        <option value="categories">Categories</option>
                        <option value="scheduled_orders">Scheduled Orders</option>
                        <option value="customers">Customers</option>
                        <option value="revenue">Revenue Summary</option>
                    </select>
                </div>

                <div class="col-12 col-md-2">
                    <label class="form-label fw-semibold">Date From</label>
                    <input type="date" id="dateFrom" class="form-control">
                </div>

                <div class="col-12 col-md-2">
                    <label class="form-label fw-semibold">Date To</label>
                    <input type="date" id="dateTo" class="form-control">
                </div>

                <!--- Orders/Revenue only --->
                <div class="col-12 col-md-2" id="statusWrap" style="display:none;">
                    <label class="form-label fw-semibold">Status</label>
                    <select id="filterStatus" class="form-select">
                        <option value="">All Status</option>
                        <option value="pending">Pending</option>
                        <option value="completed">Completed</option>
                        <option value="cancelled">Cancelled</option>
                    </select>
                </div>

                <!--- Products only --->
                <div class="col-12 col-md-2" id="categoryWrap" style="display:none;">
                    <label class="form-label fw-semibold">Category</label>
                    <select id="filterCategory" class="form-select">
                        <option value="">All Categories</option>
                        <cfoutput query="vendorCategories">
                        <option value="#id#">#encodeForHTML(category_name)#</option>
                        </cfoutput>
                    </select>
                </div>

                <div class="col-12 col-md-2">
                    <label class="form-label fw-semibold d-block">&nbsp;</label>
                    <div class="d-flex gap-2">
                        <button type="button" id="previewBtn" class="btn btn-primary">
                            Preview
                        </button>
                        <button type="button" id="pdfBtn" class="btn btn-danger">
                            PDF
                        </button>
                    </div>
                </div>

            </div>
        </div>
    </div>

    <!--- PREVIEW AREA --->
    <div id="previewWrap" style="display:none;">
        <div class="card shadow-sm">
            <div class="card-header bg-dark text-white d-flex justify-content-between align-items-center py-2">
                <span class="fw-semibold" id="previewTitle">Report Preview</span>
                <small id="previewMeta" class="text-white-50"></small>
            </div>
            <div class="card-body p-0">
                <div id="previewContent"
                     style="overflow-x:auto; max-height:500px; overflow-y:auto; padding:16px;">
                </div>
            </div>
            <div class="card-footer text-muted text-center py-2">
                <small>This is a preview. Click <strong>PDF</strong> to download.</small>
            </div>
        </div>
    </div>

</div>

<script>
(function(){
    var CTRL = "../../controllers/ReportController.cfc";

    // ── Show/hide conditional filters
    $('#reportType').on('change', function(){
        var t = $(this).val();
        $('#statusWrap').toggle(t === 'orders' || t === 'revenue');
        $('#categoryWrap').toggle(t === 'products');
        // Hide preview when type changes
        $('#previewWrap').hide();
    });

    // ── Collect params
    function getParams(){
        return {
            report_type : $('#reportType').val(),
            date_from   : $('#dateFrom').val(),
            date_to     : $('#dateTo').val(),
            status      : $('#filterStatus').val(),
            category_id : $('#filterCategory').val()
        };
    }

    // ── Validate before action
    function validate(){
        if(!$('#reportType').val()){
            alert('Please select a report type.');
            return false;
        }
        var df = $('#dateFrom').val();
        var dt = $('#dateTo').val();
        if(df && dt && df > dt){
            alert('Date From cannot be after Date To.');
            return false;
        }
        return true;
    }

    // ── PREVIEW
    $('#previewBtn').on('click', function(){
        if(!validate()) return;

        $('#previewWrap').show();
        $('#previewContent').html(
            '<div class="text-center py-4 text-muted">' +
            '<div class="spinner-border spinner-border-sm me-2"></div>' +
            'Loading report...</div>'
        );

        $.ajax({
            url      : CTRL + "?method=getPreview",
            type     : "GET",
            data     : getParams(),
            dataType : "json",
            success  : function(res){
                if(!res.success){
                    $('#previewContent').html(
                        '<div class="alert alert-danger m-3">' + res.message + '</div>'
                    );
                    return;
                }
                $('#previewTitle').text(res.data.title);
                $('#previewMeta').text(res.data.meta);
                $('#previewContent').html(res.data.html);
            },
            error : function(xhr){
                $('#previewContent').html(
                    '<div class="alert alert-danger m-3">Server error loading preview. ' +
                    'Check console for details.</div>'
                );
                console.log('Report preview error:', xhr.responseText);
            }
        });
    });

    // ── PDF 
    $('#pdfBtn').on('click', function(){
        if(!validate()) return;
        var params = $.param($.extend(getParams(), { method: 'generatePDF' }));
        window.open(CTRL + "?" + params, '_blank');
    });

})();
</script>