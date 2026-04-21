<!-- GENERATE PDF -->
<cfdocument format="pdf" filename="#invoicePath#" overwrite="true">
    <style>
        body { font-family: 'Arial', sans-serif; padding: 20px; color: #333; }
        h2 { border-bottom: 2px solid #444; padding-bottom: 10px; color: #2c3e50; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th { background-color: #f8f9fa; padding: 12px; border: 1px solid #dee2e6; text-align: left; }
        td { padding: 12px; border: 1px solid #dee2e6; }
        .total-row { font-weight: bold; background-color: #f1f1f1; }
    </style>

    <cfoutput>
        <div style="text-align: right; margin-bottom: 20px;">
            <h2>INVOICEaaaaaaaaaaaaaaaaaa</h2>
            <p><strong>Order ID:</strong> #orderGroupId#</p>
            <p><strong>Date:</strong> #dateFormat(now(), "dd-mm-yyyy")#</p>
        </div>

        <table>
            <thead>
                <tr>
                    <th>Product</th>
                    <th>Price</th>
                    <th>Qty</th>
                    <th>Total</th>
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
            <tfoot>
                <tr class="total-row">
                    <td colspan="3" style="text-align: right;">Grand Total:</td>
                    <td>#numberFormat(grandTotal, "0.00")#</td>
                </tr>
            </tfoot>
        </table>
    </cfoutput>
</cfdocument>
