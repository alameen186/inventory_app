<cfif NOT structKeyExists(session,"user_id") OR session.role_name NEQ "vendor">
    <cfabort>
</cfif>

<div class="container-fluid mt-3">

    <div class="d-flex justify-content-between align-items-center mb-3">
        <h4 class="mb-0">
            <i class="bi bi-grid-3x3-gap-fill me-2 text-primary"></i>Rack Management
        </h4>
        <span class="badge bg-warning text-dark fs-6" id="swapAlertBadge" style="display:none;">
            <i class="bi bi-bell-fill me-1"></i>
            <span id="swapAlertCount">0</span> Swap Suggestions
        </span>
    </div>

    <div id="rackMsg"></div>

    <ul class="nav nav-tabs mb-4" id="rackTabs">
        <li class="nav-item">
            <a class="nav-link active" data-bs-toggle="tab" href="#tabRackView">
                <i class="bi bi-grid me-1"></i>Rack View
            </a>
        </li>
        <li class="nav-item">
            <a class="nav-link" data-bs-toggle="tab" href="#tabMyRacks">
                <i class="bi bi-list-ul me-1"></i>My Racks
            </a>
        </li>
        <li class="nav-item">
            <a class="nav-link" data-bs-toggle="tab" href="#tabCreateRack">
                <i class="bi bi-plus-circle me-1"></i>Create Rack
            </a>
        </li>
        <li class="nav-item">
            <a class="nav-link" data-bs-toggle="tab" href="#tabSwap">
                <i class="bi bi-arrow-left-right me-1"></i>Swap Products
            </a>
        </li>
        <li class="nav-item">
            <a class="nav-link" data-bs-toggle="tab" href="#tabAlerts">
                <i class="bi bi-bell me-1"></i>Swap Alerts
                <span class="badge bg-danger ms-1" id="alertTabBadge" style="display:none;">0</span>
            </a>
        </li>
    </ul>

    <div class="tab-content">

        <!--- RACK VIEW --->
        <div class="tab-pane fade show active" id="tabRackView">
            <div id="rackViewContent">
                <div class="text-center py-5">
                    <div class="spinner-border text-primary"></div>
                    <p class="mt-2 text-muted">Loading racks...</p>
                </div>
            </div>
        </div>

        <!--- MY RACKS --->
        <div class="tab-pane fade" id="tabMyRacks">
            <div class="card shadow-sm">
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-hover mb-0 small">
                            <thead class="table-dark">
                                <tr>
                                    <th>Rack Code</th>
                                    <th>Rack Name</th>
                                    <th>Face Capacities</th>
                                    <th>Status</th>
                                    <th>Action</th>
                                </tr>
                            </thead>
                            <tbody id="myRackTableBody">
                                <tr>
                                    <td colspan="5" class="text-center py-4">
                                        <div class="spinner-border spinner-border-sm"></div>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>

        <!---  CREATE RACK --->
        <div class="tab-pane fade" id="tabCreateRack">
            <div class="row justify-content-center">
                <div class="col-md-8 col-lg-6">
                    <div class="card shadow-sm">
                        <div class="card-header bg-dark text-white">
                            <strong>
                                <i class="bi bi-plus-circle me-2"></i>Create New Rack
                            </strong>
                        </div>
                        <div class="card-body">

                            <div class="row g-3 mb-3">
                                <div class="col-md-6">
                                    <label class="form-label fw-semibold">
                                        Rack Code <span class="text-danger">*</span>
                                    </label>
                                    <input type="text" id="rackCode" class="form-control"
                                           placeholder="e.g. RACK-A">
                                </div>
                                <div class="col-md-6">
                                    <label class="form-label fw-semibold">Rack Name</label>
                                    <input type="text" id="rackName" class="form-control"
                                           placeholder="e.g. Grocery Rack">
                                </div>
                            </div>

                            <p class="fw-semibold mb-2">
                                <i class="bi bi-columns-gap me-1"></i>Face Capacities
                                <small class="text-muted fw-normal">(leave 0 to skip that face)</small>
                            </p>
                            <div class="row g-3 mb-4">
                                <div class="col-6 col-md-3">
                                    <label class="form-label">F1 Capacity</label>
                                    <input type="number" id="cap_f1" class="form-control"
                                           placeholder="0" min="0" value="0">
                                </div>
                                <div class="col-6 col-md-3">
                                    <label class="form-label">F2 Capacity</label>
                                    <input type="number" id="cap_f2" class="form-control"
                                           placeholder="0" min="0" value="0">
                                </div>
                                <div class="col-6 col-md-3">
                                    <label class="form-label">F3 Capacity</label>
                                    <input type="number" id="cap_f3" class="form-control"
                                           placeholder="0" min="0" value="0">
                                </div>
                                <div class="col-6 col-md-3">
                                    <label class="form-label">F4 Capacity</label>
                                    <input type="number" id="cap_f4" class="form-control"
                                           placeholder="0" min="0" value="0">
                                </div>
                            </div>

                            <button class="btn btn-success w-100" id="saveRackBtn">
                                <i class="bi bi-save-fill me-1"></i>Save Rack
                            </button>

                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!--- SWAP PRODUCTS --->
        <div class="tab-pane fade" id="tabSwap">
            <div class="row justify-content-center">
                <div class="col-md-8 col-lg-6">
                    <div class="card shadow-sm">
                        <div class="card-header bg-dark text-white text-center">
                            <strong>
                                <i class="bi bi-arrow-left-right me-2"></i>Swap Products Between Faces
                            </strong>
                        </div>
                        <div class="card-body">

                            <div class="mb-3">
                                <label class="form-label fw-semibold">Product 1</label>
                                <select id="swapProduct1" class="form-select">
                                    <option value="">-- Select Product --</option>
                                </select>
                                <div id="swapInfo1" class="mt-1 small fst-italic text-muted"></div>
                            </div>

                            <div class="text-center my-2">
                                <i class="bi bi-arrow-down-up fs-4 text-secondary"></i>
                            </div>

                            <div class="mb-3">
                                <label class="form-label fw-semibold">Swap With</label>
                                <select id="swapProduct2" class="form-select">
                                    <option value="">-- Select Product --</option>
                                </select>
                                <div id="swapInfo2" class="mt-1 small fst-italic text-muted"></div>
                            </div>

                            <div id="swapPreview" class="rounded border p-3 bg-light mb-4" style="display:none;">
                                <p class="text-center fw-semibold mb-3">
                                    <i class="bi bi-eye me-1"></i>After Swap Preview
                                </p>
                                <div class="d-flex justify-content-around align-items-center">
                                    <div class="text-center">
                                        <div class="small text-muted mb-1">Product 1 moves to</div>
                                        <div class="fw-semibold small" id="previewName1"></div>
                                        <span class="badge bg-primary mt-1" id="previewDest1"></span>
                                    </div>
                                    <i class="bi bi-arrow-left-right fs-3 text-secondary"></i>
                                    <div class="text-center">
                                        <div class="small text-muted mb-1">Product 2 moves to</div>
                                        <div class="fw-semibold small" id="previewName2"></div>
                                        <span class="badge bg-primary mt-1" id="previewDest2"></span>
                                    </div>
                                </div>
                            </div>

                            <button class="btn btn-warning w-100 btn-lg" id="confirmSwapBtn" disabled>
                                <i class="bi bi-arrow-left-right me-2"></i>Confirm Swap
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!--- SWAP ALERTS --->
        <div class="tab-pane fade" id="tabAlerts">
            <div id="alertsContent">
                <div class="text-center py-5">
                    <div class="spinner-border text-warning"></div>
                    <p class="mt-2 text-muted">Loading alerts...</p>
                </div>
            </div>
        </div>

    </div>
</div>

<script>
(function(){
    var RPC = '../../controllers/RackPlacementController.cfc';
    var RC  = '../../controllers/RackController.cfc';
    var swap1 = null;
    var swap2 = null;

    function showMsg(success, msg){
        var cls = success ? 'success' : 'danger';
        $('#rackMsg').html(
            '<div class="alert alert-' + cls + ' alert-dismissible fade show">'
          + '<i class="bi bi-' + (success ? 'check-circle-fill' : 'exclamation-triangle-fill') + ' me-2"></i>'
          + msg
          + '<button type="button" class="btn-close" data-bs-dismiss="alert"></button>'
          + '</div>'
        );
    }

    /* ── TAB 1: RACK VIEW ── */
    function loadRackView(){
        $('#rackViewContent').html(
            '<div class="text-center py-5"><div class="spinner-border text-primary"></div>'
          + '<p class="mt-2 text-muted">Loading racks...</p></div>'
        );
        $.get(RPC + '?method=getRackView', function(res){
            $('#rackViewContent').html(
                res.success
                    ? res.data.html
                    : '<div class="alert alert-danger">' + res.message + '</div>'
            );
        }, 'json');
    }

    /* Remove product from rack view */
    $(document).on('click', '.removeProductBtn', function(){
        if(!confirm('Remove this product from its rack face?')) return;
        var productId = $(this).data('product-id');
        $.ajax({
            url      : RPC + '?method=removeProduct',
            type     : 'POST',
            data     : { product_id: productId },
            dataType : 'json',
            success  : function(res){
                showMsg(res.success, res.success ? 'Product removed from face.' : res.message);
                if(res.success){
                    loadRackView();
                    loadSwapDropdowns();
                }
            }
        });
    });

    /* ── TAB 2: CREATE RACK ── */
    $('#saveRackBtn').on('click', function(){
        var btn = $(this);

        var rackCode = $.trim($('#rackCode').val());
        if(!rackCode){
            showMsg(false, 'Rack code is required.');
            return;
        }

        btn.prop('disabled', true)
           .html('<span class="spinner-border spinner-border-sm me-1"></span>Saving...');

        $.ajax({
            url         : RC + '?method=createRack',
            type        : 'POST',
            contentType : 'application/x-www-form-urlencoded',
            data        : 'rack_code=' + encodeURIComponent($('#rackCode').val())
                        + '&rack_name=' + encodeURIComponent($('#rackName').val())
                        + '&cap_f1='    + encodeURIComponent($('#cap_f1').val())
                        + '&cap_f2='    + encodeURIComponent($('#cap_f2').val())
                        + '&cap_f3='    + encodeURIComponent($('#cap_f3').val())
                        + '&cap_f4='    + encodeURIComponent($('#cap_f4').val()),
            dataType    : 'json',
            success     : function(res){
                btn.prop('disabled', false)
                   .html('<i class="bi bi-save-fill me-1"></i>Save Rack');
                showMsg(res.success, res.message);
                if(res.success){
                    $('#rackCode, #rackName').val('');
                    $('#cap_f1, #cap_f2, #cap_f3, #cap_f4').val('0');
                    loadRackView();
                    /* Switch to rack view tab */
                    $('a[href="#tabRackView"]').tab('show');
                }
            }
        });
    });

    /* ── TAB 3: SWAP ── */
    function loadSwapDropdowns(){
        $.get(RPC + '?method=getPlacedProducts', function(res){
            var opts = '<option value="">-- Select Product --</option>';
            if(res.success && res.data && res.data.length){
                $.each(res.data, function(i, p){
                    opts += '<option value="' + p.id + '"'
                          + ' data-rack="' + p.rack_code + '"'
                          + ' data-face="' + p.face_code + '">'
                          + p.product_name
                          + '</option>';
                });
            }
            $('#swapProduct1, #swapProduct2').html(opts);
            swap1 = null; swap2 = null;
            $('#swapPreview').hide();
            $('#confirmSwapBtn').prop('disabled', true);
            $('#swapInfo1, #swapInfo2').html('');
        }, 'json');
    }

    /* ── MY RACKS TAB ── */
function loadMyRacksTable(){
    $('#myRackTableBody').html(
        '<tr><td colspan="5" class="text-center py-4">'
      + '<div class="spinner-border spinner-border-sm"></div></td></tr>'
    );
    $.get(RC + '?method=getMyRacksTable', function(res){
        $('#myRackTableBody').html(
            res.success
                ? res.data.html
                : '<tr><td colspan="5" class="text-center text-danger py-4">' + res.message + '</td></tr>'
        );
    }, 'json');
}

$(document).on('click', '.toggleMyRackBtn', function(){
    var btn = $(this);
    $.ajax({
        url      : RC + '?method=toggleRackByVendor',
        type     : 'GET',
        data     : { id: btn.data('id'), status: btn.data('status') },
        dataType : 'json',
        success  : function(res){
            showMsg(res.success, res.success ? 'Rack status updated.' : res.message);
            if(res.success) loadMyRacksTable();
        }
    });
});

    function readSwapSelection(selectId, infoId, num){
        var sel  = $(selectId);
        var pid  = sel.val();
        var opt  = sel.find('option:selected');
        var info = $(infoId);

        if(!pid){
            info.html('');
            if(num === 1) swap1 = null; else swap2 = null;
            updateSwapPreview();
            return;
        }

        var rack = opt.data('rack');
        var face = opt.data('face');
        info.html(
            '<i class="bi bi-geo-alt-fill me-1 text-primary"></i>'
          + 'Currently at: <strong>' + rack + ' → ' + face + '</strong>'
        );

        var obj = { id: pid, name: opt.text().trim(), rack: rack, face: face };
        if(num === 1) swap1 = obj; else swap2 = obj;
        updateSwapPreview();
    }

    function updateSwapPreview(){
        if(swap1 && swap2 && swap1.id !== swap2.id){
            $('#previewName1').text(swap1.name);
            $('#previewDest1').text(swap2.rack + ' ' + swap2.face);
            $('#previewName2').text(swap2.name);
            $('#previewDest2').text(swap1.rack + ' ' + swap1.face);
            $('#swapPreview').show();
            $('#confirmSwapBtn').prop('disabled', false);
        } else {
            $('#swapPreview').hide();
            $('#confirmSwapBtn').prop('disabled', true);
        }
    }

    $('#swapProduct1').on('change', function(){
        readSwapSelection('#swapProduct1', '#swapInfo1', 1);
    });
    $('#swapProduct2').on('change', function(){
        readSwapSelection('#swapProduct2', '#swapInfo2', 2);
    });

    $('#confirmSwapBtn').on('click', function(){
        if(!swap1 || !swap2 || swap1.id === swap2.id){
            showMsg(false, 'Please select two different products to swap.');
            return;
        }
        var btn = $(this);
        btn.prop('disabled', true)
           .html('<span class="spinner-border spinner-border-sm me-1"></span>Swapping...');

        $.ajax({
            url      : RPC + '?method=swapProducts',
            type     : 'POST',
            data     : { product1_id: swap1.id, product2_id: swap2.id },
            dataType : 'json',
            success  : function(res){
                btn.prop('disabled', false)
                   .html('<i class="bi bi-arrow-left-right me-2"></i>Confirm Swap');
                showMsg(res.success, res.message);
                if(res.success){
                    loadRackView();
                    loadSwapDropdowns();
                    loadAlerts();
                }
            }
        });
    });

    /* ── TAB 4: ALERTS ── */
    function loadAlerts(){
        $.get(RPC + '?method=getSwapAlerts', function(res){
            if(!res.success) return;
            $('#alertsContent').html(res.data.html);
            var count = res.data.count;
            if(count > 0){
                $('#swapAlertBadge').show();
                $('#swapAlertCount').text(count);
                $('#alertTabBadge').text(count).show();
            } else {
                $('#swapAlertBadge, #alertTabBadge').hide();
            }
        }, 'json');
    }

    $(document).on('click', '.markAlertSeenBtn', function(){
        $.ajax({
            url      : RPC + '?method=markAlertSeen',
            type     : 'POST',
            data     : { id: $(this).data('id') },
            dataType : 'json',
            success  : function(res){
                if(res.success) loadAlerts();
            }
        });
    });

    /* ── TAB SWITCH ── */
   $('a[data-bs-toggle="tab"]').on('shown.bs.tab', function(e){
    var target = $(e.target).attr('href');
    if(target === '#tabRackView')    loadRackView();
    if(target === '#tabMyRacks')     loadMyRacksTable();
    if(target === '#tabCreateRack')  {  }
    if(target === '#tabSwap')        loadSwapDropdowns();
    if(target === '#tabAlerts')      loadAlerts();
});

    /* ── BOOT ── */
    loadRackView();
    loadAlerts();
})();
</script>
