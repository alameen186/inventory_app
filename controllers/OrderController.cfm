<cfif structKeyExists(form, "action") AND form.action EQ "checkout">


    <cfif NOT structKeyExists(session, "cart")>
        <cfset session.cart = structNew()>
    </cfif>

    <cfif structIsEmpty(session.cart)>
        <cflocation url="../index.cfm?page=dashboard&section=cart&message=Cart empty&type=error">
        <cfabort>
    </cfif>

    <cfset orderModel = createObject("component", "models.Order")>
    <cfset orderGroupId = createUUID()>

    <!-- LOOP -->
    <cfloop collection="#session.cart#" item="pid">

        <cfset item = session.cart[pid]>

        <cfset orderModel.addOrder(
            session.user_id,
            pid,
            item.price,
            item.qty,
            item.price * item.qty,
            orderGroupId
        )>

    </cfloop>

    <cfset session.cart = structNew()>

    <cflocation url="../index.cfm?page=dashboard&section=cart&message=Order placed&type=success" addtoken="false">
    <cfabort>

</cfif>