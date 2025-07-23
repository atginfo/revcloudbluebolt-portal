/**
 * @description       : Prepares payloads for either Account, Product, Order or Invoice and sends to Netsuite (MuleSoft)
 * @author            : Frank Berni
 * @group             : Cognizant
 * @last modified on  : 07-23-2025
 * @last modified by  : Frank Berni
**/
public with sharing class MuleSoftIntegrationService {

    // Shared method for callouts
    private static void sendPayload(String endpoint, Map<String, Object> payload) {
        // NEW using enqueue to avoid direct callouts in triggers
        System.enqueueJob(new MuleSoftCalloutJob(endpoint, payload));
    }

    public static void sendAccountToMuleSoft(Id accountId) {

        // Querying account
        Account acc = [
            SELECT Id, Name, ParentId, Phone, Fax, Website, Subsidiary__c, VAT_GST_ID__c, 
                   BillingStreet, BillingCity, BillingState, BillingPostalCode,
                   BillingCountry, Sync_to_Netsuite__c, Active__c, Industry,
                   Owner.Name, Owner.Email, AccountNumber
            FROM Account
            WHERE Id = :accountId
        ];

        // If Sync to Netsuite is false, don't do anything
        if (!acc.Sync_to_Netsuite__c) return;

        // Creating Map, Object for all Account Fields to send to Netsuite
        Map<String, Object> payload = new Map<String, Object>{
            'Id' => acc.Id,
            'Name' => acc.Name,
            'ParentId' => acc.ParentId,
            'Phone' => acc.Phone,
            'Fax' => acc.Fax,
            'Website' => acc.Website,
            'Subsidiary__c' => acc.Subsidiary__c,
            // CurrencyIsoCode will always be USD
            'CurrencyIsoCode' => 'USD',
            'VAT_GST_ID__c' => acc.VAT_GST_ID__c,
            'BillingStreet' => acc.BillingStreet,
            'BillingCity' => acc.BillingCity,
            'BillingState' => acc.BillingState,
            'BillingPostalCode' => acc.BillingPostalCode,
            'BillingCountry' => acc.BillingCountry,
            'Industry' => acc.Industry,
            'Active__c' => acc.Active__c,
            'OwnerName' => acc.Owner != null ? acc.Owner.Name : null,
            'OwnerEmail' => acc.Owner != null ? acc.Owner.Email : null,
            'AccountNumber' => acc.AccountNumber
        };

        // Send payload using /customer as endpoint
        System.debug('Account Payload: ' + payload);
        sendPayload('/customer', payload);
    }

    public static void sendProductToMuleSoft(Id productId) {

        // Querying Product2
        Product2 prod = [
            SELECT Id, Name, ProductCode, Description, NS_Internal_ID__c, Item_Type__c,
                   Sub_Type__c, IsActive, Subsidiary__c, Family, Type, Sync_to_Netsuite__c
            FROM Product2
            WHERE Id = :productId
        ];

        // If Sync to Netsuite is false, don't do anything
        if (!prod.Sync_to_Netsuite__c) return;

        // Creating Map, Object for all Product Fields to send to Netsuite
        Map<String, Object> payload = new Map<String, Object>{
            'Id' => prod.Id,
            'Name' => prod.Name,
            'ProductCode' => prod.ProductCode,
            'Description' => prod.Description,
            'NS_Internal_ID__c' => prod.NS_Internal_ID__c,
            'Item_Type__c' => prod.Item_Type__c,
            'Sub_Type__c' => prod.Sub_Type__c,
            'IsActive' => prod.IsActive,
            'Subsidiary__c' => prod.Subsidiary__c,
            'Family' => prod.Family,
            'ProductType' => prod.Type
        };

        // Send payload using /item as endpoint
        System.debug('Product Payload: ' + payload);
        // NEW updated to product
        sendPayload('/product', payload);
    }

    public static void sendOrderToMuleSoft(Id orderId) {

        // Querying Order with OrderItems
        Order ord = [
            SELECT Id, EffectiveDate, OrderNumber, PoNumber, EndDate, 
                   Bill_To_Address_ID__c, BillingStreet, BillingCity, BillingState, BillingPostalCode,
                   BillingCountry, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode,
                   ShippingCountry, 
                   Ship_To_Address_ID__c, 
                   ActivatedDate, Description, Payment_Term__c,
                   Subsidiary__c, Sync_to_Netsuite__c,
                   AccountId, Account.Name, Account.Phone, Contract.Id, CreatedDate,
                    // NEW add new query fields for mapping
                   Account.AccountNumber, BillToContactId, BillToContact.Name,
                   (SELECT Quantity, UnitPrice, ServiceDate, Product2.Name, Product2.Type, Product2.Family, Order_Item_Type__c,
                    TotalPrice, SBQQ__TaxAmount__c, SBQQ__TaxCode__c, TaxRate__c, Id, NetUnitPrice, BillingFrequency2, SBQQ__Contract__c, 
                    SBQQ__Contract__r.EndDate, SBQQ__Contract__r.StartDate FROM OrderItems),
                   (SELECT BillingScheduleNumber, BillingPeriodAmount, BillingTerm, BillingTermUnit FROM BillingSchedules)
            FROM Order
            WHERE Id = :orderId
        ];

        // If Sync to Netsuite is false, don't do anything
        if (!ord.Sync_to_Netsuite__c) return;

        // Creating List of Map, Object for all OrderItem Fields
        List<Map<String, Object>> lineItems = new List<Map<String, Object>>();
        for (OrderItem item : ord.OrderItems) {
            lineItems.add(new Map<String, Object>{
                'Id' => item.Id,
                'ProductName' => item.Product2 != null ? item.Product2.Name : null,
                'Quantity' => item.Quantity,
                'UnitPrice' => item.UnitPrice,
                'ServiceDate' => item.ServiceDate,
                'ProductType' => item.Product2 != null ? item.Product2.Type : null,
                'ProductFamily' => item.Product2 != null ? item.Product2.Family : null,
                'OrderItemType' => item.Order_Item_Type__c,
                // NEW added more fields missing from mapping
                'TotalPrice' => item.TotalPrice,
                'NetUnitPrice' => item.NetUnitPrice,
                'TaxAmount' => item.SBQQ__TaxAmount__c,
                'TaxCode' => item.SBQQ__TaxCode__c,
                'TaxRate' => item.TaxRate__c,
                'BillingFrequency' => item.BillingFrequency2,
                // TODO Kevin to confirm if proper StartDate field is needed
                'ContractStartDate' => item.SBQQ__Contract__c != null ? item.SBQQ__Contract__r.StartDate : null,
                'ContractEndDate' => item.SBQQ__Contract__c != null ? item.SBQQ__Contract__r.EndDate : null
            });
        }

        // Creating List of Map, Object for all BillingSchedule Fields
        List<Map<String, Object>> billingSchedules = new List<Map<String, Object>>();
        for (BillingSchedule bs : ord.BillingSchedules) {
            billingSchedules.add(new Map<String, Object>{
                'BillingScheduleNumber' => bs.BillingScheduleNumber,
                'BillingPeriodAmount' => bs.BillingPeriodAmount,
                'BillingTerm' => bs.BillingTerm,
                'BillingTermUnit' => bs.BillingTermUnit
            });
        }

        // Creating Map, Object for all Order Fields to send to Netsuite
        Map<String, Object> payload = new Map<String, Object>{
            'Id' => ord.Id,
            'OrderNumber' => ord.OrderNumber,
            'EffectiveDate' => ord.EffectiveDate,
            'PoNumber' => ord.PoNumber,
            'EndDate' => ord.EndDate,
            // CurrencyIsoCode will always be USD
            'CurrencyIsoCode' => 'USD',
            // NEW
            'BillToAddressID' => ord.Bill_To_Address_ID__c,
            'BillingStreet' => ord.BillingStreet,
            'BillingCity' => ord.BillingCity,
            'BillingState' => ord.BillingState,
            'BillingPostalCode' => ord.BillingPostalCode,
            'BillingCountry' => ord.BillingCountry,
            'ShipToAddressId' => ord.Ship_To_Address_ID__c,
            'ShippingStreet' => ord.ShippingStreet,
            'ShippingCity' => ord.ShippingCity,
            'ShippingState' => ord.ShippingState,
            'ShippingPostalCode' => ord.ShippingPostalCode,
            'ShippingCountry' => ord.ShippingCountry,
            'ActivatedDate' => ord.ActivatedDate,
            'Description' => ord.Description,
            'Payment_Term__c' => ord.Payment_Term__c,
            'Subsidiary__c' => ord.Subsidiary__c,
            // NEW updated payload mappinh with missing Order fields
            'AccountName' => ord.AccountId != null ? ord.Account.Name : null,
            'AccountPhone' => ord.AccountId != null ? ord.Account.Phone : null,
            'ContractId' => ord.ContractId,
            'BillToContactName' => ord.BillToContactId != null ? ord.BillToContact.Name : null,
            'AccountNumber' => ord.AccountId != null ? ord.Account.AccountNumber : null,
            'CreatedDate' => ord.CreatedDate,
            // Using List of Map, Object created from OrderItems
            'LineItems' => lineItems,
            'BillingSchedules' => billingSchedules
        };

        // Send payload using /salesorder as endpoint
        System.debug('Order Payload: ' + payload);
        // NEW updated endpoint to order
        sendPayload('/order', payload);
    }

    public static void sendInvoiceToMuleSoft(Id invoiceId) {

        // Querying Invoice with Invoice Lines
        Invoice invoice = [
            SELECT Id, InvoiceDate, DocumentNumber, DueDate, PostedDate, Payment_Term__c,
                   Subsidiary__c, Sync_to_Netsuite__c, Description,
                   Order__r.Order_Name__c, Order__r.Type, Order__r.OrderNumber,
                   BillingAccount.Name, BillingAccount.Phone,
                   BillingAccount.BillingAddress, BillingAccount.BillingCity, BillingAccount.BillingState,
                   BillingAccount.BillingPostalCode, BillingAccount.BillingCountry,
                   BillingAccount.ShippingAddress, BillingAccount.ShippingCity, BillingAccount.ShippingState,
                   BillingAccount.ShippingPostalCode, BillingAccount.ShippingCountry,
                   BillToContact.Name,
                   (SELECT Id, Description, LineAmount, Quantity,
                           Product2.Name, Product2.Family, Product2.Type,
                           Product2.BasedOnId, Order_Product_del__r.OrderId
                    FROM InvoiceLines)
            FROM Invoice
            WHERE Id = :invoiceId
        ];

        // If Sync to Netsuite is false, don't do anything
        if (!invoice.Sync_to_Netsuite__c) return;

        // Creating List of Map, Object for all Invoice Line Fields
        List<Map<String, Object>> lineItems = new List<Map<String, Object>>();
        for (InvoiceLine line : invoice.InvoiceLines) {
            lineItems.add(new Map<String, Object>{
                'Id' => line.Id,
                'Description' => line.Description,
                'LineAmount' => line.LineAmount,
                'Quantity' => line.Quantity,
                'ProductName' => line.Product2 != null ? line.Product2.Name : null,
                'ProductFamily' => line.Product2 != null ? line.Product2.Family : null,
                'ProductType' => line.Product2 != null ? line.Product2.Type : null,
                'ProductBasedOnId' => line.Product2 != null ? line.Product2.BasedOnId : null,
                'OrderId' => line.Order_Product_del__r.OrderId
            });
        }

        // Creating Map, Object for all Invoice Fields to send to Netsuite
        Map<String, Object> payload = new Map<String, Object>{
            'Id' => invoice.Id,
            'InvoiceDate' => invoice.InvoiceDate,
            'DocumentNumber' => invoice.DocumentNumber,
            'DueDate' => invoice.DueDate,
            'PostedDate' => invoice.PostedDate,
            'PaymentTerm' => invoice.Payment_Term__c,
            'Subsidiary' => invoice.Subsidiary__c,
            'Description' => invoice.Description,
            'OrderName' => invoice.Order__r != null ? invoice.Order__r.Order_Name__c : null,
            'OrderType' => invoice.Order__r != null ? invoice.Order__r.Type : null,
            'OrderNumber' => invoice.Order__r != null ? invoice.Order__r.OrderNumber : null,
            'BillingAccountName' => invoice.BillingAccount != null ? invoice.BillingAccount.Name : null,
            'BillingAccountPhone' => invoice.BillingAccount != null ? invoice.BillingAccount.Phone : null,
            'BillingAddress' => invoice.BillingAccount != null ? invoice.BillingAccount.BillingAddress : null,
            'BillingCity' => invoice.BillingAccount != null ? invoice.BillingAccount.BillingCity : null,
            'BillingState' => invoice.BillingAccount != null ? invoice.BillingAccount.BillingState : null,
            'BillingPostalCode' => invoice.BillingAccount != null ? invoice.BillingAccount.BillingPostalCode : null,
            'BillingCountry' => invoice.BillingAccount != null ? invoice.BillingAccount.BillingCountry : null,
            'ShippingAddress' => invoice.BillingAccount != null ? invoice.BillingAccount.ShippingAddress : null,
            'ShippingCity' => invoice.BillingAccount != null ? invoice.BillingAccount.ShippingCity : null,
            'ShippingState' => invoice.BillingAccount != null ? invoice.BillingAccount.ShippingState : null,
            'ShippingPostalCode' => invoice.BillingAccount != null ? invoice.BillingAccount.ShippingPostalCode : null,
            'ShippingCountry' => invoice.BillingAccount != null ? invoice.BillingAccount.ShippingCountry : null,
            'BillToContactName' => invoice.BillToContact != null ? invoice.BillToContact.Name : null,
            // Using List of Map, Object created from Invoice Lines
            'LineItems' => lineItems
        };

        // Send payload using /invoice as endpoint
        System.debug('Invoice Payload: ' + payload);
        sendPayload('/invoice', payload);
    }

}