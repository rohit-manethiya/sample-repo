public with sharing class ArtifactManageMetadataController {
    private Artifact__c artifact {get;set;}
    public Boolean hasOrg {get;set;}
    public String metadata_url_art {get;set;}
    public Settings settingsClass{get;set;}
    public Boolean showError {get;set;} 
    public Boolean showOptions {get;set;}
    public List<Id> relatedArtifactIds{get;set;}
    public Boolean copadoJobFinished {get;set;}
    public String slockerMessage {get; set;}
    private String cJobId = '';
    private Boolean gitExistAndValid = false;
    public Boolean jobisExecuting  {get;set;}
    public Boolean hasOLS {get;set;}
    public String dependencyMetadataJSON {get;set;}

    public ArtifactManageMetadataController(ApexPages.StandardController stdController) {
        if(!Test.isRunningTest()) {
            stdController.addFields(new List<String>(SObjectType.Artifact__c.fields.getMap().keySet()));
        }
        dependencyMetadataJSON = '';
        Boolean isAuthorizedToViewArtifact = hasAccessTo(Artifact__c.SObjectType);
        Boolean isAuthorizedToViewOrg = hasAccessTo(Org__c.SObjectType);
        Boolean isAuthorizedToViewGitRepo = hasAccessTo(Git_Repository__c.SObjectType);
        hasOLS = isAuthorizedToViewArtifact && isAuthorizedToViewOrg && isAuthorizedToViewGitRepo;
        slockerMessage = CopadoNotificationHelper.STATUS_DEFAULT_VALUE;
        settingsClass = new Settings();
        copadoJobFinished = false;
        hasOrg = false;
        showOptions = true;
        showError = false;
        this.artifact = (Artifact__c)stdController.getRecord();
        gitExistAndValid = String.isNotBlank(this.artifact.Artifact_Repository__c) ? DeployAPI.validateGit(this.artifact.Artifact_Repository__c).success : false;
        if(this.artifact.Org_Credential__c != null) {
            hasOrg=true;
            String urlParameters = '';
            String herokuServer = settingsClass.herokuServer;
            String urlBase = herokuServer + '/json/v1/'; 
            metadata_url_art = urlBase + 'metadata/' + EncodingUtil.urlEncode(artifact.Org_Credential__c,DXLabel.UTF_8) + urlParameters + '?dates=format&parentId=' + EncodingUtil.urlEncode(artifact.Org_Credential__c,DXLabel.UTF_8);
            relatedArtifactIds = new List<Id>();
            if(hasAccessTo(Artifact__c.SObjectType)) {
                for(Artifact__c a : [SELECT Id FROM Artifact__c WHERE Org_Credential__c =: artifact.Org_Credential__c AND Id != : artifact.Id]){
                    relatedArtifactIds.add(a.Id);
                }
            }
            Copado_Notification__c cn = CopadoNotificationHelper.qInProgressCopadoNotification(DXLabel.ARTIFACT_GIT_SNAPSHOT,artifact.Id);
            if(cn != null){
                cJobId = cn.Matching_Key__c;
                slockerMessage = cn.status__c;
                jobisExecuting = true;
            }
        } else {
            addPageMessage(ApexPages.Severity.WARNING, Label.Org_Credential_Is_Missing_On_Artifact);
        }
    }

    public PageReference redirectIfUnlocked() {
        PageReference unmanagedPackagePage = null;
        if(SObjectType.Artifact__c.getRecordTypeInfosByDeveloperName().get('Package_Artifact').getRecordTypeId() == artifact.RecordTypeId && artifact.Package_Type__c == 'Unmanaged'){
            unmanagedPackagePage = Page.ArtifactPackage;
            unmanagedPackagePage.getParameters().put('Id', artifact.Id);
            unmanagedPackagePage.setRedirect(true);
        }
        return unmanagedPackagePage;
    }

    public PageReference callJob() {
        gitExistAndValid = String.isNotBlank(this.artifact.Artifact_Repository__c) ? DeployAPI.validateGit(this.artifact.Artifact_Repository__c).success : false;
        copadoJobFinished = false;
        cJobId = '';
        return checkJobApex();
    }

    public PageReference checkJobApex() {
        PageReference pr = null;
        try {
            if(!gitExistAndValid) {
                addPageMessage(ApexPages.Severity.WARNING, Label.Git_Repo_is_Not_Set);
                copadoJobFinished = true;
                return null;
            }
            if(cJobId == '' && artifact.Id != null) {
                String s = SfdxAPI.artifactSnapshot(artifact.Id);
                CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse)JSON.deserialize(s,CopadoNotificationHelper.copadoFrontAPIreponse.class);
                if(r.copadoJobId != null && r.copadoJobId != '') {
                    cJobId = r.copadoJobId;
                    slockerMessage = r.ok;
                    Copado_Notification__c newCN = CopadoNotificationHelper.instCopadoNotification(CopadoNotificationHelper.PROGRESS_STATUS_COPADO, artifact.Id,DXLabel.ARTIFACT_GIT_SNAPSHOT,cJobId);
                    try {
                        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPSERTABLE, new List<Copado_Notification__c>{ newCN });
                        upsert decision.getRecords();
                        newCN = (Copado_Notification__c)decision.getRecords()[0];
                    } catch(NoAccessException ex) {
                        addPageMessage(ApexPages.Severity.WARNING, ex.getMessage());
                    }
                    copadoJobFinished = false;
                } else if(r.error != null && r.error != '') {
                    copadoJobFinished = true;
                    addPageMessage(ApexPages.Severity.ERROR,r.error);
                }
            } else {
                Copado_Notification__c c = CopadoNotificationHelper.qCopadoNotificationBycopadoJobId(cJobId);
                if(c.isFinished__c) {
                    if(c.isSuccess__c) {
                        copadoJobFinished = true;
                        addPageMessage(ApexPages.Severity.CONFIRM,'Success');
                        cJobId = '';
                    } else {
                        addPageMessage(ApexPages.Severity.ERROR,c.Message__c != null ? c.Message__c : c.status__c != null ? c.status__c : Label.Could_Not_Push_To_Repo);
                        copadoJobFinished = true;
                    }
                } else {
                    slockerMessage = c.status__c;
                    copadoJobFinished = false;
                }

            }
        } catch(Exception e) {
            addPageMessage(ApexPages.Severity.ERROR,e.getMessage());
            copadoJobFinished = true;
        }
        return pr;
    }
    /**
     * Method to be called from JS or Apex and show a fixed message includes two parameters (errorLevel and messageName)
     */
    public String errorLevel {get; set;}
    public String messageName {get; set;}
    public void showMessage() {
        ApexPages.Severity level = ApexPages.Severity.ERROR;
        if(errorLevel == 'WARNING') {
            level = ApexPages.Severity.WARNING;
        }else{
            if(errorLevel == 'CONFIRM') {
                level = ApexPages.Severity.CONFIRM;
            }
        }
        addPageMessage(level, messageName);
    }

    // it is used to find metadata dependencies for selected metadata
    public void metadataDependency() {
        String selectedM = ApexPages.currentPage().getParameters().get('selectedMetadata');
        List<SelectedMetadata> smList = new List<SelectedMetadata>();
        if(String.isNotBlank(selectedM)) {
            smList = (List<SelectedMetadata>) JSON.deserialize(selectedM, List<SelectedMetadata>.class);
        }
        if(smList.isEmpty()) {
            addPageMessage(ApexPages.Severity.WARNING, Label.Retrieve_At_Least_One_Metadata);
            return;
        }

        // Creating a where condition of dependency api callout url by using selected metadata on UI
        // Salesforce's limit on the URI length is 16,088 characters. We have to check the character limit and create loop if necessary
        Integer totalCharacter = 0;
        Integer metadataIndexForLoop = 0;
        Map<String,List<String>> typeMetadataNameMap = new Map<String,List<String>>(); // it will hold type name and metadata name list
        for(SelectedMetadata sm : smList) {
            String metadataName = 'MetadataComponentName = \'' + String.escapeSingleQuotes(sm.n) + '\'';

            totalCharacter += metadataName.length();
            if(totalCharacter > 14000) {
                metadataIndexForLoop++;
                totalCharacter = 0;
            }
            String metadataType = 'MetadataComponentType = \'' + String.escapeSingleQuotes(sm.t) + '\'' + '{' + metadataIndexForLoop + '}';

            if(!typeMetadataNameMap.containsKey(metadataType)) {
                typeMetadataNameMap.put(metadataType, new List<String>{ metadataName });
            } else {
                typeMetadataNameMap.get(metadataType).add(metadataName);
            }
        }

        Map<Integer,List<String>> conditionMap = new Map<Integer,List<String>>();
        if(!typeMetadataNameMap.isEmpty()) {
            for(String str : typeMetadataNameMap.keySet()) {
                Integer mIndex = Integer.valueOf(str.substring(str.indexOf('{')+1, str.indexOf('}')));
                String mType = str.substringBefore('{');
                String minorCondition = '(' + mType + ' AND (' + String.join(typeMetadataNameMap.get(str), ' OR ') + '))';
                if(!conditionMap.containsKey(mIndex)) {
                    conditionMap.put(mIndex, new List<String>{ minorCondition });
                } else {
                    conditionMap.get(mIndex).add(minorCondition);
                }
            }
        }

        Map<Integer,String> whereConditionMap = new Map<Integer,String>();
        if(!conditionMap.isEmpty()) {
            for(Integer intg : conditionMap.keySet()) {
                String whereCondition = String.join(conditionMap.get(intg), ' OR ');
                whereConditionMap.put(intg,whereCondition);
            }
        }

        Set<String> refMetadataComponentObjectNameSet = new Set<String>();
        Set<String> refMetadataComponentFieldNameSet = new Set<String>();
        Map<String,String> customObjectIdNameMap = new Map<String,String>();

        DependencyHandler dh = new DependencyHandler();

        // Metadata dependency callout
        Integer totalCallouts = 0;
        if(whereConditionMap.size() < 100) {
            for(String whereClause : whereConditionMap.values()) {
                DependencyHandler.RequestResponse resp = new DependencyHandler.RequestResponse();
                try {
                    resp = dh.returnWrapperMetadataDependency(whereClause);
                } catch(Exception ex) {
                    addPageMessage(ApexPages.Severity.ERROR, ex.getMessage());
                    return;
                }

                totalCallouts++;

                // if there is any error on callout show the error message
                if(resp != null && resp.errorCode != null && resp.message != null) {
                    addPageMessage(ApexPages.Severity.ERROR, resp.errorCode + ' ' + resp.message);
                    return;
                }

                // creating a SelectedMetadata wrapper to prepare selected metadata json to render perfectly on the grid
                for(DependencyHandler.Records rcd : resp.records) {
                    SelectedMetadata sm = new SelectedMetadata();
                    sm.t = rcd.RefMetadataComponentType;
                    sm.n = rcd.RefMetadataComponentName;
                    smList.add(sm);

                    // collecting object names to retrieve by using customobject tooling api
                    if(rcd.RefMetadataComponentType != null && rcd.RefMetadataComponentName != null && rcd.RefMetadataComponentType == 'CustomObject') {
                        refMetadataComponentObjectNameSet.add(rcd.RefMetadataComponentName);
                    }

                    // collecting field names to retrieve by using customfield tooling api
                    if(rcd.RefMetadataComponentType != null && rcd.RefMetadataComponentName != null && rcd.RefMetadataComponentType == 'CustomField') {
                        refMetadataComponentFieldNameSet.add(rcd.RefMetadataComponentName);
                    }
                }
            }
        } else {
            addPageMessage(ApexPages.Severity.ERROR, Label.SF_Callout_Limits_Exceeds);
        }

        // Custom object callout by using tooling api
        if(!refMetadataComponentObjectNameSet.isEmpty()) {
            String objectWhereCondition = '';
            List<String> objectConditionList = new List<String>();
            for(String str : refMetadataComponentObjectNameSet) {
                String minorCondition = 'DeveloperName = \'' + String.escapeSingleQuotes(str) + '\'';
                objectConditionList.add(minorCondition);
            }

            if(!objectConditionList.isEmpty()) {
                objectWhereCondition = String.join(objectConditionList,' OR ');
            }

            if(totalCallouts >= 99) {
                addPageMessage(ApexPages.Severity.ERROR, Label.SF_Callout_Limits_Exceeds);
                return;
            }
            DependencyHandler.RequestResponse respObj = new DependencyHandler.RequestResponse();
            try {
                respObj = dh.returnWrapperCustomObjectMetadata(objectWhereCondition);
            } catch (Exception ex) {
                addPageMessage(ApexPages.Severity.ERROR, ex.getMessage());
                return;
            }
            totalCallouts++;

            // if there is any error on callout show the error message
            if(respObj != null && respObj.errorCode != null && respObj.message != null) {
                addPageMessage(ApexPages.Severity.ERROR, respObj.errorCode + ' ' + respObj.message);
                return;
            }

            // creating a SelectedMetadata wrapper to prepare selected metadata json to render perfectly on the grid
            for(DependencyHandler.Records rcd : respObj.records) {
                SelectedMetadata sm = new SelectedMetadata();
                String objectName = rcd.DeveloperName + '__c';
                sm.t = respObj.entityTypeName;
                sm.n = objectName;
                smList.add(sm);

                customObjectIdNameMap.put(rcd.Id,objectName);
            }
        }

        // Custom field callout by using tooling api
        if(!refMetadataComponentFieldNameSet.isEmpty()) {
            List<String> fieldConditionList = new List<String>();
            Map<Integer,List<String>> fieldWhereConditionMap = new Map<Integer,List<String>>();

            Integer totalFieldAPIEndpointCharacter = 0;
            Integer metadataIndexForFieldAPILoop = 0;
            for(String str : refMetadataComponentFieldNameSet) {
                String minorCondition = 'DeveloperName = \'' + String.escapeSingleQuotes(str) + '\'';

                totalFieldAPIEndpointCharacter += minorCondition.length();
                if(totalFieldAPIEndpointCharacter > 14000) {
                    metadataIndexForFieldAPILoop++;
                    totalFieldAPIEndpointCharacter = 0;
                }

                if (!fieldWhereConditionMap.containsKey(metadataIndexForFieldAPILoop)) {
                    fieldWhereConditionMap.put(metadataIndexForFieldAPILoop, new List<String>{ minorCondition });
                } else {
                    fieldWhereConditionMap.get(metadataIndexForFieldAPILoop).add(minorCondition);
                }
            }

            if(!fieldWhereConditionMap.isEmpty()) {
                for(Integer i : fieldWhereConditionMap.keySet()) {
                    fieldConditionList.add(String.join(fieldWhereConditionMap.get(i),' OR '));
                }
            }
            
            if(!fieldConditionList.isEmpty()) {
                for(String strCond : fieldConditionList) {
                    if(totalCallouts >= 99) {
                        addPageMessage(ApexPages.Severity.ERROR, Label.SF_Callout_Limits_Exceeds);
                        return;
                    }

                    DependencyHandler.RequestResponse respField = new DependencyHandler.RequestResponse();
                    try {
                        respField = dh.returnWrapperCustomFieldMetadata(strCond);
                    } catch(Exception ex) {
                        addPageMessage(ApexPages.Severity.ERROR, ex.getMessage());
                        return;
                    }
                    totalCallouts++;

                    // if there is any error on callout show the error message
                    if(respField != null && respField.errorCode != null && respField.message != null) {
                        addPageMessage(ApexPages.Severity.ERROR, respField.errorCode + ' ' + respField.message);
                        return;
                    }

                    // creating a SelectedMetadata wrapper to prepare selected metadata json to render perfectly on the grid
                    for(DependencyHandler.Records rcd : respField.records) {
                        if(customObjectIdNameMap.containsKey(rcd.TableEnumOrId)) {
                            String fieldName = customObjectIdNameMap.get(rcd.TableEnumOrId) + '.' + rcd.DeveloperName + '__c';
                            SelectedMetadata sm = new SelectedMetadata();
                            sm.t = respField.entityTypeName;
                            sm.n = fieldName;
                            smList.add(sm);
                        }
                    }
                }
            }
        }

        if(!smList.isEmpty()) {
            dependencyMetadataJSON = JSON.serialize(smList);
        }
    }

    private Boolean hasAccessTo(SObjectType thisObjectType) {
        Boolean hasAccess = thisObjectType.getDescribe().isAccessible() && thisObjectType.getDescribe().isQueryable();
        if(!hasAccess) {
            addPageMessage(ApexPages.Severity.WARNING,thisObjectType.getDescribe().getLabel() + ': ' + Label.Insufficient_Access_Rights);
        }
        return hasAccess;
    }

    private void addPageMessage(ApexPages.Severity severity, String message) {
        ApexPages.addMessage(new ApexPages.Message(severity, message));
    }

    public class SelectedMetadata {
        public String t;
        public String n;
        public String b;
        public String d;
        public String cb;
        public String cd;
        public Boolean s;

        public SelectedMetadata() {
            this.t = '';
            this.n = '';
            this.b = '';
            this.d = '';
            this.cb = '';
            this.cd = '';
            this.s = true;
        }
    }
}