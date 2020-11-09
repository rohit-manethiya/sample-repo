public with sharing class TriggerDispatcher {
    public static void run(ITriggerHandler thisTrigger, TriggerOperation thisEvent) {
        if(thisTrigger.isDisabled()) {
            return;
        }

        switch on thisEvent {
            when BEFORE_INSERT {
                thisTrigger.onBeforeInsert(trigger.new);
            } when BEFORE_UPDATE {
                thisTrigger.onBeforeUpdate(trigger.new, trigger.oldMap);
            } when BEFORE_DELETE {
                thisTrigger.onBeforeDelete(trigger.old);
            } when AFTER_INSERT {
                thisTrigger.onAfterInsert(trigger.new);
            } when AFTER_UPDATE {
                thisTrigger.onAfterUpdate(trigger.new, trigger.oldMap);
            } when AFTER_DELETE {
                thisTrigger.onAfterDelete(trigger.old);
            } when AFTER_UNDELETE {
                thisTrigger.onAfterUndelete(trigger.old);
            }
        }
    }
}