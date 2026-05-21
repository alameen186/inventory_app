<cfif NOT structKeyExists(session,"user_id") OR session.role_name NEQ "vendor">
    <cflocation url="../index.cfm?page=auth" addtoken="false">
</cfif>

<!--- Load staff and vehicles for dropdowns --->
<cfset staffModel   = createObject("component","models.Staff")>
<cfset vehicleModel = createObject("component","models.Vehicle")>

<!--- Correct method --->
<cfset staffList    = staffModel.getActiveStaff(session.user_id)>
<cfset vehicleList  = vehicleModel.getActiveByVendor(session.user_id)>

<cfset WS_CTRL  = "../../controllers/WholesaleController.cfc">
<cfset ADM_CTRL = "../../controllers/AdminProductController.cfc">

<div class="container-fluid mt-4">

    <!--- Page Header --->
    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h3 class="mb-0 fw-bold">
                <i class="bi bi-boxes me-2 text-success"></i>Wholesale Orders
            </h3>
            <small class="text-muted">Create and manage bulk wholesale orders</small>
        </div>
        <button class="btn btn-success" data-bs-toggle="modal" data-bs-target="#createWsModal">
            <i class="bi bi-plus-circle me-1"></i> Create Wholesale Order
        </button>
    </div>

    <!--- Alert --->
    <div id="wsMsg"></div>

    <!--- Filter Bar --->
    <div class="card shadow-sm mb-4">
        <div class="card-body py-2">
            <div class="row g-2 align-items-center">
                <div class="col-12 col-md-5">
                    <div class="input-group">
                        <span class="input-group-text bg-white"><i class="bi bi-search"></i></span>
                        <input type="text" id="wsSearch" class="form-control border-start-0"
                               placeholder="Search by order ID, customer name or email...">
                    </div>
                </div>
                <div class="col-12 col-md-3">
                    <select id="wsStatusFilter" class="form-select">
                        <option value="">All Statuses</option>
                        <option value="pending">Pending</option>
                        <option value="confirmed">Confirmed</option>
                        <option value="dispatched">Dispatched</option>
                        <option value="delivered">Delivered</option>
                        <option value="cancelled">Cancelled</option>
                    </select>
                </div>
                <div class="col-6 col-md-2">
                    <button class="btn btn-primary w-100" id="wsSearchBtn">
                        <i class="bi bi-search me-1"></i>Search
                    </button>
                </div>
                <div class="col-6 col-md-2">
                    <button class="btn btn-secondary w-100" id="wsClearBtn">
                        <i class="bi bi-x-circle me-1"></i>Clear
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!--- Orders Table --->
    <div class="card shadow-sm">
        <div class="card-header bg-dark text-white">
            <i class="bi bi-table me-2"></i>Orders List
        </div>
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-dark">
                    <tr>
                        <th>Order ID</th>
                        <th>Customer</th>
                        <th>Staff</th>
                        <th>Vehicle</th>
                        <th>Amount</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody id="wsOrdersBody">
                    <tr>
                        <td colspan="7" class="text-center py-4">
                            <div class="spinner-border spinner-border-sm text-success me-2"></div>
                            Loading orders...
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
        <div class="card-footer bg-white" id="wsPaginationArea"></div>
    </div>

</div>

<!--- CREATE WHOLESALE ORDER MODAL --->
<div class="modal fade" id="createWsModal" tabindex="-1" data-bs-backdrop="static">
    <div class="modal-dialog modal-xl modal-dialog-scrollable">
        <div class="modal-content">

            <div class="modal-header bg-success text-white">
                <h5 class="modal-title">
                    <i class="bi bi-boxes me-2"></i>Create Wholesale Order
                </h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>

            <div class="modal-body">
                <div id="wsCreateMsg"></div>

                <div class="row g-4">

                    <!--- LEFT: Customer + Assignment --->
                    <div class="col-12 col-lg-5">

                        <!--- Customer Info --->
                        <div class="card border-0 bg-light mb-3">
                            <div class="card-header bg-secondary text-white py-2">
                                <i class="bi bi-person me-2"></i>Customer Details
                            </div>
                            <div class="card-body">
                                <div class="row g-2">
                                    <div class="col-6">
                                        <label class="form-label fw-semibold small">First Name <span class="text-danger">*</span></label>
                                        <input type="text" id="wsFirstName" class="form-control form-control-sm"
                                               placeholder="First name">
                                    </div>
                                    <div class="col-6">
                                        <label class="form-label fw-semibold small">Last Name</label>
                                        <input type="text" id="wsLastName" class="form-control form-control-sm"
                                               placeholder="Last name">
                                    </div>
                                    <div class="col-12">
                                        <label class="form-label fw-semibold small">Email <span class="text-danger">*</span></label>
                                        <input type="email" id="wsEmail" class="form-control form-control-sm"
                                               placeholder="customer@email.com">
                                    </div>
                                    <div class="col-12">
                                        <label class="form-label fw-semibold small">Phone <span class="text-danger">*</span></label>
                                        <input type="tel" id="wsPhone" class="form-control form-control-sm"
                                               placeholder="+91 XXXXXXXXXX">
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!--- Staff & Vehicle Assignment --->
                        <div class="card border-0 bg-light mb-3">
                            <div class="card-header bg-secondary text-white py-2">
                                <i class="bi bi-people me-2"></i>Assignment
                            </div>
                            <div class="card-body">
                                <div class="mb-2">
                                    <label class="form-label fw-semibold small">Assign Staff <span class="text-danger">*</span></label>
                                    <select id="wsStaffId" class="form-select form-select-sm">
                                        <option value="">-- Select Staff Member --</option>
                                        <cfoutput query="staffList">
                                        <option value="#staffList.id#">#encodeForHTML(staffList.full_name)#</option>
                                        </cfoutput>
                                    </select>
                                    <cfif staffList.recordCount EQ 0>
                                        <div class="form-text text-danger">
                                            <i class="bi bi-exclamation-triangle me-1"></i>
                                            No staff found.
                                            <a href="index.cfm?page=dashboard&section=staff">Add staff first</a>
                                        </div>
                                    </cfif>
                                </div>
                                <div class="mb-2">
                                    <label class="form-label fw-semibold small">Assign Vehicle <span class="text-danger">*</span></label>
                                    <select id="wsVehicleId" class="form-select form-select-sm">
                                        <option value="">-- Select Vehicle --</option>
                                        <cfoutput query="vehicleList">
                                        <option value="#vehicleList.id#">
                                            #encodeForHTML(vehicleList.vehicle_name)#
                                            (#encodeForHTML(vehicleList.vehicle_number)#)
                                        </option>
                                        </cfoutput>
                                    </select>
                                    <cfif vehicleList.recordCount EQ 0>
                                        <div class="form-text text-danger">
                                            <i class="bi bi-exclamation-triangle me-1"></i>
                                            No active vehicles.
                                            <a href="index.cfm?page=dashboard&section=vehicles">Add vehicle first</a>
                                        </div>
                                    </cfif>
                                </div>
                                <div>
                                    <label class="form-label fw-semibold small">Notes</label>
                                    <textarea id="wsNotes" class="form-control form-control-sm" rows="2"
                                              placeholder="Delivery instructions, special notes..."></textarea>
                                </div>
                            </div>
                        </div>

                        <!--- Order Summary --->
                        <div class="card border-success">
                            <div class="card-header bg-success text-white py-2">
                                <i class="bi bi-receipt me-2"></i>Order Summary
                            </div>
                            <div class="card-body p-2">
                                <table class="table table-sm mb-0" id="wsSummaryTable">
                                    <tbody id="wsSummaryBody">
                                        <tr>
                                            <td colspan="4" class="text-center text-muted fst-italic py-3">
                                                No items added yet
                                            </td>
                                        </tr>
                                    </tbody>
                                    <tfoot>
                                        <tr class="table-success">
                                            <td colspan="3" class="text-end fw-bold">Grand Total:</td>
                                            <td class="fw-bold" id="wsGrandTotal"><i class="bi bi-currency-rupee"></i>0.00</td>
                                        </tr>
                                    </tfoot>
                                </table>
                            </div>
                        </div>

                    </div>

                    <!--- RIGHT: Product Search & Add --->
                    <div class="col-12 col-lg-7">

                        <div class="card border-0 bg-light">
                            <div class="card-header bg-secondary text-white py-2">
                                <i class="bi bi-search me-2"></i>Add Products
                            </div>
                            <div class="card-body">

                                <!--- Product Search --->
                                <div class="input-group mb-3">
                                    <span class="input-group-text"><i class="bi bi-search"></i></span>
                                    <input type="text" id="wsProductSearch" class="form-control"
                                           placeholder="Search wholesale products by name...">
                                    <button class="btn btn-outline-secondary" id="wsProductSearchBtn">Search</button>
                                </div>

                                <!--- Search Results --->
                                <div id="wsProductResults" class="mb-3" style="max-height:320px; overflow-y:auto;">
                                    <div class="text-center text-muted py-4">
                                        <i class="bi bi-search fs-2 d-block mb-2 opacity-50"></i>
                                        Search for products configured for wholesale
                                    </div>
                                </div>

                                <!--- Info note --->
                                <div class="alert alert-info py-2 small mb-0">
                                    <i class="bi bi-info-circle me-1"></i>
                                    Only products with <strong>wholesale price</strong> and
                                    <strong>minimum quantity</strong> set will appear here.
                                    Configure them in
                                    <a href="index.cfm?page=dashboard&section=products">Product Management</a>.
                                </div>

                            </div>
                        </div>

                    </div>
                </div><!--- end row --->
            </div><!--- end modal-body --->

            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                <button type="button" class="btn btn-success" id="wsSubmitBtn">
                    <i class="bi bi-check-circle me-1"></i>Place Wholesale Order
                </button>
            </div>

        </div>
    </div>
</div>

<!--- VIEW ORDER MODAL --->
<div class="modal fade" id="viewWsModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header bg-dark text-white">
                <h5 class="modal-title">
                    <i class="bi bi-eye me-2"></i>Order Details
                </h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body" id="viewWsBody">
                <div class="text-center py-4">
                    <div class="spinner-border text-primary"></div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
            </div>
        </div>
    </div>
</div>

<!--- UPDATE STATUS MODAL --->
<div class="modal fade" id="updateStatusModal" tabindex="-1">
    <div class="modal-dialog modal-sm">
        <div class="modal-content">
            <div class="modal-header bg-primary text-white">
                <h5 class="modal-title">Update Order Status</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <input type="hidden" id="updateStatusOrderId">
                <label class="form-label fw-semibold">Select New Status</label>
                <select id="newStatusSelect" class="form-select">
                    <option value="confirmed">Confirmed</option>
                    <option value="dispatched">Dispatched</option>
                    <option value="delivered">Delivered</option>
                    <option value="cancelled">Cancelled</option>
                </select>
                <div id="statusUpdateMsg" class="mt-2"></div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                <button class="btn btn-primary" id="confirmStatusUpdate">
                    <i class="bi bi-check-circle me-1"></i>Update
                </button>
            </div>
        </div>
    </div>
</div>


<script>
$(function(){

    var WS_CTRL  = "<cfoutput>#WS_CTRL#</cfoutput>";

    /* CART STATE */
    var wsCart = {};  

    /* HELPERS*/
    function showMsg(el, success, text){
        var cls  = success ? "success" : "danger";
        var icon = success
            ? '<i class="bi bi-check-circle-fill me-2"></i>'
            : '<i class="bi bi-exclamation-triangle-fill me-2"></i>';
        $(el).html(
            '<div class="alert alert-' + cls + ' alert-dismissible">'
          + icon + text
          + '<button type="button" class="btn-close" data-bs-dismiss="alert"></button>'
          + '</div>'
        );
    }

    function rupee(n){ return "₹" + parseFloat(n).toFixed(2); }

    /* LOAD ORDERS TABLE*/
    function loadOrders(page){
        page = page || 1;
        $("#wsOrdersBody").html(
            '<tr><td colspan="7" class="text-center py-4">'
          + '<div class="spinner-border spinner-border-sm text-success me-2"></div>Loading...</td></tr>'
        );
        $.get(WS_CTRL, {
            method : "searchOrders",
            search : $("#wsSearch").val().trim(),
            status : $("#wsStatusFilter").val(),
            p      : page
        }, function(res){
            if(res.success){
                $("#wsOrdersBody").html(res.data.html);
                $("#wsPaginationArea").html(res.data.pagination);
            } else {
                $("#wsOrdersBody").html(
                    '<tr><td colspan="7" class="text-center text-danger py-3">'
                  + (res.message || "Error loading orders") + '</td></tr>'
                );
            }
        }, "json").fail(function(){
            $("#wsOrdersBody").html(
                '<tr><td colspan="7" class="text-center text-danger py-3">Server error</td></tr>'
            );
        });
    }

    $("#wsSearchBtn").on("click", function(){ loadOrders(1); });
    $("#wsClearBtn").on("click", function(){
        $("#wsSearch").val("");
        $("#wsStatusFilter").val("");
        loadOrders(1);
    });
    $(document).on("click", ".wsPageBtn", function(){
        loadOrders($(this).data("page"));
    });
    loadOrders(1);

    /* PRODUCT SEARCH (in modal) */
    function searchWsProducts(){
        var kw = $("#wsProductSearch").val().trim();
        $("#wsProductResults").html(
            '<div class="text-center py-3"><div class="spinner-border spinner-border-sm text-success"></div></div>'
        );
        $.get(WS_CTRL, { method: "searchProducts", keyword: kw }, function(res){
            if(!res.success || !res.data || !res.data.length){
                $("#wsProductResults").html(
                    '<div class="text-center text-muted py-4">'
                  + '<i class="bi bi-inbox fs-2 d-block mb-2 opacity-50"></i>'
                  + (kw ? "No wholesale products found for \"" + kw + "\"" : "No products configured for wholesale yet")
                  + '</div>'
                );
                return;
            }

            var html = '<div class="list-group list-group-flush">';
            $.each(res.data, function(i, p){
                var inCart   = wsCart.hasOwnProperty(p.id);
                var cartQty  = inCart ? wsCart[p.id].qty : p.min_wholesale_qty;
                var isFull   = inCart && wsCart[p.id].qty >= p.stock;

                html += '<div class="list-group-item py-2 px-2" id="productRow_' + p.id + '">'
                      + '<div class="d-flex justify-content-between align-items-start gap-2">'
                      + '<div class="flex-grow-1">'
                      + '<div class="fw-semibold small">' + p.product_name + '</div>'
                      + '<div class="text-muted" style="font-size:0.78rem;">'
                      + p.category_name + ' | '
                      + 'Retail: <span class="text-decoration-line-through"><i class="bi bi-currency-rupee"></i>' + parseFloat(p.price).toFixed(2) + '</span> | '
                      + 'Wholesale: <strong class="text-success"><i class="bi bi-currency-rupee"></i>' + parseFloat(p.wholesale_price).toFixed(2) + '</strong> | '
                      + 'Min Qty: <strong>' + p.min_wholesale_qty + '</strong> | '
                      + 'Stock: <span class="' + (p.stock < 10 ? 'text-danger' : 'text-muted') + '">' + p.stock + '</span>'
                      + '</div>'
                      + '</div>'
                      + '<div class="d-flex align-items-center gap-1 flex-shrink-0">'
                      + '<input type="number" class="form-control form-control-sm wsQtyInput" '
                      + 'id="qty_' + p.id + '" '
                      + 'value="' + (inCart ? wsCart[p.id].qty : p.min_wholesale_qty) + '" '
                      + 'min="' + p.min_wholesale_qty + '" '
                      + 'max="' + p.stock + '" '
                      + 'style="width:70px;">'
                      + '<button class="btn btn-sm '
                      + (inCart ? 'btn-warning' : 'btn-success')
                      + ' addToWsCartBtn" '
                      + 'data-id="'            + p.id               + '" '
                      + 'data-name="'          + p.product_name      + '" '
                      + 'data-price="'         + p.wholesale_price   + '" '
                      + 'data-min-qty="'       + p.min_wholesale_qty + '" '
                      + 'data-stock="'         + p.stock             + '">'
                      + (inCart ? '<i class="bi bi-arrow-repeat"></i>' : '<i class="bi bi-cart-plus"></i>')
                      + '</button>'
                      + '</div>'
                      + '</div>'
                      + '</div>';
            });
            html += '</div>';
            $("#wsProductResults").html(html);

        }, "json").fail(function(){
            $("#wsProductResults").html(
                '<div class="text-center text-danger py-3">Server error</div>'
            );
        });
    }

    $("#wsProductSearchBtn").on("click", searchWsProducts);
    $("#wsProductSearch").on("keydown", function(e){
        if(e.key === "Enter"){ e.preventDefault(); searchWsProducts(); }
    });

    /* CART LOGIC */
    function refreshCartSummary(){
        var html = "";
        var grandTotal = 0;
        var count = 0;

        $.each(wsCart, function(pid, item){
            count++;
            grandTotal += item.total_price;
            html += '<tr>'
                  + '<td class="small">' + item.product_name + '</td>'
                  + '<td class="text-center small">' + item.qty + '</td>'
                  + '<td class="text-end small">' + (item.unit_price) + '</td>'
                  + '<td class="text-end small fw-semibold">' + (item.total_price) + '</td>'
                  + '<td><button class="btn btn-link btn-sm p-0 text-danger removeWsItemBtn" data-id="' + pid + '">'
                  + '<i class="bi bi-x-circle-fill"></i></button></td>'
                  + '</tr>';
        });

        if(!count){
            html = '<tr><td colspan="5" class="text-center text-muted fst-italic py-3">No items added yet</td></tr>';
        }

        $("#wsSummaryBody").html(html);
        $("#wsGrandTotal").text((grandTotal));
    }

    /* Add to cart */
    $(document).on("click", ".addToWsCartBtn", function(){
        var btn     = $(this);
        var pid     = btn.data("id");
        var name    = btn.data("name");
        var price   = parseFloat(btn.data("price"));
        var minQty  = parseInt(btn.data("min-qty"));
        var stock   = parseInt(btn.data("stock"));
        var qty     = parseInt($("#qty_" + pid).val());

        /* Validate qty */
        if(isNaN(qty) || qty < minQty){
            showMsg("#wsCreateMsg", false, "Minimum quantity for <strong>" + name + "</strong> is " + minQty);
            return;
        }
        if(qty > stock){
            showMsg("#wsCreateMsg", false, "Only <strong>" + stock + "</strong> units available for " + name);
            return;
        }

        wsCart[pid] = {
            product_id   : pid,
            product_name : name,
            qty          : qty,
            unit_price   : price,
            total_price  : price * qty,
            min_qty      : minQty,
            stock        : stock
        };

        /* Update button appearance */
        btn.removeClass("btn-success").addClass("btn-warning")
           .html('<i class="bi bi-arrow-repeat"></i>');

        refreshCartSummary();
        showMsg("#wsCreateMsg", true, "<strong>" + name + "</strong> added to order (" + qty + " units)");
    });

    /* Remove from cart */
    $(document).on("click", ".removeWsItemBtn", function(){
        var pid = $(this).data("id");
        delete wsCart[pid];
        refreshCartSummary();
        /* Update button in search results if visible */
        var btn = $(".addToWsCartBtn[data-id='" + pid + "']");
        if(btn.length){
            btn.removeClass("btn-warning").addClass("btn-success")
               .html('<i class="bi bi-cart-plus"></i>');
        }
    });

    /*  RESET MODAL ON CLOSE */
    $("#createWsModal").on("hidden.bs.modal", function(){
        wsCart = {};
        $("#wsFirstName, #wsLastName, #wsEmail, #wsPhone, #wsNotes").val("");
        $("#wsStaffId, #wsVehicleId").val("");
        $("#wsProductSearch").val("");
        $("#wsProductResults").html(
            '<div class="text-center text-muted py-4">'
          + '<i class="bi bi-search fs-2 d-block mb-2 opacity-50"></i>'
          + 'Search for products configured for wholesale</div>'
        );
        refreshCartSummary();
        $("#wsCreateMsg").html("");
    });

    /* SUBMIT WHOLESALE ORDER*/
    $("#wsSubmitBtn").on("click", function(){
        /* Validate customer */
        var errors = [];
        var fname  = $("#wsFirstName").val().trim();
        var email  = $("#wsEmail").val().trim();
        var phone  = $("#wsPhone").val().trim();
        var staff  = $("#wsStaffId").val();
        var veh    = $("#wsVehicleId").val();

        if(!fname)  errors.push("Customer first name is required");
        if(!email)  errors.push("Customer email is required");
        else if(!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) errors.push("Invalid email format");
        if(!phone)  errors.push("Customer phone is required");
        if(!staff)  errors.push("Please assign a staff member");
        if(!veh)    errors.push("Please assign a vehicle");

        /* Validate cart */
        var cartKeys = Object.keys(wsCart);
        if(!cartKeys.length) errors.push("Please add at least one product to the order");

        if(errors.length){
            showMsg("#wsCreateMsg", false, errors.join("<br>"));
            return;
        }

        /* Build items array */
        var items = [];
        $.each(wsCart, function(pid, item){
            items.push({
                product_id   : parseInt(pid),
                product_name : item.product_name,
                qty          : item.qty,
                unit_price   : item.unit_price,
                total_price  : item.total_price
            });
        });

        var btn = $(this);
        btn.prop("disabled", true).html(
            '<span class="spinner-border spinner-border-sm me-1"></span>Placing Order...'
        );

        $.post(WS_CTRL + "?method=createOrder", {
            first_name        : fname,
            last_name         : $("#wsLastName").val().trim(),
            email             : email,
            phone             : phone,
            assigned_staff_id : staff,
            vehicle_id        : veh,
            notes             : $("#wsNotes").val().trim(),
            items             : JSON.stringify(items)
        }, function(res){
            btn.prop("disabled", false).html(
                '<i class="bi bi-check-circle me-1"></i>Place Wholesale Order'
            );
            if(res.success){
                showMsg("#wsCreateMsg", true, res.message);
                setTimeout(function(){
                    var modal = bootstrap.Modal.getInstance(document.getElementById("createWsModal"));
                    if(modal) modal.hide();
                    loadOrders(1);
                    showMsg("#wsMsg", true, res.message);
                }, 1500);
            } else {
                showMsg("#wsCreateMsg", false, res.message);
            }
        }, "json").fail(function(){
            btn.prop("disabled", false).html(
                '<i class="bi bi-check-circle me-1"></i>Place Wholesale Order'
            );
            showMsg("#wsCreateMsg", false, "Server error. Please try again.");
        });
    });

    /*  VIEW ORDER DETAILS*/
    $(document).on("click", ".viewOrderBtn", function(){
        var id = $(this).data("id");
        $("#viewWsBody").html(
            '<div class="text-center py-4"><div class="spinner-border text-primary"></div></div>'
        );
        var modal = new bootstrap.Modal(document.getElementById("viewWsModal"));
        modal.show();

        $.get(WS_CTRL, { method: "getOrder", id: id }, function(res){
            if(!res.success){
                $("#viewWsBody").html('<div class="alert alert-danger">' + res.message + '</div>');
                return;
            }
            var d = res.data;
            var statusColors = {
                pending: "bg-warning text-dark", confirmed: "bg-info text-dark",
                dispatched: "bg-primary", delivered: "bg-success", cancelled: "bg-secondary"
            };
            var sc = statusColors[d.status] || "bg-secondary";

            var itemRows = "";
            $.each(d.items, function(i, item){
                itemRows += '<tr>'
                          + '<td>' + item.product_name + '</td>'
                          + '<td class="text-center">' + item.qty + '</td>'
                          + '<td class="text-end">' + (item.unit_price) + '</td>'
                          + '<td class="text-end fw-bold">' + (item.total_price) + '</td>'
                          + '</tr>';
            });

            var html = '<div class="row g-3">'

                /* Order Info */
                + '<div class="col-12">'
                + '<div class="d-flex justify-content-between align-items-center">'
                + '<h6 class="fw-bold mb-0"><i class="bi bi-hash me-1"></i>' + d.group_id + '</h6>'
                + '<span class="badge ' + sc + '">' + d.status.charAt(0).toUpperCase() + d.status.slice(1) + '</span>'
                + '</div>'
                + '<small class="text-muted">Created: ' + d.created_at + '</small>'
                + '</div>'

                /* Customer */
                + '<div class="col-12 col-md-6">'
                + '<div class="card border-0 bg-light h-100">'
                + '<div class="card-body p-3">'
                + '<h6 class="card-title fw-bold small text-muted text-uppercase mb-2">Customer</h6>'
                + '<p class="mb-1 fw-semibold">' + d.customer_name + '</p>'
                + '<p class="mb-1 small">' + d.customer_email + '</p>'
                + '<p class="mb-0 small">' + (d.customer_phone || "—") + '</p>'
                + '</div></div></div>'

                /* Assignment */
                + '<div class="col-12 col-md-6">'
                + '<div class="card border-0 bg-light h-100">'
                + '<div class="card-body p-3">'
                + '<h6 class="card-title fw-bold small text-muted text-uppercase mb-2">Assignment</h6>'
                + '<p class="mb-1"><i class="bi bi-person me-2 text-primary"></i>' + d.staff_name + '</p>'
                + '<p class="mb-1"><i class="bi bi-truck me-2 text-success"></i>' + d.vehicle_name + '</p>'
                + '<p class="mb-0 small text-muted">' + d.vehicle_number + '</p>'
                + '</div></div></div>'

                /* Items table */
                + '<div class="col-12">'
                + '<table class="table table-sm table-bordered mb-0">'
                + '<thead class="table-dark"><tr><th>Product</th><th class="text-center">Qty</th>'
                + '<th class="text-end">Unit Price</th><th class="text-end">Total</th></tr></thead>'
                + '<tbody>' + itemRows + '</tbody>'
                + '<tfoot class="table-success"><tr><td colspan="3" class="text-end fw-bold">Grand Total</td>'
                + '<td class="text-end fw-bold">' + (d.total_amount) + '</td></tr></tfoot>'
                + '</table>'
                + '</div>'

                /* Notes */
                + (d.notes ? '<div class="col-12"><div class="alert alert-light mb-0"><strong>Notes:</strong> ' + d.notes + '</div></div>' : '')

                + '</div>';

       <!---     /* Invoice link */
            html += '<div class="mt-3 text-end">'
                  + '<a href="../../assets/invoices/wholesale/invoice_' + d.group_id + '.pdf" '
                  + 'target="_blank" class="btn btn-outline-secondary btn-sm">'
                  + '<i class="bi bi-file-earmark-pdf me-1"></i>View Invoice PDF</a>'
                  + '</div>';
--->
            $("#viewWsBody").html(html);
        }, "json");
    });

    /* UPDATE ORDER STATUS */
    $(document).on("click", ".updateStatusBtn", function(){
        var id     = $(this).data("id");
        var status = $(this).data("status");
        $("#updateStatusOrderId").val(id);
        $("#statusUpdateMsg").html("");

        /* Set next logical status */
        var nextMap = { pending: "confirmed", confirmed: "dispatched", dispatched: "delivered" };
        var next = nextMap[status] || "confirmed";
        $("#newStatusSelect").val(next);

        var modal = new bootstrap.Modal(document.getElementById("updateStatusModal"));
        modal.show();
    });

    $("#confirmStatusUpdate").on("click", function(){
        var btn    = $(this);
        var id     = $("#updateStatusOrderId").val();
        var status = $("#newStatusSelect").val();

        btn.prop("disabled", true).html(
            '<span class="spinner-border spinner-border-sm me-1"></span>Updating...'
        );

        $.post(WS_CTRL + "?method=updateStatus", { id: id, status: status }, function(res){
            btn.prop("disabled", false).html('<i class="bi bi-check-circle me-1"></i>Update');
            if(res.success){
                var modal = bootstrap.Modal.getInstance(document.getElementById("updateStatusModal"));
                if(modal) modal.hide();
                loadOrders(1);
                showMsg("#wsMsg", true, "Order status updated to <strong>" + status + "</strong>");
            } else {
                $("#statusUpdateMsg").html(
                    '<div class="alert alert-danger py-1 small mt-2">' + res.message + '</div>'
                );
            }
        }, "json");
    });

});
</script>
