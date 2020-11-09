public with sharing class NewDeploymentEmailController {
    private static final String EMPTY_STRING = '';
    private static final Integer MAX_BODY_LENGTH = 200000;
    private static final String EXPECTED_INVALID_CONVERSION_JSON_EXCEPTION = 'Invalid conversion from runtime type Map<String,ANY> to List<ANY>';
    public static String statusMessage { get; set; }
    public static String statusMessageErrorMessages { get; set; }
    public static String deploymentId { get; set; }
    public static Deployment__c deployment {
        get {
            // Needed since, when passing the entire SObject record as a paramenter to the component,
            // we only get "one bite at the cherry", not including custom fields
            if (deployment == null) {
                if (String.isNotBlank(deploymentId)) {
                    try {
                        deployment = [SELECT Name, Status__c FROM Deployment__c WHERE Id = :deploymentId WITH SECURITY_ENFORCED];
                        statusMessage = EMPTY_STRING;
                    } catch (final Exception e) {
                        statusMessage = Label.ERROR_RETRIEVING_RECORDS + ' ' + e.getMessage();
                    }
                } else {
                    statusMessage = Label.RECORD_NOT_FOUND;
                }
            }
            return deployment;
        }
        set;
    }
    public static List<Deployment_Job__c> deploymentJobs {
        get {
            if (deploymentJobs == null) {
                try {
                    deploymentJobs = [
                        SELECT Status__c, To_Org_Name__c, Step__r.Name, Step__r.Type__c, Step__r.CheckOnly__c, Step__r.Deployment__r.Name
                        FROM Deployment_Job__c
                        WHERE Step__r.Deployment__c = :deploymentId
                        WITH SECURITY_ENFORCED
                        ORDER BY Step__r.Order__c ASC
                    ];
                    statusMessage = EMPTY_STRING;
                } catch (final Exception e) {
                    statusMessage = Label.ERROR_RETRIEVING_RECORDS + ' ' + e.getMessage();
                }
            }
            return deploymentJobs;
        }
        set;
    }
    public static String getRecordUrl() {
        return Settings.ORGANIZATION_URL + '/' + deploymentId;
    }
    public static List<WrapperError> getErrorMessages() {
        final List<WrapperError> errorMessages = new List<WrapperError>();
        if (String.isNotBlank(deploymentId)) {
            statusMessage = EMPTY_STRING;
            statusMessageErrorMessages = EMPTY_STRING;
            final Set<String> deployJobsNamesJson = new Set<String>();
            for (Deployment_Job__c deploymentJob : deploymentJobs) {
                deployJobsNamesJson.add(deploymentJob.Id + '.json');
            }
            final List<Attachment> attachments;
            try {
                attachments = [
                    SELECT ParentId, Body, BodyLength, Name
                    FROM Attachment
                    WHERE ParentId = :deploymentId AND Name IN :deployJobsNamesJson AND IsDeleted = false
                    WITH SECURITY_ENFORCED
                ];
            } catch (final Exception e) {
                statusMessage = Label.ERROR_RETRIEVING_RECORDS + ' ' + e.getMessage();
            }
            final Map<String, Attachment> attachmentByParentIdAndName = new Map<String, Attachment>();
            for (Attachment attachmentRecord : attachments) {
                // This behaviour overrides the previous attachment assigned to the parent Id and Name
                // if more than one is found. Is that really expected?
                attachmentByParentIdAndName.put(attachmentRecord.ParentId + '-' + attachmentRecord.Name, attachmentRecord);
            }
            for (Deployment_Job__c deploymentJob : deploymentJobs) {
                final String deploymentJobMapKey = deploymentId + '-' + deploymentJob.Id + '.json';
                if (attachmentByParentIdAndName.containsKey(deploymentJobMapKey)) {
                    final Attachment attachmentRecord = attachmentByParentIdAndName.get(deploymentJobMapKey);
                    if (attachmentRecord.BodyLength <= MAX_BODY_LENGTH) {
                        try {
                            final List<Object> results;
                            try {
                                results = (List<Object>) JSON.deserializeUntyped(attachmentRecord.Body.toString());
                                if (results != null) {
                                    readJSONResults(errorMessages, results, false);
                                }
                            } catch (final Exception e) {
                                // This means that it is a data deployment
                                if (e.getMessage() == EXPECTED_INVALID_CONVERSION_JSON_EXCEPTION) {
                                    final Map<String, Object> parsedJSONContent = (Map<String, Object>) JSON.deserializeUntyped(
                                        attachmentRecord.Body.toString()
                                    );
                                    results = (List<Object>) parsedJSONContent.get('results');
                                    if (results != null) {
                                        readJSONResults(errorMessages, results, true);
                                    }
                                } else {
                                    statusMessageErrorMessages = Label.ERROR_PARSING_JSON + ' ' + e.getMessage();
                                    return new List<WrapperError>();
                                }
                            }
                        } catch (final Exception e) {
                            statusMessageErrorMessages = Label.ERROR_PARSING_JSON + ' ' + e.getMessage();
                            return new List<WrapperError>();
                        }
                    } else {
                        statusMessageErrorMessages = Label.MAX_FILE_SIZE_EXCEEDED;
                        return new List<WrapperError>();
                    }
                }
            }
            if (errorMessages.isEmpty()) {
                statusMessageErrorMessages = Label.NO_ERROR_ATTACHMENT_FOUND;
            }
        } else {
            statusMessage = Label.RECORD_NOT_FOUND;
        }
        return errorMessages;
    }
    public static List<WrapperStep> getDeploymentSteps() {
        final List<WrapperStep> deploymentSteps = new List<WrapperStep>();
        if (String.isNotBlank(deploymentId)) {
            statusMessage = EMPTY_STRING;
            final Set<Id> deploymentJobsStepsIds = new Set<Id>();
            for (Deployment_Job__c deploymentJob : deploymentJobs) {
                deploymentJobsStepsIds.add(deploymentJob.Step__r.Id);
            }
            for (Deployment_Job__c deploymentJob : deploymentJobs) {
                final WrapperStep step = new WrapperStep();
                step.name = deploymentJob.Step__r.Name;
                step.type = deploymentJob.Step__r.Type__c;
                step.status = deploymentJob.Status__c;
                step.destinationOrg = deploymentJob.To_Org_Name__c;
                deploymentSteps.add(step);
            }
        } else {
            statusMessage = Label.RECORD_NOT_FOUND;
        }
        return deploymentSteps;
    }
    private static void readJSONResults(final List<WrapperError> errorMessages, final List<Object> results, final Boolean isDataDeployment) {
        final List<WrapperError> currentErrorMessages = new List<WrapperError>();
        // Variable used to check if it is a data deployment and successful, since in that case, no error message should be added
        Boolean isDataDeploymentAndSuccessful = isDataDeployment;
        for (Object result : results) {
            final Map<String, Object> errorAttributesByKey = (Map<String, Object>) result;
            final WrapperError error = new WrapperError();
            try {
                error.type = (String) errorAttributesByKey.get('l');
            } catch (final Exception ex) {
                error.type = EMPTY_STRING;
            }
            try {
                if (isDataDeployment) {
                    final Map<String, Object> messageAttributesByKey = (Map<String, Object>) errorAttributesByKey.get('m');
                    error.message = (String) messageAttributesByKey.get('exception');
                    // if if is a data deployment, but any results contains an exception, then it was not successful and error message must be shown
                    if (String.isNotBlank(error.message)) {
                        isDataDeploymentAndSuccessful = false;
                    }
                } else {
                    error.message = (String) errorAttributesByKey.get('m');
                }
            } catch (final Exception ex) {
                error.message = EMPTY_STRING;
            }
            try {
                error.copadoTip = ((String) errorAttributesByKey.get('t')).replaceAll('&lt;', '<').replaceAll('&gt;', '>');
            } catch (final Exception ex) {
                error.copadoTip = EMPTY_STRING;
            }
            currentErrorMessages.add(error);
        }
        if (!isDataDeploymentAndSuccessful) {
            errorMessages.addAll(currentErrorMessages);
        }
    }
    public class WrapperError {
        public String type { get; set; }
        public String message { get; set; }
        public String copadoTip { get; set; }
    }
    public class WrapperStep {
        public String name { get; set; }
        public String type { get; set; }
        public String status { get; set; }
        public String destinationOrg { get; set; }
    }
}