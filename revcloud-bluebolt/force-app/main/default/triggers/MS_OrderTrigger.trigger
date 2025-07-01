/**
 * @description       : New or Updated Orders with Sync_to_Netsuite__c true will be sent to Netsuite on MuleSoft
 * @author            : Frank Berni
 * @group             : Cognizant
 * @last modified on  : 07-01-2025
 * @last modified by  : Frank Berni
**/
trigger MS_OrderTrigger on Order (after insert, after update) {
    for (Order ord : Trigger.new) {
        if (ord.Sync_to_Netsuite__c) {
            MuleSoftIntegrationService.sendOrderToMuleSoft(ord.Id);
        }
    }
}