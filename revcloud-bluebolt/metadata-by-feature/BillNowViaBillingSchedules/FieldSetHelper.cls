/**
 * This class provides utility methods to fetch fields from field sets.
 * It is designed to be used in Lightning Web Components (LWC) to dynamically
 * generate columns based on the fields defined in field sets.
 */
public with sharing class FieldSetHelper {

    /**
     * This method retrieves the fields from a specified field set on a given object.
     * It returns a list of field API names that can be used to dynamically construct
     * SOQL queries and LWC datatable columns.
     *
     * @param objectName The API name of the object (e.g., 'BillingSchedule', 'InvoiceLine').
     * @param fieldSetName The API name of the field set on the object.
     * @return A list of field API names included in the specified field set.
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getFieldSetFields(String objectName, String fieldSetName) {
        List<String> fieldNames = new List<String>();
        Schema.FieldSet fieldSet = Schema.getGlobalDescribe().get(objectName).getDescribe().fieldSets.getMap().get(fieldSetName);
        for (Schema.FieldSetMember f : fieldSet.getFields()) {
            fieldNames.add(f.getFieldPath());
        }
        return fieldNames;
    }
}