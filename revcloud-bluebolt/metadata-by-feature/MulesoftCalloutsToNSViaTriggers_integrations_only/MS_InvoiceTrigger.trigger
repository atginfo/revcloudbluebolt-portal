/**
 * @description       : Updated Invoices with Sync_to_Netsuite__c marked to true will be sent to Netsuite on MuleSoft
 * @author            : Frank Berni
 * @group             : Cognizant
 * @last modified on  : 08-04-2025
 * @last modified by  : Frank Berni
**/
trigger MS_InvoiceTrigger on Invoice (after insert, after update) {

    // NEW After Insert
    if (Trigger.isAfter && Trigger.isInsert) {
        InvoiceTriggerHandler.handleAfterInsert(Trigger.new, Trigger.oldMap);
    }

    // NEW After Update
    if (Trigger.isAfter && Trigger.isUpdate) {
        for (Invoice inv : Trigger.new) {
            Invoice oldInvoice = Trigger.oldMap.get(inv.Id);

            // Send to Netsuite only if Sync to Netsuite was switched from False to True
            if (!oldInvoice.Sync_to_Netsuite__c && inv.Sync_to_Netsuite__c) {
                MuleSoftIntegrationService.sendInvoiceToMuleSoft(inv.Id);
            }
        }
    }
    
}