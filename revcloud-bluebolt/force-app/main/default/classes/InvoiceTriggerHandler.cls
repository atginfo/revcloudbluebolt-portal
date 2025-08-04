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
        attachOrderForInvoice(newList, oldMap);

    }

     /********************************** Helper Methods **********************************/

    //  
    private static void attachOrderForInvoice(List<Invoice> newList, Map<Id, Invoice> oldMap) {
        // Logic to handle after insert events
        System.debug('Handling Order attachment for Invoice after insert');

        Set<Id> invoiceIds = new Set<Id>();

        // Loop through new invoices
        for (Invoice inv : newList) {
            // Put invoice Ids into a set
            invoiceIds.add(inv.Id);
        }

        // query invoices (Id, Order__c) and their invoice line items (BillingSchedule.ReferenceEntityId) based on the matching invoice set
        List<Invoice> invoiceWithLines = [
            SELECT Id, Order__c,
            (
                SELECT Id, BillingScheduleId, BillingSchedule.ReferenceEntityId
                FROM InvoiceLines
            )
            FROM Invoice
            WHERE Id IN :invoiceIds
        ];
        
        for(Invoice inv : invoiceWithLines) {
            // Check if there are any InvoiceLineItems
            if (inv.InvoiceLines.size() > 0) {
                System.debug('Invoice has InvoiceLineItems, attaching Order__c');
                // Get the first InvoiceLineItem's BillingSchedule.ReferenceEntityId
                Id refEntityId = inv.InvoiceLines[0].BillingSchedule.ReferenceEntityId;
                System.debug('refEntityId: ' + refEntityId);

                // Set the Order__c field to the ReferenceEntityId
                inv.Order__c = refEntityId;
            }
        }

        update invoiceWithLines;
        System.debug('Updating Invoices Successful');
    }
}