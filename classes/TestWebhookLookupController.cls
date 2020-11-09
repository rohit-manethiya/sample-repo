@isTest
public class TestWebhookLookupController {
    @testSetup static void setupTestData(){
        TestUtilities.setTestSettingsEE();
    }
    @testSetup static void setupTestDataDML(){
        testMethodUtilities.upsertOrgwideSettings();
    }
    static testMethod void fullTest(){
        webhookLookupController con = new webhookLookupController();
        system.assert(con.settings != null);
        system.assert(con.lookupAux != null);
    }	
}