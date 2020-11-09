/**
 * Created by COPADO\ucan on 9/6/19.
 */

@IsTest
private class Test_ConnectionBehaviorTriggerHandler {
    @IsTest
    static void testBehavior() {
        Test.startTest();
        Connection_Behavior__c cbItem = CMTestMethodUtilities.createConnectionBehavior('Automated', '57 0 1 ? * * *');
        System.debug('cbItem 1 '+cbItem);
        cbItem.Promotion_Behavior__c = 'Scheduled';
        update cbItem;
        System.debug('cbItem==2=> '+cbItem);
        List<CronTrigger> ctList = [SELECT Id, CronExpression, CronJobDetailId, OwnerId, State FROM CronTrigger WHERE CronExpression = '57 0 1 ? * * *'];
        System.debug('ctList==1==> ' + ctList);
        System.assertEquals(1, ctList.size());
        cbItem.Back_Promotion_Behavior__c = 'Scheduled';
        update cbItem;
        ctList = [SELECT Id, CronExpression, CronJobDetailId, OwnerId, State FROM CronTrigger WHERE CronExpression = '57 0 1 ? * * *'];
        System.debug('ctList==2==> ' + ctList);
        System.assertEquals(2, ctList.size());

        cbItem.Promotion_Schedule__c = '19 1 2 ? * * *';
        update cbItem;
        ctList = [SELECT Id, CronExpression, CronJobDetailId, OwnerId, State FROM CronTrigger WHERE CronExpression = '19 1 2 ? * * *'];
        System.debug('ctList==3==> ' + ctList);
        System.assertEquals(1, ctList.size());

        cbItem.Back_Promotion_Behavior__c = 'Manual';
        cbItem.Promotion_Behavior__c = 'Automated';
        update cbItem;
        delete cbItem;

        Test.stopTest();

    }
}