/**
 * @description       : Test Class for PaymentLineInvoiceJob
 * @author            : Frank Berni
 * @group             : Cognizant
 * @last modified on  : 07-07-2025
 * @last modified by  : Frank Berni
 * Using seeAllData=true due to REST limitations on inserting Invoice records
 * README: Please ensure there is at least 1 Invoice and 1 Payment in the Org and update Ids in query before executing 
**/
@isTest(seeAllData=true)
private class PaymentLineInvoiceJobTest {
    @isTest
    static void testScheduledJob() {

        // Fetch a real existing Invoice (must exist in your test org)
        Invoice inv = [
            SELECT Id, BillingAccountId 
            FROM Invoice 
            WHERE Id = '3ttKj000000vKWQIA2'
            LIMIT 1
        ];

        Payment pmt = [
            SELECT Id, Amount, Balance, AccountId, Updated_From_NetSuite__c, PaymentInvoice__c
            FROM Payment 
            WHERE Id = '0aQKj000000vSegMAE' 
            LIMIT 1
        ];

        Integer initialPLICount = [
            SELECT COUNT()
            FROM PaymentLineInvoice
            WHERE PaymentId = :pmt.Id
        ];

        pmt.PaymentInvoice__c = (String)inv.Id;
        pmt.Updated_From_NetSuite__c = false;
        update pmt;

        Test.startTest();
        new PaymentLineInvoiceJob().execute(null);
        Test.stopTest();

        List<PaymentLineInvoice> plis = [
            SELECT Id, InvoiceId, PaymentId, Amount, PaymentBalance, AssociatedAccountId
            FROM PaymentLineInvoice
            WHERE PaymentId = :pmt.Id
        ];
        System.debug(plis);
        Integer postPLICount = plis.size();

        Payment processedPmt = [SELECT Updated_From_Netsuite__c FROM Payment WHERE Id =: pmt.Id];
        System.debug(processedPmt);

        // Conditionally assert based on Payment.Balance
        if (pmt.Balance > 0) {
            Assert.isTrue(postPLICount > initialPLICount,
                'Expected new PLI(s) to be created, but count did not increase.');
            Assert.isTrue(processedPmt.Updated_From_Netsuite__c == true, 
                'Payment record checkbox did not update to true');
            // Resetting payment record back to false if processed
            processedPmt.Updated_From_Netsuite__c = false;
            update processedPmt;
        // When Payment balance is 0
        } else {
            Assert.areEqual(initialPLICount, postPLICount,
                'PLI count should not have changed since Payment balance is 0.');   
        }
    }
}
