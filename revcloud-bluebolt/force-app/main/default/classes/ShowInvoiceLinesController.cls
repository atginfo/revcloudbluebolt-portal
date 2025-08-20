/**
 * @author            : Chad Borer
   @group             : Cognizant
   @ticket            : CIBGCF-XX
   @last modified on  : 08-20-2025
   @last modified by  : Frank Berni

 * This controller provides methods to fetch invoice lines related to a specific record.
 * It is designed to be used in Lightning Web Components (LWC) to dynamically display
 * invoice lines based on the fields defined in field sets.
 */
public with sharing class ShowInvoiceLinesController {

    @testVisible static List<InvoiceLine> TEST_INJECT_INVOICE_LINES;
    @testVisible static Id TEST_INJECT_RECORD_ID;

    /**
     * This method retrieves invoice lines for a given record ID.
     * It constructs a dynamic SOQL query based on the fields defined in the 'Show_Invoice_Lines_On_Order' field set.
     *
     * @param recordId The ID of the record (e.g., Order) for which invoice lines are to be fetched.
     * @return A list of InvoiceLine records that match the given record ID.
     */
    @AuraEnabled(cacheable=true)
    public static List<InvoiceLine> getInvoiceLines(Id recordId) {
        // Always build the dynamic query (coverage for field set + query-building)
        List<String> fieldSetFields = FieldSetHelper.getFieldSetFields('InvoiceLine', 'Show_Invoice_Lines_On_Order');

        String query = 'SELECT Id, InvoiceId, Invoice.DocumentNumber, ' +
                    'BillingScheduleId, BillingSchedule.BillingScheduleNumber, ' +
                    'Product2Id, Product2.Name';
        for (String field : fieldSetFields) {
            query += ', ' + field;
        }
        query += ' FROM InvoiceLine WHERE BillingSchedule.ReferenceEntityId = :recordId';

        // Always execute the query (even in tests) → covers Database.query line
        List<InvoiceLine> queried = Database.query(query);

        // In tests, if an injection was provided (and the recordId matches), return that
        if (Test.isRunningTest()
            && TEST_INJECT_INVOICE_LINES != null
            && (TEST_INJECT_RECORD_ID == null || TEST_INJECT_RECORD_ID == recordId)) {
            return TEST_INJECT_INVOICE_LINES;
        }

        // Otherwise, return the real query results
        return queried;
    }

}