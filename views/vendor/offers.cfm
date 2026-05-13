<cfif NOT structKeyExists(session,"user_id") OR session.role_name NEQ "vendor">
    <cfabort>
</cfif>

<!--- Load categories and products --->
<cfset vendorCategories = createObject("component","models.Category").getByVendor(session.user_id)>
<cfquery name="vendorProducts" datasource="#application.dsn#">
    SELECT id, product_name FROM products
    WHERE vendor_id = <cfqueryparam value="#session.user_id#" cfsqltype="cf_sql_integer">
    AND   is_active = 1
    ORDER BY product_name ASC
</cfquery>

<cfset CTRL = "../../controllers/OfferController.cfc">

<!--- External CSS --->
<link rel="stylesheet" href="../../assets/css/offers.css">

<div class="container-fluid mt-3">

    <!--- PAGE HEADER --->
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h4 class="mb-0">Offer Management</h4>
        <button class="btn btn-primary" id="createOfferBtn">+ Create Offer</button>
    </div>

    <!--- FILTER TABS --->
    <div class="d-flex gap-2 mb-3">
        <button class="btn btn-outline-secondary offer-tab active" data-type="">All Offers</button>
        <button class="btn btn-outline-secondary offer-tab" data-type="seasonal">Seasonal</button>
        <button class="btn btn-outline-secondary offer-tab" data-type="individual">Individual</button>
    </div>

    <!--- OFFER TABLE --->
    <div class="card shadow-sm">
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover mb-0 small">
                    <thead class="table-dark">
                        <tr>
                            <th>Offer Name</th>
                            <th>Type</th>
                            <th>Category / Product</th>
                            <th>Discount</th>
                            <th>Valid Dates</th>
                            <th class="text-center">Affects</th>
                            <th class="text-center">Status</th>
                            <th class="text-center">Actions</th>
                        </tr>
                    </thead>
                    <tbody id="offerTableBody">
                        <tr>
                            <td colspan="8" class="text-center py-4">
                                <div class="spinner-border spinner-border-sm me-2"></div>
                                Loading offers...
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

</div>

<!---  CREATE / EDIT MODAL  --->
<div class="modal fade" id="offerModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">

            <div class="modal-header bg-dark text-white">
                <h5 class="modal-title" id="offerModalTitle">Create Offer</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>

            <div class="modal-body">
                <form id="offerForm">
                    <input type="hidden" id="offerId" name="id" value="0">

                    <!--- OFFER TYPE SELECTOR --->
                    <div class="mb-4">
                        <p class="modal-section-title">Select Offer Type</p>
                        <div class="offer-type-selector d-flex gap-3">

                            <input type="radio" class="btn-check" name="offer_type"
                                   id="typeSeasonalRadio" value="seasonal" checked>
                            <label class="btn btn-outline-primary offer-type-btn" for="typeSeasonalRadio">
                                <i class="bi bi-calendar"></i>Seasonal Offer
                                <small class="d-block text-muted" style="font-size:11px;">
                                    Apply to all products in a category
                                </small>
                            </label>

                            <input type="radio" class="btn-check" name="offer_type"
                                   id="typeIndividualRadio" value="individual">
                            <label class="btn btn-outline-success offer-type-btn" for="typeIndividualRadio">
                                <i class="bi bi-tag-fill"></i> Individual Offer
                                <small class="d-block text-muted" style="font-size:11px;">
                                    Apply to one specific product
                                </small>
                            </label>

                        </div>
                    </div>

                    <!--- OFFER NAME --->
                    <div class="mb-4">
                        <p class="modal-section-title">Offer Details</p>
                        <div class="row g-3">
                            <div class="col-12">
                                <label class="form-label fw-semibold">
                                    Offer Name <span class="text-danger">*</span>
                                </label>
                                <input type="text" class="form-control" id="offerName"
                                       name="offer_name"
                                       placeholder="e.g. Summer Sale, Vishu Offer, Weekend Deal">
                            </div>
                        </div>
                    </div>

                    <!--- CATEGORY (seasonal) --->
                    <div id="categoryWrap" class="mb-3">
                        <label class="form-label fw-semibold">
                            Category <span class="text-danger">*</span>
                            <small class="text-muted fw-normal">
                                 offer applies to all active products in this category
                            </small>
                        </label>
                        <select class="form-select" id="offerCategory" name="category_id">
                            <option value="">-- Select Category --</option>
                            <cfoutput query="vendorCategories">
                                <option value="#id#">#encodeForHTML(category_name)#</option>
                            </cfoutput>
                        </select>
                    </div>

                    <!--- PRODUCT (individual) --->
                    <div id="productWrap" class="mb-3" style="display:none;">
                        <label class="form-label fw-semibold">
                            Product <span class="text-danger">*</span>
                        </label>
                        <select class="form-select" id="offerProduct" name="product_id">
                            <option value="">-- Select Product --</option>
                            <cfoutput query="vendorProducts">
                                <option value="#id#">#encodeForHTML(product_name)#</option>
                            </cfoutput>
                        </select>
                    </div>

                    <!--- DISCOUNT --->
                    <div class="mb-4">
                        <p class="modal-section-title">Discount</p>
                        <div class="row g-3">
                            <div class="col-md-4">
                                <label class="form-label fw-semibold">Discount Type <span class="text-danger">*</span></label>
                                <select class="form-select" id="discountType" name="discount_type">
                                    <option value="percentage">Percentage (%)</option>
                                    <option value="flat">Flat Amount (<i class="bi bi-currency-rupee"></i>)</option>
                                </select>
                            </div>
                            <div class="col-md-4">
                                <label class="form-label fw-semibold">
                                    Discount Value <span class="text-danger">*</span>
                                </label>
                                <div class="input-group">
                                    <span class="input-group-text" id="discountSymbol">%</span>
                                    <input type="number" class="form-control" id="discountValue"
                                           name="discount_value" min="0.01" step="0.01"
                                           placeholder="Enter value">
                                </div>
                            </div>
                            <div class="col-md-4 d-flex align-items-end">
                                <div id="discountPreview" class="text-muted small fst-italic">
                                    Enter a value to see preview
                                </div>
                            </div>
                        </div>
                    </div>

                    <!--- DATES --->
                    <div class="mb-4">
                        <p class="modal-section-title">Offer Duration</p>
                        <div class="row g-3">
                            <div class="col-md-4">
                                <label class="form-label fw-semibold">
                                    Start Date <span class="text-danger">*</span>
                                </label>
                                <input type="date" class="form-control" id="startDate" name="start_date">
                            </div>
                            <div class="col-md-4">
                                <label class="form-label fw-semibold">
                                    End Date <span class="text-danger">*</span>
                                </label>
                                <input type="date" class="form-control" id="endDate" name="end_date">
                            </div>
                            <div class="col-md-4 d-flex align-items-end">
                                <div id="durationPreview" class="text-muted small fst-italic">
                                    Select dates to see duration
                                </div>
                            </div>
                        </div>
                    </div>

                    <!--- STATUS --->
                    <div class="form-check form-switch mb-2">
                        <input class="form-check-input" type="checkbox"
                               id="offerActive" name="is_active" checked>
                        <label class="form-check-label fw-semibold" for="offerActive">
                            Active (offer goes live immediately on start date)
                        </label>
                    </div>

                    <div id="emailNotice" class="alert alert-info py-2 small mt-3">
                        <i class="bi bi-envelope-arrow-down-fill"></i> An email notification will be sent to all registered customers when you save this offer.
                    </div>

                </form>
            </div>

            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                <button type="button" class="btn btn-primary" id="saveOfferBtn">Save Offer</button>
            </div>

        </div>
    </div>
</div>

<script>
(function(){
    var CTRL        = "../../controllers/OfferController.cfc";
    var activeTab   = "";   

    // ── Load offers table
    function loadOffers(){
        $('#offerTableBody').html(
            '<tr><td colspan="8" class="text-center py-4">' +
            '<div class="spinner-border spinner-border-sm me-2"></div>Loading...</td></tr>'
        );
        $.ajax({
            url      : CTRL + "?method=getAll",
            type     : "GET",
            data     : { offer_type: activeTab },
            dataType : "json",
            success  : function(res){
                if(res.success) $('#offerTableBody').html(res.data.html);
                else $('#offerTableBody').html(
                    '<tr><td colspan="8" class="text-center text-danger py-3">'
                    + res.message + '</td></tr>'
                );
            }
        });
    }
    loadOffers();

    // ── Tab filter
    $(document).on('click', '.offer-tab', function(){
        $('.offer-tab').removeClass('active');
        $(this).addClass('active');
        activeTab = $(this).data('type');
        loadOffers();
    });

    // ── category or product dropdown
    $('input[name="offer_type"]').on('change', function(){
        var val = $(this).val();
        if(val === 'seasonal'){
            $('#categoryWrap').show();
            $('#productWrap').hide();
            $('#offerCategory').val('');
        } else {
            $('#categoryWrap').hide();
            $('#productWrap').show();
            $('#offerProduct').val('');
        }
    });

    // ── Discount type → change symbol
    $('#discountType').on('change', function(){
        var sym = $(this).val() === 'percentage' ? '%' : '<i class="bi bi-currency-rupee"></i>';
        $('#discountSymbol').text(sym);
        updateDiscountPreview();
    });

    // ── Discount preview
    $('#discountValue').on('input', updateDiscountPreview);
    function updateDiscountPreview(){
        var val  = parseFloat($('#discountValue').val());
        var type = $('#discountType').val();
        if(!val || val <= 0){
            $('#discountPreview').text('Enter a value to see preview');
            return;
        }
        if(type === 'percentage'){
            if(val > 100){ $('#discountPreview').html('<span class="text-danger">Max 100%</span>'); return; }
            $('#discountPreview').html(
                'e.g. <i class="bi bi-currency-rupee"></i>1000 product → <strong><i class="bi bi-currency-rupee"></i>' + (1000 - (1000 * val / 100)).toFixed(2) + '</strong>'
            );
        } else {
            $('#discountPreview').html(
                'e.g. <i class="bi bi-currency-rupee"></i>1000 product → <strong><i class="bi bi-currency-rupee"></i>' + Math.max(0, 1000 - val).toFixed(2) + '</strong>'
            );
        }
    }

    // ── Duration preview
    $('#startDate, #endDate').on('change', function(){
        var from = $('#startDate').val();
        var to   = $('#endDate').val();
        if(from && to && to >= from){
            var d1   = new Date(from);
            var d2   = new Date(to);
            var days = Math.round((d2 - d1) / (1000*60*60*24)) + 1;
            $('#durationPreview').html('<strong>' + days + ' day' + (days !== 1 ? 's' : '') + '</strong> duration');
        } else if(to && from && to < from) {
            $('#durationPreview').html('<span class="text-danger">End date before start date</span>');
        } else {
            $('#durationPreview').text('Select dates to see duration');
        }
    });

    // ── Open create modal
    $('#createOfferBtn').on('click', function(){
        $('#offerModalTitle').text('Create Offer');
        $('#offerForm')[0].reset();
        $('#offerId').val('0');
        $('#typeSeasonalRadio').prop('checked', true);
        $('#categoryWrap').show();
        $('#productWrap').hide();
        $('#discountSymbol').text('%');
        $('#discountPreview').text('Enter a value to see preview');
        $('#durationPreview').text('Select dates to see duration');
        $('#emailNotice').show();
        new bootstrap.Modal($('#offerModal')[0]).show();
    });

    // ── Edit offer
    $(document).on('click', '.editOfferBtn', function(){
        var id = $(this).data('id');
        $.ajax({
            url      : CTRL + "?method=getOne&id=" + id,
            type     : "GET",
            dataType : "json",
            success  : function(res){
                if(!res.success){ alert(res.message); return; }
                var o = res.data;

                $('#offerModalTitle').text('Edit Offer');
                $('#offerId').val(o.id);
                $('#offerName').val(o.offer_name);
                $('#discountType').val(o.discount_type);
                $('#discountSymbol').text(o.discount_type === 'percentage' ? '%' : '<i class="bi bi-currency-rupee"></i>');
                $('#discountValue').val(o.discount_value);
                $('#startDate').val(o.start_date);
                $('#endDate').val(o.end_date);
                $('#offerActive').prop('checked', o.is_active == 1);
                $('#emailNotice').hide();   // no email on edit

                if(o.offer_type === 'seasonal'){
                    $('#typeSeasonalRadio').prop('checked', true);
                    $('#categoryWrap').show();
                    $('#productWrap').hide();
                    $('#offerCategory').val(o.category_id);
                } else {
                    $('#typeIndividualRadio').prop('checked', true);
                    $('#categoryWrap').hide();
                    $('#productWrap').show();
                    $('#offerProduct').val(o.product_id);
                }

                updateDiscountPreview();
                new bootstrap.Modal($('#offerModal')[0]).show();
            }
        });
    });

    // ── Save offer
    $('#saveOfferBtn').on('click', function(){
        var offerType = $('input[name="offer_type"]:checked').val();

        // Validate
        if(!$('#offerName').val().trim()){
            alert('Please enter an offer name'); return;
        }
        if(offerType === 'seasonal' && !$('#offerCategory').val()){
            alert('Please select a category'); return;
        }
        if(offerType === 'individual' && !$('#offerProduct').val()){
            alert('Please select a product'); return;
        }
        var discVal = parseFloat($('#discountValue').val());
        if(!discVal || discVal <= 0){
            alert('Please enter a valid discount value'); return;
        }
        if($('#discountType').val() === 'percentage' && discVal > 100){
            alert('Percentage cannot exceed 100%'); return;
        }
        if(!$('#startDate').val()){
            alert('Please select a start date'); return;
        }
        if(!$('#endDate').val()){
            alert('Please select an end date'); return;
        }
        if($('#endDate').val() < $('#startDate').val()){
            alert('End date cannot be before start date'); return;
        }

        var btn = $(this);
        btn.prop('disabled', true).text('Saving...');

        $.ajax({
            url      : CTRL + "?method=save",
            type     : "POST",
            dataType : "json",
            data     : $('#offerForm').serialize(),
            success  : function(res){
                btn.prop('disabled', false).text('Save Offer');
                if(res.success){
                    bootstrap.Modal.getInstance($('#offerModal')[0]).hide();
                    loadOffers();
                    alert(res.message);
                } else {
                    alert('Error: ' + res.message);
                }
            },
            error : function(){
                btn.prop('disabled', false).text('Save Offer');
                alert('Server error. Please try again.');
            }
        });
    });

    // ── Toggle status
    $(document).on('change', '.toggleOffer', function(){
        var id  = $(this).data('id');
        var chk = $(this);
        $.ajax({
            url      : CTRL + "?method=toggleStatus",
            type     : "POST",
            data     : { id: id },
            dataType : "json",
            success  : function(res){
                if(!res.success){
                    alert('Failed to update status');
                    chk.prop('checked', !chk.prop('checked'));
                }
            }
        });
    });

    // ── Delete offer
    $(document).on('click', '.deleteOfferBtn', function(){
        if(!confirm('Delete this offer? This cannot be undone.')) return;
        var id = $(this).data('id');
        $.ajax({
            url      : CTRL + "?method=delete",
            type     : "POST",
            data     : { id: id },
            dataType : "json",
            success  : function(res){
                if(res.success) loadOffers();
                else alert('Error: ' + res.message);
            }
        });
    });

})();
</script>