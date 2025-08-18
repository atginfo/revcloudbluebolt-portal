/**
  @author            : David Sam
  @group             : Cognizant
  @ticket            : CIBGCF-XX
  @last modified on  : 07-31-2025
  @last modified by  : Frank Berni

 * BillNowController class is responsible for fetching billing schedules related to a specific order.
 * This class provides a method to retrieve billing schedules and their associated order items.
 * 
 * Example usage:
 * Id orderId = 'a0A1t00000XXXXXX';
 * List<Map<String, Object>> billingSchedules = BillNowController.getBillingSchedules(orderId);
 */
public with sharing class BillNowController {
    /**
     * Retrieves billing schedules for a given order ID.
     * 
     * @param orderId The ID of the order to retrieve billing schedules for.
     * @return A list of maps containing billing schedule data and associated order item data.
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getBillingSchedules(Id orderId) {
        List<String> fieldSetFields = FieldSetHelper.getFieldSetFields('BillingSchedule', 'Bill_Now_Field_Set');
        // NEW added ReferenceEntityId to query
        String query = 'SELECT Id, BillingScheduleNumber, ReferenceEntityItemId, ReferenceEntityId';
        for (String field : fieldSetFields) {
            query += ', ' + field;
        }
        query += ' FROM BillingSchedule WHERE ReferenceEntityId = :orderId';
        List<BillingSchedule> billingSchedules = Database.query(query);

        // Fetch order items
        List<Id> referenceEntityItemIds = new List<Id>();
        for (BillingSchedule schedule : billingSchedules) {
            referenceEntityItemIds.add(schedule.ReferenceEntityItemId);
        }
        Map<Id, OrderItem> orderItemMap = ReferenceEntityToOrderItemHelper.getOrderItems(referenceEntityItemIds);

        // Create a list of maps to hold the combined data
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (BillingSchedule schedule : billingSchedules) {
            Map<String, Object> scheduleMap = new Map<String, Object>();
            scheduleMap.put('Id', schedule.Id);
            scheduleMap.put('BillingScheduleNumber', schedule.BillingScheduleNumber);
            scheduleMap.put('ReferenceEntityItemId', schedule.ReferenceEntityItemId);
            // NEW added ReferenceEntityId to have reference to Order
            scheduleMap.put('ReferenceEntityId', schedule.ReferenceEntityId);
            scheduleMap.put('Status', schedule.Status);
            scheduleMap.put('BillDayOfMonth', schedule.BillDayOfMonth);
            // Add other fields from the field set
            for (String field : fieldSetFields) {
                scheduleMap.put(field, schedule.get(field));
            }
            OrderItem item = orderItemMap.get(schedule.ReferenceEntityItemId);
            if (item != null) {
                scheduleMap.put('OrderItemNumber', item.OrderItemNumber);
                scheduleMap.put('OrderItemId', item.Id);
                scheduleMap.put('Product2Id', item.Product2Id);
                scheduleMap.put('Product2Name', item.Product2.Name);
                // Add links
                scheduleMap.put('OrderItemLink', '/lightning/r/OrderItem/' + item.Id + '/view');
                scheduleMap.put('ProductLink', '/lightning/r/Product2/' + item.Product2Id + '/view');
            }
            // Add billing schedule link
            scheduleMap.put('BillingScheduleLink', '/lightning/r/BillingSchedule/' + schedule.Id + '/view');
            result.add(scheduleMap);
        }
        return result;
    }
}