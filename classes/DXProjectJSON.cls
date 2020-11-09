public with sharing class DXProjectJSON {
    public String sourceSelections { get; set; }
    public String repositoryId { get; set; }
    public String dxBranchName { get; set; }
    //public DXProject project { get; set; }
    public List<ArtifactVersion> artifactVersions { get; set; }

    public DXProjectJSON() {
        this.sourceSelections = '';
        this.repositoryId = '';
        this.dxBranchName = '';
        //this.project = new DXProject(new List<ProjectArtifact>(), '', 'https://login.salesforce.com', '45.0');
        this.artifactVersions = new List<ArtifactVersion>();
    }
}