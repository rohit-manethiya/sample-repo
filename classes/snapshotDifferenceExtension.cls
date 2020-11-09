public with sharing class snapshotDifferenceExtension {
    //public boolean disableRunDeepDiff {get;set;}
    //public boolean renderDiffResults {get;set;}
    public Boolean isEdit { get; set; }
    public Settings settings { get; set; }
    public Snapshot_Difference__c snapshot { get; set; }
    public ApexPages.StandardController controller { get; set; }
    public String keyPrefix { get; set; }
    public Boolean isSnapshotEnabled { get; set; }
    public Boolean isShareable { get; set; }
    public Boolean showError { get; set; }
    public Boolean showOptions { get; set; }
    public Id usId { get; set; }
    public User_Story_Task__c us4Lookup {
        get {
            if(null == us4Lookup) {
                us4Lookup  = new User_Story_Task__c();
            }
            return us4Lookup ;
        }
        set;
    }
    private final String SNAPSHOT_DIFFERENCE = 'Snapshot Difference';
    private final String GIT_COMMIT = 'Git Commit';
    private final String SALESFORCE_ORG = 'Salesforce Org';

    public static final String[] SNAPSHOT_FIELDS = new String[]{
            'Id', 'Name', 'Last_Run__c', 'Source_Option__c', 'Destination_Option__c', 'Source_Git_Commit__c', 'Destination_Git_Commit__c', 'Source_Org_Credential__c', 'Destination_Org_Credential__c'
    };

    public snapshotDifferenceExtension(ApexPages.StandardController stdController) {
        showOptions = true;
        showError = false;
        isLicenseEnabled();
        settings = new Settings();

        controller = stdController;
        if(!Test.isRunningTest()) {
            stdController.addFields(SNAPSHOT_FIELDS); stdController.addFields(new List<String>{
                    'source_org_credential__r.environment__c'
            });
        }
        this.snapshot = (Snapshot_Difference__c) stdController.getRecord();
        DescribeSObjectResult dsr = Git_Org_Commit__c.SObjectType.getDescribe();
        keyPrefix = dsr.getKeyPrefix();
        //renderDiffResults = false;
        //disableRunDeepDiff = true;
        isEdit = true;
        if(this.snapshot == null) {
            this.snapshot = new Snapshot_Difference__c();
            //disableRunDeepDiff = true;
        }
        //calculate last run based on lastmodified date of index.json
        if(!String.isBlank(this.snapshot.Id)) {
            if(Schema.SObjectType.Attachment.isQueryable() && Schema.SObjectType.Attachment.isAccessible()) {
                List<Attachment> attList = [SELECT LastModifiedDate FROM Attachment WHERE ParentId = :this.snapshot.Id AND Name = 'index.json' ORDER BY LastModifiedDate DESC LIMIT 1];
                if(attList.size() == 1) {
                    this.snapshot.Last_Run__c = attList.get(0).LastModifiedDate;
                }
            } else {
                //TODO add global method for insufficient access error when it is back-promoted
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Schema.SObjectType.Attachment.getName() + ': ' + Label.Insufficient_Access_Rights));
            }
        }

        /*if(snapshot.Id != null && snapshot.Last_Run__c != null) {
            this.renderDiffResults = true;
            disableRunDeepDiff = false;
        }*/
        if(snapshot.Id != null) {
            isEdit = false;
        }
        //evaludateDisableRunDiff();

        isSnapshotEnabled = true;
        Boolean isLicensesExceeded = LicenseHelper.isLicensesExceeded();
        if(!FeatureHelper.isFeatureEnabled(SNAPSHOT_DIFFERENCE) || isLicensesExceeded) {
            if(isLicensesExceeded) {
                ApexPages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, Label.LICENSES_EXCEEDED));
            } else {
                ApexPages.addMessage(new Apexpages.Message(Apexpages.Severity.WARNING, Label.FEATURE_NOT_SUPPORTED + ' ' + SNAPSHOT_DIFFERENCE));
            }
            isSnapshotEnabled = false;
        }
        System.debug('*** feature enabled: ' + isSnapshotEnabled);
        Map<String, Schema.SObjectType> tokens = Schema.getGlobalDescribe();
        isShareable = tokens.containsKey('Snapshot_Difference__Share');
    }
    /*public void evaludateDisableRunDiff(){
        if(snapshot.Source_Option__c==null || snapshot.Destination_Option__c==null){
            disableRunDeepDiff = true;
            return;
        }
        if(snapshot.Source_Option__c=='Git Commit' && snapshot.Source_Git_Commit__c==null)disableRunDeepDiff = true;
        if(snapshot.Destination_Option__c=='Git Commit' && snapshot.Destination_Git_Commit__c==null)disableRunDeepDiff = true;
        if(snapshot.Source_Option__c=='Salesforce Org' && snapshot.Source_Org_Credential__c==null)disableRunDeepDiff = true;
        if(snapshot.Destination_Option__c=='Salesforce Org' && snapshot.Destination_Org_Credential__c==null)disableRunDeepDiff = true;
        disableRunDeepDiff = false;
    }*/
    public void doRerender() {
        //evaludateDisableRunDiff();
        if(snapshot.Destination_Option__c == null) {
            snapshot.Destination_Org_Credential__c = null;
            snapshot.Destination_Git_Commit__c = null;
        }
        if(snapshot.Destination_Option__c == GIT_COMMIT) {
            snapshot.Destination_Org_Credential__c = null;
        }
        if(snapshot.Destination_Option__c == SALESFORCE_ORG) {
            snapshot.Destination_Git_Commit__c = null;
        }

        if(snapshot.Source_Option__c == null) {
            snapshot.Source_Org_Credential__c = null;
            snapshot.Source_Git_Commit__c = null;
        }
        if(snapshot.Source_Option__c == GIT_COMMIT) {
            snapshot.Source_Org_Credential__c = null;
            snapshot.Partial_Selection__c = false;
        }
        if(snapshot.Source_Option__c == SALESFORCE_ORG) {
            snapshot.Source_Git_Commit__c = null;
            snapshot.Partial_Selection__c = false;
        }
    }
    public void edit() {
        isEdit = true;
    }
    public void isLicenseEnabled() {
        if(!LicenseHelper.actionIsLicenseEnabled('viewEditSnapshotDifferences')) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CCM_License_Restriction));
            showError = true;
            showOptions = false;
        }
        return;
    }

    public PageReference cancel() {
        return controller.cancel();
    }
    public PageReference save() {
        String errorMsg = Label.Source_Destination_validation_for_commit;
        if(snapshot.Source_Option__c == null || snapshot.Destination_Option__c == null) {
            snapshot.addError(errorMsg);
            return null;
        }
        if((snapshot.Source_Option__c == SALESFORCE_ORG && snapshot.Source_Org_Credential__c == null)
                || (snapshot.Destination_Option__c == SALESFORCE_ORG && snapshot.Destination_Org_Credential__c == null)) {
            snapshot.addError(errorMsg);
            return null;
        }
        if((snapshot.Source_Option__c == GIT_COMMIT && snapshot.Source_Git_Commit__c == null)
                || (snapshot.Destination_Option__c == GIT_COMMIT && snapshot.Destination_Git_Commit__c == null)) {
            snapshot.addError(errorMsg);
            return null;
        }
        PageReference pref = controller.save();

        return pref;
    }

    public void checkEnvironment() {
        showError = false;
        usId = us4Lookup.User_Story__c;
        String errorMsg = Label.Environment_selected_US_same_Environment;
        Id usOrgId;
        if(Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
            usOrgId = [SELECT Org_Credential__c,Environment__c FROM User_Story__c WHERE Id = :us4Lookup.User_Story__c].Environment__c;
        } else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Schema.SObjectType.User_Story__c.getName() + ': ' + Label.Insufficient_Access_Rights));
        }
        if(this.snapshot.Source_Org_Credential__c != null && this.snapshot.Source_Org_Credential__r.Environment__c != usOrgId) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, errorMsg));
            showError = true;
        }
    }
}