@IsTest
public class TestGitCommitChangesController {

    @TestSetup
    static void setupData() {
        TestUtilities.getAllMultilicense();
    }

    static testMethod void testGitCommitChangesController() {
        testMethodUtilities.upsertOrgwideSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, false);
        Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
        insert feature;

        Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
        insert gitRepo;
        Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
        insert flowCBM;
        System.assert(flowCBM.Id != null);

        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flowCBM.Id;
        insert testProject;

        List<Environment__c> envList = new List<Environment__c>();
        Environment__c envDev1 = new Environment__c(Name='Dev1 Environment',Type__c='Sandbox');
        envList.add(envDev1);
        Environment__c envInt = new Environment__c(Name='Dev1 Environment',Type__c='Sandbox');
        envList.add(envInt);
        insert envList;

        List<Org__c> orgList = new List<Org__c>();
        Org__c orgDev1 = CMTestMethodUtilities.createOrg('MyOrgDev1', 'Sandbox', 'SFDC_OrgId', null, null, System.now(), envDev1.Id);
        orgList.add(orgDev1);
        Org__c orgInt = CMTestMethodUtilities.createOrg('MyOrgInt', 'Production', 'SFDC_OrgId3', null, null, System.now(), envInt.Id);
        orgList.add(orgInt);
        insert orgList;

        Git_Backup__c gitSnapshotDev1 = new Git_Backup__c(Git_Repository__c = gitRepo.Id, Org__c = orgDev1.Id, Branch__c = 'dev1');
        Git_Backup__c gitSnapshotInt = new Git_Backup__c(Git_Repository__c = gitRepo.Id, Org__c = orgInt.Id, Branch__c = 'int');
        insert new List<Git_Backup__c>{gitSnapshotDev1, gitSnapshotInt};

        Deployment_Flow_Step__c stepDev1ToInt = CMTestMethodUtilities.createFlowStep(envDev1.Id, envInt.Id, flowCBM.Id);
        stepDev1ToInt.Branch__c = 'dev1';
        insert stepDev1ToInt;

        User_Story__c userStory = new User_Story__c(User_Story_Title__c = 'UserStory for Profile Changes', Project__c = testProject.Id, Org_Credential__c = orgDev1.Id, Environment__c = envDev1.Id);
        insert userStory;

        Git_Operation_Restriction__c currentUserRestriction = new Git_Operation_Restriction__c();
        currentUserRestriction.Git_Operation_Name__c = 'Recommit Files;Destructive Changes;Undo Commits;Full Profiles & Permission Sets';
        currentUserRestriction.SetupOwnerId = UserInfo.getOrganizationId();
        currentUserRestriction.Active__c = true;
        insert currentUserRestriction;

        PageReference ref = Page.GitCommitChanges;
        ApexPages.currentPage().getParameters().put('repoId', gitRepo.Id);
        ApexPages.currentPage().getParameters().put('orgId', orgDev1.Id);
        ApexPages.currentPage().getParameters().put('userStoryId', userStory.Id);
        ApexPages.currentPage().getParameters().put('snapshotId', gitSnapshotDev1.Id);

        Test.startTest();

        userStory = [SELECT Id, Name, User_Story_Title__c FROM User_Story__c WHERE Id = :userStory.Id];

        GitCommitChangesController con = new GitCommitChangesController();
        System.assert(con.userStory != null);
        System.assertEquals(orgDev1.Name, con.orgName);
        System.assertEquals(gitSnapshotDev1.Branch__c, con.branch);
        System.assertEquals(gitRepo.Name, con.repoName);

        System.assertEquals(orgDev1.Id, con.gitCommit.Org__c);
        System.assertEquals(userStory.Name + ': ' + userStory.User_Story_Title__c, (con.gitCommit.Commit_Message__c = userStory.Name +': ' + (String.isEmpty(userStory.User_Story_Title__c)?'': userStory.User_Story_Title__c)).left(254));

        // If the backend JSON is not available, only the Commit Files operation will be available
        System.assertEquals('Commit Files', con.gitCommit.Git_Operation__c);
        System.assertEquals('CommitFiles', con.selectedOperation.operationType);
        System.assertEquals(1, con.operationsMap.size());
        System.assertEquals(1, con.operationTypes.size());
        Test.stopTest();
    }

    static testMethod void testUserStoryGitOperations() {
        testMethodUtilities.upsertOrgwideSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, false);
        Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
        insert feature;

        Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
        insert gitRepo;
        Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
        insert flowCBM;
        System.assert(flowCBM.Id != null);

        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flowCBM.Id;
        insert testProject;

        List<Environment__c> envList = new List<Environment__c>();
        Environment__c envDev1 = new Environment__c(Name='Dev1 Environment',Type__c='Sandbox');
        envList.add(envDev1);
        Environment__c envInt = new Environment__c(Name='Dev1 Environment',Type__c='Sandbox');
        envList.add(envInt);
        insert envList;

        List<Org__c> orgList = new List<Org__c>();
        Org__c orgDev1 = CMTestMethodUtilities.createOrg('MyOrgDev1', 'Sandbox', 'SFDC_OrgId', null, null, System.now(), envDev1.Id);
        orgList.add(orgDev1);
        Org__c orgInt = CMTestMethodUtilities.createOrg('MyOrgInt', 'Production', 'SFDC_OrgId3', null, null, System.now(), envInt.Id);
        orgList.add(orgInt);
        insert orgList;

        Git_Backup__c gitSnapshotDev1 = new Git_Backup__c(Git_Repository__c = gitRepo.Id, Org__c = orgDev1.Id, Branch__c = 'dev1');
        Git_Backup__c gitSnapshotInt = new Git_Backup__c(Git_Repository__c = gitRepo.Id, Org__c = orgInt.Id, Branch__c = 'int');
        insert new List<Git_Backup__c>{gitSnapshotDev1, gitSnapshotInt};

        Deployment_Flow_Step__c stepDev1ToInt = CMTestMethodUtilities.createFlowStep(envDev1.Id, envInt.Id, flowCBM.Id);
        stepDev1ToInt.Branch__c = 'dev1';
        insert stepDev1ToInt;

        User_Story__c userStory = new User_Story__c(User_Story_Title__c = 'UserStory for Profile Changes', Project__c = testProject.Id, Org_Credential__c = orgDev1.Id, Environment__c = envDev1.Id);
        insert userStory;

        Git_Operation_Restriction__c currentUserRestriction = new Git_Operation_Restriction__c();
        currentUserRestriction.Git_Operation_Name__c = 'Recommit Files;Destructive Changes;Undo Commits;Full Profiles & Permission Sets';
        currentUserRestriction.SetupOwnerId = UserInfo.getOrganizationId();
        currentUserRestriction.Active__c = true;
        insert currentUserRestriction;

        // Even though the Commits in the user story happened in Dev1 and in Int (See below), they still appear in the Undo Commits table so that these can be undone in the feature branch.
        Git_Org_Commit__c snapshotCommit1 = new Git_Org_Commit__c(Git_Backup__c = gitSnapshotDev1.Id, Org__c = orgDev1.Id, Commit_Id__c = 'b7adccf3937495e8928d1023c5a5c644198b8974', Commit_Date__c = Date.today(), Commit_Message__c = 'test 1', Status__c = 'Complete');
        Git_Org_Commit__c snapshotCommit2 = new Git_Org_Commit__c(Git_Backup__c = gitSnapshotInt.Id, Org__c = orgInt.Id, Commit_Id__c = 'b5adccf3937495e8928d1023c5a5c644198b10293', Commit_Date__c = Date.today(), Commit_Message__c = 'test 2', Status__c = 'Complete');
        insert new List<Git_Org_Commit__c> {snapshotCommit1, snapshotCommit2};

        List<User_Story_Commit__c> usCommitList = new List<User_Story_Commit__c>();
        User_Story_Commit__c userStoryCommit1 = new User_Story_Commit__c(User_Story__c = userStory.Id, Snapshot_Commit__c = snapshotCommit1.Id);
        usCommitList.add(userStoryCommit1);
        User_Story_Commit__c userStoryCommit2 = new User_Story_Commit__c(User_Story__c = userStory.Id, Snapshot_Commit__c = snapshotCommit2.Id);
        usCommitList.add(userStoryCommit2);
        insert usCommitList;

        // Insert Git Metadata Attachment
        Attachment att1 = new Attachment(ParentId=userStory.Id, Name='Git Metadata', Body=Blob.valueOf('[{"t":"EmailTemplate","n":"Template1","s":true}]'));
        insert att1;

        PageReference ref = Page.GitCommitChanges;
        ApexPages.currentPage().getParameters().put('repoId', gitRepo.Id);
        ApexPages.currentPage().getParameters().put('orgId', orgDev1.Id);
        ApexPages.currentPage().getParameters().put('userStoryId', userStory.Id);
        ApexPages.currentPage().getParameters().put('snapshotId', gitSnapshotDev1.Id);

        String b = '[ { "operationType":"RecommitFiles", "operationLabel":"Recommit Files", "showAdvancedSection":true, "showGrid":true, "showUserStorySelections":true, "showCommitMessage":true, "operationFormElements":[ { "label":"Re-Create Feature Branch", "name":"recreateFeatureBranch", "value":"", "type":"checkbox", "helpText":"If checked, the existing feature branch will be deleted and the selected components in the grid will be committed in a new feature branch. Previous commits will not be present in the new feature branch." } ], "helpText":"When recommitting files, the metadata grid appears with the existing user story selections. You can uncheck the selected components and also select new ones.", "helpLink":"https://docs.copado.com/article/EYo28v6lWX#Recommit-Files", "pages":"UserStoryCommit", "endpoint":"commit" }, ' +
                '{ "operationType":"GitDeletion", "operationLabel":"Destructive Changes", "operationButtonLabel":"Commit Destructive Changes", "showAdvancedSection":true, "attachmentName":"Git Deletion", "operationFormElements":[ { "label":"Org Credential", "name":"orgId", "type":"orgLookup", "helpText":"If changed, the metadata grid will reload with the metadata items of the selected Org Credential." } ], "showGrid":true, "editGrid":true, "showCommitMessage":true, "helpText":"\'. Select the commits you would like to undo and click Undo Commits. When the operation is finished, the status of the selected User Story Commits will be updated to \'Commit Undone\'.", "helpLink":"https://docs.copado.com/article/EYo28v6lWX#Destructive-Changes-for-Git", "pages":"GitSnapshotCommit,UserStoryCommit", "endpoint":"commit" }, ' +
                '{ "operationType":"UndoCommits", "operationLabel":"Undo Commits", "operationButtonLabel":"Undo Commits", "attachmentName":"Commits", "showAdvancedSection":false, "showTable":true, "tableSObject":"USER_STORY_COMMIT__c", "helpText":"When undoing commits, a table appears with a list of User Story Commits with status \'Complete\'. Select the commits you would like to undo and click Undo Commits. The User Story Commits status will be updated to \'Commit Undone\' when finished.", "helpLink":"https://docs.copado.com/article/EYo28v6lWX#Undo-Commits", "pages":"GitSnapshotCommit,UserStoryCommit", "endpoint":"undoCommit" },' +
                '{ "operationType":"DeleteBranches", "operationLabel":"Delete Branches", "operationButtonLabel":"Delete Branches", "operationFormElements":[ { "label":"Branch Names", "name":"deleteBranches", "type":"text", "helpText":"" } ], "helpText":"", "helpLink":"", "pages":"GitRepository", "endpoint":"deleteBranch" }, ' +
                '{ "operationType":"FullProfilePermissionSets", "operationLabel":"Full Profiles & Permission Sets", "showAdvancedSection":true, "showGrid":true, "gridMetadataTypes":"Profiles,PermissionSets", "showCommitMessage":true, "helpText":"The selected profiles and permission sets will be committed with all its references to other components (e.g. objects, fields, layouts, record types, apex classes and pages). There can be deployment errors when the profiles or permission sets are referencing components that do not exist in the target Org.", "helpLink":"https://docs.copado.com/article/EYo28v6lWX#FullProfilesPermissionSets", "pages":"GitSnapshotCommit,UserStoryCommit", "endpoint":"commit" } ]';

        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Test.startTest();

        // Initialize constructor for the User Story Commit Files page
        GitCommitChangesController con = new GitCommitChangesController();
        System.assertEquals('Commit Files', con.gitCommit.Git_Operation__c);
        System.assertEquals('CommitFiles', con.selectedOperation.operationType);
        System.assertEquals(true, con.selectedOperation.showAdvancedSection);

        // Assert number of Git Operations from the backend JSON + default Commit Files operation.
        System.assertEquals(4 + 1, con.operationsMap.size());
        System.assertEquals(4 + 1, con.operationTypes.size());

        // 2 - Change Git Operation to Destructive Changes
        con.gitCommit.Git_Operation__c = con.operationsMap.get('Destructive Changes').operationLabel;
        con.changeOperation();
        System.assertEquals('GitDeletion', con.selectedOperation.operationType);
        System.assertEquals('orgLookup', con.selectedOperation.operationFormElements[0].type);
        System.assertEquals(true, con.selectedOperation.showGrid);
        System.assertEquals('Git Deletion', con.selectedOperation.attachmentName);
        System.assertEquals('Commit Destructive Changes', con.selectedOperation.operationButtonLabel);

        // 3 - Change Git Operation to Recommit Files
        con.gitCommit.Git_Operation__c = con.operationsMap.get('Recommit Files').operationLabel;
        con.changeOperation();
        con.goToWaitingForPage();
        System.assertEquals('RecommitFiles', con.selectedOperation.operationType);
        System.assertEquals('checkbox', con.selectedOperation.operationFormElements[0].type);
        System.assertEquals(att1.Id, con.gitMetadataAttachmentId);
        String checkboxName = con.selectedOperation.operationFormElements[0].name;
        System.assertEquals('&' + checkboxName + '=false' ,con.getOperationFormElementParams());
        con.selectedOperation.operationFormElements[0].boolValue = true;
        System.assertEquals('&' + checkboxName + '=true' ,con.getOperationFormElementParams());

        // 4 - Change Git Operation to Undo Commits
        con.gitCommit.Git_Operation__c = con.operationsMap.get('Undo Commits').operationLabel;
        con.changeOperation();
        System.assertEquals('UndoCommits', con.selectedOperation.operationType);
        // The gitMetadataAttachmentId value defaults to empty String
        System.assertEquals('', con.gitMetadataAttachmentId);
        System.assertEquals(2, con.snapshotCommitWrappers.size());
        con.snapshotCommitWrappers[0].selected = true;
        con.snapshotCommitWrappers[1].selected = true;
        System.assertEquals('["'+snapshotCommit1.Id+'","'+snapshotCommit2.Id+'"]', con.getSelectedTableValues());
        System.assertEquals('Commits', con.selectedOperation.attachmentName);
        System.assertEquals(false, con.selectedOperation.showAdvancedSection);

        // 5 - Change Git Operation to Full Profiles and Permission Sets
        con.gitCommit.Git_Operation__c = con.operationsMap.get('Full Profiles & Permission Sets').operationLabel;
        con.changeOperation();
        System.assertEquals('FullProfilePermissionSets', con.selectedOperation.operationType);

        Test.stopTest();
    }
    static testMethod void testGitSnapshotGitOperations() {
        testMethodUtilities.upsertOrgwideSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, false);
        Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
        insert feature;

        Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
        insert gitRepo;
        Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
        insert flowCBM;
        System.assert(flowCBM.Id != null);

        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flowCBM.Id;
        insert testProject;

        List<Environment__c> envList = new List<Environment__c>();
        Environment__c envDev1 = new Environment__c(Name='Dev1 Environment',Type__c='Sandbox');
        envList.add(envDev1);
        Environment__c envInt = new Environment__c(Name='Dev1 Environment',Type__c='Sandbox');
        envList.add(envInt);
        insert envList;

        List<Org__c> orgList = new List<Org__c>();
        Org__c orgDev1 = CMTestMethodUtilities.createOrg('MyOrgDev1', 'Sandbox', 'SFDC_OrgId', null, null, System.now(), envDev1.Id);
        orgList.add(orgDev1);
        Org__c orgInt = CMTestMethodUtilities.createOrg('MyOrgInt', 'Production', 'SFDC_OrgId3', null, null, System.now(), envInt.Id);
        orgList.add(orgInt);
        insert orgList;

        Git_Backup__c gitSnapshotDev1 = new Git_Backup__c(Git_Repository__c = gitRepo.Id, Org__c = orgDev1.Id, Branch__c = 'dev1');
        Git_Backup__c gitSnapshotInt = new Git_Backup__c(Git_Repository__c = gitRepo.Id, Org__c = orgInt.Id, Branch__c = 'int');
        insert new List<Git_Backup__c>{gitSnapshotDev1, gitSnapshotInt};

        Deployment_Flow_Step__c stepDev1ToInt = CMTestMethodUtilities.createFlowStep(envDev1.Id, envInt.Id, flowCBM.Id);
        stepDev1ToInt.Branch__c = 'dev1';
        insert stepDev1ToInt;

        User_Story__c userStory = new User_Story__c(User_Story_Title__c = 'UserStory for Profile Changes', Project__c = testProject.Id, Org_Credential__c = orgDev1.Id, Environment__c = envDev1.Id);
        insert userStory;

        Git_Operation_Restriction__c currentUserRestriction = new Git_Operation_Restriction__c();
        currentUserRestriction.Git_Operation_Name__c = 'Recommit Files;Destructive Changes;Undo Commits;Full Profiles & Permission Sets';
        currentUserRestriction.SetupOwnerId = UserInfo.getOrganizationId();
        currentUserRestriction.Active__c = true;
        insert currentUserRestriction;

        // Only the commits done in the Dev1 Snapshot will appear in the Undo Commits table
        Git_Org_Commit__c snapshotCommit1 = new Git_Org_Commit__c(Git_Backup__c = gitSnapshotDev1.Id, Org__c = orgDev1.Id, Commit_Id__c = 'b7adccf3937495e8928d1023c5a5c644198b8974', Commit_Date__c = Date.today(), Commit_Message__c = 'test 1', Status__c = 'Complete');
        Git_Org_Commit__c snapshotCommit2 = new Git_Org_Commit__c(Git_Backup__c = gitSnapshotDev1.Id, Org__c = orgDev1.Id, Commit_Id__c = 'b5adccf3937495e8928d1023c5a5c644198b10293', Commit_Date__c = Date.today(), Commit_Message__c = 'test 2', Status__c = 'Complete');
        insert new List<Git_Org_Commit__c> {snapshotCommit1, snapshotCommit2};

        PageReference ref = Page.GitCommitChanges;
        ApexPages.currentPage().getParameters().put('repoId', gitRepo.Id);
        ApexPages.currentPage().getParameters().put('orgId', orgDev1.Id);
        ApexPages.currentPage().getParameters().put('snapshotId', gitSnapshotDev1.Id);

        String b = '[ { "operationType":"RecommitFiles", "operationLabel":"Recommit Files", "showGrid":true, "showUserStorySelections":true, "showCommitMessage":true, "operationFormElements":[ { "label":"Re-Create Feature Branch", "name":"recreateFeatureBranch", "value":"", "type":"checkbox", "helpText":"If checked, the existing feature branch will be deleted and the selected components in the grid will be committed in a new feature branch. Previous commits will not be present in the new feature branch." } ], "helpText":"When recommitting files, the metadata grid appears with the existing user story selections. You can uncheck the selected components and also select new ones.", "helpLink":"https://docs.copado.com/article/EYo28v6lWX#Recommit-Files", "pages":"UserStoryCommit", "endpoint":"commit" }, ' +
                '{ "operationType":"GitDeletion", "operationLabel":"Destructive Changes", "operationButtonLabel":"Commit Destructive Changes", "attachmentName":"Git Deletion", "operationFormElements":[ { "label":"Org Credential", "name":"orgId", "type":"orgLookup", "helpText":"If changed, the metadata grid will reload with the metadata items of the selected Org Credential." } ], "showGrid":true, "editGrid":true, "showCommitMessage":true, "helpText":"\'. Select the commits you would like to undo and click Undo Commits. When the operation is finished, the status of the selected User Story Commits will be updated to \'Commit Undone\'.", "helpLink":"https://docs.copado.com/article/EYo28v6lWX#Destructive-Changes-for-Git", "pages":"GitSnapshotCommit,UserStoryCommit", "endpoint":"commit" }, ' +
                '{ "operationType":"UndoCommits", "operationLabel":"Undo Commits", "operationButtonLabel":"Undo Commits", "attachmentName":"Commits", "showTable":true, "tableSObject":"USER_STORY_COMMIT__c", "helpText":"When undoing commits, a table appears with a list of User Story Commits with status \'Complete\'. Select the commits you would like to undo and click Undo Commits. The User Story Commits status will be updated to \'Commit Undone\' when finished.", "helpLink":"https://docs.copado.com/article/EYo28v6lWX#Undo-Commits", "pages":"GitSnapshotCommit,UserStoryCommit", "endpoint":"undoCommit" },' +
                '{ "operationType":"DeleteBranches", "operationLabel":"Delete Branches", "operationButtonLabel":"Delete Branches", "operationFormElements":[ { "label":"Branch Names", "name":"deleteBranches", "type":"text", "helpText":"" } ], "helpText":"", "helpLink":"", "pages":"GitRepository", "endpoint":"deleteBranch" }, ' +
                '{ "operationType":"FullProfilePermissionSets", "operationLabel":"Full Profiles & Permission Sets", "showGrid":true, "gridMetadataTypes":"Profiles,PermissionSets", "showCommitMessage":true, "helpText":"The selected profiles and permission sets will be committed with all its references to other components (e.g. objects, fields, layouts, record types, apex classes and pages). There can be deployment errors when the profiles or permission sets are referencing components that do not exist in the target Org.", "helpLink":"https://docs.copado.com/article/EYo28v6lWX#FullProfilesPermissionSets", "pages":"GitSnapshotCommit,UserStoryCommit", "endpoint":"commit" } ]';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Test.startTest();

        // Initialize constructor for the User Story Commit Files page
        GitCommitChangesController con = new GitCommitChangesController();
        System.assertEquals('Commit Files', con.gitCommit.Git_Operation__c);
        System.assertEquals('CommitFiles', con.selectedOperation.operationType);

        // Assert number of Git Operations from the backend JSON + default Commit Files operation. The Commit Files is not included since it is not meant to be shown in the Git Snapshot Commit Files page.
        System.assertEquals(3 + 1, con.operationsMap.size());
        System.assertEquals(3 + 1, con.operationTypes.size());

        // 2 - Change Git Operation to Destructive Changes
        con.gitCommit.Git_Operation__c = con.operationsMap.get('Destructive Changes').operationLabel;
        con.changeOperation();
        System.assertEquals('GitDeletion', con.selectedOperation.operationType);
        System.assertEquals('orgLookup', con.selectedOperation.operationFormElements[0].type);
        System.assertEquals(true, con.selectedOperation.showGrid);
        System.assertEquals('Git Deletion', con.selectedOperation.attachmentName);
        System.assertEquals('Commit Destructive Changes', con.selectedOperation.operationButtonLabel);

        // 3 - Change Git Operation to Undo Commits
        con.gitCommit.Git_Operation__c = con.operationsMap.get('Undo Commits').operationLabel;
        con.changeOperation();
        System.assertEquals('UndoCommits', con.selectedOperation.operationType);
        System.assertEquals(true, con.selectedOperation.showTable);
        System.assertEquals(2, con.snapshotCommitWrappers.size());
        con.snapshotCommitWrappers[0].selected = true;
        con.snapshotCommitWrappers[1].selected = true;
        System.assertEquals('["'+snapshotCommit1.Id+'","'+snapshotCommit2.Id+'"]', con.getSelectedTableValues());

        // 4 - Change Git Operation to Full Profiles and Permission Sets
        con.gitCommit.Git_Operation__c = con.operationsMap.get('Full Profiles & Permission Sets').operationLabel;
        con.changeOperation();
        System.assertEquals('FullProfilePermissionSets', con.selectedOperation.operationType);

        Test.stopTest();
    }

    static testMethod void testBaseBranchAssignment() {
        testMethodUtilities.upsertOrgwideSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, false);
        Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
        insert feature;

        Environment__c envDev1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
        insert envDev1;

        Org__c orgDev1 = CMTestMethodUtilities.createOrg('MyOrgDev1', 'Sandbox', 'SFDC_OrgId', null, null, System.now(), envDev1.Id);
        insert orgDev1;

        Git_Repository__c gitRepo = new Git_Repository__c(Name = 'Git Repository 1');
        insert gitRepo;

        Git_Backup__c gitSnapshotDev1 = new Git_Backup__c(Git_Repository__c = gitRepo.Id, Org__c = orgDev1.Id, Branch__c = 'dev1');
        insert gitSnapshotDev1;

        Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
        insert flowCBM;

        Project__c testProject = CMTestMethodUtilities.createProject('My Test Project');
        testProject.Deployment_Flow__c = flowCBM.Id;
        insert testProject;

        Release__c testRelease = CMTestMethodUtilities.createRelease('My Test Release');
        testRelease.Project__c = testProject.Id;
        insert testRelease;

        User_Story__c userStory = new User_Story__c(User_Story_Title__c = 'UserStory for Profile Changes', Project__c = testProject.Id, Org_Credential__c = orgDev1.Id, Environment__c = envDev1.Id);
        insert userStory;

        Test.startTest();

        PageReference ref = Page.GitCommitChanges;
        ApexPages.currentPage().getParameters().put('repoId', gitRepo.Id);
        ApexPages.currentPage().getParameters().put('orgId', orgDev1.Id);
        ApexPages.currentPage().getParameters().put('userStoryId', userStory.Id);
        ApexPages.currentPage().getParameters().put('snapshotId', gitSnapshotDev1.Id);

        // Main Branch from CBM Flow Main Branch
        GitCommitChangesController con = new GitCommitChangesController();
        System.debug('### flowCBM.Main_Branch__c: '+flowCBM.Main_Branch__c);
        System.assertEquals(flowCBM.Main_Branch__c, con.baseBranch);

        // Main Branch from User Story Base Branch
        userStory.Base_Branch__c = 'int';
        update userStory;
        GitCommitChangesController con2 = new GitCommitChangesController();
        System.assertEquals(userStory.Base_Branch__c, con2.baseBranch);
        con2.baseBranch = 'patch5.1';
        con2.updateUserStory();
        userStory = [SELECT Id, Base_Branch__c FROM User_Story__c WHERE Id = :userStory.Id];
        System.assertEquals(con2.baseBranch, userStory.Base_Branch__c);

        Test.stopTest();
    }

    static testMethod void testRestrictingGitOperationsToUser(){
        testMethodUtilities.upsertOrgwideSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true, false, false, false, false);
        Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
        insert feature;

        Git_Repository__c gitRepo = new Git_Repository__c(Name = 'gitRepo');
        insert gitRepo;
        Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
        insert flowCBM;
        System.assert(flowCBM.Id != null);

        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flowCBM.Id;
        insert testProject;

        List<Environment__c> envList = new List<Environment__c>();
        Environment__c envDev1 = new Environment__c(Name='Dev1 Environment',Type__c='Sandbox');
        envList.add(envDev1);
        Environment__c envInt = new Environment__c(Name='Dev1 Environment',Type__c='Sandbox');
        envList.add(envInt);
        insert envList;

        List<Org__c> orgList = new List<Org__c>();
        Org__c orgDev1 = CMTestMethodUtilities.createOrg('MyOrgDev1', 'Sandbox', 'SFDC_OrgId', null, null, System.now(), envDev1.Id);
        orgList.add(orgDev1);
        Org__c orgInt = CMTestMethodUtilities.createOrg('MyOrgInt', 'Production', 'SFDC_OrgId3', null, null, System.now(), envInt.Id);
        orgList.add(orgInt);
        insert orgList;

        Git_Backup__c gitSnapshotDev1 = new Git_Backup__c(Git_Repository__c = gitRepo.Id, Org__c = orgDev1.Id, Branch__c = 'dev1');
        Git_Backup__c gitSnapshotInt = new Git_Backup__c(Git_Repository__c = gitRepo.Id, Org__c = orgInt.Id, Branch__c = 'int');
        insert new List<Git_Backup__c>{gitSnapshotDev1, gitSnapshotInt};

        Deployment_Flow_Step__c stepDev1ToInt = CMTestMethodUtilities.createFlowStep(envDev1.Id, envInt.Id, flowCBM.Id);
        stepDev1ToInt.Branch__c = 'dev1';
        insert stepDev1ToInt;

        User_Story__c userStory = new User_Story__c(User_Story_Title__c = 'UserStory for Profile Changes', Project__c = testProject.Id, Org_Credential__c = orgDev1.Id, Environment__c = envDev1.Id);
        insert userStory;

        // Even though the Commits in the user story happened in Dev1 and in Int (See below), they still appear in the Undo Commits table so that these can be undone in the feature branch.
        Git_Org_Commit__c snapshotCommit1 = new Git_Org_Commit__c(Git_Backup__c = gitSnapshotDev1.Id, Org__c = orgDev1.Id, Commit_Id__c = 'b7adccf3937495e8928d1023c5a5c644198b8974', Commit_Date__c = Date.today(), Commit_Message__c = 'test 1', Status__c = 'Complete');
        Git_Org_Commit__c snapshotCommit2 = new Git_Org_Commit__c(Git_Backup__c = gitSnapshotInt.Id, Org__c = orgInt.Id, Commit_Id__c = 'b5adccf3937495e8928d1023c5a5c644198b10293', Commit_Date__c = Date.today(), Commit_Message__c = 'test 2', Status__c = 'Complete');
        insert new List<Git_Org_Commit__c> {snapshotCommit1, snapshotCommit2};

        List<User_Story_Commit__c> usCommitList = new List<User_Story_Commit__c>();
        User_Story_Commit__c userStoryCommit1 = new User_Story_Commit__c(User_Story__c = userStory.Id, Snapshot_Commit__c = snapshotCommit1.Id);
        usCommitList.add(userStoryCommit1);
        User_Story_Commit__c userStoryCommit2 = new User_Story_Commit__c(User_Story__c = userStory.Id, Snapshot_Commit__c = snapshotCommit2.Id);
        usCommitList.add(userStoryCommit2);
        insert usCommitList;

        // Insert Git Metadata Attachment
        DeployAPI.MetaData gitMetaData = new DeployAPI.MetaData();
        gitMetaData.t = 'EmailTemplate';
        gitMetaData.n = 'Template1';
        gitMetaData.s = true;
        Attachment att1 = new Attachment(ParentId=userStory.Id, Name='Git Metadata', Body=Blob.valueOf(JSON.serialize(gitMetaData)));
        insert att1;

        PageReference ref = Page.GitCommitChanges;
        ApexPages.currentPage().getParameters().put('repoId', gitRepo.Id);
        ApexPages.currentPage().getParameters().put('orgId', orgDev1.Id);
        ApexPages.currentPage().getParameters().put('userStoryId', userStory.Id);
        ApexPages.currentPage().getParameters().put('snapshotId', gitSnapshotDev1.Id);

        Git_Operation_Restriction__c currentUserRestriction = new Git_Operation_Restriction__c();
        currentUserRestriction.Git_Operation_Name__c = 'Recommit Files;Destructive Changes';
        currentUserRestriction.SetupOwnerId = UserInfo.getUserId();
        currentUserRestriction.Active__c = true;
        insert currentUserRestriction;

        String gitOperationsJsonString = '[ { "operationType":"RecommitFiles", "operationLabel":"Recommit Files", "showAdvancedSection":true, "showGrid":true, "showUserStorySelections":true, "showCommitMessage":true, "operationFormElements":[ { "label":"Re-Create Feature Branch", "name":"recreateFeatureBranch", "value":"", "type":"checkbox", "helpText":"If checked, the existing feature branch will be deleted and the selected components in the grid will be committed in a new feature branch. Previous commits will not be present in the new feature branch." } ], "helpText":"When recommitting files, the metadata grid appears with the existing user story selections. You can uncheck the selected components and also select new ones.", "helpLink":"https://docs.copado.com/article/EYo28v6lWX#Recommit-Files", "pages":"UserStoryCommit", "endpoint":"commit" }, ' +
                '{ "operationType":"GitDeletion", "operationLabel":"Destructive Changes", "operationButtonLabel":"Commit Destructive Changes", "showAdvancedSection":true, "attachmentName":"Git Deletion", "operationFormElements":[ { "label":"Org Credential", "name":"orgId", "type":"orgLookup", "helpText":"If changed, the metadata grid will reload with the metadata items of the selected Org Credential." } ], "showGrid":true, "editGrid":true, "showCommitMessage":true, "helpText":"\'. Select the commits you would like to undo and click Undo Commits. When the operation is finished, the status of the selected User Story Commits will be updated to \'Commit Undone\'.", "helpLink":"https://docs.copado.com/article/EYo28v6lWX#Destructive-Changes-for-Git", "pages":"GitSnapshotCommit,UserStoryCommit", "endpoint":"commit" }, ' +
                '{ "operationType":"UndoCommits", "operationLabel":"Undo Commits", "operationButtonLabel":"Undo Commits", "attachmentName":"Commits", "showAdvancedSection":false, "showTable":true, "tableSObject":"USER_STORY_COMMIT__c", "helpText":"When undoing commits, a table appears with a list of User Story Commits with status \'Complete\'. Select the commits you would like to undo and click Undo Commits. The User Story Commits status will be updated to \'Commit Undone\' when finished.", "helpLink":"https://docs.copado.com/article/EYo28v6lWX#Undo-Commits", "pages":"GitSnapshotCommit,UserStoryCommit", "endpoint":"undoCommit" },' +
                '{ "operationType":"DeleteBranches", "operationLabel":"Delete Branches", "operationButtonLabel":"Delete Branches", "operationFormElements":[ { "label":"Branch Names", "name":"deleteBranches", "type":"text", "helpText":"" } ], "helpText":"", "helpLink":"", "pages":"GitRepository", "endpoint":"deleteBranch" }, ' +
                '{ "operationType":"FullProfilePermissionSets", "operationLabel":"Full Profiles & Permission Sets", "showAdvancedSection":true, "showGrid":true, "gridMetadataTypes":"Profiles,PermissionSets", "showCommitMessage":true, "helpText":"The selected profiles and permission sets will be committed with all its references to other components (e.g. objects, fields, layouts, record types, apex classes and pages). There can be deployment errors when the profiles or permission sets are referencing components that do not exist in the target Org.", "helpLink":"https://docs.copado.com/article/EYo28v6lWX#FullProfilesPermissionSets", "pages":"GitSnapshotCommit,UserStoryCommit", "endpoint":"commit" } ]';

        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(gitOperationsJsonString, null));

        Test.startTest();

        // Initialize constructor for the git operation restriction control
        GitCommitChangesController con = new GitCommitChangesController();

        // Assert Recommit Files and Destructive Changes are not available in operationsMap
        System.assertEquals(null, con.operationsMap.get('Undo Commits'));
        System.assertEquals(null, con.operationsMap.get('Full Profiles & Permission Sets'));
        System.assertEquals(3, con.operationsMap.size());

        Test.stopTest();

    }

    static testMethod void testParsingGitFileError(){

        GitCommitChangesController con = new GitCommitChangesController();
        con.parseGitOperationsFile('Wrong JSON');

        List<ApexPages.Message> currentPageMessageList = ApexPages.getMessages();
        Boolean hasParseError = false;
        For(ApexPages.Message msg : currentPageMessageList){
            System.debug('msg detail: ' + msg.getDetail());
            if(msg.getDetail() == Label.Error_Parsing_Git_File){
                hasParseError = true;
            }
        }

        System.assert(hasParseError);
    }
}