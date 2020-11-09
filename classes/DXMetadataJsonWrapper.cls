/**
 * Created by ferhatozsavran on 8/30/18.
 */

public with sharing class DXMetadataJsonWrapper {

    /**
     * This wrapper will be used to hold values to load metadata from artifact, org and branches
     * Note: sendEmail is not currently hardcoded and value true
     */
    public class LoadMetadataWrapper {
        public String projectJSON { get; set; }
        public String mdSourcesJSON { get; set; }
        public String scratchOrgId { get; set; }
        public String dxRepositoryId { get; set; }
        public String sendEmail { get; set; }
        public String orgId { get; set; }
        public String repoId { get; set; }
        public String branchName { get; set; }
        public String namespace { get; set; }
        public Boolean convertSource { get; set; }
        public List<Artifact_Version__c> artifactVersionList { get; set; }

        public LoadMetadataWrapper() {
            this.projectJSON = '';
            this.mdSourcesJSON = '';
            this.scratchOrgId = '';
            this.dxRepositoryId = '';
            this.sendEmail = 'true';
            this.orgId = '';
            this.repoId = '';
            this.branchName = '';
            this.namespace = '';
            this.convertSource = false;
            this.artifactVersionList = new List<Artifact_Version__c>();
        }
    }

    /**
     *Component variable wrapper will be used to hold necessary values to render and run the actions on component
     */
    public class ComponentVariablesWrapper {
        //public Boolean showArtifacts { get; set; }
        //public Boolean showArtifactsUMP { get; set; }
        //public Boolean showBranches { get; set; }
        //public Boolean showOrgs { get; set; }
        //public Boolean showPatchOptions { get; set; }
        //public Boolean showUnlockPackages { get; set; }
        //public Boolean showSecondGenerationPackages { get; set; }
        //public Boolean showVersions { get; set; }
        //public String templateId { get; set; }
        //public String templateName { get; set; }
        //public String releaseId { get; set; }
        //public String releaseName { get; set; }
        //public String repoId { get; set; }
        //public String repoName { get; set; }
        //public String selectedArtifactId { get; set; }
        //public String selectedVersionId { get; set; }
        //public DXProject artifactProject { get; set; }
        //public MetadataSource metadataSources { get; set; }
        //public List<SelectOption> artifactsOptionList { get; set; }

        public ComponentVariablesWrapper() {
            //this.showArtifacts = false;
            //this.showArtifactsUMP = false;
            //this.showBranches = false;
            //this.showOrgs = false;
            //this.showPatchOptions = false;
            //this.showUnlockPackages = false;
            //this.showSecondGenerationPackages = false;
            //this.showVersions = false;
            //this.templateId = '';
            //this.templateName = '';
            //this.releaseId = '000000000000000';
            //this.releaseName = '';
            //this.repoId = '000000000000000';
            //this.repoName = '';
            //this.selectedArtifactId = '';
            //this.selectedVersionId = '';
            //this.artifactProject = new DXProject(new List<ProjectArtifact>(), '', 'https://login.salesforce.com', '45.0');
            //this.metadataSources = new MetadataSource();
            //this.artifactsOptionList = new List<SelectOption>();
        }
    }

    /**
     * This wrapper will be used to hold values to generate sfdx project json
     */
    public class ProjectJSONWrapper {
        public String sourceSelections { get; set; }
        public String repoId { get; set; }
        public String dxBranchName { get; set; }
        //public DXProject project { get; set; }
        public List<ArtifactVersion> selectedVersionWrapperList { get; set; }

        public ProjectJSONWrapper() {
            this.sourceSelections = '';
            this.repoId = '';
            this.dxBranchName = '';
            //this.project = new DXProject(new List<ProjectArtifact>(), '', 'https://login.salesforce.com', '45.0');
            this.selectedVersionWrapperList = new List<ArtifactVersion>();
        }
    }

    /**
     * This wrapper will be used to hold response values of sfdx project json
     */
    public class ResponseProjectJSONWrapper {
        //public DXProject project { get; set; }
        //public MetadataSource mdSourcesJson { get; set; }

        public ResponseProjectJSONWrapper() {
            //this.project = new DXProject(new List<ProjectArtifact>(), '', 'https://login.salesforce.com', '45.0');
            //this.mdSourcesJson = new MetadataSource();
        }
    }
}