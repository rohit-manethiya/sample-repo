@isTest
private class TestViewDeploymentExtension {
	@testSetup static void setupTestData(){
		TestUtilities.setTestSettingsEE();
	}
	@testSetup static void setupTestDataDML(){
		testMethodUtilities.upsertOrgwideSettings();
	}
    static testMethod void myUnitTest() {
		Org__c testFromOrg = testMethodUtilities.createOrg('OrgName','Production','SFDC_OrgId','SFDC_TOKEN','USERNAME', System.now());
		insert testFromOrg;
		Deployment__c testDeployment = testMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),testFromOrg.Id,'Deploy now','Scheduled');
		insert testDeployment;
		Step__c testStep = testMethodUtilities.create('Step 1','attId','JSONString',testDeployment.Id,0,'Not started','MetaData');
		insert testStep;
		Destination_Org__c testDestOrg = testMethodUtilities.create(testDeployment.Id,'Draft',testFromOrg.Id);
        insert testDestOrg;
        
		
		PageReference pref = Page.DeploymentWizard;
		pref.getParameters().put('id',testDeployment.id);
		Test.setCurrentPage(pref);		

		ViewDeploymentExtension ext = new ViewDeploymentExtension(new ApexPages.StandardController(testDeployment));
		system.assertEquals(true, ext.runPoller);
		system.assertEquals(1, ext.mapDeploymentJobsString.size());
		system.debug('## keys: '+ext.mapAttachments.keySet());
		system.debug('## values: '+ext.mapAttachments.values());
		system.assertEquals(2, ext.mapAttachments.size());
		system.assertEquals(1, ext.matrix.size());
		system.assertEquals(testStep.Id, ext.matrix[0].step.Id);
		system.assertEquals(1, ext.matrix[0].jobs.size());
		
		Attachment depErrors = new Attachment(Body=Blob.valueOf('[{"l":"ERROR","m":"This is a deployment error message","t":""}]'),Name=testDeployment.Id+'.json',ParentId=testDeployment.Id);
		insert depErrors;
		Attachment jobError = new Attachment(Body=Blob.valueOf('[{"l":"INFO","m":"Deployment job message","t":""}]'),Name=ext.matrix[0].jobs[0].Id+'.json',ParentId=testDeployment.Id);
		insert jobError;
		testDeployment.status__c = 'Completed Successfully';
		update testDeployment;
		ext = new ViewDeploymentExtension(new ApexPages.StandardController(testDeployment));
		system.assertEquals(false, ext.runPoller);
		for(String i : ext.mapAttachments.keySet()){
			system.assertEquals(true, ext.mapAttachments.get(i));
		}
		system.assert(testMethodUtilities.hasMessage('This is a deployment error message'));
		
		ext.selectedStep = testStep.Id;
		ext.getStepDetail();
		
		DeployAPI.cancelDeployment(ext.deployment.Id);
    }
}