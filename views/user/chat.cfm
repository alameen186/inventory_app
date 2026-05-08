<cfif NOT structKeyExists(session, "user_id")>
    <cflocation url="../../index.cfm?page=auth" addtoken="false">
    <cfabort>
</cfif>

<cfparam name="url.conversation_id" default="0">

<link rel="stylesheet" href="../../assets/css/userChat.css">

<div class="chat-shell d-flex flex-column h-100"
     data-init-conv="<cfoutput>#val(url.conversation_id)#</cfoutput>">

    <div class="chat-body-row d-flex flex-1 flex-grow-1">

        <!-- LEFT: conversation list -->
        <div class="chat-left d-flex flex-column border-end bg-light"
             style="width:300px; max-width:300px; min-width:220px;">

            <div class="chat-left-header d-flex align-items-center justify-content-between
                        px-3 py-2 bg-white border-bottom flex-shrink-0">
                <h6 class="mb-0 fw-bold">Messages</h6>
            </div>

            <div id="conversationList" class="overflow-y-auto flex-grow-1 list-group list-group-flush"></div>
        </div>

        <!-- RIGHT: chat area -->
        <div class="chat-right d-flex flex-column flex-grow-1" style="background:#f0f2f5;">

            <div class="chat-right-header d-flex align-items-center justify-content-between
                        px-3 py-2 bg-white border-bottom flex-shrink-0">
                <h6 id="chatHeader" class="mb-0 text-muted">Select a conversation</h6>
                <button id="refreshConvBtn" class="btn btn-outline-secondary btn-sm">&#8635; Refresh</button>
            </div>

            <div id="messagesArea" class="d-flex flex-column overflow-y-auto flex-grow-1 p-3">
                <div id="emptyState" class="text-center text-muted m-auto">
                    <div class="fs-1">&#128172;</div>
                    <p class="mt-2 small">Select a conversation to start chatting</p>
                </div>
            </div>

            <div id="msgFormWrap" class="px-3 py-2 bg-white border-top flex-shrink-0" style="display:none;">
                <div class="d-flex gap-2">
                    <input type="text" id="msgInput"
                           class="form-control px-3 py-2 fs-6"
                           placeholder="Type your message..."
                           maxlength="2000" autocomplete="off">
                    <button id="sendBtn" class="btn btn-primary px-4">Send</button>
                </div>
            </div>

        </div>
    </div>
</div>

<script>
(function(){
    var CTRL        = "../../controllers/chat/ChatController.cfc";
    var SESSION_UID = <cfoutput>#session.user_id#</cfoutput>;

    var activeConvId   = 0;
    var lastMsgId      = 0;
    var pollTimer      = null;
    var activeConvName = '';

    var initConvId = parseInt(
        document.querySelector('.chat-shell').getAttribute('data-init-conv')
    ) || 0;

    /* ── Load conversations ── */
    function loadConversations(cb){
        $.get(CTRL + "?method=getConversations", function(res){
            if(!res.success){
                $('#conversationList').html('<p class="p-3 text-danger small">Failed to load.</p>');
                return;
            }
            var html = '';
            $.each(res.data, function(i, c){
                var name    = $('<div>').text(c.business_name || c.other_name || 'Vendor').html();
                var preview = $('<div>').text(c.last_message ? c.last_message.substring(0,50) : 'No messages yet').html();
                var badge   = c.unread_count > 0
                    ? '<span class="badge bg-danger ms-1">' + c.unread_count + '</span>' : '';
                html += '<a class="conv-item list-group-item list-group-item-action py-2 px-3'
                      + (parseInt(c.id) === activeConvId ? ' active' : '')
                      + '" data-id="' + c.id + '" href="#">'
                      + '<div class="d-flex justify-content-between align-items-center">'
                      + '<span class="fw-semibold conv-name small">' + name + badge + '</span>'
                      + '</div>'
                      + '<div class="conv-preview text-muted" style="font-size:12px;margin-top:2px;">' + preview + '</div>'
                      + '</a>';
            });
            $('#conversationList').html(html || '<p class="p-3 text-muted small">No conversations yet.</p>');
            if(cb) cb();
        }, "json").fail(function(){
            $('#conversationList').html('<p class="p-3 text-danger small">Failed to load.</p>');
        });
    }

    /* ── Open chat ── */
    function openChat(convId, nameOverride){
        activeConvId = convId;
        lastMsgId    = 0;
        stopPolling();

        $('.conv-item').removeClass('active');
        $('.conv-item[data-id="' + convId + '"]').addClass('active');

        var nameEl     = $('.conv-item[data-id="' + convId + '"] .conv-name');
        activeConvName = nameOverride || (nameEl.length ? nameEl.text().trim() : 'Chat');
        $('#chatHeader').text(activeConvName).removeClass('text-muted');

        $('#emptyState').hide();
        $('#msgFormWrap').show();
        $('#messagesArea').html(
            '<div class="text-center text-muted p-4">'
            + '<div class="spinner-border spinner-border-sm"></div>'
            + '</div>'
        );

        fetchMessages();
        startPolling();
    }

    /* ── Fetch messages ── */
    function fetchMessages(){
        if(!activeConvId) return;
        $.get(CTRL + "?method=getMessages",
            { conversation_id: activeConvId, after_id: lastMsgId },
            function(res){
                if(!res.success) return;
                var msgs      = res.data.messages;
                var newLastId = res.data.last_msg_id;

                if(msgs && msgs.length){
                    if(lastMsgId === 0){
                        renderMessages(msgs);
                    } else {
                        appendMessages(msgs);
                    }
                    lastMsgId = newLastId;
                } else if(lastMsgId === 0){
                    $('#messagesArea').html(
                        '<div class="text-center text-muted p-5 small">No messages yet. Say hello!</div>'
                    );
                }
            }, "json");
    }

    function renderMessages(msgs){
        var html = '';
        $.each(msgs, function(i, m){ html += buildBubble(m); });
        $('#messagesArea').html(html);
        scrollBottom();
    }

    function appendMessages(msgs){
        $.each(msgs, function(i, m){ $('#messagesArea').append(buildBubble(m)); });
        scrollBottom();
    }

    function buildBubble(m){
    var isMine  = (m.is_mine === true || m.is_mine === "true"
                   || parseInt(m.sender_id) === SESSION_UID);
    var name    = isMine ? 'You' : $('<div>').text(m.sender_name).html();
    var msgId   = m.id;
    var time    = m.time || '';

    var bubbleContent;
    if(m.is_deleted === true || m.is_deleted === "true"){
        bubbleContent = '<em class="text-muted" style="font-size:12px;">This message was deleted</em>';
    } else {
        var text = $('<div>').text(m.message).html();
        var editedBadge = (m.is_edited === true || m.is_edited === "true")
            ? ' <span style="font-size:10px;opacity:0.7;">(edited)</span>' : '';
        bubbleContent = text + editedBadge;
    }

    var menuHtml = '';
    if(isMine && !(m.is_deleted === true || m.is_deleted === "true")){
        menuHtml = '<div class="msg-menu-wrap">'
            + '<button class="msg-menu-btn" data-id="' + msgId + '" title="Options">&#8942;</button>'
            + '<div class="msg-menu-dropdown" id="menu-' + msgId + '" style="display:none;">'
            + '<button class="msg-menu-option edit-btn" data-id="' + msgId + '">&#9998; Edit</button>'
            + '<button class="msg-menu-option delete-btn" data-id="' + msgId + '">&#128465; Delete</button>'
            + '</div>'
            + '</div>';
    }

    return '<div class="d-flex flex-column mb-2 ' + (isMine ? 'mine' : 'theirs') + '" data-msg-id="' + msgId + '">'
         + '<div class="small fw-semibold text-muted mb-1">' + name + '</div>'
         + '<div class="d-flex align-items-center gap-1 ' + (isMine ? 'justify-content-end' : '') + '">'
         + menuHtml
         + '<div class="msg-bubble p-2 px-3 small" id="bubble-' + msgId + '">' + bubbleContent + '</div>'
         + '</div>'
         + '<div class="small text-muted mt-1 px-1">' + time + '</div>'
         + '</div>';
}

    function scrollBottom(){
        var el = document.getElementById('messagesArea');
        if(el) el.scrollTop = el.scrollHeight;
    }

    /* ── Polling ── */
    function startPolling(){
        stopPolling();
        pollTimer = setInterval(fetchMessages, 4000);
    }
    function stopPolling(){
        if(pollTimer){ clearInterval(pollTimer); pollTimer = null; }
    }

    /* ── Send message ── */
    function sendMessage(){
        var msg = $('#msgInput').val().trim();
        if(!msg || !activeConvId) return;
        $('#sendBtn').prop('disabled', true);
        $.post(CTRL + "?method=sendMessage",
            { conversation_id: activeConvId, message: msg },
            function(res){
                $('#sendBtn').prop('disabled', false);
                if(res.success){
                    $('#msgInput').val('');
                    lastMsgId = 0;
                    fetchMessages();
                } else {
                    alert(res.message || 'Send failed.');
                }
            }, "json");
    }

    /* ── Events ── */
    $(document).on('click', '.conv-item', function(e){
        e.preventDefault();
        openChat(parseInt($(this).data('id')));
    });

    $('#sendBtn').on('click', sendMessage);
    $('#msgInput').on('keydown', function(e){
        if(e.key === 'Enter' && !e.shiftKey){ e.preventDefault(); sendMessage(); }
    });

    $('#refreshConvBtn').on('click', function(){
        loadConversations(function(){
            if(activeConvId){ lastMsgId = 0; fetchMessages(); }
        });
    });

    $(window).on('beforeunload', stopPolling);
     
     /* ── Edit / Delete menu ── */
$(document).on('click', '.msg-menu-btn', function(e){
    e.stopPropagation();
    var id = $(this).data('id');
    var $drop = $('#menu-' + id);
    $('.msg-menu-dropdown').not($drop).hide();
    $drop.toggle();
});

$(document).on('click', function(){
    $('.msg-menu-dropdown').hide();
});

/* ── DELETE ── */
$(document).on('click', '.delete-btn', function(){
    var msgId = $(this).data('id');
    $('.msg-menu-dropdown').hide();

    if(!confirm('Delete this message? This cannot be undone.')) return;

    $.post(CTRL + "?method=deleteMessage", { message_id: msgId }, function(res){
        if(res.success){
            var $bubble = $('#bubble-' + msgId);
            $bubble.html('<em class="text-muted" style="font-size:12px;">This message was deleted</em>');
            $bubble.closest('[data-msg-id]').find('.msg-menu-wrap').remove();
        } else {
            alert(res.message || 'Delete failed.');
        }
    }, "json");
});

/* ── EDIT ── */
$(document).on('click', '.edit-btn', function(){
    var msgId = $(this).data('id');
    $('.msg-menu-dropdown').hide();

    var $bubble   = $('#bubble-' + msgId);
    var $clone    = $bubble.clone();
    $clone.find('span').remove();
    var currentText = $clone.text().trim();

    $bubble.html(
        '<div class="edit-wrap">'
        + '<textarea class="form-control form-control-sm edit-textarea" rows="2" maxlength="2000">' 
        + $('<div>').text(currentText).html()   /* safely encode for textarea */
        + '</textarea>'
        + '<div class="d-flex gap-1 mt-1 justify-content-end">'
        + '<button class="btn btn-success btn-sm save-edit-btn" data-id="' + msgId + '">Save</button>'
        + '<button class="btn btn-secondary btn-sm cancel-edit-btn" data-id="' + msgId 
        +   '" data-orig="' + $('<div>').text(currentText).html() + '">Cancel</button>'
        + '</div>'
        + '</div>'
    );
    $bubble.find('.edit-textarea').focus();
});

/* Save edit */
$(document).on('click', '.save-edit-btn', function(){
    var msgId   = $(this).data('id');
    var newText = $('#bubble-' + msgId).find('.edit-textarea').val().trim();

    if(!newText){ alert('Message cannot be empty.'); return; }

    $(this).prop('disabled', true).text('Saving…');

    $.post(CTRL + "?method=editMessage",
        { message_id: msgId, message: newText },
        function(res){
            if(res.success){
                var safeText = $('<div>').text(newText).html();
                $('#bubble-' + msgId).html(
                    safeText + ' <span style="font-size:10px;opacity:0.7;">(edited)</span>'
                );
            } else {
                alert(res.message || 'Edit failed.');
                $('.save-edit-btn[data-id="' + msgId + '"]').prop('disabled', false).text('Save');
            }
        }, "json");
});

/* Cancel edit */
$(document).on('click', '.cancel-edit-btn', function(){
    var msgId    = $(this).data('id');
    var origText = $(this).data('orig');
    $('#bubble-' + msgId).html(origText);
});

    /* ── Init ── */
    loadConversations(function(){
        if(initConvId > 0) openChat(initConvId);
    });

})();
</script>
