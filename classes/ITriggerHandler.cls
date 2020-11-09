public interface ITriggerHandler {
    void onBeforeInsert(List<SObject> newList);
    void onBeforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap);
    void onBeforeDelete(List<SObject> oldList);
    void onAfterInsert(List<SObject> newList);
    void onAfterUpdate(List<SObject> newList, Map<Id, SObject> oldMap);
    void onAfterDelete(List<SObject> oldList);
    void onAfterUndelete(List<SObject> oldList);
    Boolean isDisabled();
}