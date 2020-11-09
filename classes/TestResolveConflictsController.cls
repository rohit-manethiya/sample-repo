@isTest
private class TestResolveConflictsController {
    @testSetup
    static void setupData() {
        TestUtilities.getAllMultilicense();
    }

    @isTest
    static void testAutoResolveAttachment() {
        testMethodUtilities.upsertOrgwideSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, false);
        Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
        insert feature;

        Git_Repository__c gitRepo = new Git_Repository__c(name = 'gitRepo');
        insert gitRepo;
        Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
        insert flowCBM;
        System.assert(flowCBM.Id != null);

        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flowCBM.Id;
        insert testProject;

        Environment__c envDev1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
        Environment__c envInt = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
        insert new List<Environment__c>{ envDev1, envInt };

        Org__c orgDev1 = CMTestMethodUtilities.createOrg('MyOrgDev1', 'Sandbox', 'SFDC_OrgId', null, null, system.now(), envDev1.Id);
        Org__c orgInt = CMTestMethodUtilities.createOrg('MyOrgInt', 'Production', 'SFDC_OrgId3', null, null, system.now(), envInt.Id);
        insert new List<Org__c>{ orgDev1, orgInt };

        Git_Backup__c gitSnapshotDev1 = new Git_Backup__c(Git_Repository__c = gitRepo.id, Org__c = orgDev1.id, Branch__c = 'dev1');
        Git_Backup__c gitSnapshotInt = new Git_Backup__c(Git_Repository__c = gitRepo.id, Org__c = orgInt.id, Branch__c = 'int');
        insert new List<Git_Backup__c>{ gitSnapshotDev1, gitSnapshotInt };

        Deployment_Flow_Step__c stepDev1ToInt = CMTestMethodUtilities.createFlowStep(envDev1.Id, envInt.Id, flowCBM.Id);
        stepDev1ToInt.Branch__c = 'dev1';
        insert stepDev1ToInt;

        Promotion__c promotion = CMTestMethodUtilities.createPromotion(testProject.Id, envDev1.Id);
        promotion.Status__c = 'Merge Conflicts';
        insert promotion;

        String body1 = 'public class AccountOperations { public static Account setDefaultDescription(Account a) { <<<<<<< HEAD if (a.Description != null) return a; else a.Description = "Default Description"; ======= a.Description = "Default Description"; >>>>>>> refs/remotes/origin/feature/US-0061953 return a; } }';
        String body2 = 'public class OpportunityOpperations { public static Opportunity setDefaultDescription(Opportunity opp) { <<<<<<< HEAD if (opp.Description != null) return opp; else opp.Description = "Default Description"; ======= opp.Description = "Default Description"; >>>>>>> refs/remotes/origin/feature/US-0061953 return opp; } }';
        String body3 = '{json: "file"}';

        Attachment att1 = new Attachment(Name = 'US-000001 ApexClass-A.cls', Body = Blob.valueOf(body1), ParentId = promotion.Id);
        Attachment att2 = new Attachment(Name = 'US-000002 ApexClass-B.cls', Body = Blob.valueOf(body2), ParentId = promotion.Id);
        Attachment att3 = new Attachment(Name = 'logs.json', Body = Blob.valueOf(body3), ParentId = promotion.Id);
        insert new List<Attachment>{ att1, att2, att3 };

        // Open the page with no promotionId in the URL
        ResolveConflictsController con = new ResolveConflictsController();
        System.assertEquals(0, con.attachments.size());
        System.assertEquals(true, testMethodUtilities.hasMessage(Label.CONFLICT_RESOLUTION_NO_PROMOTION));

        // Open the page with a promotionId in the URL
        Test.setCurrentPageReference(new PageReference('Page.ResolveConflicts'));
        System.currentPageReference().getParameters().put('promotionId', promotion.Id);
        ResolveConflictsController con2 = new ResolveConflictsController();

        List<Attachment> attachments = con2.getAttachments();
        System.assertEquals(2, con2.attachments.size());

        // Open the first attachment
        System.currentPageReference().getParameters().put('attIndex', '0');
        con2.openAttachment();
        System.assertEquals(att1.Id, con2.attachmentToResolve.Id);
        // After being Resolved via Javascript, the name changes to RESOLVED + att.Name. Update it in the test class:
        con2.saveResolvedAttachment();
        System.assertEquals('RESOLVED ' + att1.Name, con2.attachments[0].Name);

        // AutoResolve the first attachment (that was previously RESOLVED)
        System.currentPageReference().getParameters().put('attIndex', '0');
        con2.saveAutoResolveAttachment();
        con2.getAttachments();
        System.assertEquals('AUTO RESOLVED ' + att1.Name, con2.attachments[0].Name);

        // AutoResolve the second attachment
        System.currentPageReference().getParameters().put('attIndex', '1');
        con2.saveAutoResolveAttachment();
        con2.getAttachments();
        System.assertEquals('AUTO RESOLVED ' + att2.Name, con2.attachments[1].Name);

        // Now Resolve the second attachment
        System.currentPageReference().getParameters().put('attIndex', '1');
        con2.openAttachment();
        con2.saveResolvedAttachment();
        System.assertEquals('RESOLVED ' + att2.Name, con2.attachments[1].Name);

        // Create Deployment and go back to promotion
        con2.createDeployment();
        System.assertEquals(true, con2.goToPromotion);
    }
}