/**
 * @description       : Creates new PaymentInvoiceLine records when Payment's PaymentInvoice__c is populated 
 *                      and Updated_From_Netsuite__c is false
 * @author            : Frank Berni
 * @group             : Cognizant
 * @last modified on  : 07-03-2025
 * @last modified by  : Frank Berni
 * Runs every half hour paste into Execute Anonymous: 
 * System.schedule('Payment Line Invoice Job', '0 0/30 * * * ?', new PaymentLineInvoiceJob());
**/
global class PaymentLineInvoiceJob implements Schedulable {
    global void execute(SchedulableContext sc) {

        // Query Payments who's PaymentInvoice__c is populated but Updated_From_Netsuite__c is false
        List<Payment> eligiblePayments = [
            SELECT Id, PaymentInvoice__c, Amount, Balance, AccountId, Updated_From_Netsuite__c
            FROM Payment
            WHERE PaymentInvoice__c != null AND Updated_From_Netsuite__c = false
            LIMIT 200
        ];

        if (eligiblePayments.isEmpty()) return;

        // Grab PaymentInvoice Id from Payments
        Set<String> invoiceIds = new Set<String>();
        for (Payment p : eligiblePayments) {
            invoiceIds.add(p.PaymentInvoice__c);
        }

        // Set up Map of Id to Invoice to create PLIs for
        Map<Id, Invoice> invoiceMap = new Map<Id, Invoice>(
            [SELECT Id FROM Invoice WHERE Id IN :invoiceIds]
        );

        List<PaymentLineInvoice> pliToInsert = new List<PaymentLineInvoice>();

        // Use info from Payment and related Invoice to create PLI
        for (Payment p : eligiblePayments) {
            if (invoiceMap.containsKey(p.PaymentInvoice__c)) {
                pliToInsert.add(new PaymentLineInvoice(
                    InvoiceId = p.PaymentInvoice__c,
                    PaymentId = p.Id,
                    Amount = p.Amount,
                    // Note: PaymentBalance is not writeable
                    // PaymentBalance = p.Balance,
                    AssociatedAccountId = p.AccountId
                ));

                // Updates Updated_From_Netsuite__c to true when processed
                p.Updated_From_Netsuite__c = true;
            }
        }

        // Insert the PLIs
        insert pliToInsert;
        // Update the Payments to ensure they aren't processed again
        update eligiblePayments;
    }
}