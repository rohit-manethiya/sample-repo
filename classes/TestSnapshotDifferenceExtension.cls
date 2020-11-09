@isTest
private class TestSnapshotDifferenceExtension {
    @testSetup static void setupData() {
        TestUtilities.setTestSettingsEE();
    }
    @testSetup static void setupDataDML() {
        testMethodUtilities.upsertOrgwideSettings();
    }
    @isTest
    static void test() {

        Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', 'SFDC_OrgId', null, null, system.now(), null);
        insert testOrg1;

        Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', 'SFDC_OrgId2', null, null, system.now(), null);
        insert testOrg2;
        Snapshot_Difference__c sn = new Snapshot_Difference__c(Source_Org_Credential__c = testOrg1.Id,
                Destination_Org_Credential__c = testOrg2.Id,
                Name = 'test',
                Source_Option__c = 'Salesforce Org',
                Destination_Option__c = 'Salesforce Org');
        snapshotDifferenceExtension ext = new snapshotDifferenceExtension(new ApexPages.StandardController(sn));
        ext.cancel();
        insert sn;
        ext = new snapshotDifferenceExtension(new ApexPages.StandardController(sn));
        ext.doRerender();
        ext.edit();
        ext.cancel();
        update sn;
        delete sn;
        undelete sn;

        sn.Source_Option__c = 'Git Commit';
        update sn;
        ext.doRerender();

        sn.Destination_Option__c = 'Git Commit';
        update sn;
        ext.doRerender();
        System.assertEquals(null, sn.Destination_Org_Credential__c);

        sn.Source_Option__c = 'Salesforce Org';
        update sn;
        ext.doRerender();

        sn.Source_Option__c = 'Git Commit';
        sn.Destination_Option__c = 'Salesforce Org';
        update sn;
        ext.doRerender();
        System.assertEquals(null, sn.Source_Org_Credential__c);

        sn.Source_Option__c = null;
        sn.Destination_Option__c = null;
        update sn;
        ext.doRerender();

        sn.Source_Option__c = 'Salesforce Org';
        sn.Destination_Option__c = 'Salesforce Org';
        update sn;
        ext.doRerender();
        ext.save();
        User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
        insert testUserStory;
        ext.us4Lookup.user_story__c = testUserStory.id;
        ext.checkEnvironment();
    }
}