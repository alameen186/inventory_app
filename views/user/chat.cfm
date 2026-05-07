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
        var isMine = (m.is_mine === true || m.is_mine === "true"
                      || parseInt(m.sender_id) === SESSION_UID);
        var name   = isMine ? 'You' : $('<div>').text(m.sender_name).html();
        var text   = $('<div>').text(m.message).html();
        var time   = m.time || '';
   
        return '<div class="d-flex flex-column mb-2 ' + (isMine ? 'mine' : 'theirs') + '">'
             + '<div class="small fw-semibold text-muted mb-1">' + name + '</div>'
             + '<div class="msg-bubble p-2 px-3 small">' + text + '</div>'
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

    /* ── Init ── */
    loadConversations(function(){
        if(initConvId > 0) openChat(initConvId);
    });

})();
</script>
