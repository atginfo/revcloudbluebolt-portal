/**
 * @description       : 
 * @author            : David Sam
 * @group             : Cognizant
 * @ticket            : CIBGCF-XX
 * @last modified on  : 06-23-2025
 * @last modified by  : David Sam
**/
public with sharing class PortalAccountInformation {
    public PortalAccountInformation() {

    }

     @AuraEnabled(cacheable=true)
    public static List<Account> getAccountDetails (){

        ID theCurrentUserId = UserInfo.getUserId();
        Date validityDate = Date.today(); // Default to today if not set

        List<User> users = [SELECT Contact.AccountId FROM User WHERE Id =:theCurrentUserId LIMIT 1];
        Id accountId = users[0].Contact.AccountId;          // Grab the account Id from the current User
        return null;

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
}