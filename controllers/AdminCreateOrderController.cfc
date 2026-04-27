<cfcomponent output="false">

    <cffunction name="sendJSON" access="private" returntype="void" output="true">
        <cfargument name="data" type="struct" required="true">
        <cfcontent type="application/json; charset=utf-8" reset="true">
        <cfset var map = structNew("ordered")>
        <cfloop collection="#arguments.data#" item="k">
            <cfset map[lcase(k)] = arguments.data[k]>
        </cfloop>
        <cfoutput>#serializeJSON(map)#</cfoutput>
        <cfabort>
    </cffunction>

    <cffunction name="requireAuth" access="private" returntype="void" output="false">
        <cfif NOT structKeyExists(session,"user_id")>
            <cfset sendJSON({status:"error", message:"Unauthorized"})>
        </cfif>
    </cffunction>

    <!--- CREATE ORDER --->
    <cffunction name="createOrder" access="remote" returntype="void" output="true" httpmethod="POST">
        <cfset requireAuth()>
        <cftry>
            <cfset var productModel = createObject("component","models.Product")>
            <cfset var orderModel   = createObject("component","models.Order")>
            <cfset var couponModel  = createObject("component","models.Coupon")>

            <!--- INPUTS --->
            <cfset var productId = structKeyExists(form,"product_id") ? val(form.product_id) : 0>
            <cfset var userId    = structKeyExists(form,"user_id")    ? val(form.user_id)    : 0>
            <cfset var qty       = structKeyExists(form,"qty")        ? val(form.qty)        : 0>
            <cfset var couponCode = structKeyExists(form,"coupon_id") ? trim(form.coupon_id) : "">

            <!--- VALIDATION --->
            <cfif userId LTE 0>
                <cfset sendJSON({status:"error", message:"Please select a user"})>
            </cfif>
            <cfif productId LTE 0>
                <cfset sendJSON({status:"error", message:"Please select a product"})>
            </cfif>
            <cfif qty LTE 0>
                <cfset sendJSON({status:"error", message:"Invalid quantity"})>
            </cfif>
            <cfif qty GT 3>
                <cfset sendJSON({status:"error", message:"Maximum 3 quantity allowed"})>
            </cfif>

            <!--- STOCK CHECK --->
            <cfset var stock = productModel.getStock(productId)>
            <cfif qty GT stock>
                <cfset sendJSON({status:"error", message:"Only #stock# items available"})>
            </cfif>

            <!--- PRODUCT --->
            <cfset var product   = productModel.getProductById(productId)>
            <cfset var total     = product.price * qty>
            <cfset var discount  = 0>
            <cfset var finalTotal = total>
            <cfset var usedCouponCode = "">

            <!--- COUPON --->
            <cfif len(couponCode)>
                <cfset var coupon = couponModel.getCouponByCode(couponCode)>
                <cfif coupon.recordCount>
                    <cfif total LT coupon.min_amount>
                        <cfset sendJSON({status:"error", message:"Minimum purchase amount is #coupon.min_amount# for this coupon"})>
                    </cfif>
                    <cfset usedCouponCode = coupon.code>
                    <cfif coupon.discount_type EQ "percent">
                        <cfset discount = (total * coupon.discount_value) / 100>
                    <cfelse>
                        <cfset discount = coupon.discount_value>
                    </cfif>
                    <cfif discount GT coupon.max_discount>
                        <cfset discount = coupon.max_discount>
                    </cfif>
                    <cfset finalTotal = total - discount>
                </cfif>
            </cfif>

            <!--- PLACE ORDER --->
            <cfset var orderGroupId = createUUID()>
            <cfset var result = orderModel.addOrder(
                user_id      = userId,
                temp_user_id = "",
                product_id   = productId,
                price        = product.price,
                quantity     = qty,
                total        = total,
                group_id     = orderGroupId,
                coupon_code  = usedCouponCode,
                discount     = discount,
                final_total  = finalTotal
            )>

            <cfif NOT result.success>
                <cfset sendJSON({status:"error", message:"Order failed"})>
            </cfif>

            <!--- REDUCE STOCK --->
            <cfset productModel.reduceStock(productId, qty)>

            <cfset sendJSON({status:"success", message:"Order created successfully"})>

        <cfcatch>
            <cfset sendJSON({status:"error", message:"#cfcatch.message#"})>
        </cfcatch>
        </cftry>
    </cffunction>

    <!--- VENDOR ORDER --->
<cffunction name="vendorOrder" access="remote" returntype="void" output="true" httpmethod="POST">
    <cfset requireAuth()>
    <cftry>
        <!--- VALIDATE --->
        <cfif NOT structKeyExists(form,"cart") OR NOT len(trim(form.cart))>
            <cfset sendJSON({status:"error", message:"Cart is missing"})>
        </cfif>
        <cfif NOT structKeyExists(form,"first_name") OR NOT len(trim(form.first_name))>
            <cfset sendJSON({status:"error", message:"First name is required"})>
        </cfif>
        <cfif NOT structKeyExists(form,"email") OR NOT len(trim(form.email))>
            <cfset sendJSON({status:"error", message:"Email is required"})>
        </cfif>

        <cfset var cartData = deserializeJSON(form.cart)>

        <cfif structIsEmpty(cartData)>
            <cfset sendJSON({status:"error", message:"Cart is empty"})>
        </cfif>

        <!--- MODELS --->
        <cfset var tempUserModel = createObject("component","models.TempUser")>
        <cfset var orderModel    = createObject("component","models.Order")>
        <cfset var productModel  = createObject("component","models.Product")>
        <cfset var userModel     = createObject("component","models.User")>

        <!--- CREATE OR FETCH TEMP USER --->
        <cfset var tempUserId = tempUserModel.getOrCreateTempUser(
            vendor_id  = session.user_id,
            first_name = trim(form.first_name),
            last_name  = structKeyExists(form,"last_name") ? trim(form.last_name) : "",
            email      = trim(form.email)
        )>

        <cfset var orderGroupId = createUUID()>
        <cfset var vendorData   = userModel.getUserWithRole(session.user_id)>

        <!--- SAVE EACH CART ITEM --->
        <cfloop collection="#cartData#" item="local.pid">
            <cfset var item = cartData[local.pid]>

            <cfif NOT structKeyExists(item,"price") OR NOT structKeyExists(item,"qty")>
                <cfset sendJSON({status:"error", message:"Cart item structure invalid"})>
            </cfif>

            <!--- STOCK CHECK --->
            <cfset var available = productModel.getStock(local.pid)>
            <cfif item.qty GT available>
                <cfset sendJSON({status:"error", message:"Not enough stock for #item.name#"})>
            </cfif>

            <cfset var result = orderModel.addOrder(
                user_id      = "",
                temp_user_id = tempUserId,
                product_id   = local.pid,
                price        = item.price,
                quantity     = item.qty,
                total        = item.price * item.qty,
                group_id     = orderGroupId,
                coupon_code  = "",
                discount     = 0,
                final_total  = item.price * item.qty
            )>

            <cfif isStruct(result) AND NOT result.success>
                <cfset sendJSON({status:"error", message:"Order failed for #item.name#"})>
            </cfif>

            <cfset productModel.reduceStock(local.pid, item.qty)>
        </cfloop>

        <!--- GENERATE PDF INVOICE --->
        <cfset var invoiceDir  = expandPath("/assets/invoices/")>
        <cfset var invoicePath = invoiceDir & "invoice_#orderGroupId#.pdf">

        <cfdocument format="pdf" filename="#invoicePath#" overwrite="true">
        <cfoutput>
        <style>
        body{font-family:Arial;font-size:12px;}
        .tc{text-align:center;} .tr{text-align:right;}
        .header{border-bottom:2px solid ##000;margin-bottom:15px;padding-bottom:10px;}
        .tbl{width:100%;border-collapse:collapse;margin-top:10px;}
        .tbl th{background:##f2f2f2;border:1px solid ##ccc;padding:8px;}
        .tbl td{border:1px solid ##ccc;padding:8px;}
        .total-box{width:40%;float:right;margin-top:10px;}
        .footer{margin-top:40px;font-size:10px;text-align:center;color:##777;}
        </style>
        <div>
            <div class="header tc"><h2>INVENTORY STORE</h2></div>
            <table width="100%">
            <tr>
                <td>
                    <strong>Invoice ID:</strong> #orderGroupId#<br>
                    <strong>Date:</strong> #dateFormat(now(),"dd-mmm-yyyy")#
                </td>
                <td class="tr">
                    <strong>Vendor:</strong><br>
                    #vendorData.business_name#
                </td>
            </tr>
            </table>

            <table class="tbl">
            <tr>
                <th>Product</th><th>Price</th><th>Qty</th><th>Total</th>
            </tr>
            <cfset var grandTotal = 0>
            <cfloop collection="#cartData#" item="local.pid">
                <cfset var item     = cartData[local.pid]>
                <cfset var rowTotal = item.price * item.qty>
                <cfset grandTotal  += rowTotal>
                <tr>
                    <td>#item.name#</td>
                    <td>#item.price#</td>
                    <td>#item.qty#</td>
                    <td>#rowTotal#</td>
                </tr>
            </cfloop>
            </table>

            <table class="total-box">
            <tr><td>Subtotal</td><td class="tr">#grandTotal#</td></tr>
            <tr><td>GST (0%)</td><td class="tr">0</td></tr>
            <tr>
                <td><strong>Final Total</strong></td>
                <td class="tr"><strong>#grandTotal#</strong></td>
            </tr>
            </table>
            <div style="clear:both;"></div>
            <div class="footer"><p>System generated invoice. No signature required.</p></div>
        </div>
        </cfoutput>
        </cfdocument>

        <cfset sendJSON({status:"success", message:"Order placed successfully", orderGroupId:orderGroupId})>

    <cfcatch>
        <cfset sendJSON({status:"error", message:"#cfcatch.message#"})>
    </cfcatch>
    </cftry>
</cffunction>

</cfcomponent>