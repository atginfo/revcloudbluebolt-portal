/**
 * @description       : Controller for managing documents related to invoices in the portal.
 * @author            : David Sam
 * @group             : Cognizant
 * @ticket            : CIBGCF-XX
 * @last modified on  : 08-21-2025
 * @last modified by  : Frank Berni
**/
public with sharing class PortalMyDocuments {

    @testVisible static Id TEST_ACCOUNT_ID;
    
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

        // Resolve accountId
        Id accountId;
        if (Test.isRunningTest() && TEST_ACCOUNT_ID != null) {
            accountId = TEST_ACCOUNT_ID; // test seam
        } else {
            Id theCurrentUserId = UserInfo.getUserId();
            List<User> users = [
                SELECT Contact.AccountId
                FROM User
                WHERE Id = :theCurrentUserId
                LIMIT 1
            ];
            accountId = (users.isEmpty() || users[0].Contact == null)
                ? null
                : users[0].Contact.AccountId;
        }

        if (accountId == null) {
            return new List<ContentDocumentLink>(); // nothing to do
        }

        // Get all Quotes on the Account
        List<Quote> quotes = [SELECT Id FROM Quote WHERE AccountId = :accountId];

        if (quotes.isEmpty()) {
            return new List<ContentDocumentLink>();
        }

        List<Id> quoteIds = new List<Id>();
        for (Quote q : quotes) quoteIds.add(q.Id);

        // Return document links on those quotes
        return [
            SELECT Id, ContentDocumentId,
                   ContentDocument.Title, ContentDocument.FileType,
                   ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :quoteIds
        ];
    }
}