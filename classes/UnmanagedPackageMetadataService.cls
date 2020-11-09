/**
 * Created by ferhatozsavran on 8/30/18.
 */

public with sharing class UnmanagedPackageMetadataService implements MetadataTypeService {

    /**
     * It is used to load metadata from unmanaged packages
     * ArtifactMetadataService.loadMetadata method is used. Because both are using same methods.
     * @param jsonString it need to be send by using JsonStringWrapper.LoadMetadataWrapper
     */
    public void loadMetadata(String jsonValue){
        /*System.debug('**f**UnmanagedPackageMetadataService : ');
        ArtifactMetadataService ams = new ArtifactMetadataService();
        ams.loadMetadata(jsonValue);*/
    }

    /**
     * It is used to define page variables based on selected metadata type
     * @return
     */
    public DXMetadataJsonWrapper.ComponentVariablesWrapper getSelectedMetadataType(){
        /*DXMetadataJsonWrapper.ComponentVariablesWrapper dxJsonArtifact = new DXMetadataJsonWrapper.ComponentVariablesWrapper();
        dxJsonArtifact.showArtifactsUMP = true;
        return dxJsonArtifact;*/
        return null;
    }

    /**
     * It is used to generate project json by using the sourceselection
     * @param jsonValue
     * @return
     */
    public DXMetadataJsonWrapper.ResponseProjectJSONWrapper generateSfdxProjectJson(String jsonValue) {
        /*DXMetadataJsonWrapper.ProjectJSONWrapper pjw = new DXMetadataJsonWrapper.ProjectJSONWrapper();

        if (String.isNotBlank(jsonValue)) {
            pjw = (DXMetadataJsonWrapper.ProjectJSONWrapper) JSON.deserialize(jsonValue, DXMetadataJsonWrapper.ProjectJSONWrapper.class);
        } else {
            throw new UnmanagedPackageServiceException('There is missing value in the call. Please check your data and try again!');
        }

        if (String.isBlank(pjw.sourceSelections)) {
            throw new UnmanagedPackageServiceException(Label.Select_Package_To_Load);
        }

        DXMetadataJsonWrapper.ResponseProjectJSONWrapper rsw = new DXMetadataJsonWrapper.ResponseProjectJSONWrapper();
        rsw.project = pjw.project;
        //rsw.mdSourcesJson = new SfdxAPIHelper.metadataSources(pjw.sourceSelections.replace('[', '').replace(']', '').replaceAll('\\s+', ''), 'artifactUMP','');
        List<ProjectArtifact> artifactDirectories = new List<ProjectArtifact>();
        for (String art : pjw.sourceSelections.replace('[', '').replace(']', '').split(',')) {
            if(!art.isWhitespace()) {
                //rsw.mdSourcesJson.selectedArtifactIDs.add(art.replaceAll('\\s+', ''));
            }
        }
        artifactDirectories.add(new ProjectArtifact(SfdxAPIHelper.DX_DEFAULT_PATH, true));

        SecureOperations so = new SecureOperations();
        if(so.isAuthorizedToQuery(Artifact__c.getSObjectType().getDescribe().getName())){
            for (Artifact__c artifacts : [SELECT Name FROM Artifact__c WHERE Id IN :rsw.mdSourcesJson.selectedArtifactIDs]) {
                artifactDirectories.add(new ProjectArtifact(artifacts.Name, false));
            }
        } else {
            throw new UnmanagedPackageServiceException(Schema.SObjectType.Artifact__c.label + ': ' + Label.Insufficient_Access_Rights);
        }
        for(ProjectArtifact thisArtifact : artifactDirectories) {
            thisArtifact.checkIfDependenciesAreEmptyAndClearArray();
        }
        rsw.project.packageDirectories = artifactDirectories;
        rsw.project.checkIfAliasesAreEmptyAndClearMap();
        return rsw;*/
        return null;
    }

    public class UnmanagedPackageServiceException extends Exception {}
}