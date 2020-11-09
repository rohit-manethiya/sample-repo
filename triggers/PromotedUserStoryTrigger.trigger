trigger PromotedUserStoryTrigger on Promoted_User_Story__c (after insert, after update, before insert, before update) {
  TriggerFactory.createAndExecuteHandler(PromotedUserStoryTriggerHandler.class);
}