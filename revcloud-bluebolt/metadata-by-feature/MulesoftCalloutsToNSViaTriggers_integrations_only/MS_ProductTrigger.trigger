/**
 * @description       : New or Updated Products with Sync_to_Netsuite__c true will be sent to Netsuite on MuleSoft
 * @author            : Frank Berni
 * @group             : Cognizant
 * @last modified on  : 07-29-2025
 * @last modified by  : Frank Berni
**/
trigger MS_ProductTrigger on Product2 (after insert, after update) {
    for (Product2 prod : Trigger.new) {
        if (prod.Sync_to_Netsuite__c && prod.Netsuite_Id__c == null) {
            MuleSoftIntegrationService.sendProductToMuleSoft(prod.Id);
        }
    }
}