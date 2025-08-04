/**
 * @description       : Handles standard trigger events for the Invoice object
 * @author            : Frank Berni
 * @group             : Cognizant
 * @last modified on  : 08-04-2025
 * @last modified by  : Frank Berni
**/
public class InvoiceTriggerHandler {

    /********************************** Context Methods **********************************/
    public static void handleAfterInsert(List<Invoice> newList, Map<Id, Invoice> oldMap) {
        attachOrderForInvoice(newList);

    }

     /********************************** Helper Methods **********************************/

    //  
    private static void attachOrderForInvoice(List<Invoice> newList) {
        System.debug('Handling Order attachment for Invoice after insert');

        // Id userId = UserInfo.getUserId();
        Set<Id> invoiceIds = new Set<Id>();
        
        // Loop through new invoices
        for (Invoice inv : newList) {
            // Put invoice Ids into a set
            invoiceIds.add(inv.Id);
        }

        List<Invoice> invoiceList = [SELECT Id, BillingAccountId, Order__c, Notes__c FROM Invoice WHERE Id IN :invoiceIds];

        // Collecting Account Id from invoices missing Order__c
        Set<Id> accountIds = new Set<Id>();
        Map<Id, List<Invoice>> invoicesByAccount = new Map<Id, List<Invoice>>();
        for (Invoice inv : invoiceList) {
            if (inv.Order__c == null && inv.BillingAccountId != null) {
                accountIds.add(inv.BillingAccountId);

                if(invoicesByAccount.containsKey(inv.BillingAccountId)) {
                    invoicesByAccount.get(inv.BillingAccountId).add(inv);
                } else {
                    invoicesByAccount.put(inv.BillingAccountId, new List<Invoice>{inv});
                }
            }
        }

        if (accountIds.isEmpty()) return;

        // Query most recent Order for each Account
        Map<Id, Order> latestOrderByAccount = new Map<Id, Order>();
        List<Invoice> invoicesToUpdate = new List<Invoice>();

        for (Order ord : [
            SELECT Id, AccountId, CreatedDate
            FROM Order
            WHERE AccountId IN :accountIds
            ORDER BY CreatedDate DESC
        ]) {
            // Only keep the first (most recent) order per account
            if (!latestOrderByAccount.containsKey(ord.AccountId)) {
                latestOrderByAccount.put(ord.AccountId, ord);
            }
        }
        // Assign Order__c to each matching Invoice
        for (Id acctId : invoicesByAccount.keySet()) {
            if (latestOrderByAccount.containsKey(acctId)) {
                Id orderId = latestOrderByAccount.get(acctId).Id;
                for (Invoice inv : invoicesByAccount.get(acctId)) {
                    inv.Order__c = orderId;
                    // String noteStamp = 'Invoice Updated by InvoiceTriggerHandler on ' + String.valueOf(System.now()) + ' by User ' + userId;
                    // inv.Notes__c = noteStamp;
                    invoicesToUpdate.add(inv);
                }
            }
        }

        update invoicesToUpdate;
        System.debug('Updating Invoices Successful');
    }
}