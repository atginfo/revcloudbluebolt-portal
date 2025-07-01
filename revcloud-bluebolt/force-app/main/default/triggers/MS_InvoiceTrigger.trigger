/**
 * @description       : New or Updated Invoices with Sync_to_Netsuite__c true will be sent to Netsuite on MuleSoft
 * @author            : Frank Berni
 * @group             : Cognizant
 * @last modified on  : 07-01-2025
 * @last modified by  : Frank Berni
**/
trigger MS_InvoiceTrigger on Invoice (after insert, after update) {
    for (Invoice inv : Trigger.new) {
        if (inv.Sync_to_Netsuite__c) {
            MuleSoftIntegrationService.sendInvoiceToMuleSoft(inv.Id);
        }
    }
}