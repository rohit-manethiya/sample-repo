@isTest
private class TestNewDeploymentEmailController {
    private static final String EMPTY_STRING = '';
    @testSetup static void setupTestData(){
        TestUtilities.setTestSettingsEE();
    }
    static testMethod void TestFullComponent(){
        Org__c testFromOrg = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
		insert testFromOrg;
		Deployment__c testDeployment = testMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),testFromOrg.Id,'Deploy now','Scheduled');
		insert testDeployment;
		Step__c testStep = testMethodUtilities.create('Step 1','attId','JSONString',testDeployment.Id,0,'Not started','Git MetaData');
		insert testStep;
        Step__c testStep2 = testMethodUtilities.create('Step 2','attId','JSONString',testDeployment.Id,0,'Not started','Git MetaData');
		insert testStep2;
		Destination_Org__c testDestOrg = testMethodUtilities.create(testDeployment.Id,'Draft',testFromOrg.Id);
        insert testDestOrg;
        List<Deployment_Job__c> testJobs = [select Id from Deployment_Job__c where Step__r.Deployment__c=:testDeployment.Id and Step__r.Type__c='Git MetaData'];
        system.assertEquals(2, testJobs.size(), 'the deployment job query did not return any records.');

        test.startTest();
        NewDeploymentEmailController.deploymentId = null;
        system.assertEquals(null, NewDeploymentEmailController.deployment, 'Deployment should be null');
        NewDeploymentEmailController.getRecordUrl();
        NewDeploymentEmailController.getDeploymentSteps();
        NewDeploymentEmailController.getErrorMessages();
        system.assertEquals(Label.RECORD_NOT_FOUND, NewDeploymentEmailController.statusMessage);

        NewDeploymentEmailController.deploymentId = testDeployment.Id;
        system.assertNotEquals(null, NewDeploymentEmailController.deployment, 'Deployment should not be null');
        NewDeploymentEmailController.getDeploymentSteps();
        NewDeploymentEmailController.getErrorMessages();
        system.assertEquals(Label.NO_ERROR_ATTACHMENT_FOUND, NewDeploymentEmailController.statusMessageErrorMessages);

        String attBody = '[{"l":"ERROR","m":"[ApexClass DeploymetEmailController] unexpected token: 1","t":""},{"l":"ERROR","m":"[ApexClass DeploymetEmailController] unexpected token: 2","t":""}]';
        system.debug('@@@ jobs Id: '+testJobs[0].Id+'.json');
        Attachment testAttachment = createAttachment(testDeployment.Id, testJobs[0].Id+'.json', attBody);
        insert testAttachment;
        attBody = '{"sourceDomain":"https://yulio30-dev-ed.my.salesforce.com/","targetDomain":"https://eu19.salesforce.com/","results":[{"l":"Error","m":{"deployedRecords":0,"failedRecords":0,"exception":"Exception upserting data to OrgCredentialId: a0T1n000007L9xdEAC. [InvalidFieldFault [ApiQueryFault [ApiFault  exceptionCode=No such column CustomerPriority__c on entity Account. If you are attempting to use a custom field, be sure to append the __c after the custom field name. Please reference your WSDL or the describe call for the appropriate names."},"t":""}]}';
        testAttachment = createAttachment(testDeployment.Id, testJobs[1].Id+'.json', attBody);
        insert testAttachment;
        NewDeploymentEmailController.getDeploymentSteps();
        List<NewDeploymentEmailController.WrapperError> wrapperErrors = NewDeploymentEmailController.getErrorMessages();
        system.assertEquals(EMPTY_STRING, NewDeploymentEmailController.statusMessage);
        system.assertEquals(EMPTY_STRING, NewDeploymentEmailController.statusMessageErrorMessages);
        system.assertEquals('[ApexClass DeploymetEmailController] unexpected token: 2', wrapperErrors[2].message, 'Received error message is not the expected one');
        system.assertEquals('[ApexClass DeploymetEmailController] unexpected token: 1', wrapperErrors[1].message, 'Received error message is not the expected one');
        system.assertEquals('Exception upserting data to OrgCredentialId: a0T1n000007L9xdEAC. [InvalidFieldFault [ApiQueryFault [ApiFault  exceptionCode=No such column CustomerPriority__c on entity Account. If you are attempting to use a custom field, be sure to append the __c after the custom field name. Please reference your WSDL or the describe call for the appropriate names.', wrapperErrors[0].message, 'Received error message is not the expected one');

        test.stopTest();
    }

    static testMethod void MaxSizeAttachmentError(){
        Org__c testFromOrg = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
		insert testFromOrg;
		Deployment__c testDeployment = testMethodUtilities.create('DEPLOYMENT_NAME',System.now(), System.now(),testFromOrg.Id,'Deploy now','Scheduled');
		insert testDeployment;
		Step__c testStep = testMethodUtilities.create('Step 1','attId','JSONString',testDeployment.Id,0,'Not started','Git MetaData');
		insert testStep;
		Destination_Org__c testDestOrg = testMethodUtilities.create(testDeployment.Id,'Draft',testFromOrg.Id);
        insert testDestOrg;
        List<Deployment_Job__c> testJobs = [select Id from Deployment_Job__c where Step__r.Deployment__c=:testDeployment.Id and Step__r.Type__c='Git MetaData'];
        system.assertEquals(1, testJobs.size(), 'the deployment job query did not return any records.');

        test.startTest();
        NewDeploymentEmailController.getRecordUrl();
        NewDeploymentEmailController.deploymentId = testDeployment.Id;
        //Now create attachment against deployment.
        String attBody = '{"l":"ERROR","m":"[ApexClass DeploymetEmailController] unexpected token: \u0027(\u0027","t":""},{"l":"ERROR","m":"[ApexClass DeploymetEmailController] unexpected token: \u0027(\u0027","t":""},';
        for(Integer i=0; i<=11; i++){
            attBody += attBody;
        }
        attBody = attBody.substring(0, attBody.length()-1); //removes last comma.
        Attachment testAttachment = createAttachment(testDeployment.Id, testJobs[0].Id+'.json', '['+attBody+']');
        insert testAttachment;
        List<Attachment> attr = [select Id, BodyLength from Attachment where Id=:testAttachment.Id];
        system.assert(attr[0].BodyLength>BuildTaskEmailController.MAX_BODY_LENGTH);
        NewDeploymentEmailController.getErrorMessages();
        system.assertEquals(Label.MAX_FILE_SIZE_EXCEEDED, NewDeploymentEmailController.statusMessageErrorMessages);

        test.stopTest();
    }

    private static Attachment createAttachment(String parentId, String name, String body){
		Attachment a = new Attachment(parentId=parentId, name=name);
		a.Body = Blob.valueOf(body);
		return a;
	}
}