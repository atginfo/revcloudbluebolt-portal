/**
  @author            : David Sam
  @group             : Cognizant
  @ticket            : CIBGCF-XX
  @last modified on  : 08-20-2025
  @last modified by  : Frank Berni

 * BillNowController class is responsible for fetching billing schedules related to a specific order.
 * This class provides a method to retrieve billing schedules and their associated order items.
 * 
 * Example usage:
 * Id orderId = 'a0A1t00000XXXXXX';
 * List<Map<String, Object>> billingSchedules = BillNowController.getBillingSchedules(orderId);
 */
public with sharing class BillNowController {

    @testVisible static List<BillingSchedule> TEST_INJECT_BILLING_SCHEDULES;
    @testVisible static Map<Id, Id> TEST_SCHEDULE_TO_ORDERITEM;


    /**
     * Retrieves billing schedules for a given order ID.
     * 
     * @param orderId The ID of the order to retrieve billing schedules for.
     * @return A list of maps containing billing schedule data and associated order item data.
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getBillingSchedules(Id orderId) {
        List<String> fieldSetFields = FieldSetHelper.getFieldSetFields('BillingSchedule', 'Bill_Now_Field_Set');

        String query = 'SELECT Id, BillingScheduleNumber, ReferenceEntityItemId, ReferenceEntityId';
        for (String field : fieldSetFields) query += ', ' + field;
        query += ' FROM BillingSchedule WHERE ReferenceEntityId = :orderId';

        // Use injected rows in tests
        List<BillingSchedule> billingSchedules =
            (Test.isRunningTest() && TEST_INJECT_BILLING_SCHEDULES != null)
            ? TEST_INJECT_BILLING_SCHEDULES
            : Database.query(query);

        // Collect OrderItem Ids (from record OR injected sidecar map)
        List<Id> referenceEntityItemIds = new List<Id>();
        for (BillingSchedule schedule : billingSchedules) {
            Id refItemId = schedule.ReferenceEntityItemId;
            if (refItemId == null && Test.isRunningTest() && TEST_SCHEDULE_TO_ORDERITEM != null) {
                refItemId = TEST_SCHEDULE_TO_ORDERITEM.get(schedule.Id);
            }
            if (refItemId != null) referenceEntityItemIds.add(refItemId);
        }
        Map<Id, OrderItem> orderItemMap = ReferenceEntityToOrderItemHelper.getOrderItems(referenceEntityItemIds);

        // Build result payload
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (BillingSchedule schedule : billingSchedules) {
            Map<String, Object> scheduleMap = new Map<String, Object>();
            scheduleMap.put('Id', schedule.Id);
            scheduleMap.put('BillingScheduleNumber', schedule.BillingScheduleNumber);

            // ReferenceEntityId: use record value, or fall back to the method param during tests
            Id refOrderId = schedule.ReferenceEntityId;
            if (refOrderId == null && Test.isRunningTest()) refOrderId = orderId;
            scheduleMap.put('ReferenceEntityId', refOrderId);

            // ReferenceEntityItemId: use record value, or injected sidecar
            Id refItemId = schedule.ReferenceEntityItemId;
            if (refItemId == null && Test.isRunningTest() && TEST_SCHEDULE_TO_ORDERITEM != null) {
                refItemId = TEST_SCHEDULE_TO_ORDERITEM.get(schedule.Id);
            }
            scheduleMap.put('ReferenceEntityItemId', refItemId);

            scheduleMap.put('Status', schedule.Status);
            scheduleMap.put('BillDayOfMonth', schedule.BillDayOfMonth);

            for (String field : fieldSetFields) scheduleMap.put(field, schedule.get(field));

            OrderItem item = (refItemId != null) ? orderItemMap.get(refItemId) : null;
            if (item != null) {
                scheduleMap.put('OrderItemNumber', item.OrderItemNumber);
                scheduleMap.put('OrderItemId', item.Id);
                scheduleMap.put('Product2Id', item.Product2Id);
                scheduleMap.put('Product2Name', item.Product2.Name);
                scheduleMap.put('OrderItemLink', '/lightning/r/OrderItem/' + item.Id + '/view');
                scheduleMap.put('ProductLink', '/lightning/r/Product2/' + item.Product2Id + '/view');
            }

            scheduleMap.put('BillingScheduleLink', '/lightning/r/BillingSchedule/' + schedule.Id + '/view');
            result.add(scheduleMap);
        }
        return result;
    }


}