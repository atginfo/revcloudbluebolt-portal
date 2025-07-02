/**
 * @description       : Updated Invoices with Sync_to_Netsuite__c marked to true will be sent to Netsuite on MuleSoft
 * @author            : Frank Berni
 * @group             : Cognizant
 * @last modified on  : 07-01-2025
 * @last modified by  : Frank Berni
**/
trigger MS_InvoiceTrigger on Invoice (after update) {
    for (Invoice inv : Trigger.new) {
        Invoice oldInvoice = Trigger.oldMap.get(inv.Id);

        // Send to Netsuite only if Sync to Netsuite was switched from False to True
        if (!inv.Sync_to_Netsuite__c && inv.Sync_to_Netsuite__c) {
            MuleSoftIntegrationService.sendInvoiceToMuleSoft(inv.Id);
        }
    }
}