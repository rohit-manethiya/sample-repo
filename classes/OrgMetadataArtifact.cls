public with sharing class OrgMetadataArtifact {
    public void loadMetadata(String projectJson, String metadataSourcesJson, String dxRepositoryId, String scratchOrgId, String orgId, String convertIgnore, String pushIgnore) {
        if(String.isEmpty(scratchOrgId)) {
            //throw new ArtifactException(Label.Load_MD_OrgId_Required);
        }
        Map<String, String> attachmentMap = new Map<String, String>();
        if(String.isNotBlank(projectJson)) {
            attachmentMap.put(DXLabel.PROJECT_FILE, SfdxAPIHelper.orgDefinitionDefaultKeyFixer(projectJson));
        }
        if(String.isNotBlank(metadataSourcesJson)) {
            attachmentMap.put(DXLabel.METADATA_SOURCES, metadataSourcesJson);
        }
        if(String.isNotBlank(convertIgnore)) {
            attachmentMap.put(DXLabel.CONVERT_IGNORE, convertIgnore);
        }
        if(String.isNotBlank(pushIgnore)) {
            attachmentMap.put(DXLabel.PUSH_IGNORE, pushIgnore);
        }

        sendLoadMetadataCallout(scratchOrgId, dxRepositoryId, orgId, JSON.serialize(attachmentMap));
    }

    private void sendLoadMetadataCallout(String scratchOrgId, String dxRepositoryId, String orgId, String attachmentJson) {
        String callUrl = Settings.server_url + '/json/v1/dx/scratchOrg/' + EncodingUtil.urlEncode(scratchOrgId, 'UTF-8') + '/metadata?orgId=' + EncodingUtil.urlEncode(orgId, 'UTF-8');
        if(String.isNotBlank(dxRepositoryId)) {
            callURL += '&dxRepositoryId=' + EncodingUtil.urlEncode(dxRepositoryId, 'UTF-8');
        }
        SfdxAPIHelper.callDxJob('POST', callUrl, attachmentJson, false, DXLabel.LOAD_METADATA);
    }

    // TODO: ADJUST THIS METHOD TO NEW DESIGN
    public String generateProjectJson(DXProject project, String sourceSelections, String dxBranchName) {
        if(String.isBlank(sourceSelections)) {
            if(String.isNotBlank(dxBranchName)) {
                sourceSelections = dxBranchName;
            } else {
                //throw new ArtifactException(Label.Select_Org_Credential_To_Load);
            }
        }

        List<ProjectArtifact> artifactDirectories = new List<ProjectArtifact>();
        artifactDirectories.add(new ProjectArtifact(sourceSelections ,true));
        for(ProjectArtifact thisArtifact : artifactDirectories) {
            thisArtifact.checkIfDependenciesAreEmptyAndClearArray();
        } 
        //project.packageDirectories = artifactDirectories;
        project.clearAliasesIfEmpty();
        //return getFormattedProjectJson(project);
        return null;
    }

    public String generateMetadataSourcesJson(String sourceSelections, String repositoryId) {
        if(String.isBlank(sourceSelections)) {
            //throw new ArtifactException(Label.Select_Org_Credential_To_Load);
        }

        List<String> artifactIds = new List<String>(sourceSelections.split(','));
        return getFormattedMetadataSourcesJson(artifactIds, repositoryId);
    }

    public String getFormattedMetadataSourcesJson(List<String> artifactIds, String repositoryId) {
        String artifactIdString = String.join(artifactIds,',');
        MetadataSource metadataSource = new MetadataSource(artifactIdString, 'org',repositoryId);
        return JSON.serializePretty(metadataSource, true);
    }

    public String getFormattedMetadataSourcesJson(List<String> artifactIds) {
        String artifactIdString = String.join(artifactIds,',');
        MetadataSource metadataSource = new MetadataSource(artifactIdString, 'org',null); // TODO: ADD REPO ID
        return JSON.serializePretty(metadataSource, true);
    }
}