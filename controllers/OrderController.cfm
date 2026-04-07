<cfif structKeyExists(form, "action") AND form.action EQ "checkout">

    <cfif NOT structKeyExists(session, "cart") OR structIsEmpty(session.cart)>
        <cflocation url="../index.cfm?page=dashboard&section=cart&message=Cart empty&type=error">
        <cfabort>
    </cfif>

    <cfset orderModel = createObject("component", "models.Order")>
    <cfset orderGroupId = createUUID()>

    <cfloop collection="#session.cart#" item="pid">
        <cfset item = session.cart[pid]>
        <cfset orderModel.addOrder(
            session.user_id,
            pid,
            item.price,
            item.qty,
            (item.price * item.qty),
            orderGroupId
        )>
    </cfloop>

    <cfset invoiceDir = expandPath("../assets/invoices/")>

    <cfset fileName = "invoice_#orderGroupId#.pdf">
    <cfset invoicePath = invoiceDir & fileName>

    <!--- GENERATE THE PDF INVOICE --->
    <cfdocument format="pdf" filename="#invoicePath#" overwrite="true">
        <html>
        <head>
            <style>
                body { font-family: Arial, sans-serif; padding: 20px; color: ##333; }
                .header { text-align: center; border-bottom: 2px solid ##2c3e50; padding-bottom: 15px; margin-bottom: 20px; }
                table { width: 100%; border-collapse: collapse; margin-top: 10px; }
                th { background-color: ##f8f9fa; padding: 12px; border: 1px solid ##dee2e6; text-align: left; }
                td { padding: 12px; border: 1px solid ##dee2e6; }
                .total-box { text-align: right; margin-top: 25px; font-size: 1.2em; font-weight: bold; }
            </style>
        </head>
        <body>
            <cfoutput>
                <div class="header">
                    <h1>TAX INVOICE</h1>
                    <p>Order ID: <strong>#orderGroupId#</strong></p>
                    <p>Date: #dateFormat(now(), "dd-mmm-yyyy")#</p>
                </div>

                <table>
                    <thead>
                        <tr>
                            <th>Product Name</th>
                            <th>Price</th>
                            <th>Quantity</th>
                            <th>Subtotal</th>
                        </tr>
                    </thead>
                    <tbody>
                        <cfset grandTotal = 0>
                        <cfloop collection="#session.cart#" item="pid">
                            <cfset item = session.cart[pid]>
                            <cfset lineTotal = item.price * item.qty>
                            <cfset grandTotal += lineTotal>
                            <tr>

                                <td>#item.name#</td>
                                <td>#numberFormat(item.price, "0.00")#</td>
                                <td>#item.qty#</td>
                                <td>#numberFormat(lineTotal, "0.00")#</td>
                            </tr>
                        </cfloop>
                    </tbody>
                </table>
                
                <div class="total-box">
                    Grand Total: #numberFormat(grandTotal, "0.00")#
                </div>
            </cfoutput>
        </body>
        </html>
    </cfdocument>

    <!--- SEND EMAIL --->
    <cftry>
        <cfmail 
            to="#session.user_email#" 
            from="ameenalalameen8841@gmail.com" 
            subject="New Order Confirmation - #orderGroupId#" 
            type="html">
            
            <h2>Hello!</h2>
            <p>Thank you for your purchase. Please find your invoice attached to this email.</p>
            <p>Order ID: <strong>#orderGroupId#</strong></p>

            <!--- Attach the file --->
            <cfmailparam file="#invoicePath#" disposition="attachment">
        </cfmail>
        
        <cfcatch type="any">
            <!--- For debugging only - remove in production --->
            <cfdump var="#cfcatch#">
            <cfabort>
        </cfcatch>
    </cftry>

    <cfset session.cart = structNew()>

    <cflocation url="../index.cfm?page=dashboard&section=productList&message=Order successful! Invoice sent to your mail.&type=success" addtoken="false">
    <cfabort>

</cfif>
