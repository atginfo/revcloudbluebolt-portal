/**
 * @description       : Asynchronous process to callout to MuleSoft based on type of payload and stamps Netsuite Id upon success
 * @author            : Frank Berni
 * @group             : Cognizant
 * @last modified on  : 07-30-2025
 * @last modified by  : Frank Berni
**/
public class MuleSoftCalloutJob implements Queueable, Database.AllowsCallouts {
    private String endpoint;
    private Map<String, Object> payload;
    // NEW private class variables for recordId and objectType
    private Id recordId;
    private String objectType;

    // TODO to be deprecated
    public MuleSoftCalloutJob(String endpoint, Map<String, Object> payload) {
        this(endpoint, payload, null, null);
    }

    // NEW constructor handles SObject and stamps NSId
    public MuleSoftCalloutJob(String endpoint, Map<String, Object> payload, Id recordId, String objectType) {
        this.endpoint = endpoint;
        this.payload = payload;
        // NEW writing private variables based on parameters
        this.recordId = recordId;
        this.objectType = objectType;
    }

    public void execute(QueueableContext context) {
        HttpRequest req = new HttpRequest();
        // Uses MuleSoft_Integration Named Credential URL: 
        // current URL: https://sf-netsuite-revcloud-esulje.2tku8l.usa-e1.cloudhub.io/api
        req.setEndpoint('callout:MuleSoft_Integration' + endpoint);
        req.setMethod('PUT');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload));
        // NEW using setTimeout to avoid timeout issues when stamping NS Id
        req.setTimeout(90000);

        Http http = new Http();
        HttpResponse res = new HttpResponse();

        // NEW Attempting the callout first
        try {
            res = http.send(req);
            String body = res.getBody();
            // Log response in chunks
            Integer chunkSize = 1000;
            for (Integer i=0; i < body.length(); i+=chunkSize) {
                Integer ending = Math.min(i + chunkSize, body.length());
                System.debug('MuleSoft response for ' + endpoint);
                System.debug('MuleSoft response chunk: ' + body.substring(i, ending));
            }
            System.debug('Payload from Netsuite received. Attempting to update record.');
            
        } 
        catch (Exception e) {
            System.debug('Callout failed for ' + endpoint + ': ' + e.getMessage());
        }

        
        System.debug(res.getStatusCode());
        // System.debug(recordId);
        // System.debug(objectType);

        // NEW Then checking if Response is populated before proceeding
        if(res != null && res.getStatusCode() == 200 && recordId != null && objectType != null) {
            // grab json and translate to list of objects
            List<Object> responsePayload = (List<Object>) JSON.deserializeUntyped(res.getBody());
            System.debug(responsePayload);
            if (!responsePayload.isEmpty()) {
                System.debug('responsePayload is populated. Processing...');
                // grabbing netsuite Id from json
                Map<String, Object> firstRecord = (Map<String, Object>) responsePayload[0];
                if (firstRecord.containsKey('id')) {
                    String nsId = String.valueOf(firstRecord.get('id'));
                    System.debug('Netsuite Id: ' + nsId);

                    // Determine what objectType then update existing record with new Netsuite Id
                    if (objectType == 'Account') {
                        Account accToUpdate = new Account(Id = recordId, Netsuite_Id__c = nsId);
                        update accToUpdate;
                        System.debug('Account Update Successful: ' + recordId);
                    } else if (objectType == 'Product2') {
                        Product2 prodToUpdate = new Product2(Id = recordId, Netsuite_Id__c = nsId);
                        update prodToUpdate;
                        System.debug('Product Update Successful: ' + recordId);
                    // NEW added handling for Order and Invoice records
                    } else if (objectType == 'Order') {
                        Order orderToUpdate = new Order(Id = recordId, Netsuite_Id__c = nsId);
                        update orderToUpdate;
                        System.debug('Order Update Successful: ' + recordId);
                    } else if (objectType == 'Invoice') {
                        Invoice invoiceToUpdate = new Invoice(Id = recordId, Netsuite_Id__c = nsId);
                        update invoiceToUpdate;
                        System.debug('Invoice Update Successful: ' + recordId);
                    }
                }
            }
        }
    }
}
