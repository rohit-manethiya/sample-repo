@isTest
private class TestStepEditionController {
    private static final String STANDARD_USER = 'test_user@myorg.com';
    @testSetup
    static void setupTestData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
    }

    @isTest
    static void myUnitTest() {
        StepEditionController handler = new StepEditionController();

        Step__c testStep = new Step__c();
        testStep.Name = 'test';

        handler.setStep(testStep);

        System.assertEquals(true, handler.filtered);

        Step__c currentStep = handler.getStep();

        System.assertEquals(testStep, currentStep);
    }

    /**
     * Since FlowDefinitionView type is not creatable (Error: DML operation Insert not allowed on FlowDefinitionView),
     * we perforn a real query to the Org (this metadata is accessible from test context) and compare the results
     */
    @IsTest
    static void testGetFlowsAvailableForExecution() {
        final User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);
        System.runAs(standardUser) {
            final StepEditionController handler = new StepEditionController();

            Test.startTest();
            final String flowsResult = handler.getFlowsAvailableForExecution();
            Test.stopTest();

            final List<StepEditionController.FlowOptionWrapper> flowOptionWrappersAvailableForExecution = new List<StepEditionController.FlowOptionWrapper>();
            for (FlowDefinitionView flowAvailableForExecution : [
                SELECT ApiName, Label, NamespacePrefix
                FROM FlowDefinitionView
                WHERE ProcessType = 'AutoLaunchedFlow' AND IsActive = true AND IsTemplate = false AND TriggerType = null
            ]) {
                final String namespace = flowAvailableForExecution.NamespacePrefix != null ? flowAvailableForExecution.NamespacePrefix + '.' : '';
                flowOptionWrappersAvailableForExecution.add(
                    new StepEditionController.FlowOptionWrapper(
                        namespace + flowAvailableForExecution.ApiName,
                        namespace + flowAvailableForExecution.Label
                    )
                );
            }
            System.assertEquals(JSON.serialize(flowOptionWrappersAvailableForExecution), flowsResult, 'Results should match.');
        }
    }
}