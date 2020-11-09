/**
 *  TODO: enhance class providing meaningful names to variables
 *  a proper TestSetup scenario, user specific context,
 *  and making use of AbstractTestData Framework
 */
@IsTest
private class TestDeployJobHelper {
    @TestSetup
    static void setupTestData() {
        TestUtilities.setTestSettingsEE();
    }

    @IsTest
    static void doTest() {
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Org__c testOrg = testMethodUtilities.createOrg('OrgTestName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testOrg;
        Deployment__c d = testMethodUtilities.create('DEPLOYMENT_NAME', System.now(), System.now(), testOrg.Id, 'Deploy now', 'Pending');
        insert d;
        Destination_Org__c o = testMethodUtilities.create(d.id, 'Pending', testOrg.Id);
        insert o;
        Step__c s = testMethodUtilities.create('Step 1', 'attId', 'JSONString', d.Id, 0, 'Pending', 'MetaData');
        insert s;
        System.assertEquals(1, [SELECT COUNT() FROM Deployment_Job__c WHERE step__c = :s.id AND destination_org__c = :o.id]);
        Destination_Org__c o2 = testMethodUtilities.create(d.id, 'Pending', testOrg.Id);
        insert o2;
        System.assertEquals(1, [SELECT COUNT() FROM Deployment_Job__c WHERE step__c = :s.id AND destination_org__c = :o2.id]);
        System.assertEquals(2, [SELECT COUNT() FROM Deployment_Job__c WHERE step__c = :s.id]);

        delete o;
        System.assertEquals(1, [SELECT COUNT() FROM Deployment_Job__c WHERE step__c = :s.id AND destination_org__c = :o2.id]);
        System.assertEquals(1, [SELECT COUNT() FROM Deployment_Job__c WHERE step__c = :s.id]);
    }

    @IsTest
    static void testNextStep() {
        testMethodUtilities.upsertOrgwideSettings();

        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Org__c testOrg = testMethodUtilities.createOrg('OrgTestName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testOrg;
        Deployment__c deployment = testMethodUtilities.create('DEPLOYMENT_NAME', System.now(), System.now(), testOrg.Id, 'Deploy now', 'Pending');
        insert deployment;

        Destination_Org__c o = testMethodUtilities.create(deployment.Id, 'Pending', testOrg.Id);
        insert o;
        String dataJson = '{"Perform_in_Destination_Orgs":true,"Perform_in_Source_Org":false,"Task_Description":"","Task_Owner":"';
        dataJson += UserInfo.getUserId();
        dataJson += '","Notify_Task_Owner":"Chatter and Email"}';
        Step__c s = testMethodUtilities.create('Step 1', 'attId', dataJson, deployment.Id, 1, 'Pending', 'Manual Task');

        Step__c s2 = testMethodUtilities.create('Step 2', 'attId', 'JSONString', deployment.Id, 2, 'Pending', 'MetaData');
        List<Step__c> steps = new List<Step__c>();
        steps.add(s);
        steps.add(s2);
        insert steps;
        Destination_Org__c o2 = testMethodUtilities.create(deployment.id, 'Pending', testOrg.Id);
        insert o2;
        Deployment_Job__c dj11 = [SELECT id, status__c FROM Deployment_Job__c WHERE step__c = :s.id AND destination_org__c = :o.id];
        System.assertEquals('Pending', dj11.Status__c);
        dj11.Status__c = 'Success';
        dj11.Deployed__c = 100;
        update dj11;
        system.assertEquals('In progress', [SELECT status__c FROM step__c WHERE id = :s.id].status__c);
    }

    @IsTest
    static void testNextStep2() {
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Org__c testOrg = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testOrg;
        Deployment__c d = testMethodUtilities.create('DEPLOYMENT_NAME', System.now(), System.now(), testOrg.Id, 'Deploy now', 'In progress');
        insert d;
        Destination_Org__c o = testMethodUtilities.create(d.id, 'Pending', testOrg.Id);
        insert o;
        Step__c s = testMethodUtilities.create('Step 1', 'attId', 'JSONString', d.Id, 1, 'Pending', 'MetaData');
        insert s;
        Step__c s2 = testMethodUtilities.create('Step 2', 'attId', 'JSONString', d.Id, 2, 'Pending', 'MetaData');
        insert s2;
        Destination_Org__c o2 = testMethodUtilities.create(d.id, 'Pending', testOrg.Id);
        insert o2;
        Test.startTest();
        Deployment_Job__c dj11 = [SELECT id, status__c FROM Deployment_Job__c WHERE step__c = :s.id AND destination_org__c = :o.id];
        System.assertEquals('Pending', dj11.Status__c);
        dj11.Status__c = 'Failed';
        dj11.Deployed__c = 0;
        update dj11;
        system.assertEquals('In progress', [SELECT status__c FROM step__c WHERE id = :s.id].status__c);

        system.assertEquals('In progress', [SELECT status__c FROM Deployment__c WHERE id = :d.id].status__c);

        Deployment_Job__c dj12 = [SELECT id, status__c FROM Deployment_Job__c WHERE step__c = :s.id AND destination_org__c = :o2.id];
        System.assertEquals('Pending', dj12.Status__c);
        dj12.Status__c = 'Failed';
        dj12.Deployed__c = 0;
        update dj12;
        system.assertEquals('Completed with Errors', [SELECT status__c FROM step__c WHERE id = :s.id].status__c);

        system.assertEquals('Completed with Errors', [SELECT status__c FROM Deployment__c WHERE id = :d.id].status__c);

        Deployment_Job__c dj21 = [SELECT id, status__c FROM Deployment_Job__c WHERE step__c = :s2.id AND destination_org__c = :o.id];
        System.assertEquals('Pending', dj21.Status__c);
        system.assertEquals('Completed with Errors', [SELECT status__c FROM step__c WHERE id = :s.id].status__c);

        Deployment_Job__c dj22 = [SELECT id, status__c FROM Deployment_Job__c WHERE step__c = :s2.id AND destination_org__c = :o2.id];
        System.assertEquals('Pending', dj22.Status__c);
        system.assertEquals('Pending', [SELECT status__c FROM step__c WHERE id = :s2.id].status__c);
        Test.stopTest();
    }

    @IsTest
    static void testNextStep3() {
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Org__c testOrg = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testOrg;
        Deployment__c d = testMethodUtilities.create('DEPLOYMENT_NAME', System.now(), System.now(), testOrg.Id, 'Deploy now', 'In progress');
        insert d;
        Destination_Org__c o = testMethodUtilities.create(d.id, 'Pending', testOrg.Id);
        insert o;
        Step__c s = testMethodUtilities.create('Step 1', 'attId', 'JSONString', d.Id, 1, 'Pending', 'MetaData');
        insert s;
        Destination_Org__c o2 = testMethodUtilities.create(d.id, 'Pending', testOrg.Id);
        insert o2;

        Deployment_Job__c dj11 = [SELECT id, status__c FROM Deployment_Job__c WHERE step__c = :s.id AND destination_org__c = :o.id];
        System.assertEquals('Pending', dj11.Status__c);
        dj11.Status__c = 'Failed';
        dj11.Deployed__c = 0;
        update dj11;
        system.assertEquals('In progress', [SELECT status__c FROM step__c WHERE id = :s.id].status__c);
        system.assertEquals('In progress', [SELECT status__c FROM Deployment__c WHERE id = :d.id].status__c);
        system.assertEquals('Completed with Errors', [SELECT status__c FROM Destination_Org__c WHERE id = :o.id].status__c);

        Deployment_Job__c dj12 = [SELECT id, status__c FROM Deployment_Job__c WHERE step__c = :s.id AND destination_org__c = :o2.id];
        System.assertEquals('Pending', dj12.Status__c);
        dj12.Status__c = 'Success';
        dj12.Deployed__c = 100;
        update dj12;
        system.assertEquals('Completed with Errors', [SELECT status__c FROM step__c WHERE id = :s.id].status__c);
        system.assertEquals('Completed Successfully', [SELECT status__c FROM Destination_Org__c WHERE id = :o2.id].status__c);
        system.assertEquals('Completed with Errors', [SELECT status__c FROM Deployment__c WHERE id = :d.id].status__c);
    }

    @IsTest
    static void testSalesforceFlowStepExecution() {
        Settings__c setting = Settings__c.getOrgDefaults();
        setting.CryptoKey__c = EncodingUtil.base64Encode(Crypto.generateAesKey(256));
        upsert setting;

        Personal_Settings__c personalSetting = Personal_Settings__c.getInstance();
        personalSetting.API_Key__c = DeployAPI.encryptAPIKey('testApiKey');
        upsert personalSetting;

        ITestDefaults environmentDefaults = new CopadoSetupTestDefaults.EnvironmentDefaults()
            .setFieldDefaults()
            .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Copado')
            .setDataSize(Environment__c.SObjectType, 1)
            .generateDefaults()
            .includeDefaults(CopadoSetupTestDefaults.EnvironmentDefaults.class)
            .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Production')
            .setDataSize(Environment__c.SObjectType, 1)
            .generateDefaults()
            .executeDML();

        Environment__c copadoEnvironment;
        Environment__c productionEnvironment;

        for (Environment__c env : (List<Environment__c>) environmentDefaults.getTestData(Environment__c.SObjectType)) {
            switch on env.Name {
                when 'Copado 0' {
                    copadoEnvironment = env;
                }
                when 'Production 0' {
                    productionEnvironment = env;
                }
            }
        }

        String sfdcOrgId = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
        ITestDefaults orgCredentialDefaults = new CopadoSetupTestDefaults.OrgCredentialDefaults()
            .setFieldDefaults()
            .setFieldValue(Org__c.SObjectType, Org__c.Name, 'Copado')
            .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, copadoEnvironment.Id)
            .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
            .setFieldValue(Org__c.SObjectType, Org__c.Validated_Date__c, System.now())
            .setFieldValue(Org__c.SObjectType, Org__c.SFDC_Org_ID__c, sfdcOrgId)
            .setDataSize(Org__c.SObjectType, 1)
            .generateDefaults()
            .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
            .setFieldValue(Org__c.SObjectType, Org__c.Name, 'Production')
            .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, productionEnvironment.Id)
            .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
            .setDataSize(Org__c.SObjectType, 1)
            .generateDefaults()
            .executeDML();

        Org__c copadoOrg = new Org__c();
        Org__c productionOrg = new Org__c();

        for (Org__c org : (List<Org__c>) orgCredentialDefaults.getTestData(Org__c.SObjectType)) {
            switch on org.Name {
                when 'Copado 0' {
                    copadoOrg = org;
                }
                when 'Production 0' {
                    productionOrg = org;
                }
            }
        }

        String dataJson =
            '{"flowApiName": "TestFlow","type":"wait","flowParameters":[' +
            '["Copado Org Id","{!CopadoOrg.OrgId}"],' +
            '["Copado Org Credential Id","{!CopadoOrg.CredentialId}"],' +
            '["Copado Org Api Key","{!CopadoOrg.ApiKey}"],' +
            '["Source Org Id","{!Source.OrgId}"],' +
            '["Source Credential Id","{!Source.CredentialId}"],' +
            '["Destination Org Id","{!Destination.OrgId}"],' +
            '["Destination Credential Id","{!Destination.CredentialId}"],' +
            '["Deployment Id","{!Deployment.Id}"],' +
            '["Deployment Job Id","{!Deployment.JobId}"],' +
            '["Promotion Id","{!Promotion.Id}"],' +
            '["Resume URL","{!ResumeURL}"]' +
            ']}';

        ITestDefaults deploymentDefaults = new CopadoUserStoryTestDefaults.DeploymentDefaults()
            .setFieldDefaults()
            .setFieldValue(Deployment__c.SObjectType, Deployment__c.From_Org__c, productionOrg.Id)
            .setDataSize(Deployment__c.SObjectType, 1)
            .generateDefaults()
            .includeDefaults(CopadoUserStoryTestDefaults.DeploymentStepDefaults.class)
            .setFieldValue(Step__c.SObjectType, Step__c.Status__c, 'Pending')
            .setFieldValue(Step__c.SObjectType, Step__c.Type__c, 'Salesforce Flow')
            .setFieldValue(Step__c.SObjectType, Step__c.dataJson__c, dataJson)
            .setDataSize(Step__c.SObjectType, 1)
            .setSObjectRelation(Step__c.SObjectType, Deployment__c.SObjectType, new Map<Schema.SObjectField, Integer>{ Step__c.Deployment__c => 1 })
            .generateDefaults()
            .executeDML();

        Deployment__c deployment = (Deployment__c) deploymentDefaults.getTestData(Deployment__c.SObjectType)[0];

        Destination_Org__c destinationOrg = testMethodUtilities.create(deployment.Id, 'Pending', productionOrg.Id);
        insert destinationOrg;

        Step__c salesforceFlowStep = (Step__c) deploymentDefaults.getTestData(Step__c.SObjectType)[0];

        Test.startTest();
        Deployment_Job__c deployentJob = [
            SELECT Status__c
            FROM Deployment_Job__c
            WHERE Step__c = :salesforceFlowStep.Id AND Destination_org__c = :destinationOrg.Id
        ];
        System.assertEquals('Pending', deployentJob.Status__c);
        deployentJob.Status__c = 'In progress';
        update deployentJob;
        Test.stopTest();

        deployentJob = [SELECT Status__c FROM Deployment_Job__c WHERE Step__c = :salesforceFlowStep.Id AND Destination_org__c = :destinationOrg.Id];
        System.assertEquals('Failed', deployentJob.Status__c, 'Deployment job status should be Failed.');
        Attachment resultAttachment = [SELECT Body FROM Attachment WHERE ParentId = :deployentJob.Id];
        String resultBody = resultAttachment.Body.toString();
        System.assert(
            resultBody.contains(String.format(Label.ERROR_FLOW_EXECUTION, new List<Object>{ 'Invalid type: TestFlow' })),
            'Flow execution should fail'
        );
    }

    @IsTest
    static void testSalesforceFlowStepExecutionJsonParsingError() {
        ITestDefaults environmentDefaults = new CopadoSetupTestDefaults.EnvironmentDefaults()
            .setFieldDefaults()
            .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Copado')
            .setDataSize(Environment__c.SObjectType, 1)
            .generateDefaults()
            .includeDefaults(CopadoSetupTestDefaults.EnvironmentDefaults.class)
            .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Production')
            .setDataSize(Environment__c.SObjectType, 1)
            .generateDefaults()
            .executeDML();

        Environment__c copadoEnvironment;
        Environment__c productionEnvironment;

        for (Environment__c env : (List<Environment__c>) environmentDefaults.getTestData(Environment__c.SObjectType)) {
            switch on env.Name {
                when 'Copado 0' {
                    copadoEnvironment = env;
                }
                when 'Production 0' {
                    productionEnvironment = env;
                }
            }
        }

        String sfdcOrgId = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
        ITestDefaults orgCredentialDefaults = new CopadoSetupTestDefaults.OrgCredentialDefaults()
            .setFieldDefaults()
            .setFieldValue(Org__c.SObjectType, Org__c.Name, 'Copado')
            .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, copadoEnvironment.Id)
            .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
            .setFieldValue(Org__c.SObjectType, Org__c.Validated_Date__c, System.now())
            .setFieldValue(Org__c.SObjectType, Org__c.SFDC_Org_ID__c, sfdcOrgId)
            .setDataSize(Org__c.SObjectType, 1)
            .generateDefaults()
            .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
            .setFieldValue(Org__c.SObjectType, Org__c.Name, 'Production')
            .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, productionEnvironment.Id)
            .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
            .setDataSize(Org__c.SObjectType, 1)
            .generateDefaults()
            .executeDML();

        Org__c copadoOrg = new Org__c();
        Org__c productionOrg = new Org__c();

        for (Org__c org : (List<Org__c>) orgCredentialDefaults.getTestData(Org__c.SObjectType)) {
            switch on org.Name {
                when 'Copado 0' {
                    copadoOrg = org;
                }
                when 'Production 0' {
                    productionOrg = org;
                }
            }
        }

        ITestDefaults deploymentDefaults = new CopadoUserStoryTestDefaults.DeploymentDefaults()
            .setFieldDefaults()
            .setFieldValue(Deployment__c.SObjectType, Deployment__c.From_Org__c, productionOrg.Id)
            .setDataSize(Deployment__c.SObjectType, 1)
            .generateDefaults()
            .includeDefaults(CopadoUserStoryTestDefaults.DeploymentStepDefaults.class)
            .setFieldValue(Step__c.SObjectType, Step__c.Status__c, 'Pending')
            .setFieldValue(Step__c.SObjectType, Step__c.Type__c, 'Salesforce Flow')
            .setFieldValue(Step__c.SObjectType, Step__c.dataJson__c, 'testDataJson')
            .setDataSize(Step__c.SObjectType, 1)
            .setSObjectRelation(Step__c.SObjectType, Deployment__c.SObjectType, new Map<Schema.SObjectField, Integer>{ Step__c.Deployment__c => 1 })
            .generateDefaults()
            .executeDML();

        Deployment__c deployment = (Deployment__c) deploymentDefaults.getTestData(Deployment__c.SObjectType)[0];

        Destination_Org__c destinationOrg = testMethodUtilities.create(deployment.Id, 'Pending', productionOrg.Id);
        insert destinationOrg;

        Step__c salesforceFlowStep = (Step__c) deploymentDefaults.getTestData(Step__c.SObjectType)[0];

        Test.startTest();
        Deployment_Job__c deployentJob = [
            SELECT Status__c
            FROM Deployment_Job__c
            WHERE Step__c = :salesforceFlowStep.Id AND Destination_org__c = :destinationOrg.Id
        ];
        System.assertEquals('Pending', deployentJob.Status__c);
        deployentJob.Status__c = 'In progress';
        update deployentJob;
        Test.stopTest();

        deployentJob = [SELECT Status__c FROM Deployment_Job__c WHERE Step__c = :salesforceFlowStep.Id AND Destination_org__c = :destinationOrg.Id];
        System.assertEquals('Failed', deployentJob.Status__c, 'Deployment job status should be Failed.');
        Attachment resultAttachment = [SELECT Body FROM Attachment WHERE ParentId = :deployentJob.Id];
        String resultBody = resultAttachment.Body.toString();
        System.assert(
            resultBody.contains(String.format(Label.ERROR_PARSING_FLOW_INFORMATION, new List<Object>{ '' })),
            'Flow information parsing should fail'
        );
    }
}