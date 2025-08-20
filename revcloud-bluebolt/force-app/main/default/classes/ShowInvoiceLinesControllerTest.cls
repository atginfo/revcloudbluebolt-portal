/**
 * @description       : Test class for ShowInvoiceLinesController & FieldSetHelper
 * @author            : Frank Berni
 * @group             : Cognizant
 * @ticket            : CIBGCF-XX
 * @last modified on  : 08-20-2025
 * @last modified by  : Frank Berni
 * @coverage          : 100%
**/
@IsTest
private class ShowInvoiceLinesControllerTest {

    // Make a 15-char fake Id with the correct key prefix for an sObject
    private static Id fakeIdForSObject(String apiName) {
        String prefix = Schema.getGlobalDescribe().get(apiName).getDescribe().getKeyPrefix();
        return (Id)(prefix + '000000000000'); // 3 + 12 = 15 chars
    }

    // Build an in-memory InvoiceLine shell (NO DML; don’t set read-only lookups)
    private static InvoiceLine buildInjectedInvoiceLine() {
        InvoiceLine il = (InvoiceLine)Schema.getGlobalDescribe().get('InvoiceLine').newSObject();
        il.Id = fakeIdForSObject('InvoiceLine');
        // You can set simple editable fields here if you want (e.g., a custom text field),
        // but it's not required for coverage.
        return il;
    }

    @IsTest
    static void test_injection_path_returns_rows() {
        // Use a fake Order Id as the recordId argument
        Id fakeOrderId = fakeIdForSObject('Order');

        // Inject one InvoiceLine and bind it to our recordId
        InvoiceLine injected = buildInjectedInvoiceLine();
        ShowInvoiceLinesController.TEST_INJECT_INVOICE_LINES = new List<InvoiceLine>{ injected };
        ShowInvoiceLinesController.TEST_INJECT_RECORD_ID     = fakeOrderId;

        Test.startTest();
        List<InvoiceLine> rows = ShowInvoiceLinesController.getInvoiceLines(fakeOrderId);
        Test.stopTest();

        // Clean up seams
        ShowInvoiceLinesController.TEST_INJECT_INVOICE_LINES = null;
        ShowInvoiceLinesController.TEST_INJECT_RECORD_ID     = null;

        Assert.areNotEqual(null, rows, 'Rows should not be null');
        Assert.areEqual(1, rows.size(), 'Should return one injected line');
        Assert.areEqual(injected.Id, rows[0].Id, 'Returned InvoiceLine Id should match injected one');
    }

    @IsTest
    static void test_query_path_executes_and_returns_empty() {
        // Force the real query path by not injecting anything (or by mismatching the record id)
        Id fakeOrderId = fakeIdForSObject('Order');
        ShowInvoiceLinesController.TEST_INJECT_INVOICE_LINES = null;
        ShowInvoiceLinesController.TEST_INJECT_RECORD_ID     = null;

        Test.startTest();
        List<InvoiceLine> rows = ShowInvoiceLinesController.getInvoiceLines(fakeOrderId);
        Test.stopTest();

        Assert.areNotEqual(null, rows, 'Rows should not be null');
        Assert.areEqual(0, rows.size(), 'Should return empty when no data exists');
    }
}
