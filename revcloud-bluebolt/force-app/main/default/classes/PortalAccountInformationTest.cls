/**
 * @description       : Test class for PortalAccountInformation
 * @author            : Frank Berni
 * @group             : Cognizant
 * @ticket            : CIBGCF-XX
 * @last modified on  : 08-20-2025
 * @last modified by  : Frank Berni
 * @coverage          : 90%
**/
@IsTest
private class PortalAccountInformationTest {

    private static Profile getPortalProfile() {
        return [
            SELECT Id, Name
            FROM Profile
            WHERE Name IN (
                'Customer Community User',
                'Customer Community Login User',
                'Customer Community Plus User',
                'Partner Community User'   // ok too, but see note below
            )
            LIMIT 1
        ];
    }

    // Internal owner must have a Role
    private static Profile getInternalProfile() {
        return [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
    }

    // Creates an Admin User with a Role
    private static User createInternalOwnerWithRole() {
        UserRole someRole = [SELECT Id FROM UserRole LIMIT 1];
        Assert.areNotEqual(null, someRole, 'This org needs at least one UserRole for the test.');

        Profile admin = getInternalProfile();
        String uniq = String.valueOf(Crypto.getRandomInteger());
        User u = new User(
            Alias = 'ownr' + uniq.substring(0,4),
            Email = 'owner' + uniq + '@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Owner',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/New_York',
            Username = 'owner' + uniq + '@test.com',
            ProfileId = admin.Id,
            UserRoleId = someRole.Id
        );
        insert u;
        return u;
    }

    @IsTest
    static void testGetAccountDetailsAndContactDetails() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Account acc;
        Contact con;
        User portalUser;

        System.runAs(thisUser) {
            // 1) Internal Admin owner WITH a Role
            User ownerWithRole = createInternalOwnerWithRole();

            // 2) Account owned by that user
            acc = new Account(Name = 'Test Account', BillingCountry = 'US', OwnerId = ownerWithRole.Id);
            insert acc;

            // 3) Contact under that Account
            con = new Contact(
                LastName = 'Test Contact',
                AccountId = acc.Id,
                Email = 'testcontact+' + String.valueOf(Crypto.getRandomInteger()) + '@test.com'
            );
            insert con;

            // 4) Portal/Community user linked to Contact
            Profile p = getPortalProfile();
            String uniq = String.valueOf(Crypto.getRandomInteger());
            portalUser = new User(
                Alias = 'portal',
                Email = 'portaluser' + uniq + '@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Test',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'America/New_York',
                Username = 'portaluser' + uniq + '@test.com',
                ProfileId = p.Id,
                ContactId = con.Id
            );
            insert portalUser;
        }

        System.runAs(portalUser) {
            Test.startTest();
            Account resultAcc = PortalAccountInformation.getAccountDetails();
            Assert.areNotEqual(null, resultAcc);
            Assert.areEqual(acc.Id, resultAcc.Id);

            List<Contact> contacts = PortalAccountInformation.getContactDetails();
            Assert.areNotEqual(null, contacts);
            Assert.areEqual(1, contacts.size());
            Assert.areEqual(con.Id, contacts[0].Id);
            Test.stopTest();
        }
    }

    @IsTest
    static void testDeleteContact() {
        Account acc = new Account(Name = 'Delete Test Account', BillingCountry = 'US');
        insert acc;
        Contact con = new Contact(LastName = 'Delete Contact', AccountId = acc.Id, Email = 'deletecontact@test.com');
        insert con;

        Test.startTest();
        PortalAccountInformation.deleteContact(con.Id);
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Contact WHERE Id = :con.Id]);
    }
}
