/**
 * @description       : Creates new PaymentInvoiceLine records when Payment's PaymentInvoice__c is populated 
 *                      and Updated_From_Netsuite__c is false
 *                      Payment Balance must not be 0 and Payment Amounts exceeding Balance will result in partial payments
 * @author            : Frank Berni
 * @group             : Cognizant
 * @last modified on  : 07-07-2025
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
            [SELECT Id, Balance FROM Invoice WHERE Id IN :invoiceIds]
        );

        List<PaymentLineInvoice> pliToInsert = new List<PaymentLineInvoice>();

        // Use info from Payment and related Invoice to create PLI
        for (Payment p : eligiblePayments) {
            if (invoiceMap.containsKey(p.PaymentInvoice__c)) {
                Invoice inv = invoiceMap.get(p.PaymentInvoice__c);

                // handle debug messaging based on Balance value
                String message = (p.Balance > 0) ? 
                    'Processing PLI for Payment: ' + p.Id : 
                    'Skipped Payment ' + p.Id + ': No balance left to apply or no matching Invoice.';
                System.debug(message);

                // Grabs minimum between Balance and Amount
                Decimal appliedAmount = Math.min(p.Balance, p.Amount); 
                System.debug(appliedAmount);
                
                if (p.Amount > appliedAmount) {
                    System.debug('Partial Payment Detected - Applied only ' + appliedAmount + ' of ' + p.Amount);
                }

                PaymentLineInvoice newPli = new PaymentLineInvoice(
                    InvoiceId = p.PaymentInvoice__c,
                    PaymentId = p.Id,
                    // Assigning all or some of the payment based on remaining Payment balance
                    Amount = appliedAmount,
                    // Note: PaymentBalance is not writeable
                    // PaymentBalance = p.Balance,
                    AssociatedAccountId = p.AccountId,
                    // Modified Billing Settings Apply Credits and Payments to Invoice
                    HasBeenUnapplied = 'No', // REQUIRED
                    Type = 'Applied' //REQUIRED
                );
                
                // Updates Updated_From_Netsuite__c to true if Balance is greater 0, otherwise leave false
                p.Updated_From_Netsuite__c = (p.Balance > 0) ? true : false;  

                // Add new PLI if Balance is greater than 0
                if (p.Balance > 0) {
                    pliToInsert.add(newPli);   
                }     
            } 
        }     
        
        // Insert the PLIs
        System.debug(pliToInsert);
        insert pliToInsert;
        // Update the Payments to ensure they aren't processed again
        update eligiblePayments;
    }
}