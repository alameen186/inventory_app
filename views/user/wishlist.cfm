<cfif NOT structKeyExists(session, "user_id")>
    <cfabort>
</cfif>

<div class="container-fluid mt-3">

    <div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-2">
        <h4 class="mb-0">
            <i class="bi bi-heart-fill text-danger me-2"></i>My Wishlist
            <span class="badge bg-secondary ms-2 fs-6" id="wishlistCount">0</span>
        </h4>
    </div>

    <div id="wishlistMsg"></div>

    <div class="row g-3" id="wishlistGrid">
        <div class="col-12 text-center py-5">
            <div class="spinner-border text-danger"></div>
            <p class="mt-2 text-muted">Loading your wishlist...</p>
        </div>
    </div>

    <div id="wishlistPagination"
         class="d-flex justify-content-center gap-2 mt-4 flex-wrap"></div>

</div>

<script>
(function(){
    var WCTRL = '../../controllers/WishlistController.cfc';
    var CCTRL = '../../controllers/CartController.cfc';

    function showMsg(success, text){
        var cls  = success ? 'success' : 'danger';
        var icon = success ? '&#10003;' : '&#9888;';
        $('#wishlistMsg').html(
            '<div class="alert alert-' + cls + ' alert-dismissible">'
          + icon + ' ' + text
          + '<button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>'
        );
        if(success) setTimeout(function(){ $('#wishlistMsg .alert').alert('close'); }, 3000);
    }

    function loadWishlist(page){
        $('#wishlistGrid').html(
            '<div class="col-12 text-center py-5">'
          + '<div class="spinner-border text-danger"></div>'
          + '<p class="mt-2 text-muted">Loading...</p></div>'
        );
        $.ajax({
            url      : WCTRL + '?method=getWishlist',
            type     : 'GET',
            data     : { p: page || 1 },
            dataType : 'json',
            success  : function(res){
                if(res.success){
                    $('#wishlistGrid').html(res.data.html);
                    $('#wishlistPagination').html(res.data.pagination);
                    $('#wishlistCount').text(res.data.total);
                } else {
                    $('#wishlistGrid').html(
                        '<div class="col-12"><div class="alert alert-danger">'
                      + res.message + '</div></div>'
                    );
                }
            }
        });
    }

    /* Pagination */
    $(document).on('click', '.wishPageBtn', function(){
        loadWishlist($(this).data('page'));
    });

    /* Remove from wishlist */
    $(document).on('click', '.removeWishBtn', function(){
        var btn = $(this);
        var pid = btn.data('product-id');
        btn.prop('disabled', true).html(
            '<span class="spinner-border spinner-border-sm"></span>'
        );
        $.ajax({
            url      : WCTRL + '?method=toggle',
            type     : 'POST',
            data     : { product_id: pid },
            dataType : 'json',
            success  : function(res){
                if(res.success){
                    $('#wishCard_' + pid).fadeOut(300, function(){
                        $(this).remove();
                        var cur = parseInt($('#wishlistCount').text()) || 0;
                        $('#wishlistCount').text(Math.max(0, cur - 1));
                    });
                    showMsg(true, 'Removed from wishlist');
                } else {
                    showMsg(false, res.message);
                    btn.prop('disabled', false).html('&#10005;');
                }
            }
        });
    });

    /* Add to cart from wishlist */
    $(document).on('submit', '.addToCartForm', function(e){
        e.preventDefault();
        var form = $(this);
        $.ajax({
            url      : CCTRL + '?method=add',
            type     : 'POST',
            data     : form.serialize(),
            dataType : 'json',
            success  : function(res){
                showMsg(res.status === 'success', res.message);
            }
        });
    });

    loadWishlist(1);
})();
</script>