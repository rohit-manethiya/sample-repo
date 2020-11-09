public with sharing class FilterManager {
    private static final String USER_STORY = 'User_Story__c';
    private static final String ENVIRONMENT = 'Environment__c';
    private static IFilterFactory thisFilterFactory;
    public IFilter thisFilterInstance { get; private set; }
    public String thisObjectType;
    public String selectedFilterId { get; set; }
    public FilterWrapper selectedFilter { get; set; }

    public List<SelectOption> fieldOptions {
        get {
            List<SelectOption> options = new List<SelectOption>();
            Map<String, SObjectField> userStoryFields = Schema.getGlobalDescribe().get(Settings.ns + USER_STORY).getDescribe().fields.getMap();
            for(SObjectField thisField : userStoryFields.values()) {
                if(thisField.getDescribe().isAccessible()) {
                    SelectOption thisOption = new SelectOption(thisField.getDescribe().getName(), thisField.getDescribe().getLabel());
                    options.add(thisOption);
                }
            }
            return options;
        }
    }
    public String selectedField { get; set; }
    public String selectedOperator { get; set; }
    public String selectedValue { get; set; }

    static {
        thisFilterFactory = new IFilterFactory();
    }

    public IFilter getFilterInstance(String objectType) {
        if(thisFilterInstance == null) {
            thisFilterInstance = thisFilterFactory.getFilterInstance(objectType);
        }
        return thisFilterInstance;
    }

    public String getThisObjectType() {
        return thisObjectType;
    }

    public void setThisObjectType(String value) {
        thisObjectType = value;
        initFilterInstance();
    }

    public void initFilterInstance() {
        if(thisFilterInstance == null) {
            thisFilterInstance = thisFilterFactory.getFilterInstance(thisObjectType);
        }
        applySelectedFilter();
    }

    public void applySelectedFilter() {
        thisFilterInstance.setSelectedFilterId(selectedFilterId);
        loadSelectedFilter();
        // TODO: rerender pipeline diagram
    }

    public void loadSelectedFilter() {
        selectedFilter = thisFilterInstance.getSelectedFilter();
    }

    public void saveFilter() {
        if(requiredFieldsAreEmpty()) {
            return;
        }
        if(selectedFilter.filterConditions.isEmpty()) {
            createFirstCondition();
        }
        String filterConditionJSON = JSON.serialize(selectedFilter.filterConditions);
        System.debug('filterConditionJSON: ' + filterConditionJSON);
        selectedFilter.thisFilter.Parameters__c = filterConditionJSON;
        try {
            Utilities.Secure_DML(selectedFilter.thisFilter, Utilities.DML_Action.UPS, SObjectType.Filter__c);
        } catch(DmlException dmlEx) {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, dmlEx.getDmlMessage(0)));
        } catch(Exception ex) {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
    }

    private void createFirstCondition() {
        selectedFilter.filterConditions = new List<FilterCondition>();
        FilterCondition thisCondition = new FilterCondition();
        thisCondition.fieldApiName = selectedField;
        thisCondition.operator = selectedOperator;
        thisCondition.fieldValue = selectedValue;
        selectedFilter.filterConditions.add(thisCondition);
    }

    private Boolean requiredFieldsAreEmpty() {
        ApexPages.getMessages().clear();

        Boolean requiredFieldsAreEmpty = false;
        if(String.isBlank(selectedFilter.thisFilter.Name)) {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, SObjectType.User_Story__c.fields.Name.Label + ' ' + Label.Required_Field));
            requiredFieldsAreEmpty = true;
        }
        return requiredFieldsAreEmpty;
    }

    public with sharing class EnvironmentFilter implements IFilter {
        private String selectedFilterId;

        public Map<Id, FilterWrapper> getFilters() {
            return null;
        }

        public void setSelectedFilterId(String filterId) {
            selectedFilterId = filterId;
        }

        public FilterWrapper getSelectedFilter() {
            return null;
        }

        public List<SelectOption> getFilterOptions() {
            return null;
        }
    }

    public with sharing class UserStoryFilter implements IFilter {
        private String selectedFilterId;
        private Map<Id, FilterWrapper> filterWrapperMap;

        public UserStoryFilter() {
            initFilters();
        }

        public Map<Id, FilterWrapper> getFilters() {
            if(filterWrapperMap == null) {
                initFilters();
            }
            return filterWrapperMap;
        }

        private void initFilters() {
            filterWrapperMap = new Map<Id, FilterWrapper>();
            List<Filter__c> filters = [SELECT Name, Parameters__c FROM Filter__c WHERE OwnerId = :UserInfo.getUserId()];
            for(Filter__c thisFilter : filters) {
                FilterWrapper thisFilterWrapper = new FilterWrapper(thisFilter);
                filterWrapperMap.put(thisFilter.Id, thisFilterWrapper);
            }
        }

        public void setSelectedFilterId(String filterId) {
            selectedFilterId = filterId;
        }

        public FilterWrapper getSelectedFilter() {
            FilterWrapper thisFilterWrapper = filterWrapperMap.get(selectedFilterId);
            if(thisFilterWrapper == null) {
                Filter__c thisFilter = new Filter__c();
                thisFilterWrapper = new FilterWrapper(thisFilter);
            }
            return thisFilterWrapper;
        }

        public List<SelectOption> getFilterOptions() {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('', Label.ALL));
            for(FilterWrapper thisWrapper : filterWrapperMap.values()) {
                SelectOption thisOption = new SelectOption(thisWrapper.thisFilter.Id, thisWrapper.thisFilter.Name);
                options.add(thisOption);
            }
            return options;
        }
    }

    private with sharing class IFilterFactory {
        public IFilter getFilterInstance(String filterType) {
            try {
                if(filterType == FilterManager.USER_STORY) {
                    return new UserStoryFilter();
                } else if (filterType == FilterManager.ENVIRONMENT) {
                    return new EnvironmentFilter();
                }
            } catch(Exception ex) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            }
            return null;
        }
    }

    public interface IFilter {
        Map<Id, FilterWrapper> getFilters();
        void setSelectedFilterId(String filterId);
        FilterWrapper getSelectedFilter();
        List<SelectOption> getFilterOptions();
    }

    private with sharing class FilterWrapper {
        public Filter__c thisFilter { get; private set; }
        public List<FilterCondition> filterConditions { get; private set; }

        public FilterWrapper(Filter__c filter) {
            thisFilter = filter;
            filterConditions = new List<FilterCondition>();
            if(String.isNotBlank(thisFilter.Parameters__c)) {
                setFilterConditions();
            }
        }

        private void setFilterConditions() {
            try {
                filterConditions = (List<FilterCondition>) JSON.deserialize(thisFilter.Parameters__c, FilterCondition.class);
            } catch(JSONException ex) {
                if(ApexPages.currentPage() != null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
                } else {
                    throw ex;
                }
            }
        }
    }

    private class FilterCondition {
        public String fieldApiName { get; private set; }
        public String operator { get; private set; }
        public String fieldValue { get; private set; }
    }
}