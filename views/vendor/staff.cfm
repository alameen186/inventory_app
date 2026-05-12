<cfif NOT structKeyExists(session,"user_id") OR session.role_name NEQ "vendor">
    <cfabort>
</cfif>

<cfset CTRL = "../../controllers/StaffController.cfc">

<div class="container-fluid mt-3">

    <div class="d-flex justify-content-between align-items-center mb-4">
        <h4 class="mb-0">Staff Management</h4>
        <button class="btn btn-primary" id="addStaffBtn">
            + Add Staff
        </button>
    </div>

    <!--- STAFF TABLE --->
    <div class="card shadow-sm">
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover mb-0">
                    <thead class="table-dark">
                        <tr>
                            <th>Photo</th>
                            <th>Name</th>
                            <th>Phone</th>
                            <th>Position</th>
                            <th>Join Date</th>
                            <th class="text-center">Active</th>
                            <th class="text-center">Actions</th>
                        </tr>
                    </thead>
                    <tbody id="staffTableBody">
                        <tr>
                            <td colspan="7" class="text-center py-4">
                                <div class="spinner-border spinner-border-sm"></div> Loading...
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

</div>

<!--- add edit modal  --->
<div class="modal fade" id="staffModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">

            <div class="modal-header bg-dark text-white">
                <h5 class="modal-title" id="staffModalTitle">Add Staff</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>

            <div class="modal-body">
                <form id="staffForm" enctype="multipart/form-data">
                    <input type="hidden" id="staffId" name="id" value="0">

                    <!--- Personal Info --->
                    <h6 class="fw-bold text-primary border-bottom pb-1 mb-3">Personal Information</h6>
                    <div class="row g-3 mb-3">

                        <div class="col-md-6">
                            <label class="form-label fw-semibold">Full Name <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="fullName" name="full_name" required>
                        </div>

                        <div class="col-md-6">
                            <label class="form-label fw-semibold">Phone <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="phone" name="phone"
                                   maxlength="10" placeholder="10 digit number" required>
                        </div>

                        <div class="col-md-6">
                            <label class="form-label fw-semibold">Email</label>
                            <input type="email" class="form-control" id="email" name="email">
                        </div>

                        <div class="col-md-3">
                            <label class="form-label fw-semibold">Gender</label>
                            <select class="form-select" id="gender" name="gender">
                                <option value="">Select</option>
                                <option value="male">Male</option>
                                <option value="female">Female</option>
                                <option value="other">Other</option>
                            </select>
                        </div>

                        <div class="col-md-3">
                            <label class="form-label fw-semibold">Date of Birth</label>
                            <input type="date" class="form-control" id="dob" name="date_of_birth">
                        </div>

                        <div class="col-12">
                            <label class="form-label fw-semibold">Address</label>
                            <textarea class="form-control" id="address" name="address" rows="2"></textarea>
                        </div>

                    </div>

                    <!---  Job Info --->
                    <h6 class="fw-bold text-primary border-bottom pb-1 mb-3">Job Information</h6>
                    <div class="row g-3 mb-3">

                        <div class="col-md-4">
                            <label class="form-label fw-semibold">Position / Role</label>
                            <input type="text" class="form-control" id="position" name="position"
                                   placeholder="e.g. Delivery Boy, Manager">
                        </div>

                        <div class="col-md-4">
                            <label class="form-label fw-semibold">Join Date</label>
                            <input type="date" class="form-control" id="joinDate" name="join_date">
                        </div>

                        <div class="col-md-4">
                            <label class="form-label fw-semibold">Salary (₹)</label>
                            <input type="number" class="form-control" id="salary" name="salary"
                                   min="0" step="0.01">
                        </div>

                    </div>

                    <!---  Documents --->
                    <h6 class="fw-bold text-primary border-bottom pb-1 mb-3">Documents & Photo</h6>
                    <div class="row g-3">

                        <div class="col-md-4">
                            <label class="form-label fw-semibold">Profile Photo</label>
                            <input type="file" class="form-control" id="profileImage"
                                   name="profile_image" accept="image/*">
                            <div id="profilePreview" class="mt-2"></div>
                        </div>

                        <div class="col-md-8">
                            <label class="form-label fw-semibold">Aadhaar Number</label>
                            <input type="text" class="form-control" id="aadhaarNumber"
                                   name="aadhaar_number" maxlength="12" placeholder="12 digit number">
                        </div>

                        <div class="col-md-6">
                            <label class="form-label fw-semibold">Aadhaar Image</label>
                            <input type="file" class="form-control" id="aadhaarFront"
                                   name="aadhaar_front" accept="image/*">
                            <div id="frontPreview" class="mt-2"></div>
                        </div>

                    </div>

                </form>
            </div>

            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                <button type="button" class="btn btn-primary" id="saveStaffBtn">Save Staff</button>
            </div>

        </div>
    </div>
</div>

<!---  DOCUMENTS   --->
<div class="modal fade" id="docsModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header bg-dark text-white">
                <h5 class="modal-title" id="docsModalTitle">Staff Documents</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body" id="docsModalBody">
                Loading...
            </div>
        </div>
    </div>
</div>

<script>
(function(){
    var CTRL = "../../controllers/staff/StaffController.cfc";

    // ── Load staff list
    function loadStaff(){
        $.ajax({
            url      : CTRL + "?method=getAll",
            type     : "GET",
            dataType : "json",
            success  : function(res){
                if(res.success) $('#staffTableBody').html(res.data.html);
                else $('#staffTableBody').html('<tr><td colspan="7" class="text-center text-danger">'+res.message+'</td></tr>');
            }
        });
    }
    loadStaff();

    // ── Open Add modal
    $('#addStaffBtn').on('click', function(){
        $('#staffModalTitle').text('Add Staff');
        $('#staffForm')[0].reset();
        $('#staffId').val('0');
        $('#profilePreview, #frontPreview').html('');
        new bootstrap.Modal($('#staffModal')[0]).show();
    });

    // ── Image preview helper
    function previewImage(inputId, previewId){
        $('#' + inputId).on('change', function(){
            var file = this.files[0];
            if(!file) return;
            var reader = new FileReader();
            reader.onload = function(e){
                $('#' + previewId).html(
                    '<img src="'+e.target.result+'" style="max-height:80px;max-width:100%;border-radius:6px;margin-top:4px;">'
                );
            };
            reader.readAsDataURL(file);
        });
    }
    previewImage('profileImage','profilePreview');
    previewImage('aadhaarFront','frontPreview');
    previewImage('aadhaarBack','backPreview');

$(document).on('click', '.editBtn', function(){
    var id = $(this).data('id');
    
    $.ajax({
        url      : CTRL + "?method=getOne&id=" + id,
        type     : "GET",
        dataType : "json",
        success  : function(res){
            if(!res.success){ alert(res.message); return; }
            
            var s = res.data;
            $('#staffModalTitle').text('Edit Staff');
            $('#staffId').val(s.id);
            $('#fullName').val(s.full_name);
            $('#phone').val(s.phone);
            $('#email').val(s.email);
            $('#gender').val(s.gender);
            $('#dob').val(s.date_of_birth);
            $('#address').val(s.address);
            $('#position').val(s.position);
            $('#salary').val(s.salary);
            $('#joinDate').val(s.join_date);
            $('#aadhaarNumber').val(s.aadhaar_number);

            // Clear previous previews
            $('#profilePreview, #frontPreview').html('');

            // Show existing images
            var base = 'assets/images/staff/';
            
            if(s.profile_image){
                $('#profilePreview').html(
                    '<img src="'+base+'profiles/'+s.profile_image+'" style="max-height:100px;border-radius:6px;">'
                );
            }
            if(s.aadhaar_image){
                $('#frontPreview').html(
                    '<img src="'+base+'aadhaar/'+s.aadhaar_image+'" style="max-height:100px;border-radius:6px;">'
                );
            }

            new bootstrap.Modal($('#staffModal')[0]).show();
        }
    });
});

   $('#saveStaffBtn').on('click', function(){
    var name = $('#fullName').val().trim();
    var phone = $('#phone').val().trim();
    var aadhaar = $('#aadhaarNumber').val().trim();

    if(!name){
        alert('Full name is required'); return;
    }
    if(!/^\d{10}$/.test(phone)){
        alert('Phone must be exactly 10 digits'); return;
    }
    if(aadhaar.length && !/^\d{12}$/.test(aadhaar)){
        alert('Aadhaar must be exactly 12 digits if provided'); return;
    }

    var formData = new FormData($('#staffForm')[0]);

    $.ajax({
        url         : CTRL + "?method=save",
        type        : "POST",
        data        : formData,
        processData : false,
        contentType : false,
        dataType    : "json",
        success     : function(res){
            if(res.success){
                bootstrap.Modal.getInstance($('#staffModal')[0]).hide();
                loadStaff();
                alert(res.message);
            } else {
                alert('Error: ' + res.message);
            }
        },
        error: function(){
            alert('Network error occurred');
        }
    });
});

    // ── Toggle active/inactive
    $(document).on('change', '.toggleStatus', function(){
        var id  = $(this).data('id');
        var chk = $(this);
        $.ajax({
            url      : CTRL + "?method=toggleStatus",
            type     : "POST",
            data     : { id: id },
            dataType : "json",
            success  : function(res){
                if(!res.success){
                    alert('Toggle failed'); 
                    chk.prop('checked', !chk.prop('checked')); // revert
                }
            }
        });
    });

    // ── Delete
    $(document).on('click', '.deleteBtn', function(){
        if(!confirm('Delete this staff member? This cannot be undone.')) return;
        var id = $(this).data('id');
        $.ajax({
            url      : CTRL + "?method=delete",
            type     : "POST",
            data     : { id: id },
            dataType : "json",
            success  : function(res){
                if(res.success) loadStaff();
                else alert('Error: ' + res.message);
            }
        });
    });

    // ── View Documents
    $(document).on('click', '.docsBtn', function(){
        var id = $(this).data('id');
        $('#docsModalBody').html('<div class="text-center py-3"><div class="spinner-border spinner-border-sm"></div> Loading...</div>');
        new bootstrap.Modal($('#docsModal')[0]).show();

        $.ajax({
            url      : CTRL + "?method=getDocs&id=" + id,
            type     : "GET",
            dataType : "json",
            success  : function(res){
                if(!res.success){ $('#docsModalBody').html('<p class="text-danger">'+res.message+'</p>'); return; }
                var d    = res.data;
                var base = 'assets/images/staff/';
                $('#docsModalTitle').text(d.full_name + ' — Documents');
                $('#docsModalBody').html(
                    '<div class="row g-3">' +
                        '<div class="col-12">' +
                            '<strong>Aadhaar Number:</strong> ' +
                            (d.aadhaar_number || '<span class="text-muted">Not provided</span>') +
                        '</div>' +
                        '<div class="col-md-4">' +
                            '<p class="fw-semibold mb-1">Profile Photo</p>' +
                            (d.profile_image
                                ? '<img src="'+base+'profiles/'+d.profile_image+'" class="img-fluid rounded">'
                                : '<span class="text-muted">Not uploaded</span>') +
                        '</div>' +
                        '<div class="col-md-6">' +
                            '<p class="fw-semibold mb-1">Aadhaar Image</p>' +
                            (d.aadhaar_image ? '<img src="'+base+'aadhaar/'+d.aadhaar_image+'" class="img-fluid rounded">'
                                             : '<span class="text-muted">Not uploaded</span>') +
                        '</div>' +
                    '</div>'
                );
            }
        });
    });

})();
</script>