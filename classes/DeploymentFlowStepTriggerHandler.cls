public class DeploymentFlowStepTriggerHandler implements ITrigger{

    //public class ApplicationException extends Exception {}

    public DeploymentFlowStepTriggerHandler(){
    }

    public void bulkBefore(){
        if(Trigger.new !=null) {
            DeploymentFlowStepTriggerHelper.prepareData();
        }
        if(Trigger.isInsert) {
            DeploymentFlowStepTriggerHelper.populateFlowStepDestinationBranch(Trigger.new, null);
        } else if(Trigger.isUpdate) {
            DeploymentFlowStepTriggerHelper.populateFlowStepDestinationBranch(Trigger.new, (Map<Id, Deployment_Flow_Step__c>) Trigger.oldMap);
        }
    }

    public void bulkAfter() {

        if (Trigger.isInsert || Trigger.isUpdate) {
            DeploymentFlowStepTriggerHelper.firePossibleFlowValidations(Trigger.new);
        }
    }

    public void beforeInsert(SObject so){
    }

    public void beforeUpdate(SObject oldSo, SObject so){
    }

    public void beforeDelete(SObject so){
    }

    public void afterInsert(SObject so){
    }

    public void afterUpdate(SObject oldSo, SObject so){
    }

    public void afterDelete(SObject so){
    }

    public void afterUndelete(SObject so){
    }

    public void andFinally(){
    }
}