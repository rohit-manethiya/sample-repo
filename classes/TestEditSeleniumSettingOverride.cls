/**
 * Created by umitcanuckan on 26/11/2018.
 */

@IsTest
private class TestEditSeleniumSettingOverride {
    @testSetup static void setupTestData(){
        TestUtilities.getAllMultilicense();
    }
    @testSetup static void setupTestDataDML(){
        testMethodUtilities.upsertOrgwideSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);
    }
    @IsTest
    static void EditSeleniumSettingOverride() {
        Selenium_Settings__c ss = new Selenium_Settings__c(Name = 'uucka Quick Test Settings',Provider__c = 'Custom/Other',Webdriver_URL__c = 'https://webdriver.copado.com',Selected_Platforms__c = '[copado]chrome');
        Insert ss;
        ApexPages.StandardController sc = new ApexPages.StandardController(ss);
        EditSeleniumSettingOverride testSeleniumSetting = new EditSeleniumSettingOverride(sc);

        Selenium_Test_Case__c stc = new Selenium_Test_Case__c(Name = 'Test case');
        Insert stc;

        PageReference pageRef = Page.editSeleniumSettingOverride;
        pageRef.getParameters().put('caseId', stc.Id);
        pageRef.getParameters().put('fromQuickRun', 'uucka');
        Test.setCurrentPage(pageRef);

        testSeleniumSetting.saveMethod();
        testSeleniumSetting.goBackToQuickRunPage();
        System.assertEquals(testSeleniumSetting.SeleniumSetting.Id,ss.Id);
        System.assertEquals(testSeleniumSetting.SeleniumSetting.Name,ss.Name);
    }
}