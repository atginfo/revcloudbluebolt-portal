/**
 * @description       : Asynchronous process to callout to MuleSoft based on type of payload
 * @author            : Frank Berni
 * @group             : Cognizant
 * @last modified on  : 07-18-2025
 * @last modified by  : Frank Berni
**/
public class MuleSoftCalloutJob implements Queueable, Database.AllowsCallouts {
    private String endpoint;
    private Map<String, Object> payload;

    public MuleSoftCalloutJob(String endpoint, Map<String, Object> payload) {
        this.endpoint = endpoint;
        this.payload = payload;
    }

    public void execute(QueueableContext context) {
        HttpRequest req = new HttpRequest();
        // Uses MuleSoft_Integration Named Credential URL: 
        // NEW current URL: https://sf-netsuite-revcloud-esulje.2tku8l.usa-e1.cloudhub.io
        req.setEndpoint('callout:MuleSoft_Integration' + endpoint);
        req.setMethod('PUT');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload));

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('MuleSoft response for ' + endpoint + ': ' + res.getBody());
        } catch (Exception e) {
            System.debug('Callout failed for ' + endpoint + ': ' + e.getMessage());
        }
    }
}
