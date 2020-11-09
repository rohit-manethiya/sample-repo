public with sharing class StepEditionController {
    public final String STEP_TYPE_USERS = 'Users';
    public Settings settings { get; set; }

    /**
     * main component object
     */
    public Step__c step;
    public Boolean scalableGrid { get; set; }

    /* faster render definer */
    public String stepType { get; set; }

    /* helper to create inputText */
    public String inputAux { get; set; }
    public AuxiliaryObject__c lookupAux { get; set; }

    /* shows if from Org has filter activated */
    public Boolean filtered { get; set; }

    /**
     * config helper for UI components for step type.
     */
    public Map<String, Map<String, Object>> completeUITypeConfig = new Map<String, Map<String, Object>>{
        'Users' => new Map<String, Object>{ 'renderForm' => true, 'renderGrid' => true, 'renderQueryBuilder' => false },
        'MetaData' => new Map<String, Object>{ 'renderForm' => false, 'renderGrid' => true, 'renderQueryBuilder' => false },
        'Full Profiles' => new Map<String, Object>{ 'renderForm' => false, 'renderGrid' => true, 'renderQueryBuilder' => false }
    };

    public Map<String, Object> configUI { get; set; }

    /**
     * setter should be defined in commponents
     * to call fake constructor for UI
     */
    public void setStep(Step__c s) {
        this.step = s;
        this.stepType = s.Type__c;
        //init UI config.
        initConfig();
    }

    public Step__c getStep() {
        return this.step;
    }

    public StepEditionController() {
        //initConfig();
        settings = new Settings();
        scalableGrid = Settings.scalableGrid;
    }

    public void initConfig() {
        configUI = completeUITypeConfig.get(this.stepType);

        //TODO
        filtered = true;
    }

    public Boolean getIsFeatureAvailable() {
        return true;
    }

    /**
     * TriggerType values can be Scheduled, PlatformEvent, RecordAfterSave, among others. Null means it is not automatically fired by itself.
     * NamespacePrefix will contain the namespace if the flow was installed from a package, which is ManegeableState = true
     * ProcessType can have also values Flow which means it is an screen flow, and Workflow, CustomEvent OR InvocableProcess which means it is a process builder
     * TODO: group flows by package (Namespace)
     */
    public String getFlowsAvailableForExecution() {
        final List<FlowOptionWrapper> flowOptionWrappersAvailableForExecution = new List<FlowOptionWrapper>();
        for (FlowDefinitionView flowAvailableForExecution : [
            SELECT ApiName, Label, NamespacePrefix
            FROM FlowDefinitionView
            WHERE ProcessType = 'AutoLaunchedFlow' AND IsActive = true AND IsTemplate = false AND TriggerType = null
        ]) {
            final String namespace = flowAvailableForExecution.NamespacePrefix != null ? flowAvailableForExecution.NamespacePrefix + '.' : '';
            flowOptionWrappersAvailableForExecution.add(
                new FlowOptionWrapper(namespace + flowAvailableForExecution.ApiName, namespace + flowAvailableForExecution.Label)
            );
        }

        return JSON.serialize(flowOptionWrappersAvailableForExecution);
    }

    public class FlowOptionWrapper {
        private final String flowApiName;
        private final String flowLabel;

        public FlowOptionWrapper(final String flowApiName, final String flowLabel) {
            this.flowApiName = flowApiName;
            this.flowLabel = flowLabel;
        }
    }
}