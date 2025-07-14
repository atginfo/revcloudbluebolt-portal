/**
 * @description       : Asynchronous process to callout to MuleSoft based on type of payload
 * @author            : Frank Berni
 * @group             : Cognizant
 * @last modified on  : 07-14-2025
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
        // NEW current URL: https://sfdc-netsuite-rev-cloud-api-test2-b0zm8z.5sc6y6-2.usa-e2.cloudhub.io/api
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
