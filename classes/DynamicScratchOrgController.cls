/**
 * Created by mertyalti on 01/02/2018.
 */

public with sharing class DynamicScratchOrgController extends ScratchOrgWizardPageBase {
    public Test_Run__c testRun { get; set; }
    private Id stdObjectId;
    private String sourceBranch;
    public String initialPageMessage { get; set; }
    public Boolean showInitialPageMessage { get; set; }
    public Boolean showComponent { get; set; }

    public DynamicScratchOrgController(ApexPages.StandardController std) {
        showComponent = true;
        showInitialPageMessage = true;
        stdObjectId = std.getId();
        SObjectType parentObject = stdObjectId.getSobjectType();
        if (parentObject == SObjectType.Test_Run__c.getSObjectType()) {
            testRunOperation();
        }
    }
    private void testRunOperation() {
        try {
            testRun = [
                SELECT
                    Name,
                    Test_Script__r.User_Story__r.Org_Credential__r.Org_Type__c,
                    Test_Script__r.User_Story__r.Org_Credential__r.Developer_Hub_Org__c,
                    Test_Script__r.User_Story__r.Org_Credential__c,
                    Test_Script__r.User_Story__r.Name,
                    Test_Script__r.User_Story__r.Project__c,
                    Test_Script__r.User_Story__r.Project__r.Deployment_Flow__c,
                    Test_Script__r.User_Story__r.Project__r.Deployment_Flow__r.Git_Repository__c,
                    Test_Script__r.User_Story__r.Release__c,
                    Test_Script__r.User_Story__r.Release__r.Project__c,
                    Test_Script__r.User_Story__r.Release__r.Project__r.Deployment_Flow__c,
                    Test_Script__r.User_Story__r.Release__r.Project__r.Deployment_Flow__r.Git_Repository__c
                FROM Test_Run__c
                WHERE Id = :stdObjectId
                WITH SECURITY_ENFORCED
            ];
        } catch (System.QueryException ex) {
            addPageMessage(ApexPages.Severity.ERROR, Test_Run__c.SObjectType.getDescribe().getLabel() + ': ' + Label.Insufficient_Access_Rights);
            return;
        }

        if (
            testRun != null &&
            testRun.Test_Script__c != null &&
            testRun.Test_Script__r.User_Story__c != null &&
            testRun.Test_Script__r.User_Story__r.Org_Credential__c != null &&
            testRun.Test_Script__r.User_Story__r.Org_Credential__r.Org_Type__c == 'Scratch Org' &&
            testRun.Test_Script__r.User_Story__r.Org_Credential__r.Developer_Hub_Org__c != null
        ) {
            Id orgId = testRun.Test_Script__r.User_Story__r.Org_Credential__c;
            Org__c usOrg;
            try {
                usOrg = [
                    SELECT Org_Type__c, Scratch_Org_Expiration_Date__c, Scratch_Org_Status__c, Developer_Hub_Org__c
                    FROM Org__c
                    WHERE Id = :orgId
                    WITH SECURITY_ENFORCED
                ];
            } catch (System.QueryException ex) {
                addPageMessage(ApexPages.Severity.ERROR, Org__c.SObjectType.getDescribe().getLabel() + ': ' + Label.Insufficient_Access_Rights);
                return;
            }
            setDevHubOrgId(usOrg.Developer_Hub_Org__c);
            sourceBranch = SfdxAPIHelper.DX_PROJECT_BRANCH + String.valueOf(testRun.Test_Script__r.User_Story__r.Org_Credential__c).substring(3, 15);
            initialPageMessage = 'Test Scratch org will be created out of ' + sourceBranch;
            try {
                Attachment attDefinition = getOrgAttachment(orgId, SfdxAPIHelper.DX_DEFINITION_FILE);
                Attachment attProject = getOrgAttachment(orgId, SfdxAPIHelper.DX_PROJECT_FILE);
                ScratchOrgDefinition orgTemplate = (ScratchOrgDefinition) JSON.deserialize(attDefinition.Body.toString(), ScratchOrgDefinition.class);
                orgTemplate.setOrgName(testRun.Name + ' Scratch Org');
                orgTemplate.setUsername('');
                setOrgTemplate(orgTemplate);
                String projectJson = attProject.Body.toString();
                projectJson = projectJson.replaceAll('"package":', '"packageName":');
                projectJson = projectJson.replaceAll('"default":', '"defaultArtifact":');
                DXProject artifactProject = (DXProject) JSON.deserialize(projectJson, DXProject.class);
                setArtifactProject(artifactProject);
            } catch (Exception ex) {
                addPageMessage(ApexPages.Severity.ERROR, 'Error during test run operations with message: ' + ex.getMessage());
            }
        } else {
            showComponent = false;
            addPageMessage(ApexPages.Severity.ERROR, 'No org credentials found or missing configuration.');
        }
    }

    private Attachment getOrgAttachment(Id ParentId, String attName) {
        //if (hasAccessTo(parentId.getSobjectType())) { probably not needed
            try {
                return [
                    SELECT Body, ParentId, Name
                    FROM Attachment
                    WHERE ParentId = :ParentId AND Name = :attName
                    WITH SECURITY_ENFORCED
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
            } catch (System.QueryException ex) {
                addPageMessage(ApexPages.Severity.ERROR, Attachment.SObjectType.getDescribe().getLabel() + ': ' + ex.getMessage());
                return null;
            }
        //}
        //return null;
    }

    public PageReference loadReviewData() {
        ScratchOrgDefinition orgTemplate = getOrgTemplate();
        DXProject artifactProject = getArtifactProject();
        if (orgTemplate != null && artifactProject != null) {
            ScratchOrgCompletionController completionController = ((ScratchOrgCompletionController) getComponentController('ScratchOrgCompletion'));
            completionController.orgDefinition = orgTemplate;
            completionController.artifactProject = artifactProject;
            completionController.artifactDirectories = new List<ProjectArtifact>();
            for (ProjectArtifact art : artifactProject.getPackageDirectories()) {
                Boolean defaultArtifact = art.getDefaultArtifact() != null ? art.getDefaultArtifact() : art.getPath() == 'force-app';
                completionController.artifactDirectories.add(new ProjectArtifact(art.getPath(), defaultArtifact));
            }
            completionController.parentId = stdObjectId;
            completionController.setDevHubOrgId(getDevHubOrgId());
            completionController.showPermissionsPanel = false;
            completionController.sourceBranch = sourceBranch;
            completionController.showSetup = false;
        }
        return null;
    }

    public PageReference jobStatusNotification() {
        Map<String, String> pageParameters = ApexPages.currentPage().getParameters();
        Boolean jobFinished = pageParameters.get('jobFinished') == 'true';

        if (jobFinished) {
            Boolean jobSuccess = pageParameters.get('jobSuccess') == 'true';
            if (jobSuccess) {
                String jobType = pageParameters.get('jobType');
                if (String.isNotBlank(jobType)) {
                    addPageMessage(ApexPages.Severity.CONFIRM, Label.Scratch_Org_Created_Success);
                    PageReference pRef = Page.DXTestOrgIntermediary;
                    pRef.getParameters().put('id', testRun.Id);
                    pRef.setRedirect(true);
                    return pRef;
                }
            } else {
                String jobMessage = pageParameters.get('jobMessage');
                if (String.isNotBlank(jobMessage)) {
                    addPageMessage(ApexPages.Severity.ERROR, jobMessage);
                }
            }
        }

        return null;
    }

    /**
     * @description checks if the user has read access to a Salesforce Object and displays an error message otherwise.
     *
     * @param thisObjectType is the SObject type being evaluated.
     *
     * @return a flag indicating if a user has access to the given SObject type or not.
     */
    private Boolean hasAccessTo(SObjectType thisObjectType) {
        Boolean hasAccess = thisObjectType.getDescribe().isAccessible() && thisObjectType.getDescribe().isQueryable();
        if (!hasAccess) {
            addPageMessage(ApexPages.Severity.WARNING, thisObjectType.getDescribe().getLabel() + ': ' + Label.Insufficient_Access_Rights);
        }
        return hasAccess;
    }

    /**
     * @description a utility method for displaying messages on the parent page.
     *
     * @param severity is the ApexPages.Severity enum value for the type of message.
     * @param message is the actual message to be shown to the user.
     */
    private void addPageMessage(ApexPages.Severity severity, String message) {
        ApexPages.addMessage(new ApexPages.Message(severity, message));
    }
}