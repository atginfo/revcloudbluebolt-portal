/**
 * @description       : 
 * @author            : David Sam
 * @group             : Cognizant
 * @ticket            : CIBGCF-XX
 * @last modified on  : 08-20-2025
 * @last modified by  : Frank Berni
**/
public with sharing class AssetVisualizationOnAccount_lwc {

    /**
    * @description : Get the currently logged in user and query all active asset  using the Mrr being greater than 0
    * @author David Sam | 04-16-2025 
    * @param Id theCurrentUserId 
    * @return List<AggregateResult> 
    **/
    @AuraEnabled(cacheable=true)
    public static List<AggregateResult> getAssetAmountDetails(Id theCurrentUserId){

        System.debug('theCurrentUserId: ' + theCurrentUserId);

         if(theCurrentUserId == null){
            theCurrentUserId = userinfo.getUserId();
            System.debug('theCurrentUserId: ' + theCurrentUserId);
        //     return null;
         }
        //List<Contact> users = [SELECT AccountId FROM Contact WHERE Id =:theCurrentUserId LIMIT 1];
        List<User> users = [SELECT Contact.AccountId FROM User WHERE Id =:theCurrentUserId LIMIT 1];
        Id accountId = users[0].Contact.AccountId;
        system.debug('AccountId '+accountId);

        return [SELECT Count(Id) Id,Asset.Name, Sum(Asset.CurrentMrr) summedAmount
                FROM AssetStatePeriod
                WHERE Asset.AccountId = :accountId
                AND Mrr  > 0
                GROUP BY Asset.Name
                LIMIT 3
        ];
    }

    /**
    * @description: Get a list of all active asset on the account (with Mrr  greater than 0) and display it on the portal
    * @description: Get the currently logged in user and query all active asset  using the Mrr being greater than 0)
    * @author David Sam | 04-23-2025 
    * @param Id theCurrentUserId 
    * @return List<AssetStatePeriod> 
    **/
    @AuraEnabled(cacheable=true)
    public static List<AssetStatePeriod> getAssetsList(Id theCurrentUserId) {
        try {
            if(theCurrentUserId == null){
                theCurrentUserId = userinfo.getUserId();
                System.debug('theCurrentUserId: ' + theCurrentUserId);
            }

            List<User> users = [SELECT Contact.AccountId FROM User WHERE Id =:theCurrentUserId LIMIT 1];
            Id accountId = users[0].Contact.AccountId;
            system.debug('AccountId '+accountId);
            return [
                SELECT Id, Amount, Mrr, Quantity, StartDate, Asset.AccountId,Asset.Name,
                    Asset.Account.Name
                FROM AssetStatePeriod
                WHERE Asset.AccountId = :AccountId
                AND Mrr > 0
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description: Pull Data for showing a list of related Assets and standalones on the portal.
    * @author David Sam | 05-12-2025 
    * @param Id theCurrentUserId 
    * @return Map<Id, List<AssetStatePeriod>> 
    **/
    @AuraEnabled(cacheable=true)
    public static Map<Id,List<AssetStatePeriod>> getAssetAndRelatedAssets (Id theCurrentUserId) {
        if (theCurrentUserId == null) {
            theCurrentUserId = UserInfo.getUserId();
        }

        // Resolve current user's account
        Id accountId = [
            SELECT Contact.AccountId
            FROM User
            WHERE Id = :theCurrentUserId
            LIMIT 1
        ].Contact.AccountId;

        Map<Id,List<AssetStatePeriod>> asset2RelatedAssetIds = new Map<Id,List<AssetStatePeriod>>();

        // Relationships (parent = AssetId, child = RelatedAssetId)
        List<AssetRelationship> assetIds = [
            SELECT AssetId, RelatedAssetId
            FROM AssetRelationship
            WHERE Asset.AccountId = :accountId
            ORDER BY AssetId ASC
        ];

        // All ASPs we’ll need
        List<AssetStatePeriod> columnNames = [
            SELECT Id, Amount, Mrr, Quantity, StartDate, EndDate, AssetId,
                Asset.Name, Asset.Billing_Frequency2__c
            FROM AssetStatePeriod
            WHERE Asset.AccountId = :accountId
            ORDER BY AssetId ASC
        ];

        // Build quick lookup sets to identify parents/children
        Set<Id> childAssetIdSet  = new Set<Id>();
        Set<Id> parentAssetIdSet = new Set<Id>();
        for (AssetRelationship ar : assetIds) {
            childAssetIdSet.add(ar.RelatedAssetId);
            parentAssetIdSet.add(ar.AssetId);
        }

        // 1) Bundle children under their parent
        for (AssetRelationship parentAsset : assetIds) {
            List<AssetStatePeriod> childAsps = new List<AssetStatePeriod>();
            for (AssetStatePeriod asp : columnNames) {
                if (asp.AssetId == parentAsset.RelatedAssetId) {
                    childAsps.add(asp); // collect all ASPs for this child asset
                }
            }
            if (!childAsps.isEmpty()) {
                if (asset2RelatedAssetIds.containsKey(parentAsset.AssetId)) {
                    asset2RelatedAssetIds.get(parentAsset.AssetId).addAll(childAsps);
                } else {
                    asset2RelatedAssetIds.put(parentAsset.AssetId, new List<AssetStatePeriod>(childAsps));
                }
            }
        }

        // 2) Standalones = not a parent and not a child
        for (AssetStatePeriod asp : columnNames) {
            if (!childAssetIdSet.contains(asp.AssetId) && !parentAssetIdSet.contains(asp.AssetId)) {
                if (asset2RelatedAssetIds.containsKey(asp.AssetId)) {
                    asset2RelatedAssetIds.get(asp.AssetId).add(asp);
                } else {
                    asset2RelatedAssetIds.put(asp.AssetId, new List<AssetStatePeriod>{ asp });
                }
            }
        }

        return asset2RelatedAssetIds;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String,List<Asset>> getAssets () {
        // Resolve current user's account
        Id accountId = [
            SELECT Contact.AccountId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ].Contact.AccountId;

        // Relationships for this account
        List<AssetRelationship> assetIds = [
            SELECT AssetId, RelatedAssetId
            FROM AssetRelationship
            WHERE Asset.AccountId = :accountId
            ORDER BY AssetId ASC
        ];

        Set<Id> childAssetIdSet  = new Set<Id>();
        Set<Id> parentAssetIdSet = new Set<Id>();
        for (AssetRelationship ar : assetIds) {
            childAssetIdSet.add(ar.RelatedAssetId);
            parentAssetIdSet.add(ar.AssetId);
        }

        // All assets for the account (with related data)
        List<Asset> theAssetList = [
            SELECT Id, Name, Billing_Frequency2__c,
                (SELECT RelatedAssetId FROM RelatedAssets),
                (SELECT StartDate, EndDate, Mrr, Quantity, Asset.Name FROM AssetStatePeriods)
            FROM Asset
            WHERE AccountId = :accountId
        ];

        List<Asset> standalone = new List<Asset>();
        List<Asset> bundled    = new List<Asset>();

        for (Asset a : theAssetList) {
            if (childAssetIdSet.contains(a.Id)) {
                bundled.add(a);                  // a is a child in some bundle
            } else if (!parentAssetIdSet.contains(a.Id)) {
                standalone.add(a);               // neither parent nor child → standalone
            }
            // (If you want to include explicit parents themselves somewhere, add another bucket.)
        }

        return new Map<String, List<Asset>>{
            'standalone' => standalone,
            'bundled'    => bundled
        };
    }


     @AuraEnabled(cacheable=true)
    public static List<Asset> getAssetAndReletionships (Id theCurrentUserId, date validityDate){

         if(theCurrentUserId == null || validityDate == null){
            theCurrentUserId = userinfo.getUserId();
            validityDate = Date.today();
        }
        System.debug('validityDate: ' + validityDate);

        List<User> users = [SELECT Contact.AccountId FROM User WHERE Id =:theCurrentUserId LIMIT 1];
        Id accountId = users[0].Contact.AccountId;          // Grab the account Id from the current User

        // Querry all assets (parent assets = AssetId. child assets = RelatedAssetId))
         return [
            SELECT Id,Name,Billing_Frequency2__c,
         
                    (
                        SELECT AssetId, RelatedAssetId, Asset.Name, RelatedAsset.Name 
                        FROM RelatedAssets
                    ),
                    (
                        SELECT StartDate,EndDate, Mrr, Quantity, Asset.Name
                        FROM AssetStatePeriods
                        WHERE Quantity > 0
                        AND (StartDate <= :validityDate AND EndDate >= :validityDate)
                    )
                FROM Asset
                WHERE AccountId =:accountId]; // '001Kj00002TV6kLIAT'];
    }

}