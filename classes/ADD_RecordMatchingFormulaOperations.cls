public with sharing class ADD_RecordMatchingFormulaOperations {
    private static final String C_ORGANIZATION = 'organization/';
    private static final String NONE = '--None--';
    private static final String C_METADATA = '/metadata/';
    private static final String C_DESCRIBE = '/describe';
    private static final String C_DESCRIBE_GLOBAL = 'describeGlobal';
    private static final String UTF_8 = 'UTF-8';
    private static final String C_ADDRESS = 'address';
    private static final String C_GEOLOCATION = 'location';
    private static final String C_LABEL = 'label';
    private static final String C_VALUE = 'value';
    private static List<Object> errors { get; set; }
    private static Map<String, String> fieldTypesByNames { get; set; }
    private static Map<String, List<String>> referenceObjectsByReferenceFields { get; set; }
    private static List<Map<String, String>> options { get; set; }

    /**
     * It is doing callout to get object details of given org and object
     * @param orgId organization id of the record matching formula record
     * @param mainObject object field value of the record matching formula record
     * @return JSON value of populated FilterableFields
     * @see FilterableFields
     */
    @AuraEnabled
    public static String getPickListValues(String orgId, String mainObject) {
        options = new List<Map<String, String>>();
        fieldTypesByNames = new Map<String, String>();
        referenceObjectsByReferenceFields = new Map<String, List<String>>();
        Map<String, String> fieldNamesByLabels = new Map<String, String>();
        List<String> sortedFieldLabels = new List<String>();
        errors = new List<Object>();
        DescribeResponse desResponse = doDescribeResponseCallout(orgId, mainObject);
        if (desResponse != null && desResponse.fields != null) {
            addValuesToOptions(NONE, NONE);
            for (CopadoField copadoFld : desResponse.fields) {
                // checking if the current user can see these fields and only adding filterable fields to the option list
                if (copadoFld.filterable && copadoFld.type != null && copadoFld.type != C_ADDRESS && copadoFld.type != C_GEOLOCATION) {
                    String fieldLabel = copadoFld.label + ' (' + copadoFld.name + ')';
                    fieldNamesByLabels.put(fieldLabel, copadoFld.name);
                    sortedFieldLabels.add(fieldLabel);
                    fieldTypesByNames.put(copadoFld.name, copadoFld.type);

                    if (copadoFld.referenceTo != null) {
                        referenceObjectsByReferenceFields.put(copadoFld.name, copadoFld.referenceTo);
                    }
                }
            }

            sortedFieldLabels.sort();
            for (String fieldLabel : sortedFieldLabels) {
                addValuesToOptions(fieldLabel, fieldNamesByLabels.get(fieldLabel));
            }
        }
        FilterableFields filterablefieldsItem = new FilterableFields();
        filterablefieldsItem.errors = errors;
        filterablefieldsItem.options = options;
        filterablefieldsItem.fieldTypesByNames = fieldTypesByNames;
        filterablefieldsItem.referenceObjectsByReferenceFields = referenceObjectsByReferenceFields;
        return JSON.serialize(filterablefieldsItem);
    }

    /**
     * It is used to populate options by given values
     */
    private static void addValuesToOptions(String optionLabel, String optionValue) {
        Map<String, String> valuesByLabels = new Map<String, String>{ C_LABEL => optionLabel, C_VALUE => optionValue };
        options.add(valuesByLabels);
    }

    /**
     * It is used to do callout to get object describe response
     */
    private static DescribeResponse doDescribeResponseCallout(String orgId, String mainObject) {
        DescribeResponse desResponse = new DescribeResponse();
        try {
            Settings sttng = new Settings();
            String url =
                sttng.urlBase +
                C_ORGANIZATION +
                EncodingUtil.urlEncode(orgId, UTF_8) +
                C_METADATA +
                EncodingUtil.urlEncode(mainObject, UTF_8) +
                C_DESCRIBE;
            HttpResponse res = doCallout(url);
            if (res != null) {
                desResponse = (DescribeResponse) JSON.deserialize(res.getBody(), DescribeResponse.class);
                if (!desResponse.success) {
                    errors.add(desResponse.error);
                }
                return desResponse;
            }
        } catch (Exception excp) {
            errors.add(excp.getMessage());
        }
        return null;
    }

    /**
     * It is used to make a callout to the backend for given url
     *
     * @param calloutURL
     */
    private static HttpResponse doCallout(String calloutURL) {
        try {
            HttpRequest req = new HttpRequest();
            String url = calloutURL;
            req.setEndpoint(url);
            req.setMethod('GET');
            req.setHeader('userId', UserInfo.getUserId());
            req.setHeader('orgId', UserInfo.getOrganizationId());
            req.setHeader('token', DeployAPI.getAuthToken());
            req.setTimeout(120000);

            Http http = new Http();
            HttpResponse res = http.send(req);
            return res;
        } catch (Exception excp) {
            errors.add(excp.getMessage());
            return null;
        }
    }

    @AuraEnabled
    public static List<Record_Matching_Formula__c> getRecordMatchingFormulas(String recordId) {
        return [
            SELECT Id, Name, Configuration_Source_Org__c, Object__c, Hash_Formula__c, Field_1__c, Field_2__c, Field_3__c
            FROM Record_Matching_Formula__c
            WHERE Id = :recordId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
    }

    /**
     * It is doing callout to get all objects of given org
     * @param orgId organization id of the record matching formula record
     * @return JSON value of populated GlobalDescribe
     * @see GlobalDescribe
     */
    @AuraEnabled
    public static String getOrgObjects(String orgId) {
        errors = new List<Object>();
        options = new List<Map<String, String>>();
        Map<String, String> objectNamesByLabels = new Map<String, String>();
        List<String> sortedObjectLabels = new List<String>();
        CopadoDescribeGlobalResponse describeGlobalResponse = doDescribeGlobalCallout(orgId);
        if (describeGlobalResponse != null && describeGlobalResponse.sobjects != null) {
            String allDisabledMainObject = getDisabledObjects('Disabled_Main_Objects');
            List<String> disabledMainObjects = allDisabledMainObject.split(',');
            for (CopadoDescribeGlobalSObjectResult desObj : describeGlobalResponse.sobjects) {
                // Exclude all the unwanted Sobjects e.g. History, Share etc..
                Boolean isUnwantedSobjects =
                    desObj.name.containsIgnoreCase('history') ||
                    desObj.name.containsIgnoreCase('tag') ||
                    desObj.name.containsIgnoreCase('share') ||
                    desObj.name.containsIgnoreCase('feed') ||
                    desObj.name.containsIgnoreCase('changeevent');
                //Exclude all custom metadata types
                Boolean isCustomMetadataTypes = desObj.name.containsIgnoreCase('__mdt');
                Boolean disabledObject = !disabledMainObjects.isEmpty() && disabledMainObjects.contains(desObj.name);
                Boolean isObjectTriggerable = desObj.triggerable;
                if (!disabledObject && !isUnwantedSobjects && !isCustomMetadataTypes && isObjectTriggerable) {
                    String objectLabel = desObj.label + ' (' + desObj.name + ')';
                    objectNamesByLabels.put(objectLabel, desObj.name);
                    sortedObjectLabels.add(objectLabel);
                }
            }

            sortedObjectLabels.sort();
            for (String objectLabel : sortedObjectLabels) {
                addValuesToOptions(objectLabel, objectNamesByLabels.get(objectLabel));
            }
        }

        GlobalDescribe globalDescribeItem = new GlobalDescribe();
        globalDescribeItem.errors = errors;
        globalDescribeItem.options = options;
        return JSON.serialize(globalDescribeItem);
    }

    /**
     * It is used to retrieve disabled parent / child objects by using custom metadata type
     * (Data_Template_Setup__mdt => Manage Records) = (Disabled_Main_Objects)
     *
     * @return
     */
    private static String getDisabledObjects(String developerName) {
        String disabledFields = '';
        for (Data_Template_Setup__mdt cs : [SELECT Id, API_Names__c FROM Data_Template_Setup__mdt WHERE DeveloperName = :developerName LIMIT 1]) {
            disabledFields = cs.API_Names__c;
        }
        return disabledFields;
    }

    /**
     * It is used to do callout to get describe global response
     */
    private static CopadoDescribeGlobalResponse doDescribeGlobalCallout(String orgId) {
        CopadoDescribeGlobalResponse describeGlobalResponse = new CopadoDescribeGlobalResponse();
        try {
            Settings sttng = new Settings();
            String url = sttng.urlBase + C_ORGANIZATION + EncodingUtil.urlEncode(orgId, UTF_8) + C_METADATA + C_DESCRIBE_GLOBAL;
            HttpResponse res = doCallout(url);
            if (res != null) {
                describeGlobalResponse = (CopadoDescribeGlobalResponse) JSON.deserialize(res.getBody(), CopadoDescribeGlobalResponse.class);
                if (!describeGlobalResponse.success) {
                    errors.add(describeGlobalResponse.error);
                }
                return describeGlobalResponse;
            }
        } catch (Exception excp) {
            errors.add(excp.getMessage());
        }
        return null;
    }

    public class CopadoDescribeGlobalResponse {
        @AuraEnabled
        public Boolean success { get; set; }
        @AuraEnabled
        public String error { get; set; }
        @AuraEnabled
        public List<CopadoDescribeGlobalSObjectResult> sobjects { get; set; }
    }

    public class CopadoDescribeGlobalSObjectResult {
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public Boolean triggerable { get; set; }
    }

    public class DescribeResponse {
        @AuraEnabled
        public Boolean success { get; set; }
        @AuraEnabled
        public String error { get; set; }
        @AuraEnabled
        public List<CopadoField> fields { get; set; }
    }

    public class CopadoField {
        @AuraEnabled
        public Boolean filterable { get; set; }
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public String type { get; set; }
        @AuraEnabled
        public List<String> referenceTo { get; set; }
    }

    /**
     * The reason that we are returning List<Map<String, String>>, SelectOptions are not serializable
     */
    public class FilterableFields {
        @AuraEnabled
        public List<Object> errors { get; set; }
        @AuraEnabled
        public Map<String, String> fieldTypesByNames { get; set; }
        @AuraEnabled
        public List<Map<String, String>> options { get; set; }
        @AuraEnabled
        public Map<String, List<String>> referenceObjectsByReferenceFields { get; set; }
    }

    /**
     * The reason that we are returning List<Map<String, String>>, SelectOptions are not serializable
     */
    public class GlobalDescribe {
        @AuraEnabled
        public List<Object> errors { get; set; }
        @AuraEnabled
        public List<Map<String, String>> options { get; set; }
    }
}