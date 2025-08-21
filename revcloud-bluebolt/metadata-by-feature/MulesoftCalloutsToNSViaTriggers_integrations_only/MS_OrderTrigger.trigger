/**
 * @description       : Updated Orders with Sync_to_Netsuite__c marked to true will be sent to Netsuite on MuleSoft
 * @author            : Frank Berni
 * @group             : Cognizant
 * @last modified on  : 07-02-2025
 * @last modified by  : Frank Berni
**/
trigger MS_OrderTrigger on Order (after update) {
    for (Order ord : Trigger.new) {
        Order oldOrder = Trigger.oldMap.get(ord.Id); 

        // Send to Netsuite only if Sync to Netsuite was switched from False to True
        if (!oldOrder.Sync_to_Netsuite__c && ord.Sync_to_Netsuite__c) {
            MuleSoftIntegrationService.sendOrderToMuleSoft(ord.Id);
        }
    }
}