/**
 * @description       : Test class for InvoiceGenerator
 * @author            : Frank Berni
 * @group             : Cognizant
 * @ticket            : CIBGCF-XX
 * @last modified on  : 08-21-2025
 * @last modified by  : Frank Berni
 * @coverage          : 83%
**/
@IsTest
private class InvoiceGeneratorTest {

    /* ==========
       Captured call + config
       ========== */
    private static Integer nextStatus;
    private static String  nextBody;
    private static String  lastEndpoint;
    private static String  lastMethod;
    private static String  lastBody;
    private static Map<String, String> lastHeaders;

     // Accumulate ALL calls (for batching coverage)
    private static Integer callCount;
    private static List<String> allBodies;
    private static List<String> allEndpoints;


    /* ==========
       Inner mock with NO static members
       ========== */
    private class CapturingMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Capture on outer static fields
            InvoiceGeneratorTest.lastEndpoint = req.getEndpoint();
            InvoiceGeneratorTest.lastMethod   = req.getMethod();
            InvoiceGeneratorTest.lastBody     = req.getBody();
            InvoiceGeneratorTest.lastHeaders  = new Map<String, String>{
                'Authorization'  => req.getHeader('Authorization'),
                'Content-Type'   => req.getHeader('Content-Type'),
                'Content-Length' => req.getHeader('Content-Length')
            };

            // Count + collect all
            if (InvoiceGeneratorTest.callCount == null) InvoiceGeneratorTest.callCount = 0;
            InvoiceGeneratorTest.callCount++;
            if (InvoiceGeneratorTest.allBodies == null)    InvoiceGeneratorTest.allBodies    = new List<String>();
            if (InvoiceGeneratorTest.allEndpoints == null) InvoiceGeneratorTest.allEndpoints = new List<String>();
            InvoiceGeneratorTest.allBodies.add(InvoiceGeneratorTest.lastBody);
            InvoiceGeneratorTest.allEndpoints.add(InvoiceGeneratorTest.lastEndpoint);

            // Respond
            HttpResponse res = new HttpResponse();
            res.setStatusCode(InvoiceGeneratorTest.nextStatus);
            res.setBody(InvoiceGeneratorTest.nextBody);
            if (InvoiceGeneratorTest.nextStatus == 201) res.setStatus('Created');
            else if (InvoiceGeneratorTest.nextStatus == 202) res.setStatus('Accepted');
            else if (InvoiceGeneratorTest.nextStatus == 401) res.setStatus('Unauthorized');
            else if (InvoiceGeneratorTest.nextStatus == 403) res.setStatus('Forbidden');
            else if (InvoiceGeneratorTest.nextStatus == 404) res.setStatus('Not Found');
            else if (InvoiceGeneratorTest.nextStatus == 429) res.setStatus('Too Many Requests');
            else if (InvoiceGeneratorTest.nextStatus == 500) res.setStatus('Internal Server Error');
            else res.setStatus('Bad Request');
            return res;
        }
    }

    /* ==========
       Helpers
       ========== */

    // Build a 15-char Id with the correct key prefix for a given sObject
    private static Id fakeIdForSObject(String apiName) {
        String prefix = Schema.getGlobalDescribe().get(apiName).getDescribe().getKeyPrefix();
        return (Id)(prefix + '000000000000'); // 3 + 12 = 15
    }

    private static Map<String, Object> parseBody(String body) {
        return (Map<String, Object>) JSON.deserializeUntyped(body);
    }

    private static Integer countIdsInBodies(List<String> bodies) {
        Integer total = 0;
        if (bodies == null) return 0;
        for (String b : bodies) {
            if (b == null) continue;
            Map<String, Object> req = (Map<String, Object>) JSON.deserializeUntyped(b);
            if (!req.containsKey('billingScheduleIds')) continue;
            Object raw = req.get('billingScheduleIds');
            if (raw == null) continue; 
            List<Object> ids = (List<Object>) raw;
            total += ids.size();
        }
        return total;
    }

    /* ==========
       Tests
       ========== */

    @IsTest
    static void test_genInvoice_201() {
        Id bs1 = fakeIdForSObject('BillingSchedule');
        Id bs2 = fakeIdForSObject('BillingSchedule');

        nextStatus   = 201;
        nextBody     = '{"created":true}';
        lastEndpoint = null; lastMethod = null; lastBody = null; lastHeaders = null;

        Test.setMock(HttpCalloutMock.class, new CapturingMock());

        Test.startTest();
        InvoiceGenerator.generateInvoices(new List<Id>{ bs1, bs2 }, null); // null → default date
        Test.stopTest();

        Assert.areEqual('POST', lastMethod, 'Should POST to the invoices endpoint');
        Assert.areNotEqual(null, lastEndpoint, 'Endpoint should be set');
        Assert.areNotEqual(null, lastBody, 'Body should be present');

        Map<String, Object> req = parseBody(lastBody);
        Assert.isTrue(req.containsKey('billingScheduleIds'), 'Body must include billingScheduleIds');
        Assert.areEqual('2100-01-01', (String)req.get('targetDate'),
            'Null targetDate should default to 2100-01-01');
        List<Object> ids = (List<Object>) req.get('billingScheduleIds');
        Assert.areEqual(2, ids.size(), 'Should send both BillingSchedule Ids');
        Assert.areEqual(String.valueOf(bs1), (String)ids.get(0));
        Assert.areEqual(String.valueOf(bs2), (String)ids.get(1));
    }

    @IsTest
    static void test_genInvoice_202() {
        Id bs = fakeIdForSObject('BillingSchedule');

        nextStatus   = 202;
        nextBody     = '{"accepted":true}';
        lastEndpoint = null; lastMethod = null; lastBody = null; lastHeaders = null;

        Test.setMock(HttpCalloutMock.class, new CapturingMock());

        Test.startTest();
        InvoiceGenerator.generateInvoices(new List<Id>{ bs }, '2025-12-31');
        Test.stopTest();

        Map<String, Object> req = parseBody(lastBody);
        Assert.areEqual('2025-12-31', (String)req.get('targetDate'),
            'Explicit targetDate should be used');
        Assert.areEqual(1, ((List<Object>)req.get('billingScheduleIds')).size(),
            'Should send one BillingSchedule Id');
    }

    @IsTest
    static void test_genInvoice_400() {
        Id bs = fakeIdForSObject('BillingSchedule');

        nextStatus   = 400;
        nextBody     = '{"error":"bad request"}';
        lastEndpoint = null; lastMethod = null; lastBody = null; lastHeaders = null;

        Test.setMock(HttpCalloutMock.class, new CapturingMock());

        Test.startTest();
        InvoiceGenerator.generateInvoices(new List<Id>{ bs }, '2099-01-01');
        Test.stopTest();

        Assert.areEqual('POST', lastMethod);
        Assert.areNotEqual(null, lastBody, 'Request body should be captured even on error');
    }

    @IsTest
    static void test_genInvoice_401() {
        Id bs = fakeIdForSObject('BillingSchedule');

        nextStatus   = 401;
        nextBody     = '{"error":"unauthorized"}';
        lastEndpoint = null; lastMethod = null; lastBody = null; lastHeaders = null;

        Test.setMock(HttpCalloutMock.class, new CapturingMock());

        Test.startTest();
        InvoiceGenerator.generateInvoices(new List<Id>{ bs }, '2099-02-02');
        Test.stopTest();

        Assert.areEqual('POST', lastMethod);
        Assert.areNotEqual(null, lastBody);
    }

    @IsTest
    static void test_genInvoice_403() {
        Id bs = fakeIdForSObject('BillingSchedule');

        nextStatus   = 403;
        nextBody     = '{"error":"forbidden"}';
        lastEndpoint = null; lastMethod = null; lastBody = null; lastHeaders = null;

        Test.setMock(HttpCalloutMock.class, new CapturingMock());

        Test.startTest();
        InvoiceGenerator.generateInvoices(new List<Id>{ bs }, '2099-06-06');
        Test.stopTest();

        Assert.areEqual('POST', lastMethod);
        Assert.areNotEqual(null, lastBody);
    }

    @IsTest
    static void test_genInvoice_404() {
        Id bs = fakeIdForSObject('BillingSchedule');

        nextStatus   = 404;
        nextBody     = '{"error":"not found"}';
        lastEndpoint = null; lastMethod = null; lastBody = null; lastHeaders = null;

        Test.setMock(HttpCalloutMock.class, new CapturingMock());

        Test.startTest();
        InvoiceGenerator.generateInvoices(new List<Id>{ bs }, '2099-07-07');
        Test.stopTest();

        Assert.areEqual('POST', lastMethod);
        Assert.areNotEqual(null, lastBody);
    }

    @IsTest
    static void test_genInvoice_429() {
        Id bs = fakeIdForSObject('BillingSchedule');

        nextStatus   = 429;
        nextBody     = '{"error":"rate limited"}';
        lastEndpoint = null; lastMethod = null; lastBody = null; lastHeaders = null;

        Test.setMock(HttpCalloutMock.class, new CapturingMock());

        Test.startTest();
        InvoiceGenerator.generateInvoices(new List<Id>{ bs }, '2099-09-09');
        Test.stopTest();

        Assert.areEqual('POST', lastMethod);
        Assert.areNotEqual(null, lastBody);
    }

    @IsTest
    static void test_genInvoice_500() {
        Id bs = fakeIdForSObject('BillingSchedule');

        nextStatus   = 500;
        nextBody     = '{"error":"server"}';
        lastEndpoint = null; lastMethod = null; lastBody = null; lastHeaders = null;

        Test.setMock(HttpCalloutMock.class, new CapturingMock());

        Test.startTest();
        InvoiceGenerator.generateInvoices(new List<Id>{ bs }, '2099-03-03');
        Test.stopTest();

        Assert.areEqual('POST', lastMethod);
        Assert.areNotEqual(null, lastBody);
    }

    @IsTest
    static void test_genInvoice_nullListPosts_nullArray() {
        nextStatus   = 201;
        nextBody     = '{"created":true}';
        lastEndpoint = null; lastMethod = null; lastBody = null; lastHeaders = null;
        callCount = 0; allBodies = new List<String>(); allEndpoints = new List<String>();
        Test.setMock(HttpCalloutMock.class, new CapturingMock());

        Test.startTest();
        InvoiceGenerator.generateInvoices(null, '2099-04-04');
        Test.stopTest();

        Assert.areEqual('POST', lastMethod, 'Expect POST even if list is null');
        Map<String, Object> req = parseBody(lastBody);
        Assert.isTrue(req.containsKey('billingScheduleIds'), 'Key must exist even when null');
        Assert.areEqual(null, req.get('billingScheduleIds'), 'billingScheduleIds should be null');
    }

    @IsTest
    static void test_genInvoice_emptyListPosts_emptyArray() {
        nextStatus   = 201;
        nextBody     = '{"created":true}';
        lastEndpoint = null; lastMethod = null; lastBody = null; lastHeaders = null;
        callCount = 0; allBodies = new List<String>(); allEndpoints = new List<String>();
        Test.setMock(HttpCalloutMock.class, new CapturingMock());

        Test.startTest();
        InvoiceGenerator.generateInvoices(new List<Id>(), '2099-05-05');
        Test.stopTest();

        Assert.areEqual('POST', lastMethod, 'Expect POST even if list is empty');
        Map<String, Object> req = parseBody(lastBody);
        Assert.isTrue(req.containsKey('billingScheduleIds'), 'Key must exist');
        List<Object> ids = (List<Object>) req.get('billingScheduleIds');
        Assert.areEqual(0, ids.size(), 'Should be an empty array in the payload');
    }

    @IsTest
    static void test_genInvoice_blankTargetDateDefaultsHeaders() {
        Id bs = fakeIdForSObject('BillingSchedule');

        nextStatus   = 201;
        nextBody     = '{"created":true}';
        lastEndpoint = null; lastMethod = null; lastBody = null; lastHeaders = null;

        Test.setMock(HttpCalloutMock.class, new CapturingMock());

        Test.startTest();
        // Pass empty string to trigger default path (treat as "not provided")
        InvoiceGenerator.generateInvoices(new List<Id>{ bs }, '');
        Test.stopTest();

        Assert.areEqual('POST', lastMethod);

        Map<String, Object> req = parseBody(lastBody);
        Assert.areEqual('2100-01-01', (String)req.get('targetDate'),
            'Blank targetDate should default to 2100-01-01');

        if (lastHeaders != null) {
            Assert.areEqual('application/json', lastHeaders.get('Content-Type'));
            if (lastHeaders.get('Content-Length') != null) {
                Assert.areEqual(String.valueOf(lastBody.length()), lastHeaders.get('Content-Length'),
                    'Content-Length should match body length');
            }
        }
    }

    @IsTest
    static void test_genInvoice_largeListBatches() {
        // Create a large list; if batching exists, multiple posts happen; if not, one post
        List<Id> many = new List<Id>();
        for (Integer i = 0; i < 401; i++) {
            many.add(fakeIdForSObject('BillingSchedule'));
        }

        nextStatus   = 201;
        nextBody     = '{"created":true}';
        lastEndpoint = null; lastMethod = null; lastBody = null; lastHeaders = null;
        callCount = 0; allBodies = new List<String>(); allEndpoints = new List<String>();
        Test.setMock(HttpCalloutMock.class, new CapturingMock());

        Test.startTest();
        InvoiceGenerator.generateInvoices(many, '2099-08-08');
        Test.stopTest();

        // At least one POST should happen
        Assert.isTrue(callCount >= 1, 'Expected at least one callout');
        // Total IDs across all payloads should equal input
        Integer totalIdsSent = countIdsInBodies(allBodies);
        Assert.areEqual(401, totalIdsSent, 'All IDs should be sent across one or more requests');
    }

    @IsTest
    static void test_syncSeam_genInvoicesWithTargetDate() {
        // Arrange: mock callout
        nextStatus   = 201;
        nextBody     = '{"created":true}';
        lastEndpoint = null; lastMethod = null; lastBody = null; lastHeaders = null;
        Test.setMock(HttpCalloutMock.class, new CapturingMock());

        // These are the IDs we pass in
        List<Id> inputIds = new List<Id>{
            fakeIdForSObject('BillingSchedule'),
            fakeIdForSObject('BillingSchedule'),
            fakeIdForSObject('BillingSchedule')
        };

        // Inject a non-null expanded list so getBillingSchedules(...) returns something
        InvoiceGenerator.TEST_INJECT_BS_FOR_GET = new List<Id>(inputIds);

        // Activate sync seam so we hit generateInvoicesWithTargetDate(...) directly
        InvoiceGenerator.TEST_CALL_SYNC = true;

        Test.startTest();
        InvoiceGenerator.generateInvoices(inputIds, '2030-12-31');
        Test.stopTest();

        // Cleanup seams
        InvoiceGenerator.TEST_CALL_SYNC        = false;
        InvoiceGenerator.TEST_INJECT_BS_FOR_GET = null;

        // Assertions: POST happened and body contains all ids + explicit date
        Assert.areEqual('POST', lastMethod);
        Map<String,Object> req = (Map<String,Object>) JSON.deserializeUntyped(lastBody);
        Assert.areEqual('2030-12-31', (String)req.get('targetDate'));
        List<Object> sent = (List<Object>) req.get('billingScheduleIds');
        Assert.areEqual(3, sent.size(), 'All IDs should be sent in sync path');
    }


    @IsTest
    static void test_getBillSchedules_queryExecutes_returnsNull() {
        // Force real query path (no injection)
        InvoiceGenerator.TEST_INJECT_BS_FOR_GET = null;

        // Use a fake BillingSchedule Id so the SOQL executes but returns 0 rows
        List<Id> input = new List<Id>{ fakeIdForSObject('BillingSchedule') };

        Test.startTest();
        List<Id> got = InvoiceGenerator.getBillingSchedules(input);
        Test.stopTest();

        // Your method returns NULL when no rows are found
        Assert.areEqual(null, got, 'Expected null when no BillingSchedules match');
    }

    @IsTest
    static void test_getBillSchedules_injectionPath_returnsRows() {
        // Prepare injected return (no DML needed)
        List<Id> injected = new List<Id>{
            fakeIdForSObject('BillingSchedule'),
            fakeIdForSObject('BillingSchedule')
        };
        InvoiceGenerator.TEST_INJECT_BS_FOR_GET = injected;

        // Call with any non-null list so the SOQL line still executes for coverage
        List<Id> input = new List<Id>{ fakeIdForSObject('BillingSchedule') };

        Test.startTest();
        List<Id> got = InvoiceGenerator.getBillingSchedules(input);
        Test.stopTest();

        // Cleanup seam
        InvoiceGenerator.TEST_INJECT_BS_FOR_GET = null;

        Assert.areEqual(2, got.size(), 'Injected two BillingSchedule Ids');
        Assert.areEqual(injected, got, 'Should return exactly the injected list');
    }

}

