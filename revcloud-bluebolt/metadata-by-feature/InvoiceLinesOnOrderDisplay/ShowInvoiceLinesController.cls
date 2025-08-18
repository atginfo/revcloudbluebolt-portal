/**
 * This controller provides methods to fetch invoice lines related to a specific record.
 * It is designed to be used in Lightning Web Components (LWC) to dynamically display
 * invoice lines based on the fields defined in field sets.
 */
public with sharing class ShowInvoiceLinesController {

    /**
     * This method retrieves invoice lines for a given record ID.
     * It constructs a dynamic SOQL query based on the fields defined in the 'Show_Invoice_Lines_On_Order' field set.
     *
     * @param recordId The ID of the record (e.g., Order) for which invoice lines are to be fetched.
     * @return A list of InvoiceLine records that match the given record ID.
     */
    @AuraEnabled(cacheable=true)
    public static List<InvoiceLine> getInvoiceLines(Id recordId) {
        List<String> fieldSetFields = FieldSetHelper.getFieldSetFields('InvoiceLine', 'Show_Invoice_Lines_On_Order');
        String query = 'SELECT Id, InvoiceId, Invoice.DocumentNumber, BillingScheduleId, BillingSchedule.BillingScheduleNumber, Product2Id, Product2.Name';
        for (String field : fieldSetFields) {
            query += ', ' + field;
        }
        query += ' FROM InvoiceLine WHERE BillingSchedule.ReferenceEntityId = :recordId';
        return Database.query(query);
    }
}