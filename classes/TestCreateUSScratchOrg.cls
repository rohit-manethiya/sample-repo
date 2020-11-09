@IsTest
private class  TestCreateUSScratchOrg {
    private static final String jsonfile = '{"features":["Communities","ServiceCloud","Chatbot"],"settings":{"orgPreferenceSettings":{"networksEnabled":true,"s1DesktopEnabled":true,"s1EncryptedStoragePref2":false},"omniChannelSettings":{"enableOmniChannel":true},"caseSettings":{"systemUserEmail":"support@acme.com"}}}';
    private static final String orgDefinitionfile = '{"orgName":"Acme","edition":"Enterprise","features":["Communities","ServiceCloud","Chatbot"],"settings":{"orgPreferenceSettings":{"networksEnabled":true,"s1DesktopEnabled":true,"s1EncryptedStoragePref2":false},"omniChannelSettings":{"enableOmniChannel":true},"caseSettings":{"systemUserEmail":"support@acme.com"}}}';

    @TestSetup static void setup() {
        // Create common test records
        insert TestUtilities.getTestSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);
        TestUtilities.createAllDXTestData();
    }

    @IsTest static void createUserStoryScratchOrg(){
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.CreateUserStoryScratchOrg;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);
        List<String> orgNameStrings = new List<String>{'Dev Hub 1','Scratch Org Branch'};
        String devHub;
        List<Org__c> orgList = [SELECT Id, Name, Developer_Hub_Org__c, is_Developer_Hub_Org__c FROM Org__c WHERE Name = :orgNameStrings];
        for(Org__c orgCred : orgList){
            if(orgCred.is_Developer_Hub_Org__c){
                devHub = orgCred.Id;
                break;
            }
        }
        for(Org__c orgCred : orgList){
            if(!orgCred.is_Developer_Hub_Org__c){
                orgCred.Developer_Hub_Org__c = devHub;
                break;
            }
        }
        update orgList;

        User_Story__c us = [SELECT Id,Name, Org_Credential__c FROM User_Story__c WHERE User_Story_Title__c =: 'Error on dx operation 2'];
        pageRef.getParameters().put('Id', us.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(us);

        //Create test run
        Test_Script__c testScript = new Test_Script__c();
        testScript.User_Story__c = us.Id;
        insert testScript;

        Test_Run__c testRun = new Test_Run__c();
        testRun.User_Story__c = us.Id;
        testRun.Test_Script__c = testScript.Id;
        insert testRun;

        Test_Run__c testRunObject = [SELECT Id, Name, Test_Script__r.User_Story__r.Project__r.Deployment_Flow__r.Git_Repository__c, Test_Script__r.User_Story__r.Project__r.Deployment_Flow__c, Test_Script__r.User_Story__r.Project__c, Test_Script__r.User_Story__r.Org_Credential__c, Test_Script__r.User_Story__r.Org_Credential__r.Developer_Hub_Org__c FROM Test_Run__c WHERE Id = :testRun.Id LIMIT 1];
        Attachment att = new Attachment();
        att.ParentId = testRunObject.Test_Script__r.User_Story__r.Org_Credential__c;
        att.Name = SfdxAPIHelper.DX_DEFINITION_FILE;
        att.Body = Blob.valueOf(orgDefinitionfile);
        insert  att;

        //Instantiate and construct the controller class of DX Operation page.
        CreateUserStoryScratchOrgController controller = new CreateUserStoryScratchOrgController(sc);

        controller.getChildComponentController();

        //Instantiate and construct the controller class of component.
        ScratchOrgMetadataController somcController = new ScratchOrgMetadataController();
        somcController.setComponentMode('wizard');
        somcController.setShowTemplateButtons(false);
        somcController.setShowButtons(true);
        somcController.setPageController(controller);
        somcController.setControllerKey('ScratchOrgMetadata');
        somcController.typeName = 'branch';
        //somcController.showPatchOptions = false;

        controller.nextStep(); // it will return because dev hub org id is not selected
        controller.previousStep();
        controller.nextStep();

        ScratchOrgController socController = new ScratchOrgController();
        socController.setComponentMode('wizard');
        socController.setShowTemplateButtons(false);
        socController.setShowButtons(true);
        socController.setPageController(controller);
        socController.setControllerKey('ScratchOrgTemplate');

        socController.orgTemplate.setOrgName('FO test');

        //Org__c devHubOrg = [SELECT Id FROM Org__c WHERE Name =: 'Dev Hub 1'];
        socController.setDevHubOrgId(devHub);

        //Select git repository and populate grid panel
        Git_Repository__c gr = [SELECT Id, Name FROM Git_Repository__c WHERE Name =: 'git 1'];
        //somcController.repoId = gr.Id;
        //somcController.repoName = gr.Name;
        // TODO wrapper class will be updating the records

        //Select git snapshot from grid panel and populate branch name parameter at dxoperation controller
        Git_Backup__c gb = [SELECT Id, Branch__c FROM Git_Backup__c WHERE Git_Repository__c =: gr.Id];

        //Select branch and render artifact panels
        ApexPages.currentPage().getParameters().put('nextStepParam', gb.Branch__c);
        controller.setJsonSettingsFeatures(jsonfile);

        controller.nextStep();
        System.assertEquals('COMPLETE',controller.definition);
        controller.previousStep();
        controller.nextStep();

        ScratchOrgExtensionsController soecController = new ScratchOrgExtensionsController();
        soecController.setComponentMode('wizard');
        soecController.setShowTemplateButtons(false);
        soecController.setShowButtons(true);
        soecController.setPageController(controller);
        soecController.setControllerKey('ScratchOrgExtensions');
        soecController.sourceOrgId = devHub;
        soecController.populateDeployments();
        //soecController.selectedDeploymentId = [SELECT Id FROM Deployment__c WHERE Name = 'Dev1 Deployment' LIMIT 1].Id;
        soecController.addToExtensions();

        controller.nextStep();
        controller.previousStep();
        controller.nextStep();

        ScratchOrgCompletionController soccController = new ScratchOrgCompletionController();
        soccController.setComponentMode('wizard');
        soccController.setShowTemplateButtons(false);
        soccController.setShowButtons(true);
        soccController.setPageController(controller);
        soccController.setControllerKey('ScratchOrgCompletion');
        soccController.tRun = testRunObject;

        Test.startTest();
        MockHttpResponseGenerator fullScratchOrgFakeResponse = new MockHttpResponseGenerator(200,'Complete','{"example":"test"}',null);
        Test.setMock(HttpCalloutMock.class, fullScratchOrgFakeResponse);

        soccController.createFullScratchOrg();

        ApexPages.currentPage().getParameters().put('csvPerm', '');
        //soccController.getSelectedPermissionSets();

        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200,'Complete','{"example":"test"}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        controller.nextStep();

        controller.loadReviewData();
        //run the event listener job for create org job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobMessage', '');
        ApexPages.currentPage().getParameters().put('jobType', CopadoNotificationHelper.DX_CREATE_FULL_ORG);
        controller.jobStatusNotification();

        soccController.showDeploymentFlow = true;
        soccController.deploymentFlowOperations();
        controller.nextStepOrgTemplate();
        controller.fullCreateCompleted();

        Test.stopTest();
    }

    @IsTest static void createUserStoryScratchOrgUnlockedPackage(){
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.CreateUserStoryScratchOrg;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        User_Story__c us = [SELECT Id,Name, Org_Credential__c FROM User_Story__c WHERE User_Story_Title__c =: 'Error on dx operation 2'];
        pageRef.getParameters().put('Id', us.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(us);

        //Instantiate and construct the controller class of DX Operation page.
        CreateUserStoryScratchOrgController controller = new CreateUserStoryScratchOrgController(sc);

        controller.getChildComponentController();

        //Instantiate and construct the controller class of component.
        ScratchOrgMetadataController somcController = new ScratchOrgMetadataController();
        somcController.setComponentMode('wizard');
        somcController.setShowTemplateButtons(false);
        somcController.setShowButtons(true);
        somcController.setPageController(controller);
        somcController.setControllerKey('ScratchOrgMetadata');
        somcController.typeName = 'unlocked'; //Old value "unlockPackage"
        //somcController.showPatchOptions = false;

        controller.nextStep(); // it will return because dev hub org id is not selected
        controller.previousStep();
        controller.nextStep();//

        ScratchOrgController socController = new ScratchOrgController();
        socController.setComponentMode('wizard');
        socController.setShowTemplateButtons(false);
        socController.setShowButtons(true);
        socController.setPageController(controller);
        socController.setControllerKey('ScratchOrgTemplate');

        socController.orgTemplate.setOrgName('FO test');

        //socController.mergeArtifactOrgDefinitionDependencies();

        Org__c devHubOrg = [SELECT Id FROM Org__c WHERE Name =: 'Dev Hub 1'];
        socController.setDevHubOrgId(devHubOrg.Id);

        //Select git repository and populate grid panel
        Git_Repository__c gr = [SELECT Id, Name FROM Git_Repository__c WHERE Name =: 'git 1'];
        //somcController.repoId = gr.Id;
        //somcController.repoName = gr.Name;
        // TODO wrapper class will be updating the records

        //Select git snapshot from grid panel and populate branch name parameter at dxoperation controller
        Git_Backup__c gb = [SELECT Id, Branch__c FROM Git_Backup__c WHERE Git_Repository__c =: gr.Id];

        //Select branch and render artifact panels
        ApexPages.currentPage().getParameters().put('nextStepParam', gb.Branch__c);
        controller.setJsonSettingsFeatures(jsonfile);

        controller.nextStep();
        System.assertEquals('COMPLETE',controller.definition);
        controller.previousStep();
        controller.nextStep();

        ScratchOrgExtensionsController soecController = new ScratchOrgExtensionsController();
        soecController.setComponentMode('wizard');
        soecController.setShowTemplateButtons(false);
        soecController.setShowButtons(true);
        soecController.setPageController(controller);
        soecController.setControllerKey('ScratchOrgExtensions');

        controller.nextStep();
        controller.previousStep();
        controller.nextStep();

        ScratchOrgCompletionController soccController = new ScratchOrgCompletionController();
        soccController.setComponentMode('wizard');
        soccController.setShowTemplateButtons(false);
        soccController.setShowButtons(true);
        soccController.setPageController(controller);
        soccController.setControllerKey('ScratchOrgCompletion');

        soccController.createFullScratchOrg();

        ApexPages.currentPage().getParameters().put('csvPerm', '');
        //soccController.getSelectedPermissionSets();

        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200,'Complete','{"example":"test"}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        controller.nextStep();

        controller.loadReviewData();
        //run the event listener job for create org job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobMessage', '');
        ApexPages.currentPage().getParameters().put('jobType', CopadoNotificationHelper.DX_CREATE_FULL_ORG);
        controller.jobStatusNotification();

        soccController.showDeploymentFlow = true;
        soccController.deploymentFlowOperations();

        Test.stopTest();
    }

    @IsTest static void createUserStoryScratchOrgArtifact(){
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.CreateUserStoryScratchOrg;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        User_Story__c us = [SELECT Id,Name, Org_Credential__c FROM User_Story__c WHERE User_Story_Title__c =: 'Error on dx operation 2'];
        Artifact__c at = [SELECT Id FROM Artifact__c WHERE Name = 'StaticResources2' LIMIT 1];

        pageRef.getParameters().put('Id', us.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(us);

        //Instantiate and construct the controller class of DX Operation page.
        CreateUserStoryScratchOrgController controller = new CreateUserStoryScratchOrgController(sc);

        controller.getChildComponentController();

        //Instantiate and construct the controller class of component.
        ScratchOrgMetadataController somcController = new ScratchOrgMetadataController();
        somcController.setComponentMode('wizard');
        somcController.setShowTemplateButtons(false);
        somcController.setShowButtons(true);
        somcController.setPageController(controller);
        somcController.setControllerKey('ScratchOrgMetadata');
        somcController.typeName = 'artifact';

        somcController.setSourceSelections(at.Id);

        controller.nextStep(); // it will return because dev hub org id is not selected
        controller.previousStep();
        controller.nextStep();//

        ScratchOrgController socController = new ScratchOrgController();
        socController.setComponentMode('wizard');
        socController.setShowTemplateButtons(false);
        socController.setShowButtons(true);
        socController.setPageController(controller);
        socController.setControllerKey('ScratchOrgTemplate');
        ScratchOrgDefinition orgTemplate = socController.orgTemplate;

        Attachment orgDefinitionDependency = new Attachment();
        orgDefinitionDependency.ParentId = at.Id;
        orgDefinitionDependency.Body = Blob.valueOf(jsonfile);
        orgDefinitionDependency.Name = SfdxAPIHelper.DX_DEFINITION_FILE;
        insert orgDefinitionDependency;

        //socController.mergeArtifactOrgDefinitionDependencies();
        socController.orgTemplate.setOrgName('FO test');

        Org__c devHubOrg = [SELECT Id FROM Org__c WHERE Name =: 'Dev Hub 1'];
        socController.setDevHubOrgId(devHubOrg.Id);

        //Select git repository and populate grid panel
        Git_Repository__c gr = [SELECT Id, Name FROM Git_Repository__c WHERE Name =: 'git 1'];
        //somcController.repoId = gr.Id;
        //somcController.repoName = gr.Name;
        // TODO wrapper class will be updating the records

        //Select git snapshot from grid panel and populate branch name parameter at dxoperation controller
        Git_Backup__c gb = [SELECT Id, Branch__c FROM Git_Backup__c WHERE Git_Repository__c =: gr.Id];

        //Select branch and render artifact panels
        ApexPages.currentPage().getParameters().put('nextStepParam', gb.Branch__c);
        controller.setJsonSettingsFeatures(jsonfile);

        controller.nextStep();
        System.assertEquals('COMPLETE',controller.definition);
        controller.previousStep();
        controller.nextStep();

        ScratchOrgExtensionsController soecController = new ScratchOrgExtensionsController();
        soecController.setComponentMode('wizard');
        soecController.setShowTemplateButtons(false);
        soecController.setShowButtons(true);
        soecController.setPageController(controller);
        soecController.setControllerKey('ScratchOrgExtensions');

        controller.nextStep();
        controller.previousStep();
        controller.nextStep();

        ScratchOrgCompletionController soccController = new ScratchOrgCompletionController();
        soccController.setComponentMode('wizard');
        soccController.setShowTemplateButtons(false);
        soccController.setShowButtons(true);
        soccController.setPageController(controller);
        soccController.setControllerKey('ScratchOrgCompletion');

        soccController.createFullScratchOrg();

        ApexPages.currentPage().getParameters().put('csvPerm', '');
        //soccController.getSelectedPermissionSets();

        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200,'Complete','{"example":"test"}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        controller.nextStep();

        controller.loadReviewData();
        //run the event listener job for create org job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobMessage', '');
        ApexPages.currentPage().getParameters().put('jobType', CopadoNotificationHelper.DX_CREATE_FULL_ORG);
        controller.jobStatusNotification();

        soccController.showDeploymentFlow = true;
        soccController.deploymentFlowOperations();

        Test.stopTest();
    }

    @IsTest static void createUserStoryScratchOrgPatch(){
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.CreateUserStoryScratchOrg;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        User_Story__c us = [SELECT Id,Name, Org_Credential__c FROM User_Story__c WHERE User_Story_Title__c =: 'Error on dx operation 2'];
        pageRef.getParameters().put('Id', us.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(us);

        //Instantiate and construct the controller class of DX Operation page.
        CreateUserStoryScratchOrgController controller = new CreateUserStoryScratchOrgController(sc);

        controller.getChildComponentController();

        //Instantiate and construct the controller class of component.
        ScratchOrgMetadataController somcController = new ScratchOrgMetadataController();
        somcController.setComponentMode('wizard');
        somcController.setShowTemplateButtons(false);
        somcController.setShowButtons(true);
        somcController.setPageController(controller);
        somcController.setControllerKey('ScratchOrgMetadata');
        somcController.typeName = 'patch';

        controller.nextStep(); // it will return because dev hub org id is not selected
        controller.previousStep();
        controller.nextStep();//

        ScratchOrgController socController = new ScratchOrgController();
        socController.setComponentMode('wizard');
        socController.setShowTemplateButtons(false);
        socController.setShowButtons(true);
        socController.setPageController(controller);
        socController.setControllerKey('ScratchOrgTemplate');

        socController.orgTemplate.setOrgName('FO test');

        Org__c devHubOrg = [SELECT Id FROM Org__c WHERE Name =: 'Dev Hub 1'];
        socController.setDevHubOrgId(devHubOrg.Id);

        //Select git repository and populate grid panel
        Git_Repository__c gr = [SELECT Id, Name FROM Git_Repository__c WHERE Name =: 'git 1'];
        //somcController.repoId = gr.Id;
        //somcController.repoName = gr.Name;
        // TODO wrapper class will be updating the records

        //Select git snapshot from grid panel and populate branch name parameter at dxoperation controller
        Git_Backup__c gb = [SELECT Id, Branch__c FROM Git_Backup__c WHERE Git_Repository__c =: gr.Id];

        //Select branch and render artifact panels
        ApexPages.currentPage().getParameters().put('nextStepParam', gb.Branch__c);
        controller.setJsonSettingsFeatures(jsonfile);

        controller.nextStep();
        System.assertEquals('COMPLETE',controller.definition);
        controller.previousStep();
        controller.nextStep();

        ScratchOrgExtensionsController soecController = new ScratchOrgExtensionsController();
        soecController.setComponentMode('wizard');
        soecController.setShowTemplateButtons(false);
        soecController.setShowButtons(true);
        soecController.setPageController(controller);
        soecController.setControllerKey('ScratchOrgExtensions');

        controller.nextStep();
        controller.previousStep();
        controller.nextStep();

        ScratchOrgCompletionController soccController = new ScratchOrgCompletionController();
        soccController.setComponentMode('wizard');
        soccController.setShowTemplateButtons(false);
        soccController.setShowButtons(true);
        soccController.setPageController(controller);
        soccController.setControllerKey('ScratchOrgCompletion');

        soccController.createFullScratchOrg();

        ApexPages.currentPage().getParameters().put('csvPerm', '');
        //soccController.getSelectedPermissionSets();

        Test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200,'Complete','{"example":"test"}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        controller.nextStep();

        controller.loadReviewData();
        //run the event listener job for create org job
        ApexPages.currentPage().getParameters().put('jobFinished', 'true');
        ApexPages.currentPage().getParameters().put('jobSuccess', 'true');
        ApexPages.currentPage().getParameters().put('jobMessage', '');
        ApexPages.currentPage().getParameters().put('jobType', CopadoNotificationHelper.DX_CREATE_FULL_ORG);
        controller.jobStatusNotification();

        soccController.showDeploymentFlow = true;
        soccController.deploymentFlowOperations();

        Test.stopTest();
    }

    @IsTest static void scratchOrgOpen(){
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.ScratchOrgOpen;

        //In this case, the Visualforce page named 'DXOperation' is the starting point of this test method.
        Test.setCurrentPage(pageRef);

        Org__c orgScratch = [SELECT Id, Environment__c FROM Org__c WHERE Name =: 'Scratch Org 1'];

        Copado_Notification__c cn = new Copado_Notification__c();
        cn.Type__c = CopadoNotificationHelper.DX_OPEN_ORG;
        cn.OwnerId = UserInfo.getUserId();
        cn.isFinished__c = false;
        cn.ParentId__c = orgScratch.Id;
        cn.Matching_Key__c = 'testmatching';
        insert cn;

        pageRef.getParameters().put('id',orgScratch.Id);

        //Instantiate and construct the controller class of DX Operation page.
        ScratchOrgOpen sooController = new ScratchOrgOpen();
        sooController.soId = orgScratch.Id;

        System.assertEquals(null,sooController.copadoJobFinished);

        //Open scratch org
        Test.startTest();
        MockHttpResponseGenerator fakeResponseCopadoId = new MockHttpResponseGenerator(200,'Complete','{"test":"123456789012345678"}',null);
        Test.setMock(HttpCalloutMock.class, fakeResponseCopadoId);
        sooController.rScratchOrgJob();
        Test.stopTest();
    }

    // Those method are never used, because they are overwritten.
    @IsTest static void overWrittenMethods(){
        Test.startTest();
        ScratchOrgWizardPageBase scowpb = new ScratchOrgWizardPageBase();
        ScratchOrgWizardComponentBase controller = scowpb.getChildComponentController();
        scowpb.getThis();

        scowpb.setComponentControllerMap('ScratchOrgComponent', controller);
        Map<String, ScratchOrgWizardComponentBase> testScowpb = scowpb.getComponentControllerMap();
        Test.stopTest();
    }
}