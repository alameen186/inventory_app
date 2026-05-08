<cfcomponent output="false">

    <cffunction name="jsonRes" access="private" returntype="void" output="true">
        <cfargument name="success" type="boolean" required="true">
        <cfargument name="message" type="string"  default="">
        <cfargument name="data"    type="any"     default="">
        <cfcontent type="application/json; charset=utf-8" reset="true">
        <cfoutput>#serializeJSON({
            "success" : arguments.success,
            "message" : arguments.message,
            "data"    : arguments.data
        })#</cfoutput>
        <cfabort>
    </cffunction>

    <cffunction name="requireAuth" access="private" returntype="void" output="false">
        <cfif NOT structKeyExists(session, "user_id")>
            <cfset jsonRes(false, "Unauthorized")>
        </cfif>
    </cffunction>

  
    <cffunction name="startConversation" access="remote" returntype="void" output="true" httpMethod="POST">
    <cfset requireAuth()>
    <cftry>
        <cfif NOT structKeyExists(form, "vendor_id") OR NOT isNumeric(form.vendor_id)>
            <cfset jsonRes(false, "Invalid vendor")>
            <cfreturn>
        </cfif>

        <cfset var convModel = createObject("component", "models.Conversation")>
        <cfset var msgModel  = createObject("component", "models.Message")>
        <cfset var vendor_id = val(form.vendor_id)>
        <cfset var user_id   = session.user_id>

        <cfif vendor_id EQ user_id>
            <cfset jsonRes(false, "Cannot chat with yourself")>
            <cfreturn>
        </cfif>

        <!--- Use model to check existence — no raw query in controller --->
        <cfset var existing = convModel.existsByUserAndVendor(user_id, vendor_id)>
        <cfset var isNew    = (existing.recordCount EQ 0)>
        <cfset var chat_id  = convModel.findOrCreate(user_id, vendor_id)>

        <!--- Send auto first message only for new chats --->
        <cfif isNew AND structKeyExists(form, "product_name") AND len(trim(form.product_name))>
            <cfset msgModel.send(
                chat_id   = chat_id,
                sender_id = user_id,
                message   = "Hi, I am interested in your product: " & trim(form.product_name)
            )>
            <cfset convModel.touch(chat_id)>
        </cfif>

        <cfset jsonRes(true, "", { "conversation_id": chat_id })>
    <cfcatch>
        <cfset jsonRes(false, "Error: #cfcatch.message#")>
    </cfcatch>
    </cftry>
</cffunction>


    <cffunction name="sendMessage" access="remote" returntype="void" output="true" httpMethod="POST">
        <cfset requireAuth()>
        <cftry>
            <cfif NOT structKeyExists(form, "conversation_id") OR NOT isNumeric(form.conversation_id)>
                <cfset jsonRes(false, "Invalid conversation")>
                <cfreturn>
            </cfif>
            <cfif NOT structKeyExists(form, "message") OR NOT len(trim(form.message))>
                <cfset jsonRes(false, "Message cannot be empty")>
                <cfreturn>
            </cfif>
            <cfif len(trim(form.message)) GT 200>
                <cfset jsonRes(false, "Message too long ")>
                <cfreturn>
            </cfif>

            <cfset var convModel = createObject("component", "models.Conversation")>
            <cfset var msgModel  = createObject("component", "models.Message")>
            <cfset var chat_id   = val(form.conversation_id)>
            <cfset var conv      = convModel.getById(chat_id)>

            <cfif conv.recordCount EQ 0>
                <cfset jsonRes(false, "Conversation not found")>
                <cfreturn>
            </cfif>

            <cfif conv.user_id NEQ session.user_id AND conv.vendor_id NEQ session.user_id>
                <cfset jsonRes(false, "Access denied")>
                <cfreturn>
            </cfif>

            <cfset var newMsgId = msgModel.send(
                chat_id   = chat_id,
                sender_id = session.user_id,
                message   = trim(form.message)
            )>

            <cfset convModel.touch(chat_id)>

            <cfset jsonRes(true, "Message sent", { "message_id": newMsgId })>
        <cfcatch>
            <cfset jsonRes(false, "Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="editMessage" access="remote" returntype="void" output="true" httpMethod="POST">
      <cfset requireAuth()>
      <cftry>
        <cfif NOT structKeyExists(form, "message_id") OR NOT isNumeric(form.message_id)>
            <cfset jsonRes(false, "Invalid message")>
            <cfreturn>
        </cfif>
        <cfif NOT structKeyExists(form, "message") OR NOT len(trim(form.message))>
            <cfset jsonRes(false, "Message cannot be empty")>
            <cfreturn>
        </cfif>
        <cfif len(trim(form.message)) GT 200>
            <cfset jsonRes(false, "Message too long")>
            <cfreturn>
        </cfif>

        <cfset var msgModel = createObject("component", "models.Message")>

        <!--- Use model to verify ownership — no raw query in controller --->
        <cfset var chk = msgModel.getById(val(form.message_id), session.user_id)>

        <cfif chk.recordCount EQ 0>
            <cfset jsonRes(false, "Not allowed")>
            <cfreturn>
        </cfif>
        <cfif chk.is_deleted EQ 1>
            <cfset jsonRes(false, "Cannot edit a deleted message")>
            <cfreturn>
        </cfif>

        <cfset msgModel.editMessage(val(form.message_id), session.user_id, trim(form.message))>
        <cfset jsonRes(true, "Message updated")>
      <cfcatch>
        <cfset jsonRes(false, "Error: #cfcatch.message#")>
      </cfcatch>
      </cftry>
    </cffunction>

    <cffunction name="deleteMessage" access="remote" returntype="void" output="true" httpMethod="POST">
      <cfset requireAuth()>
      <cftry>
        <cfif NOT structKeyExists(form, "message_id") OR NOT isNumeric(form.message_id)>
            <cfset jsonRes(false, "Invalid message")>
            <cfreturn>
        </cfif>

        <cfset var msgModel = createObject("component", "models.Message")>

        <cfset var chk = msgModel.getById(val(form.message_id), session.user_id)>

        <cfif chk.recordCount EQ 0>
            <cfset jsonRes(false, "Not allowed")>
            <cfreturn>
        </cfif>

        <cfset msgModel.deleteMessage(val(form.message_id), session.user_id)>
        <cfset jsonRes(true, "Message deleted")>
      <cfcatch>
        <cfset jsonRes(false, "Error: #cfcatch.message#")>
      </cfcatch>
      </cftry>
    </cffunction>

    <cffunction name="getMessages" access="remote" returntype="void" output="true" httpMethod="GET">
    <cfset requireAuth()>
    <cftry>
        <cfif NOT structKeyExists(url, "conversation_id") OR NOT isNumeric(url.conversation_id)>
            <cfset jsonRes(false, "Invalid conversation")>
            <cfreturn>
        </cfif>

        <cfset var chat_id   = val(url.conversation_id)>
        <cfset var after_id  = (structKeyExists(url, "after_id")  AND isNumeric(url.after_id))  ? val(url.after_id)  : 0>
        <cfset var before_id = (structKeyExists(url, "before_id") AND isNumeric(url.before_id)) ? val(url.before_id) : 0>
        
        <cfset var convModel = createObject("component", "models.Conversation")>
        <cfset var msgModel  = createObject("component", "models.Message")>
        <cfset var conv      = convModel.getById(chat_id)>

        <cfif conv.recordCount EQ 0>
            <cfset jsonRes(false, "Conversation not found")>
            <cfreturn>
        </cfif>

        <cfif conv.user_id NEQ session.user_id AND conv.vendor_id NEQ session.user_id>
            <cfset jsonRes(false, "Access denied")>
            <cfreturn>
        </cfif>

        <cfset msgModel.markRead(chat_id, session.user_id)>

        <cfset var messages  = msgModel.getByConversation(chat_id, after_id, before_id)>
        <cfset var result    = createObject("java", "java.util.ArrayList").init()>

        <cfloop query="messages">
            <cfset var row = structNew("ordered")>
            <cfset row["id"]          = messages.id>
            <cfset row["sender_id"]   = messages.sender_id>
            <cfset row["sender_name"] = messages.sender_name>
            <cfset row["message"]     = messages.message>
            <cfset row["is_mine"]     = (messages.sender_id EQ session.user_id)>
            <cfset row["is_edited"]   = (messages.is_edited  EQ 1)>
            <cfset row["is_deleted"]  = (messages.is_deleted EQ 1)>
            <cfset row["time"]        = timeFormat(messages.created_at, "HH:mm") & " " & dateFormat(messages.created_at, "dd-mmm")>
            <cfset result.add(row)>
        </cfloop>

        <!--- Only reverse on INITIAL load (after_id = 0 and before_id = 0) --->
        <cfif after_id EQ 0 AND before_id EQ 0>
            <cfset var reversed = createObject("java", "java.util.ArrayList").init()>
            <cfloop index="i" from="#result.size()#" to="1" step="-1">
                <cfset reversed.add(result.get(i - 1))>
            </cfloop>
            <cfset result = reversed>
        </cfif>

        <cfset var firstMsgId = 0>
        <cfset var lastMsgId  = 0>

        <cfif result.size() GT 0>
            <cfset firstMsgId = result.get(0)["id"]>
            <cfset lastMsgId  = result.get(result.size() - 1)["id"]>
        </cfif>

        <!--- Improved has_more logic --->
        <cfset var hasMore = false>
        <cfif before_id GT 0 OR after_id EQ 0>
            <cfset hasMore = (messages.recordCount GTE 15)>
        </cfif>

        <cfset jsonRes(true, "", {
            "messages"     : result,
            "last_msg_id"  : lastMsgId,
            "first_msg_id" : firstMsgId,
            "has_more"     : hasMore
        })>

     <cfcatch>
        <cfset jsonRes(false, "Error: #cfcatch.message#")>
     </cfcatch>
    </cftry>
</cffunction>

    <cffunction name="getConversations" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireAuth()>
        <cftry>
            <cfset var convModel = createObject("component", "models.Conversation")>
            <cfset var isVendor  = structKeyExists(session, "role_name") AND session.role_name EQ "vendor">
            <cfset var convList  = isVendor
                                   ? convModel.getForVendor(session.user_id)
                                   : convModel.getForUser(session.user_id)>

            <cfset var result = createObject("java", "java.util.ArrayList").init()>

            <cfloop query="convList">
                <cfset var row = structNew("ordered")>
                <cfset row["id"]           = convList.id>
                <cfset row["other_name"]   = convList.other_name>
                <cfset row["last_message"] = len(trim(convList.last_message)) ? left(trim(convList.last_message), 50) : "No messages yet">
                <cfset row["unread_count"] = convList.unread_count>
                <cfset row["updated_at"]   = dateFormat(convList.updated_at, "dd-mmm-yyyy")>
                <cfif NOT isVendor>
                    <cfset row["business_name"] = convList.business_name>
                </cfif>
                <cfset result.add(row)>
            </cfloop>

            <cfset jsonRes(true, "", result)>
        <cfcatch>
            <cfset jsonRes(false, "Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getAllConversations" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireAuth()>
        <cftry>
            <cfif NOT structKeyExists(session, "role_id") OR session.role_id NEQ 1>
                <cfset jsonRes(false, "Admin access required")>
                <cfreturn>
            </cfif>

            <cfset var convModel = createObject("component", "models.Conversation")>
            <cfset var convList  = convModel.getAll()>
            <cfset var result    = createObject("java", "java.util.ArrayList").init()>

            <cfloop query="convList">
                <cfset var row = structNew("ordered")>
                <cfset row["id"]            = convList.id>
                <cfset row["customer_name"] = convList.customer_name>
                <cfset row["vendor_name"]   = convList.vendor_name>
                <cfset row["last_message"]  = len(trim(convList.last_message)) ? left(trim(convList.last_message), 60) : "">
                <cfset row["last_time"]     = dateFormat(convList.updated_at, "dd-mmm-yyyy")>
                <cfset result.add(row)>
            </cfloop>

            <cfset jsonRes(true, "", { "conversations": result })>
        <cfcatch>
            <cfset jsonRes(false, "Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getUnreadCount" access="remote" returntype="void" output="true" httpMethod="GET">
        <cfset requireAuth()>
        <cftry>
            <cfset var convModel = createObject("component", "models.Conversation")>
            <cfset var isVendor  = structKeyExists(session, "role_name") AND session.role_name EQ "vendor">
            <cfset var count     = 0>

            <cfif isVendor>
                <cfset count = convModel.getTotalUnread(vendor_id = session.user_id)>
            <cfelse>
                <cfset count = convModel.getTotalUnread(user_id = session.user_id)>
            </cfif>

            <cfset jsonRes(true, "", { "count": count })>
        <cfcatch>
            <cfset jsonRes(false, "Error: #cfcatch.message#")>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>