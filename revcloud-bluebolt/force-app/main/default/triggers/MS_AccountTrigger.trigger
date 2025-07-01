/**
 * @description       : New or Updated Accounts with Sync_to_Netsuite__c true will be sent to Netsuite on MuleSoft
 * @author            : Frank Berni
 * @group             : Cognizant
 * @last modified on  : 07-01-2025
 * @last modified by  : Frank Berni
**/
trigger MS_AccountTrigger on Account (after insert, after update) {
    for (Account acc : Trigger.new) {
        if (acc.Sync_to_Netsuite__c) {
            MuleSoftIntegrationService.sendAccountToMuleSoft(acc.Id);
        }
    }
}