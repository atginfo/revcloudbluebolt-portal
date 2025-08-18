/**
 * InvoiceGenerator class is responsible for generating invoices for given billing schedules.
 * This class provides methods to generate invoices both synchronously and asynchronously.
 * 
 * Example usage:
 * List<Id> billingScheduleIds = new List<Id>{'a0A1t00000XXXXXX', 'a0A1t00000YYYYYY'};
 * InvoiceGenerator.generateInvoices(billingScheduleIds);
 */
public class InvoiceGenerator {
    public static String domain = 'chadborerrlmorg-dev-ed.develop';
    public static String apiVersion = 'v62.0'; // Updated API version
    public static String targetDate = '';
    public static String invoiceDate = DateTime.now().format('yyyy-MM-dd');

    /**
     * Generates invoices for a list of billing schedule IDs asynchronously.
     * 
     * @param billingScheduleIds List of billing schedule IDs to generate invoices for.
     */
    @AuraEnabled
    public static void generateInvoices(List<Id> billingScheduleIds, String targetDate) {
        if (targetDate == null || targetDate == '') {
            targetDate = '2100-01-01';
        }
        generateInvoicesAsync(billingScheduleIds, targetDate);
    }

    @AuraEnabled
    public static void generateInvoicesWithTargetDate(List<Id> billingScheduleIds, String targetDate) {
        // Prevent system crash for any unaccounted scenario where the date is missing
        System.debug('billingScheduleIds 12 Begin: ' + billingScheduleIds);
        if (targetDate == null || targetDate == '') {
            targetDate = '2100-01-01';
        }
        System.debug('billingScheduleIds 12: ' + billingScheduleIds);
        List<Id> allBillingScheduleIds = getBillingSchedules(billingScheduleIds);
        System.debug('allBillingScheduleIds: ' + allBillingScheduleIds);

        if (allBillingScheduleIds.size() > 0 || allBillingScheduleIds != null) {
            System.debug('allBillingScheduleIds: ' + allBillingScheduleIds);
            generateInvoicesAsync(allBillingScheduleIds, targetDate);
        } else {
            generateInvoicesAsync(billingScheduleIds, targetDate);
        }
    }

    /**
     * Asynchronous method to generate invoices for a list of billing schedule IDs.
     * 
     * @param billingScheduleIds List of billing schedule IDs to generate invoices for.
     */
    @future(callout=true)
    public static void generateInvoicesAsync(List<Id> billingScheduleIds, String targetDate) {
        if (targetDate == null || targetDate == '') {
            targetDate = '2100-01-01'; 
        }
        //CHAD 4-29for (Id billingScheduleId : billingScheduleIds) {
            //CHAD 4-29 generateInvoice(billingScheduleId, targetDate);
            generateInvoice(billingScheduleIds, targetDate);
        //CHAD 4-29}
    }

    /**
     * Generates an invoice for a single billing schedule ID by making an HTTP POST request.
     * 
     * @param billingScheduleId The ID of the billing schedule to generate an invoice for.
     */
    //CHAD 4-29 private static void generateInvoice(Id billingScheduleId, String targetDate) {
    private static void generateInvoice(List<Id> billingScheduleIds, String targetDate) {  //CHAD 4-29
        System.debug('billingScheduleIds: ' + billingScheduleIds);
        System.debug('targetDate: ' + targetDate);
        
        String endpoint = 'https://' + domain + '.my.salesforce.com/services/data/' + apiVersion + '/commerce/invoicing/invoices/collection/actions/generate';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');

        Map<String, Object> requestBodyMap = new Map<String, Object>{
            //CHAD 4-29 'billingScheduleIds' => new List<Id>{billingScheduleId},
            'billingScheduleIds' => billingScheduleIds,  //CHAD 4-29
            'action' => 'Posted',
            'targetDate' => targetDate,
            'invoiceDate' => invoiceDate
        };
        String requestBody = JSON.serialize(requestBodyMap);
        req.setHeader('Content-Length', String.valueOf(requestBody.length()));
        req.setBody(requestBody);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 201) {
            System.debug('Invoice created successfully: ' + res.getBody());
        } else if (res.getStatusCode() == 202) {
            System.debug('Invoice creation accepted for processing: ' + res.getBody());
        } else {
            System.debug('Failed to create invoice: ' + res.getStatus() + ' ' + res.getBody());
            handleErrorResponse(res);
        }
    }

    /**
     * Handles error responses from the HTTP request.
     * 
     * @param res The HttpResponse object containing the error details.
     */
    private static void handleErrorResponse(HttpResponse res) {
        Integer statusCode = res.getStatusCode();
        String responseBody = res.getBody();
        System.debug('Error: HTTP ' + statusCode + ' - ' + responseBody);

        if (statusCode == 400) {
            System.debug('Bad Request: ' + responseBody);
        } else if (statusCode == 401) {
            System.debug('Unauthorized: Check your session ID.');
        } else if (statusCode == 403) {
            System.debug('Forbidden: You do not have permission to perform this action.');
        } else if (statusCode == 404) {
            System.debug('Not Found: The endpoint may be incorrect.');
        } else if (statusCode == 500) {
            System.debug('Internal Server Error: Try again later.');
        }
    }

    // public static List<Id> getBillingScheduleGroupIds(List<Id> billingScheduleIds){
    //     return [SELECT  BillingScheduleGroupId FROM BillingSchedule WHERE Id IN :billingScheduleIds];
    // }

    public static List<Id> getBillingSchedules(List<Id> billingScheduleIds){
        List<BillingSchedule> allBillingScheduleIds = [SELECT  BillingScheduleGroupId FROM BillingSchedule WHERE Id IN :billingScheduleIds];//getBillingScheduleGroupIds(billingScheduleIds);
        System.debug('allBillingScheduleIds: ' + allBillingScheduleIds);
        if (!allBillingScheduleIds.isEmpty()){
        List<Id> idList = new List<Id>();
        for (BillingSchedule bs : allBillingScheduleIds){
            idList.add(bs.BillingScheduleGroupId);
        }
        
        System.debug('idList: ' + idList);
            System.debug('billingScheduleIds: ' + billingScheduleIds);

        List<Id> newBillingScheduleIds = new List<Id>();
        for (BillingSchedule bs : [SELECT  Id FROM BillingSchedule WHERE BillingScheduleGroupId IN :idList]){
            newBillingScheduleIds.add(bs.Id);
        }
        System.debug('newBillingScheduleIds: ' + newBillingScheduleIds);
            return newBillingScheduleIds;
        }
        else {
            return null;
        }
    }
}