/**
 * Created by ferhatozsavran on 8/30/18.
 */

public with sharing class ArtifactMetadataService implements MetadataTypeService {

    private final  String UTF_8 = 'UTF-8';
    /**
     * It is used to load metadata from artifact
     * @param jsonString it need to be send by using JsonStringWrapper.LoadMetadataWrapper
     */
    /*public void loadMetadata(String jsonValue){
        System.debug('**f**ArtifactMetadataService : ');
        DXMetadataJsonWrapper.LoadMetadataWrapper jsw = new DXMetadataJsonWrapper.LoadMetadataWrapper();

        if (String.isNotBlank(jsonValue)) {
            jsw = (DXMetadataJsonWrapper.LoadMetadataWrapper) JSON.deserialize(jsonValue, DXMetadataJsonWrapper.LoadMetadataWrapper.class);
        } else {
            throw new ArtifactMetadataServiceException(Label.Missing_value_in_call);
        }

        if(String.isBlank(jsw.scratchOrgId)) {
            throw new ArtifactMetadataServiceException(Label.Load_MD_OrgId_Required);
        }

        if(String.isBlank(jsw.mdSourcesJSON)){
            throw new ArtifactMetadataServiceException(Label.Artifact_Selection_Validation);
        }

        Map<String, String> attachmentMap = new Map<String, String>();
        if(String.isNotBlank(jsw.projectJSON)) {
            attachmentMap.put(SfdxAPIHelper.DX_PROJECT_FILE, SfdxAPIHelper.orgDefinitionDefaultKeyFixer(jsw.projectJSON));
        }
        if(String.isNotBlank(jsw.mdSourcesJSON)) {
            attachmentMap.put(SfdxAPIHelper.DX_METADATA_SOURCES, jsw.mdSourcesJSON);
        }

        String callURL = Settings.server_url + '/json/v1/dx/scratchOrg/' + EncodingUtil.urlEncode(jsw.scratchOrgId, UTF_8) + '/metadata?sendEmail=' + jsw.sendEmail;
        if(String.isNotBlank(jsw.dxRepositoryId)) {
            callURL += '&dxRepositoryId=' + EncodingUtil.urlEncode(jsw.dxRepositoryId, UTF_8);
        }

        SfdxAPIHelper.callDxJob('POST', callURL, JSON.serialize(attachmentMap), false, CopadoNotificationHelper.DX_LOAD_METADATA);
    }*/

    /**
     * It is used to define page variables based on selected metadata type
     * @return
     */
    /*public DXMetadataJsonWrapper.ComponentVariablesWrapper getSelectedMetadataType(){
        DXMetadataJsonWrapper.ComponentVariablesWrapper dxJsonArtifact = new DXMetadataJsonWrapper.ComponentVariablesWrapper();
        //dxJsonArtifact.showArtifacts = true;
        return dxJsonArtifact;
    }*/

    /**
     * It is used to generate project json by using the sourceselection
     * @param jsonValue it need to be send by using JsonStringWrapper.ProjectJSONWrapper
     * @return
     */
    /*public DXMetadataJsonWrapper.ResponseProjectJSONWrapper generateSfdxProjectJson(String jsonValue) {
        DXMetadataJsonWrapper.ProjectJSONWrapper pjw = new DXMetadataJsonWrapper.ProjectJSONWrapper();

        if (String.isNotBlank(jsonValue)) {
            pjw = (DXMetadataJsonWrapper.ProjectJSONWrapper) JSON.deserialize(jsonValue, DXMetadataJsonWrapper.ProjectJSONWrapper.class);
        } else {
            throw new ArtifactMetadataServiceException(Label.Missing_value_in_call);
        }

        if (String.isBlank(pjw.sourceSelections)) {
            throw new ArtifactMetadataServiceException(Label.Artifact_Selection_Validation);
        }

        DXMetadataJsonWrapper.ResponseProjectJSONWrapper rsw = new DXMetadataJsonWrapper.ResponseProjectJSONWrapper();
        rsw.project = pjw.project;
        rsw.mdSourcesJson = new MetadataSource(pjw.sourceSelections.replace('[', '').replace(']', '').replaceAll('\\s+', ''), 'artifact','');
        List<ProjectArtifact> artifactDirectories = new List<ProjectArtifact>();
        for (String art : pjw.sourceSelections.replace('[', '').replace(']', '').split(',')) {
            if(!art.isWhitespace()) {
                rsw.mdSourcesJson.addArtifactId(art.replaceAll('\\s+', ''));
            }
        }
        artifactDirectories.add(new ProjectArtifact(SfdxAPIHelper.DX_DEFAULT_PATH, true));

        SecureOperations so = new SecureOperations();
        if(so.isAuthorizedToQuery(Artifact__c.getSObjectType().getDescribe().getName())){
            for (Artifact__c artifacts : [SELECT Name FROM Artifact__c WHERE Id IN :rsw.mdSourcesJson.getArtifactIds()]) {
                artifactDirectories.add(new ProjectArtifact(artifacts.Name, false));
            }
        } else {
            throw new ArtifactMetadataServiceException(Schema.SObjectType.Artifact__c.label + ': ' + Label.Insufficient_Access_Rights);
        }
        for(ProjectArtifact thisArtifact : artifactDirectories) {
            thisArtifact.checkIfDependenciesAreEmptyAndClearArray();
        }
        rsw.project.packageDirectories = artifactDirectories;
        rsw.project.checkIfAliasesAreEmptyAndClearMap();
        return rsw;
    }*/

    public class ArtifactMetadataServiceException extends Exception {}
}