/**
 * @description       : Test class for AssetVisualizationOnAccount_lwc
 * @author            : Frank Berni
 * @group             : Cognizant
 * @ticket            : CIBGCF-XX
 * @last modified on  : 08-20-2025
 * @last modified by  : Frank Berni
 * @coverage          : 85%
**/
@IsTest
private class AssetVisualizationOnAccount_lwcTest {

    /* ===========================
       Helper: Profiles & Users
       =========================== */

    private static Profile getPortalProfile() {
        // Adjust names to match your org if needed
        return [
            SELECT Id, Name
            FROM Profile
            WHERE Name IN (
                'Customer Community User',
                'Customer Community Login User',
                'Customer Community Plus User',
                'Partner Community User'
            )
            LIMIT 1
        ];
    }

    private static Profile getInternalProfile() {
        // A standard full internal profile to own the Account
        return [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
    }

    private static User createInternalOwnerWithRole() {
        UserRole role = [SELECT Id FROM UserRole LIMIT 1];
        System.assertNotEquals(null, role, 'Org must have at least one UserRole for this test.');

        Profile admin = getInternalProfile();
        String uniq = String.valueOf(Crypto.getRandomInteger());
        User u = new User(
            Alias = 'own' + uniq.substring(0,4),
            Email = 'owner' + uniq + '@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Owner',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/New_York',
            Username = 'owner' + uniq + '@test.com',
            ProfileId = admin.Id,
            UserRoleId = role.Id
        );
        insert u;
        return u;
    }

    private static User createPortalUser(Id contactId) {
        Profile p = getPortalProfile();
        String uniq = String.valueOf(Crypto.getRandomInteger());
        User u = new User(
            Alias = 'port' + uniq.substring(0,4),
            Email = 'portal' + uniq + '@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Portal',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/New_York',
            Username = 'portal' + uniq + '@test.com',
            ProfileId = p.Id,
            // External users usually do NOT have a role:
            ContactId = contactId
        );
        insert u;
        return u;
    }

        /* ===========================
       Helper: Safe field setter
       =========================== */

    // Safely set a field if it exists on the target sObject in this org
    private static void setIfExists(SObject sob, String fieldApi, Object value) {
        Schema.DescribeSObjectResult d = sob.getSObjectType().getDescribe();
        if (d.fields.getMap().containsKey(fieldApi)) {
            sob.put(fieldApi, value);
        }
    }

    /* ===========================
       Helper: Seed domain data
       =========================== */
    private class SeedResult {
        Account acc;
        Contact con;
        User portalUser;
        Asset parentAsset;
        Asset childAsset;
        AssetStatePeriod parentAsp;
        AssetStatePeriod childAsp;
    }

     private static SeedResult seedData() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        SeedResult r = new SeedResult();

        System.runAs(thisUser) {
            // 1) Internal owner WITH a role (required by portal-user creation)
            User ownerWithRole = createInternalOwnerWithRole();

            // 2) Account owned by that user
            r.acc = new Account(Name = 'Acct for Asset Viz', BillingCountry = 'US', OwnerId = ownerWithRole.Id);
            insert r.acc;

            // 3) Contact on that Account
            r.con = new Contact(
                LastName = 'Portal Person',
                AccountId = r.acc.Id,
                Email = 'c+' + String.valueOf(Crypto.getRandomInteger()) + '@test.com'
            );
            insert r.con;

            // 4) Portal user tied to Contact
            r.portalUser = createPortalUser(r.con.Id);

            // 5) Minimal Product (only if your org requires Product2Id on Asset)
            Product2 prod = new Product2(Name = 'Sub Product', IsActive = true);
            insert prod;

            // 6) Parent & child Assets (bundle scenario)
            r.parentAsset = new Asset(
                Name = 'Bundle Parent',
                AccountId = r.acc.Id,
                Product2Id = prod.Id
            );
            r.childAsset = new Asset(
                Name = 'Bundle Child',
                AccountId = r.acc.Id,
                Product2Id = prod.Id
            );
            insert new List<Asset>{ r.parentAsset, r.childAsset };

            // 7) Relate the assets (bundle)
            AssetRelationship rel = new AssetRelationship(
                AssetId = r.parentAsset.Id,
                RelatedAssetId = r.childAsset.Id
            );
            insert rel;

            // Ensure Asset.CurrentMrr is populated (the query sums this field)
            setIfExists(r.parentAsset, 'CurrentMrr', 120);
            setIfExists(r.childAsset,  'CurrentMrr', 80);
            // Persist the changes
            update new List<Asset>{ r.parentAsset, r.childAsset };

            // explicitly set the hierarchy parent
            r.childAsset.ParentId = r.parentAsset.Id;
            update r.childAsset;

            // 8) Valid AssetStatePeriods that include Date.today()
            Date startD = Date.today().addDays(-10);
            Date endD   = Date.today().addDays(10);

            r.parentAsp = new AssetStatePeriod(
                AssetId   = r.parentAsset.Id,
                StartDate = startD,
                EndDate   = endD,
                Quantity  = 1,
                Mrr       = 120
            );
            // Satisfy orgs where Amount (or others) is required
            setIfExists(r.parentAsp, 'Amount', 120);
            setIfExists(r.parentAsp, 'ACV', 120);
            setIfExists(r.parentAsp, 'TCV', 120);
            setIfExists(r.parentAsp, 'TotalAmount', 120);

            r.childAsp = new AssetStatePeriod(
                AssetId   = r.childAsset.Id,
                StartDate = startD,
                EndDate   = endD,
                Quantity  = 2,
                Mrr       = 80
            );
            // Example math: 2 * 80 = 160
            setIfExists(r.childAsp, 'Amount', 160);
            setIfExists(r.childAsp, 'ACV', 160);
            setIfExists(r.childAsp, 'TCV', 160);
            setIfExists(r.childAsp, 'TotalAmount', 160);

            insert new List<AssetStatePeriod>{ r.parentAsp, r.childAsp };
        }

        return r;
    }

    /* ===========================
       Tests
       =========================== */

    @IsTest
    static void test_AllEndpoints_AsPortalUser() {
        SeedResult r = seedData();

        System.runAs(r.portalUser) {
            Test.startTest();

            // --- getAssetAmountDetails(null) ---
            // Should group by Asset.Name and sum MRR from AssetStatePeriod for current user’s Account
            List<AggregateResult> ar = AssetVisualizationOnAccount_lwc.getAssetAmountDetails(null);
            System.assertNotEquals(null, ar, 'Aggregate list should not be null');
            System.assert(ar.size() > 0, 'Should have at least one grouped row');
            // Soft check one field exists
            Decimal anySum = (Decimal)ar[0].get('summedAmount');
            System.assert(anySum >= 0, 'Summed MRR should be non-negative');

            // --- getAssetsList(null) ---
            // Should return ASP rows for the account with Mrr > 0
            List<AssetStatePeriod> aspList = AssetVisualizationOnAccount_lwc.getAssetsList(null);
            System.assertEquals(2, aspList.size(), 'Expected two ASP rows (parent & child)');

            // --- getAssetAndRelatedAssets(null) ---
            // Map<Id, List<AssetStatePeriod>> keyed by parent or standalone Asset Id
            Map<Id, List<AssetStatePeriod>> relMap = AssetVisualizationOnAccount_lwc.getAssetAndRelatedAssets(null);
            System.assertNotEquals(null, relMap, 'Map should not be null');
            System.assert(relMap.containsKey(r.parentAsset.Id) || relMap.containsKey(r.childAsset.Id),
                          'Map should include bundle parent or standalone keys');
            // If parent key is present, its list should include the child ASP (depending on code grouping)
            if (relMap.containsKey(r.parentAsset.Id)) {
                System.assert(relMap.get(r.parentAsset.Id).size() > 0, 'Parent grouping should have entries');
            }

            // --- getAssetAndReletionships(null, null) ---
            // Returns List<Asset> with RelatedAssets and filtered AssetStatePeriods by validity date
            List<Asset> assetsWithRels = AssetVisualizationOnAccount_lwc.getAssetAndReletionships(null, null);
            System.assertNotEquals(null, assetsWithRels, 'Should not be null');
            System.assert(assetsWithRels.size() >= 2, 'Should at least return our parent & child assets');

            Test.stopTest();
        }
    }

    @IsTest
    static void test_getAssets_HardcodedAccount_Behaves() {
        // This method uses a hard-coded AccountId in SOQL, which won't exist in a scratch/test org.
        // It should still safely return a map with keys and empty lists (no exceptions).
        Test.startTest();
        Map<String, List<Asset>> res = AssetVisualizationOnAccount_lwc.getAssets();
        Test.stopTest();

        System.assertNotEquals(null, res, 'Map should not be null even if no data exists');
        System.assert(res.containsKey('standalone'), 'Map should have "standalone" key');
        System.assert(res.containsKey('bundled'), 'Map should have "bundled" key');
        System.assertEquals(0, res.get('standalone').size(), 'No data expected for hard-coded Id');
        System.assertEquals(0, res.get('bundled').size(), 'No data expected for hard-coded Id');
    }
}
