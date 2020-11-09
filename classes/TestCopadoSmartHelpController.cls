@isTest
private class TestCopadoSmartHelpController {

    @TestSetup static void setupData() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User testUser = new User(Alias = 'standt', Email = 'test1@test1.com',
		                  EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
		                  LocaleSidKey = 'en_US', ProfileId = profile.Id, Show_Copado_Tips__c = true,
                          TimeZoneSidKey = 'America/Los_Angeles', UserName = 'myTester@testorg.com');
        insert testUser;
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetId = ps.Id);
    }

    static testMethod void testAlwaysShownTips() {
        User sysUser = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            CopadoSmartHelpController handler = new CopadoSmartHelpController();
            handler.vfPageName = 'GitCommitMain';
            
            List<Copado_Smart_Help__mdt> smartHelpMetadataList = new List<Copado_Smart_Help__mdt>([SELECT
		                                        Base_Page__c, DeveloperName, Help_Text__c, Id, Label, Triggering_Action__c, Triggering_Value__c
		                                   FROM Copado_Smart_Help__mdt
                                           WHERE Base_Page__c = : handler.vfPageName AND Triggering_Action__c = 'Always Show']);
                
            handler.setHelpList();
            System.assertEquals(smartHelpMetadataList.size(),handler.helpList.size());
		}
    }
    
    static testMethod void testSetType() {
        User sysUser = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

		System.runAs(sysUser) {

            CopadoSmartHelpController handler = new CopadoSmartHelpController();
            handler.vfPageName = 'GitCommitMain';
            handler.tipType = 'CustomField';

            List<Copado_Smart_Help__mdt> smartHelpMetadataList = new List<Copado_Smart_Help__mdt>([SELECT
		                                        Base_Page__c, DeveloperName, Help_Text__c, Id, Label, Triggering_Action__c, Triggering_Value__c
		                                   FROM Copado_Smart_Help__mdt
		                                   WHERE Base_Page__c = : handler.vfPageName AND Triggering_Action__c != 'Always Show'
		                                           AND DeveloperName NOT IN: handler.removedTips AND Triggering_Value__c = : handler.tipType
		                                                   ORDER BY Triggering_Value__c]);

			handler.setTypeList();
            System.assertEquals(smartHelpMetadataList.size(), handler.helpList.size());

            Integer smartHelpCount = handler.helpList.size();
            
            handler.tipKey = 'Profile_Permission_Set_FLS';
            handler.removeTip();

            System.assertEquals(smartHelpCount - 1, handler.helpList.size());
        }
    }
}