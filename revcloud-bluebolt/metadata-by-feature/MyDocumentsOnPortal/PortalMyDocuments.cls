/**
 * @description       : Controller for managing documents related to invoices in the portal.
 * @author            : David Sam
 * @group             : Cognizant
 * @ticket            : CIBGCF-XX
 * @last modified on  : 06-25-2025
 * @last modified by  : David Sam
**/
public with sharing class PortalMyDocuments {
    
    @AuraEnabled(cacheable=true)
    public static List<ContentDocumentLink> getMyInvoicesDocuments(Id accountId) {
        // Query ContentDocumentLinks related to the Account (or adjust for your Invoice object)
        return [
            SELECT Id, ContentDocumentId, ContentDocument.Title, ContentDocument.FileType, ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :accountId
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<ContentDocumentLink> getMyInvoicesDocumentsByContactId(Id contactId) {
        // Query ContentDocumentLinks related to the Contact (or adjust for your Invoice object)
        return [
            SELECT Id, ContentDocumentId, ContentDocument.Title, ContentDocument.FileType, ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :contactId
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<ContentDocumentLink> getAccountQuoteDocuments() {

        ID theCurrentUserId = UserInfo.getUserId();
        // Date validityDate = Date.today(); // Default to today if not set

        List<User> users = [SELECT Contact.AccountId FROM User WHERE Id =:theCurrentUserId LIMIT 1];
        Id accountId = users[0].Contact.AccountId;  
        System.debug('Account Id: ' + accountId); // Debugging line to check the accountId
        // Get all Quote Ids related to the Account
        List<Id> quoteIds = new List<Id>();
        List<Quote> quotes = [SELECT Id FROM Quote WHERE AccountId = :accountId];
         system.debug('quotes Id for before: ' + quotes); 
        for (Quote q : quotes) {
            system.debug('Quote Id for loop before: ' + quoteIds); 
            quoteIds.add(q.Id);
            system.debug('Quote Id for loop: ' + quoteIds); 
        }

        if (quoteIds.isEmpty()) {
            return new List<ContentDocumentLink>();
        }
        system.debug('Quote Ids: ' + quoteIds); // Debugging line to check the quoteIds
        // Query ContentDocumentLinks related to those Quotes
        return [
            SELECT Id, ContentDocumentId, ContentDocument.Title, ContentDocument.FileType, ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :quoteIds
        ];
    }
}