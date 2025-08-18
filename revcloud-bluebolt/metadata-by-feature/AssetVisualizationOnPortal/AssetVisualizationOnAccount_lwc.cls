/**
 * @description       : 
 * @author            : David Sam
 * @group             : Cognizant
 * @ticket            : CIBGCF-XX
 * @last modified on  : 06-09-2025
 * @last modified by  : David Sam
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
                WHERE Asset.AccountId =:accountId
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

    // public static List<AssetStatePeriod> draftDateRangeSort (Id theCurrentUserId) {
    //     try {
    //         if(theCurrentUserId == null){
    //             theCurrentUserId = userinfo.getUserId();

    //         }

            
    //         List<AssetStatePeriod> accountsActiveAssets = [
    //             SELECT Id, Amount, Mrr, Quantity, StartDate, EndDate, Asset.AccountId,Asset.Name,
    //                 Asset.Account.Name
    //             FROM AssetStatePeriod
    //             WHERE Asset.AccountId = :AccountId
    //             AND Mrr >0
    //             ORDER BY StartDate, EndDate ASC];
            
    //         Date graphStartDate = accountsActiveAssets[0].StartDate;
    //         Date graphTempEndDate = accountsActiveAssets[accountsActiveAssets.size() - 1].EndDate;
    //         Date graphTempStartDate = '';
    //         Date graphTempEndDate = '';
    //         Date graphEndDate = '';

    //         Set<AssetStatePeriod> sameStartDate = new Set<AssetStatePeriod>();
    //         List<String> dateRanges = new List<String>();
    //         Map<String,List<String>> mapOfDates = new Map<String,List<String>>();

    //         integer i  = 0;
    //         for (AssetStatePeriod asp : accountsActiveAssets) {

    //             graphStartDate = asp.StartDate;
    //             for (AssetStatePeriod aspDesc : [SELECT Id, Amount, Mrr, Quantity, StartDate, EndDate, Asset.AccountId,Asset.Name,
    //                     Asset.Account.Name
    //                 FROM AssetStatePeriod
    //                 WHERE Asset.AccountId = :AccountId
    //                 AND Mrr >0
    //                 ORDER BY EndDate DESC]) {
                        
    //                 if (asp.id != aspDesc.id) { // check to make sure we are not running against the same record
    //                     //assign the end date from the order by
    //                     if (graphEndDate == '') {
    //                         graphEndDate = aspDesc.EndDate;
    //                     }
    //                     List<String> dateRanges = new List<String>();

    //                     // if the start date of the first asset is the start date of the latest end date
    //                     if ((graphEndDate == aspDesc.EndDate) && (asp.StartDate.isSameDay(aspDesc.StartDate))) {
    //                         if (asp.EndDate.isGreaterThan(aspDesc.EndDate)) {
    //                             graphTempEndDate = aspDesc.EndDate;
    //                             dateRanges.add(asp.StartDate, asp.Mrr + aspDesc.Mrr, aspDesc.EndDate);
    //                             mapOfDates.put('range'+i, dateRanges);
    //                         }else{
    //                             graphTempEndDate = asp.EndDate;
    //                             dateRanges.add(asp.StartDate, asp.Mrr + aspDesc.Mrr, aspDesc.EndDate);
    //                             mapOfDates.put('range'+i, dateRanges);
    //                         }
    //                     } 
    //                     else if ((graphEndDate != aspDesc.EndDate) && (asp.StartDate.isSameDay(aspDesc.StartDate))) {
    //                         if (asp.EndDate.isGreaterThan(aspDesc.EndDate)) {
    //                             graphTempEndDate = aspDesc.EndDate;
    //                             dateRanges.add(asp.StartDate, asp.Mrr + aspDesc.Mrr, aspDesc.EndDate);
    //                             mapOfDates.put('range'+i, dateRanges);
    //                         }else{
    //                             graphTempEndDate = asp.EndDate;
    //                             dateRanges.add(asp.StartDate, asp.Mrr + aspDesc.Mrr, aspDesc.EndDate);
    //                             mapOfDates.put('range'+i, dateRanges);
    //                         }
    //                     }
    //                     else ((graphEndDate != aspDesc.EndDate) && (!asp.StartDate.isSameDay(aspDesc.StartDate))) {
    //                         if (asp.EndDate.isGreaterThan(aspDesc.EndDate) && asp.StartDate.isLessThan(aspDesc.StartDate)) {
    //                             graphTempEndDate = aspDesc.EndDate;
    //                             dateRanges.add(aspDesc.StartDate, asp.Mrr + aspDesc.Mrr, aspDesc.EndDate);
    //                             mapOfDates.put('range'+i, dateRanges);
    //                         }else{
    //                             graphTempEndDate = asp.EndDate;
    //                             dateRanges.add(asp.StartDate, asp.Mrr + aspDesc.Mrr, aspDesc.EndDate);
    //                             mapOfDates.put('range'+i, dateRanges);
    //                         }
    //                     }
    //                 }
                
    //             }
    //             i++;
    //         }
            
    //     } catch (Exception e) {
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }


    /**
    * @description: Pull Data for showing a list of related Assets and standalones on the portal.
    * @author David Sam | 05-12-2025 
    * @param Id theCurrentUserId 
    * @return Map<Id, List<AssetStatePeriod>> 
    **/
    @AuraEnabled(cacheable=true)
    public static Map<Id,List<AssetStatePeriod>> getAssetAndRelatedAssets (Id theCurrentUserId) {
        if(theCurrentUserId == null){
            theCurrentUserId = userinfo.getUserId();
        }

        List<User> users = [SELECT Contact.AccountId FROM User WHERE Id =:theCurrentUserId LIMIT 1];
        Id accountId = users[0].Contact.AccountId;          // Grab the account Id from the current User

        // Map to pass to the LWC
        Map<Id,List<AssetStatePeriod>> asset2RelatedAssetIds = new Map<Id,List<AssetStatePeriod>>();
        
        Set<Id> childAssetIdSet = new Set<Id>();
        Set<Id> parentAssetIdSet = new Set<Id>();

        // Querry all assets (parent assets = AssetId. child assets = RelatedAssetId))
        List<AssetRelationship> assetIds = [
            SELECT AssetId, RelatedAssetId
            FROM AssetRelationship 
            WHERE Asset.AccountId =:accountID
            ORDER BY AssetId ASC
        ];

        // Querry all needed columns to be shown on the table on the LWC
        List<AssetStatePeriod> columnNames = [
            SELECT ID,Amount, Mrr, Quantity, StartDate, EndDate, Asset.Name,
                AssetId,Asset.Billing_Frequency2__c
            FROM AssetStatePeriod
            WHERE Asset.AccountId = :AccountId
		    ORDER BY AssetId ASC
        ];

        // Use the list childAssetIdSet for filtering the standalone assets later.
        for (AssetRelationship theAsset: assetIds) {
            childAssetIdSet.add(theAsset.RelatedAssetId); // child of bundles
            parentAssetIdSet.add(theAsset.AssetId); // parents of bundles
        }

        AssetStatePeriod tmpASP ;
        //List<AssetStatePeriod> assetRelationshipList = new List<AssetStatePeriod>();

        for (AssetRelationship parentAsset : assetIds) {
           List<AssetStatePeriod> assetRelationshipList = new List<AssetStatePeriod>();
            for (AssetStatePeriod asp: columnNames) {
                // We will see duplicates assets here because an asset can have multiple state periods.
                if (asp.AssetId == parentAsset.RelatedAssetId ) {    
                    assetRelationshipList.add(asp);
                    tmpASP = ASP;
                    
                }
                else if ((!childAssetIdSet.contains(asp.AssetID)) &&
                    !parentAssetIdSet.contains(asp.AssetID)){ 
                    
                    // It is a standalone, let's add it to the map with its own Asset Id and clumn values
                    assetRelationshipList.add(asp);
               
                    // Standalones: If the key exist, append to its values. Else, add the key/pair
                    if (asset2RelatedAssetIds.containsKey(asp.AssetId)){
                        asset2RelatedAssetIds.get(asp.AssetId).add(asp);
                    }else {
                        asset2RelatedAssetIds.put(asp.AssetId, assetRelationshipList);
                    }
                    
                    assetRelationshipList.clear();
                }
            }

            // Bundles: If the key exist, append to its values. Else, add the key/pair
            if (asset2RelatedAssetIds.containsKey(parentAsset.AssetID) &&
            !asset2RelatedAssetIds.get(parentAsset.AssetID).contains(tmpASP)){
                asset2RelatedAssetIds.get(parentAsset.AssetID).add(tmpASP);

            }else {
                asset2RelatedAssetIds.put(parentAsset.AssetID,assetRelationshipList);
            }
            assetRelationshipList.clear();
            tmpASP = null;
        }
    	System.debug('asset2RelatedAssetIds: ' + asset2RelatedAssetIds);
        System.debug('asset2RelatedAssetIds.size: ' + asset2RelatedAssetIds.size());
        // formattedList(asset2RelatedAssetIds);
        System.debug('@@@@ passed function call: ' );
        
    	return asset2RelatedAssetIds;
    }

    @AuraEnabled (cacheable=true)
    public static Map<String,List<Asset>> getAssets (){

        // Querry all assets (parent assets = AssetId. child assets = RelatedAssetId))
        List<AssetRelationship> assetIds = [
            SELECT AssetId, RelatedAssetId
            FROM AssetRelationship 
            WHERE Asset.AccountId ='001Kj00002TV6kLIAT'
            ORDER BY AssetId ASC
        ];

        Set<Id> childAssetIdSet = new Set<Id>();
        Set<Id> parentAssetIdSet = new Set<Id>();
        List<Asset> standaloneAssets = new List<Asset>();
        List<Asset> bundledAssets = new List<Asset>();
        Map<String,List<Asset>> assetMap = new Map<String,List<Asset>>();
       // List<Asset> formattedList = new List<Asset>();
     

        // Use the list childAssetIdSet for filtering the standalone assets later.
        for (AssetRelationship theAsset: assetIds) {
            childAssetIdSet.add(theAsset.RelatedAssetId); // child of bundles
            parentAssetIdSet.add(theAsset.AssetId); // parents of bundles
        }

        System.debug('$$ childAssetIdSet.Size: ' + childAssetIdSet.size() + ' -- ' +'parentAssetIdSet.size: ' + parentAssetIdSet.size());


        List<Asset> theAssetList = [SELECT Id,Name,Billing_Frequency2__c,
                    (
                        SELECT RelatedAssetId
                        FROM RelatedAssets
                    ),
                    (
                        SELECT StartDate,EndDate, Mrr, Quantity, Asset.Name
                        FROM AssetStatePeriods
                    )
                FROM Asset
                WHERE AccountId = '001Kj00002TV6kLIAT'];

        System.debug('$$ childAssetIdSet.Size: ' + childAssetIdSet.size() + ' -- ' +'parentAssetIdSet.size: ' + parentAssetIdSet.size() + ' -- ' +
                    'theAssetList.size: ' + theAssetList.size());
        Integer i = 0;
        List<Asset> assetAssetIds = new List<Asset>();
        ID tempAssetID = null;
        for (ID ARP: childAssetIdSet) {

            //standaloneAssets = new List<Asset>();
            // bundledAssets = new List<Asset>();

            for (Asset AST: theAssetList) {
                tempAssetID = AST.Id;
                if (AST.Id == ARP ) {
                    System.debug('$$ ARP: ' + ARP + ' -- ' + 'AST.Id: ' + AST.Id);
                    System.debug('$$ bundledAssets: ' + bundledAssets);
                    bundledAssets.add(AST);
                
                }
                else if (AST.Id != ARP && !childAssetIdSet.contains(tempAssetID) && !parentAssetIdSet.contains(tempAssetID)) {
                     System.debug('$$ ARP: ' + ARP + ' -- ' + 'AST.Id: ' + AST.Id);
                    standaloneAssets.add(AST);
                }
                
            }
            System.debug('$$ bundledAssets.Size: ' + bundledAssets.size() + ' -- ' +'standaloneAssets.size: ' + standaloneAssets.size() );
        }
        assetMap.put('standalone', standaloneAssets);
        assetMap.put('bundled', bundledAssets);
        System.debug('$$ assetMap.Size: ' + assetMap.size() + ' -- ' +'assetMap: ' + assetMap);
        return assetMap;

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

    // public static List<Asset> orderedAssets(List<Asset> assets) {
    //     Set<ID> assetIds = [SELECT AssetId FROM Asset WHERE AccountId = '001Kj00002TV6kLIAT'];
    //     List<Asset> theAssetList = [[SELECT Id,Name,Billing_Frequency2__c,
    //                 (
    //                     SELECT AssetId, RelatedAssetId
    //                     FROM RelatedAssets
    //                 ),
    //                 (
    //                     SELECT Id, EndDate, Mrr, Quantity, StartDate,Asset.Name
    //                     FROM AssetStatePeriods
    //                 )
    //             FROM Asset
    //             WHERE AccountId = '001Kj00002TV6kLIAT']];
    //     System.debug('AssetIds: ' + assetId);
    //     List<Asset> orderedAssets = new List<Asset>();

    //     for(ID assetId : assetIds) {
    //         for(Asset key: assets) {
    //             System.debug('key: ' + key);
    //             System.debug('key.Id: ' + key.Id);
    //             if(key.Id == id) {
    //                 orderedAssets.add(key);
    //             }
    //         }
    //     }
        
    //     return orderedAssets;
    // }

    // public Static List<Asset> formattedList(Map<Id,List<AssetStatePeriod>> relatedAssetMap) {
    //     List<Asset> formattedList = new List<Asset>();
    //     List<List<AssetStatePeriod>> listOfLists = new List<List<AssetStatePeriod>>();
    //     List<AssetStatePeriod> aspList = [SELECT AssetId, EndDate, Mrr, Quantity, StartDate,Asset.Name
    //                                         FROM AssetStatePeriod
    //                                         WHERE AssetId IN :relatedAssetMap.keySet()
    //                                         ORDER BY StartDate ASC];

    //     System.debug('relatedAssetMap: ' + relatedAssetMap);
    //     for(ID key : relatedAssetMap.keySet()) {

    //         System.debug('@@@ key: ' + key);
    //         List<AssetStatePeriod> tmpASP = new List<AssetStatePeriod>();

    //          for (AssetStatePeriod ASP : aspList) {
    //         //     System.debug('@@@ key: ' + key);
    //             System.debug('@@@ relatedAssetMap.get(): ' + relatedAssetMap.get(key));
    //             if (key == ASP.AssetId) {
    //                 System.debug('@@@ ASP.AssetId: ' + ASP.AssetId);
    //                 tmpASP.add(ASP);
    //             }
    //         }
    //         // listOfLists.add(key, tmpASP);
    //         // System.debug('@@@ listOfLists: ' + listOfLists);
            
        
    //     }
    //     return formattedList;
    
    // }



    // public class AssetRelationshipStatePeriodClass{

    //     @AuraEnabled
    //     public String AssetName;
    //     @AuraEnabled
    //     public Date StartDate;
    //     @AuraEnabled
    //     public Date EndDate;
    //     @AuraEnabled
    //     public Currency Amount;
    //     @AuraEnabled
    //     public String BillingFrequency;
    //     @AuraEnabled
    //     public Integer Quantity;
    //     @AuraEnabled
    //     public Asset ParentAssetId;
    //     @AuraEnabled
    //     public Id AssetId;


    //     public AssetRelationshipStatePeriodClass(Account account2Use){
    //         this.AssetRelationship = assetRelationship;
        
    //     }
    // }


}