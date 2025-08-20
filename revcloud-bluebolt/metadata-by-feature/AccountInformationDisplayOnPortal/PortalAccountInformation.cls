/**
 * @description       : Controller for portalAccountInformation LWC
 * @author            : David Sam
 * @group             : Cognizant
 * @ticket            : CIBGCF-XX
 * @last modified on  : 08-20-2025
 * @last modified by  : Frank Berni
**/
public with sharing class PortalAccountInformation {

    @AuraEnabled(cacheable=true)
    public static Account getAccountDetails (){

        ID theCurrentUserId = UserInfo.getUserId();
        // NEW updated to pull related Account basd on current
        List<User> users = [
            SELECT Contact.AccountId 
            FROM User 
            WHERE Id = :theCurrentUserId 
            LIMIT 1
        ];

        Id accountId = users[0].Contact.AccountId;

        Account result = [
            SELECT Id, Name 
            FROM Account 
            WHERE Id = :accountId 
            LIMIT 1
        ];

        System.debug('Current Account: ' + result.Name + ' Id:' + result.Id);
        return result;

        // Date validityDate = Date.today(); // Default to today if not set
        // List<User> users = [SELECT Contact.AccountId FROM User WHERE Id =:theCurrentUserId LIMIT 1];
        // Id accountId = users[0].Contact.AccountId;          // Grab the account Id from the current User
        // return null;
    }

    @AuraEnabled(cacheable=true)
    public static List<Contact> getContactDetails (){

        ID theCurrentUserId = UserInfo.getUserId();
        Date validityDate = Date.today(); // Default to today if not set

        List<User> users = [SELECT Contact.AccountId FROM User WHERE Id =:theCurrentUserId LIMIT 1];
        Id accountId = users[0].Contact.AccountId;          // Grab the account Id from the current User

        // Querry all contacts on the account
        // Note: The query is WITH Security_ENFORCED to ensure that the user has access to the Contact records
        // and that the query respects sharing rules.
        // This is important for security and data privacy, especially in a multi-tenant environment like Salesforce.
        List<Contact> contactsOnTheAccount = [
            SELECT ID,Name, FirstName, LastName, Email, Phone, Fax, AccountId,
                   MobilePhone, OwnerId, Title,Salutation, Department, Account.Name, Owner.Name,
                   Account.AccountNumber
            FROM Contact
            WHERE AccountId =:accountId
            WITH Security_ENFORCED
            ORDER BY FirstName, LastName
        ];
        System.debug('contactsOnTheAccount: ' + contactsOnTheAccount);
         return contactsOnTheAccount;
    }

    // NEW Method to be tied to delete contact row action
    @AuraEnabled
    public static void deleteContact(Id contactId) {
        try {
            delete [SELECT Id FROM Contact WHERE Id = :contactId LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting contact: ' + e.getMessage());
        }
    }
}