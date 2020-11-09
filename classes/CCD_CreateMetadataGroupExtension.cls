public with sharing class CCD_CreateMetadataGroupExtension {
    public Metadata_Group__c thisMetadataGroup { get; set; }
    public static Metadata_Group_Item__c groupItemFilter { get; set; }
    public String selectedMetadataItemName { get; set; }
    public List<Metadata_Group_Item__c> groupItems { get; set; }
    public List<SelectOption> itemTypeOptions {
        get {
            if(itemTypeOptions == null) {
                itemTypeOptions = new List<SelectOption>();
                List<Schema.PicklistEntry> picklistValues = Metadata_Group_Item__c.Type__c.getDescribe().getPicklistValues();
                for(PicklistEntry thisValue : picklistValues) {
                    SelectOption thisOption = new SelectOption(thisValue.getValue(), thisValue.getLabel());
                    itemTypeOptions.add(thisOption);
                }
            }
            return itemTypeOptions;
        }
        private set;
    }
    public List<SelectOption> itemOperatorOptions {
        get {
            if(itemOperatorOptions == null) {
                itemOperatorOptions = new List<SelectOption>();
                List<Schema.PicklistEntry> picklistValues = Metadata_Group_Item__c.Operator__c.getDescribe().getPicklistValues();
                for(PicklistEntry thisValue : picklistValues) {
                    SelectOption thisOption = new SelectOption(thisValue.getValue(), thisValue.getLabel());
                    itemOperatorOptions.add(thisOption);
                }
            }
            return itemOperatorOptions;
        }
        private set;
    }

    static {
        groupItemFilter = new Metadata_Group_Item__c();
    }

    public CCD_CreateMetadataGroupExtension(ApexPages.StandardController thisStdController) {
        thisMetadataGroup = (Metadata_Group__c) thisStdController.getRecord();

        if(thisMetadataGroup.Id != null) {
            getMetadataGroupItems();
        } else {
            groupItems = new List<Metadata_Group_Item__c>();
        }
    }

    private void getMetadataGroupItems() {
        groupItems = [SELECT Type__c, Operator__c, Value__c FROM Metadata_Group_Item__c
                      WHERE Metadata_Group__c = :thisMetadataGroup.Id];
    }

    public void addGroupItem() {
        Metadata_Group_Item__c thisItem = new Metadata_Group_Item__c();
        thisItem.Type__c = groupItemFilter.Type__c;

        if(selectedMetadataItemName == Label.ALL) {
            thisItem.Operator__c = Label.ALL;
            thisItem.Value__c = '*';
        } else {
            thisItem.Operator__c = groupItemFilter.Operator__c;
            thisItem.Value__c = groupItemFilter.Value__c;
        }

        groupItems.add(thisItem);
    }

    public PageReference save() {
        ApexPages.getMessages().clear();

        try {
            Utilities.Secure_DML(thisMetadataGroup, Utilities.DML_Action.UPS, SObjectType.Metadata_Group__c);

            for(Metadata_Group_Item__c thisItem : groupItems) {
                if(thisItem.Id == null) {
                    thisItem.Metadata_Group__c = thisMetadataGroup.Id;
                }
            }

            Utilities.Secure_DML(groupItems, Utilities.DML_Action.UPS, SObjectType.Metadata_Group_Item__c);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.SAVE_SUCCESS));
        } catch(Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }

        return null;
    }
}