public without sharing class PromotedUserStoryTriggerHandler implements ITrigger{
    public class ApplicationException extends Exception {}

    public PromotedUserStoryTriggerHandler(){
    }

    public void bulkBefore(){

    }

    public void bulkAfter(){
    }

    public void beforeCommon(SObject so){

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
        PromotedUserStoryTriggerHelper.prepareCheckBackPromotion(oldSo,so);
    }

    public void afterDelete(SObject so){
    }

    public void afterUndelete(SObject so){
    }
    public void andFinally(){

    }
}