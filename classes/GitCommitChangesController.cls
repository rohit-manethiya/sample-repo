global with sharing class GitCommitChangesController {

    public Git_Org_Commit__c gitCommit { get; set; }
    public Git_Backup__c gitBackup { get; set; }
    public User_Story__c userStory { get; set; }

    public String repositoryId { get; set; }
    public String snapshotId { get; set; }
    public String orgId { get; set; }
    public String userStoryId { get; set; }
    public String orgName { get; set; }
    public String repoName { get; set; }
    public String branch { get; set; }
    public String artifactsParentOrgId { get; set; }
    public String errorDetails { get; set; }

    public Boolean showSnapshotInformation { get; set; }
    public Boolean isDXEnabled { get; set; }
    public Boolean showVlocity { get; set; }

    private final String COMMITFILES = 'Commit Files';
    private final String VLOCITY = 'Vlocity';
    private final String UTF8 = 'UTF-8';
    private final String RECREATEFEATUREBRANCH = 'recreateFeatureBranch';

    public List<Schema.FieldSetMember> getFields() {
        List<Schema.FieldSetMember> fields = SObjectType.Git_Backup__c.fieldSets.Commit_Files_Information.getFields();
        showSnapshotInformation = !fields.isEmpty();
        return fields;
    }
    public List<Schema.FieldSetMember> getUSFields() {
        return SObjectType.User_Story__c.fieldSets.Commit_Files_Information.getFields();
    }

    // Advanced
    public String baseBranch { get; set; }
    public Boolean showBaseBranch { get; set; }

    // Git Operations variables
    public Map<String, Operation> operationsMap { get; set; }
    public List<SelectOption> operationTypes { get; set; }
    public Operation selectedOperation { get; set; }
    public List<SnapshotCommitWrapper> snapshotCommitWrappers { get; set; }
    public String gitMetadataAttachmentId { get; set; }
    public String possibleRunningJobs { get; set; }

    /**
     * constructor
     * @return [description]
     */
    public GitCommitChangesController() {
        // get from parameter the related snapshot
        Map<String, String> params = ApexPages.currentPage().getParameters();

        repositoryId = params.get('repoId');
        snapshotId = params.get('snapshotId');
        orgId = params.get('orgId');
        baseBranch = '';
        showBaseBranch = false;
        userStoryId = params.get('userStoryId');

        String Commit_Message = '';
        if(String.isNotBlank(userStoryId)) {
            isDXEnabled = SfdxAPIHelper.isDXEnabledForUSDeploymentFlow(userStoryId);
            // get values for userStory fields and commit Message
            try {
                String query = 'SELECT ';
                for(Schema.FieldSetMember f : this.getUSFields()) {
                    String fp = f.getFieldPath();
                    if(fp != 'Name') {
                        query += fp + ', ';
                    }
                }
                query += 'Release__r.Version__c, ';
                query += 'Name FROM User_Story__c WHERE Id =:userStoryId LIMIT 1';
                if(Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
                    userStory = Database.query(query);
                } else {
                    UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story__c.getLabel());
                    return;
                }
            } catch(Exception ex) {
                errorDetails = UIDesignHelper.catchExceptionMessage(ex);
            }
            if(Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
                for(User_Story__c us : [SELECT Name, User_Story_Title__c FROM User_Story__c WHERE Id = :userStoryId]) {
                    Commit_Message = (us.Name + ': ' + (String.isEmpty(us.User_Story_Title__c) ? '' : us.User_Story_Title__c)).left(254);
                }
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story__c.getLabel());
                return;
            }
        } else {
            showBaseBranch = false;
        }

        // get values snapshot fields and subtitle
        try {
            String query = 'SELECT ';
            for(Schema.FieldSetMember f : this.getFields()) {
                String fp = f.getFieldPath();
                if(fp != 'Git_Repository__r.Name') {
                    query += fp + ', ';
                }
            }
            query += ' Org__r.Org_Type__c, ';
            query += ' Git_Repository__r.Name FROM Git_Backup__c WHERE Id =:snapshotId LIMIT 1';
            if(Schema.SObjectType.Git_Backup__c.isQueryable() && Schema.SObjectType.Git_Backup__c.isAccessible()) {
                gitBackup = Database.query(query);
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Git_Backup__c.getLabel());
                return;
            }
        } catch(Exception ex) {
            errorDetails = UIDesignHelper.catchExceptionMessage(ex);
        }

        //Artifacts: If there is a Scratch Org associated and commit is done from US, try to get the Parent Org of the loaded artifacts
        if(String.isNotBlank(orgId) && String.isNotBlank(userStoryId) && null != gitBackup && null != gitBackup.Org__r.Org_Type__c && gitBackup.Org__r.Org_Type__c == 'Scratch Org') {
            artifactsParentOrgId = SfdxAPIHelper.getSOartifactParentId(orgId);
            if(String.isNotBlank(artifactsParentOrgId) && (null == userStory.Release__c || null == userStory.Release__r.Version__c)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.USER_STORY_RELEASE_VERSION_MISSING));
            }
        }

        Git_Backup__c snapshot = new Git_Backup__c();
        if(String.isNotBlank(snapshotId)) {
            if(Schema.SObjectType.Git_Backup__c.isQueryable() && Schema.SObjectType.Git_Backup__c.isAccessible()) {
                snapshot = [SELECT Org__r.Name, Branch__c, Git_Repository__r.Name FROM Git_Backup__c WHERE Id = :snapshotId];
                orgName = snapshot.Org__r.Name;
                repoName = snapshot.Git_Repository__r.Name;
                branch = snapshot.Branch__c;
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Git_Backup__c.getLabel());
                return;
            }
        }

        // create a fake commit record
        gitCommit = new Git_Org_Commit__c(
            Git_Backup__c = snapshotId,
            Org__c = orgId,
            Commit_Message__c = Commit_Message
        );

        // Get Base Branch
        getBaseBranch();

        // Init Git Operations
        operationsMap = new Map<String, Operation>();
        operationTypes = new List<SelectOption>();
        Operation commitFilesOperation = new Operation();
        commitFilesOperation.operationLabel = COMMITFILES;
        commitFilesOperation.operationType = 'CommitFiles';
        commitFilesOperation.showGrid = true;
        commitFilesOperation.editGrid = false;
        commitFilesOperation.showCommitMessage = true;
        commitFilesOperation.endpoint = 'commit';
        commitFilesOperation.pages = 'GitSnapshotCommit,UserStoryCommit';
        commitFilesOperation.showAdvancedSection = true;
        gitCommit.Git_Operation__c = COMMITFILES;

        operationsMap.put(commitFilesOperation.operationLabel, commitFilesOperation);
        operationTypes.add(new SelectOption(commitFilesOperation.operationLabel, commitFilesOperation.operationLabel));
        selectedOperation = commitFilesOperation;
        possibleRunningJobs = '';
        requestGitOperationsFile();
        if(String.isBlank(possibleRunningJobs)) {
            possibleRunningJobs = ',GitDeletion,,true;,MetadataDependenciesJob,,true;,GitCommit,,true';
            if(String.isNotBlank(snapshotId) && String.isNotBlank(orgId)) {
                possibleRunningJobs = ',GitDeletion,,true;,MetadataDependenciesJob,,true;,GitCommit,' + snapshotId + ',true';
            }
        }

        snapshotCommitWrappers = new List<SnapshotCommitWrapper>();
        showVlocity = null != Feature__c.getValues(VLOCITY) ? Feature__c.getValues(VLOCITY).Enabled__c : false;

        if(!Schema.SObjectType.Git_Org_Commit__c.isCreateable() && !Schema.SObjectType.Git_Org_Commit__c.isUpdateable()) {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Git_Org_Commit__c.getLabel());
            return;
        }
    }

    /**
     * Method to get the Base Branch from the CBM Flow, User Story or Release
     */
    public void getBaseBranch() {
        if(null != userStory) {
            List<User_Story__c> userStories = new List<User_Story__c>();
            if(Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
                for(User_Story__c us : [SELECT Id, Base_Branch__c, Release__r.Base_Branch__c FROM User_Story__c WHERE Id = :userStory.Id LIMIT 1]) {
                    userStories.add(us);
                }
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story__c.getLabel());
                return;
            }

            if(!userStories.isEmpty()) {
                GlobalUtilities.deploymentFlowDetails flowDetails = GlobalUtilities.getUserStoryDeploymentFlowDetails(userStories[0].Id, '');
                if(flowDetails.isCBMFlow) {
                    // Get Main Branch of Deployment Flow
                    baseBranch = null != flowDetails.flow.Main_Branch__c ? flowDetails.flow.Main_Branch__c : '';
                    if(String.isNotEmpty(userStories[0].Base_Branch__c)) {
                        baseBranch = userStories[0].Base_Branch__c;
                    } else if(String.isNotEmpty(userStories[0].Release__r.Base_Branch__c)) {
                        baseBranch = userStories[0].Release__r.Base_Branch__c;
                    }
                }
            }

            if(String.isNotEmpty(baseBranch)) {
                showBaseBranch = true;
            }
        }
    }

    /**
     * Method to switch the selected Operation triggered by a SelectList in the Visualforce page
     */
    public void changeOperation() {
        Operation newOperation = operationsMap.get(gitCommit.Git_Operation__c);
        if(null != newOperation) {
            selectedOperation = newOperation;
            gitCommit.Git_Operation__c = selectedOperation.operationLabel;

            if(selectedOperation.showUserStorySelections == true) {
                List<Attachment> attachmentList = new List<Attachment>();
                if(Schema.SObjectType.Attachment.isQueryable() && Schema.SObjectType.Attachment.isAccessible()) {
                    attachmentList = [SELECT Id FROM Attachment WHERE ParentId = :userStoryId AND Name = 'Git Metadata' LIMIT 1];
                } else {
                    UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Attachment.getLabel());
                    return;
                }
                if(!attachmentList.isEmpty()) {
                    gitMetadataAttachmentId = attachmentList[0].Id;
                }
            } else {
                gitMetadataAttachmentId = '';
            }

            // Get SnapshotCommits if showTable is enabled
            if(null != selectedOperation.showTable && selectedOperation.showTable && null != selectedOperation.tableSObject && selectedOperation.tableSObject == 'USER_STORY_COMMIT__c') {
                getSnapshotCommitWrappers();
            } else {
                snapshotCommitWrappers = new List<SnapshotCommitWrapper>();
            }
        } else {
            selectedOperation = null;
        }
    }

    /**
     * Calls backend for Git Operations file which contains options JSON file
     * @return PageReference
     */
    public PageReference requestGitOperationsFile() {
        try {
            String callUrul = Settings.server_url + '/json/v1/gitOperations';
            HttpRequest req = new HttpRequest();
            req.setTimeout(30000);
            DeployAPI.setAuthHeaders(req);
            req.setHeader('Accept', 'application/json');
            req.setEndpoint(callUrul);
            req.setMethod('GET');
            Http h = new Http();
            HttpResponse res = h.send(req);
            String body = res.getBody();
            parseGitOperationsFile(body);
        } catch(Exception ex) {
            errorDetails = UIDesignHelper.catchExceptionMessage(ex);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Connection_Problem));
        }
        return null;
    }

    /**
     * Parser method for Git Operations file retrieved from backend
     * @param jsonStr Backend call Http response body
     */
    @TestVisible
    private void parseGitOperationsFile(String jsonStr) {
        List<Object> jsonObject = new List<Object>();
        try {
            jsonObject = (List<Object>) JSON.deserializeUntyped(jsonStr);
        } catch(Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Error_Parsing_Git_File));
            return;
        }

        //This is for showing a git operation if a related Git Operation Permission found in custom setting
        //Ordering By SetupOwner.Type is for if 2 custom setting found for user choose User setting over Profile setting
        Set<String> allowedGitOperationLabels = new Set<String>();
        List<Git_Operation_Restriction__c> allowedGitOperations = new List<Git_Operation_Restriction__c>();
        if(Schema.SObjectType.Git_Operation_Restriction__c.isAccessible() && Schema.SObjectType.Git_Operation_Restriction__c.isQueryable()) {
            allowedGitOperations = [
                SELECT Id, SetupOwner.Name, SetupOwner.Type, SetupOwnerId, Git_Operation_Name__c, Active__c
                FROM Git_Operation_Restriction__c
                WHERE (SetupOwnerId = :UserInfo.getUserId() OR SetupOwnerId = :UserInfo.getProfileId()) AND Active__c = TRUE
                ORDER BY SetupOwnerId
            ];

            Git_Operation_Restriction__c orgDefaultRestriction = Git_Operation_Restriction__c.getOrgDefaults();
            if(null != orgDefaultRestriction && orgDefaultRestriction.Active__c == true) {
                allowedGitOperations.add(orgDefaultRestriction);
            }

            if(!allowedGitOperations.isEmpty()) {
                List<String> allowedGitOperationsLabelsList = new List<String>();
                allowedGitOperationsLabelsList.addAll(allowedGitOperations[0].Git_Operation_Name__c.trim().toLowerCase().split(';'));
                if(!allowedGitOperationsLabelsList.isEmpty()) {
                    for(Integer i = 0; i < allowedGitOperationsLabelsList.size(); i++) {
                        allowedGitOperationsLabelsList[i] = allowedGitOperationsLabelsList[i].trim();
                    }
                    allowedGitOperationLabels.addAll(allowedGitOperationsLabelsList);
                }
            }
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Git_Operation_Restriction__c.getLabel());
            return;
        }

        for(Object jsonObj : jsonObject) {
            Operation op = new Operation();
            try {
                op = (Operation) JSON.deserialize(JSON.serialize(jsonObj), Operation.class);
            } catch(Exception ex) {
                errorDetails = UIDesignHelper.catchExceptionMessage(ex);
                continue;
            }

            // Validate that the operation is available for the current page
            if((String.isNotBlank(userStoryId) && !op.pages.contains('UserStoryCommit')) || (String.isBlank(userStoryId) && !op.pages.contains('GitSnapshotCommit'))) {
                continue;
            }

            //If operation label exist in custom setting OR if there is no active custom setting then add it to picklist
            if(!String.isEmpty(op.operationLabel) && ((allowedGitOperationLabels.contains(op.operationLabel.toLowerCase())) || allowedGitOperations.isEmpty())) {
                operationTypes.add(new SelectOption(op.operationLabel, op.operationLabel));
                operationsMap.put(op.operationLabel, op);
            }

            if(!String.isEmpty(op.possibleRunningJob)) {
                possibleRunningJobs += op.possibleRunningJob + ';';
            }
        }

        String tempUSId = String.isNotBlank(userStoryId) ? userStoryId : '';
        String tempOrgId = String.isNotBlank(orgId) ? orgId : '';
        String tempSnapshotId = String.isNotBlank(snapshotId) ? snapshotId : '';
        possibleRunningJobs = possibleRunningJobs.replace('{!userStoryId}', tempUSId).replace('{!orgId}', tempOrgId).replace('{!snapshotId}', tempSnapshotId);

        jsonObject.clear();
    }

    /**
     * Wrapper object to parse Git Operations file easily
     */
    public class Operation {
        public String operationType { get; set; }
        public String operationLabel { get; set; }
        public String operationButtonLabel { get; set; }
        public String endpoint { get; set; }
        public Boolean showCommitMessage { get; set; }
        public String helpText { get; set; }
        public String helpLink { get; set; }
        public List<OperationFormElement> operationFormElements { get; set; }
        public String pages { get; set; }
        public String attachmentName { get; set; }
        public Boolean showAdvancedSection { get; set; }

        // Grid
        public Boolean showGrid { get; set; }
        public Boolean editGrid { get; set; }
        public Boolean reloadGridData { get; set; }
        public String gridMetadataTypes { get; set; }
        public Boolean showUserStorySelections { get; set; }

        // Table
        public Boolean showTable { get; set; }
        public String tableSObject { get; set; }

        public String possibleRunningJob { get; set; }
    }

    /**
     * Wrapper object to parse Git Operation file easily
     */
    public class OperationFormElement {
        public String label { get; set; }
        public String name { get; set; }
        public String type { get; set; }
        public String helpText { get; set; }
        public String value { get; set; }
        public Boolean boolValue { get; set; }
    }

    /**
     * Method to get the list of params from the operation form elements
     */
    public String getOperationFormElementParams() {
        String formElementParams = '';
        if(null != selectedOperation.operationFormElements) {
            for(OperationFormElement element : selectedOperation.operationFormElements) {
                if(element.type == 'checkbox') {
                    if(null != element.boolValue) {
                        formElementParams += '&' + EncodingUtil.urlEncode(element.name, UTF8) + '=' + element.boolValue;
                    } else {
                        formElementParams += '&' + EncodingUtil.urlEncode(element.name, UTF8) + '=false';
                    }
                } else if(null != element.value) {
                    formElementParams += '&' + EncodingUtil.urlEncode(element.name, UTF8) + '=' + EncodingUtil.urlEncode(element.value, UTF8);
                }
            }
        }
        return formElementParams;
    }

    /**
     * Wrapper object for the Commit Table
     */
    public class SnapshotCommitWrapper {
        public Boolean selected { get; set; }
        public Git_Org_Commit__c snapshotCommit { get; set; }
        public SnapshotCommitWrapper(Boolean b, Git_Org_Commit__c snapshotCommit) {
            this.selected = b;
            this.snapshotCommit = snapshotCommit;
        }
    }

    /**
     * Method to retrieve the Snapshot Commits for the Commit Table whenever the User chooses to Undo Commits
     */
    public void getSnapshotCommitWrappers() {
        Integer limitHeapSize = Limits.getLimitHeapSize();
        Integer maxMetadataHeapSize = 0;
        Integer limitCPUTime = Limits.getLimitCpuTime();
        Integer maxCPUTime = 0;

        if(Schema.SObjectType.Git_Org_Commit__c.isAccessible() && Schema.SObjectType.Git_Org_Commit__c.isQueryable()) {
            if(String.isNotBlank(userStoryId)) {
                try {
                    for(Git_Org_Commit__c snapshotCommit : [
                        SELECT Name, Commit_Message__c, Status__c, CreatedDate, Git_Operation__c, Commit_Id__c
                        FROM Git_Org_Commit__c
                        WHERE Id IN (SELECT Snapshot_Commit__c FROM User_Story_Commit__c WHERE User_Story__c = :userStoryId) AND Status__c = 'Complete'
                        ORDER BY CreatedDate DESC
                        LIMIT 1000
                    ]) {
                        Integer startingHeap = Limits.getHeapSize();
                        Integer startingCpuTime = Limits.getCpuTime();
                        if((startingHeap + maxMetadataHeapSize * 2) > limitHeapSize || (startingCpuTime + maxCPUTime * 2) > limitCPUTime) {
                            System.debug('### Heap Size limit reached. Exit Git Org Commit for loop.');
                            break;
                        }
                        snapshotCommitWrappers.add(new SnapshotCommitWrapper(false, snapshotCommit));

                        Integer addedHeap = Limits.getHeapSize() - startingHeap;
                        Integer addedCpuTime = Limits.getCpuTime() - startingCpuTime;
                        if(addedHeap > maxMetadataHeapSize) {
                            maxMetadataHeapSize = addedHeap;
                        }
                        if(addedCpuTime > maxCPUTime) {
                            maxCPUTime = addedCpuTime;
                        }
                    }
                } catch(Exception ex) {
                    errorDetails = UIDesignHelper.catchExceptionMessage(ex);
                }
            } else if(String.isBlank(userStoryId) && String.isNotBlank(snapshotId)) {
                for(Git_Org_Commit__c snapshotCommit : [
                    SELECT Name, Commit_Message__c, Status__c, CreatedDate, Git_Operation__c, Commit_Id__c
                    FROM Git_Org_Commit__c
                    WHERE Git_Backup__c = :snapshotId AND Status__c = 'Complete'
                    ORDER BY CreatedDate DESC
                    LIMIT 1000
                ]) {
                    Integer startingHeap = Limits.getHeapSize();
                    Integer startingCpuTime = Limits.getCpuTime();
                    if((startingHeap + maxMetadataHeapSize * 2) > limitHeapSize || (startingCpuTime + maxCPUTime * 2) > limitCPUTime) {
                        System.debug('### Heap Size limit reached. Exit Git Org Commit for loop.');
                        break;
                    }
                    snapshotCommitWrappers.add(new SnapshotCommitWrapper(false, snapshotCommit));

                    Integer addedHeap = Limits.getHeapSize() - startingHeap;
                    Integer addedCpuTime = Limits.getCpuTime() - startingCpuTime;
                    if(addedHeap > maxMetadataHeapSize) {
                        maxMetadataHeapSize = addedHeap;
                    }
                    if(addedCpuTime > maxCPUTime) {
                        maxCPUTime = addedCpuTime;
                    }
                }
            }
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Git_Org_Commit__c.getLabel());
            return;
        }
    }
    /**
     * Method to get the list of the selected Commit Ids as a JSON String
     */
    public String getSelectedTableValues() {
        String selectedValues = '';
        List<String> selectedSnapshotIds = new List<String>();
        for(SnapshotCommitWrapper scw : snapshotCommitWrappers) {
            if(scw.selected && null != scw.snapshotCommit.Id) {
                selectedSnapshotIds.add(scw.snapshotCommit.Id);
            }
        }
        if(!selectedSnapshotIds.isEmpty()) {
            selectedValues = JSON.serialize(selectedSnapshotIds);
        }
        return selectedValues;
    }

    public void checkMetadataIndex() {
        if(null != selectedOperation && null != selectedOperation.operationFormElements) {
            for(OperationFormElement ofe : selectedOperation.operationFormElements) {
                if(ofe.name == RECREATEFEATUREBRANCH && ofe.boolValue) {
                    List<User_Story_Metadata__c> usmList = new List<User_Story_Metadata__c>();
                    if(Schema.SObjectType.User_Story_Metadata__c.isAccessible() && Schema.SObjectType.User_Story_Metadata__c.isQueryable()) {
                        usmList = [SELECT Id, Name FROM User_Story_Metadata__c WHERE User_Story__c = :userStoryId];
                    } else {
                        UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story_Metadata__c.getLabel());
                        return;
                    }
                    if(!usmList.isEmpty()) {
                        Utilities.Secure_DML(usmList, Utilities.DML_Action.DEL, Schema.SObjectType.User_Story_Metadata__c);
                    }
                }
            }
        }
    }

    /**
     * Method to call the GlobalUtilities method that updates the User Story Base Branch field.
     */
    public PageReference updateUserStory() {
        if(null != userStory) {
            GlobalUtilities.updateUserStoryBaseBranch(userStory.Id, baseBranch);
        }
        return null;
    }

    /**
     * It is used to redirect to the user story waiting for page
     * Note: it will only work for user story for now
     * @return
     */
    public PageReference goToWaitingForPage() {
        String commitId = ApexPages.currentPage().getParameters().get('commitId');
        PageReference preference = Page.UserStoryPageWaitingFor;
        preference.getParameters().put('id', userStoryId);
        preference.getParameters().put('type', 'co_commitChanges');
        preference.getParameters().put('ep', selectedOperation.endpoint);
        preference.getParameters().put('sId', snapshotId);
        preference.getParameters().put('mBranch', baseBranch);
        preference.getParameters().put('cType', gitCommit.Git_Operation__c);
        preference.getParameters().put('cId', commitId);
        if(null != selectedOperation && null != selectedOperation.operationFormElements) {
            for(OperationFormElement ofe : selectedOperation.operationFormElements) {
                if(ofe.name == RECREATEFEATUREBRANCH) {
                    preference.getParameters().put(ofe.name, String.valueOf(ofe.boolValue));
                }
            }
        }
        preference.setRedirect(true);
        return preference;
    }
}