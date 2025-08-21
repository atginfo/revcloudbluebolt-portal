/**
 * @description       : Test class for PortalMyDocuments
 * @author            : Frank Berni
 * @group             : Cognizant
 * @ticket            : CIBGCF-XX
 * @last modified on  : 08-21-2025
 * @last modified by  : Frank Berni
 * @coverage          : 96%
**/
@IsTest
private class PortalMyDocumentsTest {

    // ---- helpers ----

    private static Account createAccount(String name) {
        Account a = new Account(Name = name, BillingCountry = 'US');
        insert a;
        return a;
    }

    private static Contact createContact(Account a, String lastName) {
        Contact c = new Contact(LastName = lastName, AccountId = a.Id);
        insert c;
        return c;
    }

    private static Opportunity createOpportunity(Account a) {
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = a.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
        return opp;
    }

    private static Quote createQuote(Opportunity opp) {
        Quote q = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id
        );
        insert q;
        return q;
    }

    // Create a ContentDocument (via ContentVersion) and link it to a record
    private static ContentDocumentLink createDocLink(Id linkedEntityId, String title) {
        ContentVersion cv = new ContentVersion(
            Title        = title,
            PathOnClient = title + '.txt',
            VersionData  = Blob.valueOf('hello world')
        );
        insert cv;

        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1]
                   .ContentDocumentId;

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = docId,
            LinkedEntityId    = linkedEntityId,
            ShareType         = 'V',         // Viewer
            Visibility        = 'AllUsers'   // Works in tests
        );
        insert cdl;
        return cdl;
    }

    /* =========
       Tests
       ========= */

    @IsTest
    static void test_getMyInvDocs_accountDocs() {
        Account a = createAccount('Docs Account');
        ContentDocumentLink accLink = createDocLink(a.Id, 'AccDoc');

        Test.startTest();
        List<ContentDocumentLink> rows = PortalMyDocuments.getMyInvoicesDocuments(a.Id);
        Test.stopTest();

        Assert.areNotEqual(null, rows, 'Should not return null');
        Boolean found = false;
        for (ContentDocumentLink r : rows) {
            if (r.ContentDocumentId == accLink.ContentDocumentId) { found = true; break; }
        }
        Assert.isTrue(found, 'Expected account-linked document to be returned');
    }

    @IsTest
    static void test_getMyInvDocs_empty() {
        Account a = createAccount('No Docs Account');

        Test.startTest();
        List<ContentDocumentLink> rows = PortalMyDocuments.getMyInvoicesDocuments(a.Id);
        Test.stopTest();

        Assert.areNotEqual(null, rows, 'Rows should not be null');
        Assert.areEqual(0, rows.size(), 'Expected no documents for this account');
    }

    @IsTest
    static void test_getMyInvDocsByContactId_contactDoc() {
        Account a = createAccount('Contact Docs Account');
        Contact c = createContact(a, 'Contactor');
        ContentDocumentLink contactLink = createDocLink(c.Id, 'ContactDoc');

        Test.startTest();
        List<ContentDocumentLink> rows = PortalMyDocuments.getMyInvoicesDocumentsByContactId(c.Id);
        Test.stopTest();

        Assert.areNotEqual(null, rows, 'Should not return null');
        Boolean found = false;
        for (ContentDocumentLink r : rows) {
            if (r.ContentDocumentId == contactLink.ContentDocumentId) { found = true; break; }
        }
        Assert.isTrue(found, 'Expected contact-linked document to be returned');
    }

    @IsTest
    static void test_getMyInvDocsByContactId_empty() {
        Account a = createAccount('Contact No Docs');
        Contact c = createContact(a, 'NoDocs');

        Test.startTest();
        List<ContentDocumentLink> rows = PortalMyDocuments.getMyInvoicesDocumentsByContactId(c.Id);
        Test.stopTest();

        Assert.areNotEqual(null, rows, 'Rows should not be null');
        Assert.areEqual(0, rows.size(), 'Expected no documents for this contact');
    }

     @IsTest
    static void test_getAccQuoteDocs_injection() {
        Account a = createAccount('Quote Docs Account');
        Opportunity opp = createOpportunity(a);
        Quote q1 = createQuote(opp);
        Quote q2 = createQuote(opp);

        // Link docs to two different Quotes under the same Account
        ContentDocumentLink q1Link = createDocLink(q1.Id, 'Quote1Doc');
        ContentDocumentLink q2Link = createDocLink(q2.Id, 'Quote2Doc');

        // Inject the account so the no-arg method can resolve it in tests
        PortalMyDocuments.TEST_ACCOUNT_ID = a.Id;

        Test.startTest();
        List<ContentDocumentLink> rows = PortalMyDocuments.getAccountQuoteDocuments(); // no args
        Test.stopTest();

        // Clean up seam
        PortalMyDocuments.TEST_ACCOUNT_ID = null;

        Assert.areNotEqual(null, rows, 'Should not return null');
        Boolean found1 = false, found2 = false;
        for (ContentDocumentLink r : rows) {
            if (r.ContentDocumentId == q1Link.ContentDocumentId) found1 = true;
            if (r.ContentDocumentId == q2Link.ContentDocumentId) found2 = true;
        }
        Assert.isTrue(found1 || found2,
            'Expected at least one quote-linked document for the account to be returned');
    }

    @IsTest
    static void test_getAccQuoteDocs_injection_empty() {
        Account a = createAccount('No Quote Docs Account');

        // Inject this account which has no quotes
        PortalMyDocuments.TEST_ACCOUNT_ID = a.Id;

        Test.startTest();
        List<ContentDocumentLink> rows = PortalMyDocuments.getAccountQuoteDocuments(); // no args
        Test.stopTest();

        // Clean seam
        PortalMyDocuments.TEST_ACCOUNT_ID = null;

        Assert.areNotEqual(null, rows, 'Rows should not be null');
        Assert.areEqual(0, rows.size(), 'Expected no quote documents for this account');
    }

    @IsTest
    static void test_getAccQuoteDocs_noInjection() {
        // Do NOT set PortalMyDocuments.TEST_ACCOUNT_ID here — we want the real path
        PortalMyDocuments.TEST_ACCOUNT_ID = null;

        // Run as the default test-running user (internal, no Contact)
        Test.startTest();
        List<ContentDocumentLink> rows = PortalMyDocuments.getAccountQuoteDocuments(); // no args
        Test.stopTest();

        Assert.areNotEqual(null, rows, 'Method should return an empty list, not null');
        Assert.areEqual(0, rows.size(), 'Internal user has no Contact → no account → no quote docs');
    }

}
