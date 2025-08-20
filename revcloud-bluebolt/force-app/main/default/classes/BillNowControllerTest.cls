/**
 * @description       : Test class for BillNowController, FieldSetHelper & ReferenceEntityToOrderItemHelper
 * @author            : Frank Berni
 * @group             : Cognizant
 * @ticket            : CIBGCF-XX
 * @last modified on  : 08-20-2025
 * @last modified by  : Frank Berni
 * @coverage          : 100%
**/
@IsTest
private class BillNowControllerTest {

    // ---------- Seed helpers ----------
    private static Account createAccount() {
        Account a = new Account(Name = 'BillNow Test Acc', BillingCountry = 'US');
        insert a;
        return a;
    }

    // Activate Standard Price Book via the official test helper
    private static Pricebook2 ensureStandardPricebookActive() {
        Id stdId = Test.getStandardPricebookId();
        // In tests, we can update it directly; if it's already active, this is harmless.
        Pricebook2 std = new Pricebook2(Id = stdId, IsActive = true);
        update std;
        // Re-query to return a full record if you want, but not required
        return new Pricebook2(Id = stdId, IsActive = true);
    }

    private static Product2 createProduct() {
        Product2 p = new Product2(Name = 'BillNow Product', IsActive = true);
        insert p;
        return p;
    }

    // Insert the **Standard** price for the product
    private static PricebookEntry createStandardPBE(Pricebook2 stdPb, Product2 p, Decimal unitPrice) {
        PricebookEntry stdPbe = new PricebookEntry(
            Pricebook2Id = stdPb.Id,
            Product2Id   = p.Id,
            UnitPrice    = unitPrice,
            IsActive     = true
        );
        insert stdPbe;
        return stdPbe;
    }

    private static Order createOrder(Account a, Pricebook2 stdPb) {
        Order o = new Order(
            AccountId     = a.Id,
            EffectiveDate = Date.today(),
            Status        = 'Draft',
            Pricebook2Id  = stdPb.Id
        );
        insert o;
        return o;
    }

    private static OrderItem createOrderItem(Order o, PricebookEntry stdPb, Integer qty, Decimal unitPrice) {
        OrderItem oi = new OrderItem(
            OrderId          = o.Id,
            PricebookEntryId = stdPb.Id,
            Quantity         = qty,
            UnitPrice        = unitPrice
        );
        insert oi;
        return oi;
    }

    /* ===========================
    Helpers: injection builders
    =========================== */
    // 15-char fake Id with correct key prefix for a given sObject
    private static Id fakeIdForSObject(String apiName) {
        String prefix = Schema.getGlobalDescribe().get(apiName).getDescribe().getKeyPrefix();
        return (Id)(prefix + '000000000000'); // prefix + 12 zeros = 15 chars
    }

    // Build an in-memory BillingSchedule shell (NO DML, do not set read-only fields)
    private static BillingSchedule buildInjectedBillingSchedule() {
        BillingSchedule bsView = (BillingSchedule)Schema.getGlobalDescribe()
            .get('BillingSchedule').newSObject();
        bsView.Id = fakeIdForSObject('BillingSchedule');
        // Avoid setting ANY read-only fields here
        return bsView;
    }

    // ---------- Tests ----------
    @IsTest
    static void test_getBillingSchedules_returns_rows_via_injection() {
        // Seed minimal Order -> OrderItem with Standard Pricebook
        Account a = createAccount();
        Pricebook2 stdPb  = ensureStandardPricebookActive();
        Product2 prod = createProduct();
        PricebookEntry stdPbe = createStandardPBE(stdPb , prod, 100);
        Order ord = createOrder(a, stdPb );
        OrderItem oi = createOrderItem(ord, stdPbe, 1, 100);

        // Build in-memory BillingSchedule and inject it
        BillingSchedule bsView = buildInjectedBillingSchedule();
        BillNowController.TEST_INJECT_BILLING_SCHEDULES = new List<BillingSchedule>{ bsView };
        BillNowController.TEST_SCHEDULE_TO_ORDERITEM   = new Map<Id, Id>{ bsView.Id => oi.Id };

        Test.startTest();
        List<Map<String, Object>> res = BillNowController.getBillingSchedules(ord.Id);
        Test.stopTest();

        // cleanup
        BillNowController.TEST_INJECT_BILLING_SCHEDULES = null;
        BillNowController.TEST_SCHEDULE_TO_ORDERITEM   = null;

        // assertions
        Assert.areEqual(1, res.size());
        Map<String,Object> row = res[0];
        Assert.areEqual(bsView.Id, (Id)row.get('Id'));
        Assert.areEqual(ord.Id,    (Id)row.get('ReferenceEntityId'));
        Assert.areEqual(oi.Id,     (Id)row.get('ReferenceEntityItemId'));

    }

    @IsTest
    static void test_getBillingSchedules_empty_when_no_matches() {
        Account a = createAccount();
        Pricebook2 stdPb  = ensureStandardPricebookActive();
        Product2 prod = createProduct();
        PricebookEntry stdPbe = createStandardPBE(stdPb , prod, 50);
        Order ord = createOrder(a, stdPb );
        // No BillingSchedule seeded for this order

        Test.startTest();
        List<Map<String, Object>> res = BillNowController.getBillingSchedules(ord.Id);
        Test.stopTest();

        Assert.areNotEqual(null, res, 'Result should not be null');
        Assert.areEqual(0, res.size(), 'Should be empty when no schedules exist');
    }
}
