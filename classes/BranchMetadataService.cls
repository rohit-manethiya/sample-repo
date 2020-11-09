/**
 * Created by ferhatozsavran on 8/30/18.
 */

public with sharing class BranchMetadataService implements MetadataTypeService {

    /**
     * It is used to load metadata from branch
     * @param jsonString it need to be send by using JsonStringWrapper.LoadMetadataWrapper
     */
    /*public void loadMetadata(String jsonValue){
        System.debug('**f**BranchMetadataService : ');
        DXMetadataJsonWrapper.LoadMetadataWrapper jsw = new DXMetadataJsonWrapper.LoadMetadataWrapper();

        if (String.isNotBlank(jsonValue)) {
            jsw = (DXMetadataJsonWrapper.LoadMetadataWrapper) JSON.deserialize(jsonValue, DXMetadataJsonWrapper.LoadMetadataWrapper.class);
        } else {
            throw new BranchServiceException('There is missing value in the call. Please check your data and try again!');
        }

        if(String.isEmpty(jsw.scratchOrgId)) {
            throw new BranchServiceException(Label.Load_MD_OrgId_Required);
        }

        Map<String, String> attachmentMap = new Map<String, String>();
        if(String.isNotBlank(jsw.projectJSON)) {
            attachmentMap.put(SfdxAPIHelper.DX_PROJECT_FILE, SfdxAPIHelper.orgDefinitionDefaultKeyFixer(jsw.projectJSON));
        }
        if(String.isNotBlank(jsw.mdSourcesJSON)) {
            attachmentMap.put(SfdxAPIHelper.DX_METADATA_SOURCES, jsw.mdSourcesJSON);
        }

        String callURL = Settings.server_url + '/json/v1/dx/scratchOrg/' + jsw.scratchOrgId + '/metadata?repositoryId=' + jsw.repoId + '&sendEmail=' + jsw.sendEmail + '&convertSource=' + jsw.convertSource;

        if(String.isNotBlank(jsw.dxRepositoryId)) {
            callURL += '&dxRepositoryId=' + jsw.dxRepositoryId;
            callURL += '&branch=' + EncodingUtil.urlEncode(jsw.branchName, 'UTF-8');
        }

        SfdxAPIHelper.callDxJob('POST', callURL, JSON.serialize(attachmentMap), false, CopadoNotificationHelper.DX_LOAD_METADATA);
    }*/

    /**
     * It is used to define page variables based on selected metadata type
     */
    /*public DXMetadataJsonWrapper.ComponentVariablesWrapper getSelectedMetadataType(){
        DXMetadataJsonWrapper.ComponentVariablesWrapper dxJsonArtifact = new DXMetadataJsonWrapper.ComponentVariablesWrapper();
        //dxJsonArtifact.showBranches = true;
        return dxJsonArtifact;
    }*/

    /**
     * It is used to generate project json by using the sourceselection
     * @param jsonValue
     * @return
     */
    /*public DXMetadataJsonWrapper.ResponseProjectJSONWrapper generateSfdxProjectJson(String jsonValue) {
        DXMetadataJsonWrapper.ProjectJSONWrapper pjw = new DXMetadataJsonWrapper.ProjectJSONWrapper();

        if (String.isNotBlank(jsonValue)) {
            pjw = (DXMetadataJsonWrapper.ProjectJSONWrapper) JSON.deserialize(jsonValue, DXMetadataJsonWrapper.ProjectJSONWrapper.class);
        } else {
            throw new BranchServiceException('There is missing value in the call. Please check your data and try again!');
        }

        if(String.isNotBlank(pjw.dxBranchName) && String.isBlank(pjw.sourceSelections)){
            pjw.sourceSelections = pjw.dxBranchName;
        } else if(String.isBlank(pjw.sourceSelections)) {
            throw new BranchServiceException(Label.Select_a_Branch);
        }

        List<ProjectArtifact> packDirectories = new List<ProjectArtifact>();
        if(pjw.sourceSelections != null) {
            ProjectArtifact directory = new ProjectArtifact(pjw.sourceSelections ,true);
            packDirectories.add(directory);
        }
        for(ProjectArtifact thisArtifact : packDirectories) {
            thisArtifact.checkIfDependenciesAreEmptyAndClearArray();
        }
        DXMetadataJsonWrapper.ResponseProjectJSONWrapper rsw = new DXMetadataJsonWrapper.ResponseProjectJSONWrapper();
        rsw.project = pjw.project;
        rsw.project.packageDirectories = packDirectories;
        rsw.project.checkIfAliasesAreEmptyAndClearMap();
        rsw.mdSourcesJson = new MetadataSource(pjw.sourceSelections, 'branch', pjw.repoId);
        return rsw;
    }*/

    public class BranchServiceException extends Exception {}
}