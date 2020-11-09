/**
 * @description The Sfdx API helper. Generic operation handlers are given in this class for SFDX operations
 * @author Mert YALTI
 * @author Ferhat Ozsavran
 * @author Umit Can Uckan
 */
public with sharing abstract class SfdxAPIHelper {
    // Set of consts that represents attachment names
    public static final String DX_PROJECT_BRANCH = 'project/DX-'; //+scratchOrgId (15 chars)
    public static final String DX_DEFINITION_FILE = 'project-scratch-def.json';
    public static final String DX_PROJECT_FILE = 'sfdx-project.json';
    public static final String DX_METADATA_SOURCES = 'metadataSources.json';
    public static final String DX_PACKAGE_DETAILS = 'packageDetail.json';
    public static String flowMessage;
    static String SOQL_STRING = 'SELECT {0} FROM {1} WHERE {2}';
    // Supported Http call methods
    static Set<String> callMethods = new Set<String>{ 'DELETE', 'GET', 'HEAD', 'POST', 'PUT', 'TRACE' };
    /**
     * The default keyword is reserved so that we cannot use it as a variable name
     * Therefore we use defaultArtifact and replace it with default before calling the backend out
     * @param jsonBody raw org definition json
     * @return org definition json with replaced reserved names
     */
    public static String orgDefinitionDefaultKeyFixer(String jsonBody) {
        return jsonBody.replaceAll(',"defaultArtifact":false', '').replace('"defaultArtifact":true', '"default":true');
    }
    /**
     * ScratchOrgDefinition is a wrapper we use the store org definition values
     * With this method we generate a proper JSON to be used in callouts
     * Note: Reserved keywords are not removed since this maybe used for another operation than callout
     * @param orgTemplate
     * @return org definition json
     */
    public static String prepareOrgDefinition(ScratchOrgDefinition orgTemplate, String jsonSettingFeature) {
        if (!String.isBlank(orgTemplate.getEdition())) {
            Map<String, Object> orgTemplateMap = new Map<String, Object>();
            if (String.isNotBlank(jsonSettingFeature)) {
                orgTemplateMap.putAll((Map<String, Object>) JSON.deserializeUntyped(jsonSettingFeature));
            }
            orgTemplateMap.putAll((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(orgTemplate)));
            return JSON.serializePretty(orgTemplateMap);
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.DX_Edition_is_required));
            return null;
        }
    }
    public static String prepareDataforJsonEditor(ScratchOrgDefinition orgTemplate, String jsonDefinition) {
        Map<String, Object> templateMap = new Map<String, Object>((Map<String, Object>) JSON.deserializeUntyped(jsonDefinition));
        for (String generalProperty : orgTemplate.getProperties()) {
            templateMap.remove(generalProperty);
        }
        return JSON.serialize(templateMap);
    }
    /**
     * Generates SFDX default org definition
     * @return org definition json
     */
    public static String prepareDefaultOrgDefinitionJSON() {
        ScratchOrgDefinition defaultOrgDef = new ScratchOrgDefinition();
        return JSON.serialize(defaultOrgDef, true);
    }

    /**
     * Calls backend with given Http callout setup
     * @param callMethod Http method
     * @param callURL Http endpoint
     * @param callBody Http payload body
     * @param bodyRequired Boolen param that decides to add body or not
     * @param runningJobName the Copado job name to be created in order to track the status of the job
     * @see CopadoNotificationHelper
     * @see JobsManager
     * @return string result
     */
    public static String callDxJob(String callMethod, String callURL, String callBody, Boolean bodyRequired, String runningJobName) {
        HttpResponse res = SfdxAPIHelper.callDxJob(callMethod, callURL, callBody, bodyRequired);
        String body = res.getBody();
        CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse) JSON.deserialize(
            body,
            CopadoNotificationHelper.copadoFrontAPIreponse.class
        );
        if (String.isNotBlank(r.copadoJobId)) {
            JobsManager.createRunningJob(r.copadoJobId, runningJobName, null, 'Starting...');
        }
        return body;
    }
    /**
     * Calls backend with given Http callout setup
     * @param callMethod Http method
     * @param callURL Http endpoint
     * @param callBody Http payload bodyt
     * @param bodyRequired Boolen param that decides to add body or not
     * @return HttpResponse of the callout
     */
    public static HttpResponse callDxJob(String callMethod, String callURL, String callBody, Boolean bodyRequired) {
        if (!callMethods.contains(callMethod)) {
            throw new CopadoDxException(Label.Unknown_HTTP_Request_method);
        }
        HttpRequest req = new HttpRequest();
        req.setTimeout(30000);
        DeployAPI.setAuthHeaders(req);
        if (bodyRequired && String.isEmpty(callBody)) {
            return null;
        } else if (!String.isEmpty(callBody)) {
            req.setBody(callBody);
        }
        req.setHeader('Accept', 'application/json');
        req.setHeader('content-type', 'application/json');
        req.setEndpoint(callURL);
        req.setMethod(callMethod);
        Http h = new Http();
        HttpResponse res = h.send(req);
        return res;
    }

    //Given a Scratch org Id, get the org Id of the artifacts or Org where de metadata was selected
    public static String getSOartifactParentId(String SOId) {
        String oId = '';
        if (String.isNotBlank(SOId)) {
            if (Schema.SObjectType.Attachment.isQueryable() && Schema.SObjectType.Attachment.isAccessible()) {
                List<Attachment> mSTatt = [
                    SELECT Body
                    FROM Attachment
                    WHERE ParentId = :SOId AND Name = :DX_METADATA_SOURCES
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
                if (!mSTatt.isEmpty()) {
                    Map<String, Object> deserializedJsonMap = (Map<String, Object>) JSON.deserializeUntyped(mSTatt.get(0).Body.toString());
                    String mSourceType = deserializedJsonMap.containsKey('metadataSourceType')
                        ? String.valueOf(deserializedJsonMap.get('metadataSourceType'))
                        : '';
                    String mSource = deserializedJsonMap.containsKey('metadataSource')
                        ? String.valueOf(deserializedJsonMap.get('metadataSource'))
                        : '';
                    if (String.isNotBlank(mSource) && String.isNotBlank(mSource) && mSourceType == 'org') {
                        oId = mSource;
                    } else if (String.isNotBlank(mSource) && String.isNotBlank(mSourceType) && mSourceType == 'artifact') {
                        String firstArtifactId = mSource.split(',')[0];
                        List<Artifact__c> parentOrg = new List<Artifact__c>();
                        if (Schema.SObjectType.Artifact__c.isQueryable() && Schema.SObjectType.Artifact__c.isAccessible()) {
                            parentOrg = [SELECT Org_Credential__c FROM Artifact__c WHERE Id = :firstArtifactId];
                            if (!parentOrg.isEmpty() && parentOrg[0].Org_Credential__c != null) {
                                oId = parentOrg[0].Org_Credential__c;
                            }
                        } else {
                            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Artifact__c.label);
                        }
                    }
                }
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Attachment.label);
            }
        }
        return oId;
    }
    public static String returnJsonAfterCorrection(String scratchJson) {
        ScratchOrgDefinition tempwrapperItem = (ScratchOrgDefinition) JSON.deserialize(scratchJson, ScratchOrgDefinition.class);
        tempwrapperItem.setAdminEmail(UserInfo.getUserEmail());
        String jsonSettingsFeatures = prepareDataforJsonEditor(tempwrapperItem, scratchJson);
        String returnCorrectJson = prepareOrgDefinition(tempwrapperItem, jsonSettingsFeatures);
        return returnCorrectJson;
    }

    public static Deployment_Flow__c usDeploymentFlow(String usId) {
        try {
            User_Story__c us = new User_Story__c();
            if (Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
                us = [
                    SELECT Id, Project__c, Project__r.Deployment_Flow__c, Release__c, Release__r.Project__r.Deployment_Flow__c
                    FROM User_Story__c
                    WHERE Id = :usId
                    LIMIT 1
                ];
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story__c.label);
            }
            String dfId;
            if (us.Project__r.Deployment_Flow__c != null) {
                dfId = us.Project__r.Deployment_Flow__c;
            } else if (us.Release__r.Project__r.Deployment_Flow__c != null) {
                dfId = us.Release__r.Project__r.Deployment_Flow__c;
            }
            Deployment_Flow__c depFlow = new Deployment_Flow__c();
            if (Schema.SObjectType.Deployment_Flow__c.isQueryable() && Schema.SObjectType.Deployment_Flow__c.isAccessible()) {
                depFlow = [
                    SELECT
                        Id,
                        Name,
                        Enable_Copado_DX__c,
                        Copado_DX_Mode__c,
                        Block_Commits__c,
                        Active__c,
                        Main_Branch__c,
                        (
                            SELECT
                                Id,
                                Name,
                                Enable_as_Scratch_Org_Destination__c,
                                Destination_Environment__c,
                                Destination_Environment__r.Name,
                                Source_Environment__c,
                                Source_Environment__r.Name
                            FROM Deployment_Flow_Steps__r
                            WHERE Enable_as_Scratch_Org_Destination__c != NULL
                        )
                    FROM Deployment_Flow__c
                    WHERE Id = :dfId
                    LIMIT 1
                ];
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Deployment_Flow__c.label);
            }
            return depFlow;
        } catch (Exception e) {
            flowMessage = Label.UNEXPECTED_DX_DF_ERROR + ' ' + e.getMessage() + ' ' + e.getStackTraceString();
            return null;
        }
    }
    public static Boolean isDXEnabledForUSDeploymentFlow(Deployment_Flow__c depFlow) {
        if (depFlow == null) {
            flowMessage = Label.DX_NO_US_FLOW;
            return false;
        }
        if (!depFlow.Enable_Copado_DX__c) {
            flowMessage = Label.DX_NOT_ENABLED_DF;
            return false;
        }
        if (depFlow.Deployment_Flow_Steps__r.size() == 0) {
            flowMessage = Label.DF_HAS_NO_DX_TARGET;
            return false;
        }
        return true;
    }
    public static Boolean isDXEnabledForUSDeploymentFlow(String usId) {
        Deployment_Flow__c depFlow = usDeploymentFlow(usId);
        return isDXEnabledForUSDeploymentFlow(depFlow);
    }

    public class PackageCreateResponse {
        public String status { get; set; } //always populated
        public String message { get; set; } //gets populated when any error occurs
        public String stack { get; set; } //gets populated when any error occurs
        public String name { get; set; } //gets populated when any error occurs
        public PackageCreateResponseResult result { get; set; }
    }

    public class PackageCreateResponseResult {
        public String Id { get; set; }
        public String Status { get; set; }
        public String Package2Id { get; set; }
        public String Package2VersionId { get; set; }
        public String SubscriberPackageVersionId { get; set; }
        public String Tag { get; set; }
        public String Branch { get; set; }
        public String CreatedDate { get; set; }
    }

    public class CopadoDxException extends Exception {
    }
}