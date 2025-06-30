/**
 * This helper class provides methods to map ReferenceEntityItemIds to OrderItems.
 * It is designed to be used in conjunction with other controllers to dynamically
 * fetch and map order item details based on ReferenceEntityItemIds.
 */
public with sharing class ReferenceEntityToOrderItemHelper {

    /**
     * This method retrieves order items for a given list of ReferenceEntityItemIds.
     * It returns a map of ReferenceEntityItemId to OrderItem.
     *
     * @param referenceEntityItemIds The list of ReferenceEntityItemIds to fetch order items for.
     * @return A map of ReferenceEntityItemId to OrderItem.
     */
    @AuraEnabled(cacheable=true)
    public static Map<Id, OrderItem> getOrderItems(List<Id> referenceEntityItemIds) {
        Map<Id, OrderItem> orderItemMap = new Map<Id, OrderItem>();
        for (OrderItem item : [
            SELECT Id, OrderItemNumber, Product2Id, Product2.Name
            FROM OrderItem
            WHERE Id IN :referenceEntityItemIds
        ]) {
            orderItemMap.put(item.Id, item);
        }
        return orderItemMap;
    }
}