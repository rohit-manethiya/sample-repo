/**
 * Created by ferhatozsavran on 9/4/18.
 */

public with sharing class UnlockPackageService implements MetadataTypeService {
    private final String USER_SELECTED = 'User Selected';
    public static Boolean skipInstallPackageValidation { get; set; }

    static {
        skipInstallPackageValidation = false;
    }

    /**
     * It is used to load metadata from unmanaged packages
     * @param jsonString it need to be send by using JsonStringWrapper.LoadMetadataWrapper
     */
    /*public void loadMetadata(String jsonValue){
        System.debug('**f**UnlockPackageService : ');
        DXMetadataJsonWrapper.LoadMetadataWrapper jsw = new DXMetadataJsonWrapper.LoadMetadataWrapper();

        if (String.isNotBlank(jsonValue)) {
            jsw = (DXMetadataJsonWrapper.LoadMetadataWrapper) JSON.deserialize(jsonValue, DXMetadataJsonWrapper.LoadMetadataWrapper.class);
        } else {
            throw new UnlockPackageServiceException(Label.Missing_value_in_call);
        }

        if(String.isEmpty(jsw.scratchOrgId)) {
            throw new UnlockPackageServiceException(Label.Load_MD_OrgId_Required);
        }

        if(jsw.artifactVersionList.isEmpty()) {
            System.debug('*** LoadMetadata Unlocked packages service');
            throw new UnlockPackageServiceException(Label.Select_package_to_install);
        }

        Map<String, String> attachmentMap = new Map<String, String>();
        if(String.isNotBlank(jsw.projectJSON)) {
            attachmentMap.put(SfdxAPIHelper.DX_PROJECT_FILE, SfdxAPIHelper.orgDefinitionDefaultKeyFixer(jsw.projectJSON));
        }
        if(String.isNotBlank(jsw.mdSourcesJSON)) {
            attachmentMap.put(SfdxAPIHelper.DX_METADATA_SOURCES, jsw.mdSourcesJSON);
        }

        SecureOperations so = new SecureOperations();
        String devhubOrgId = '';
        if(so.isAuthorizedToQuery(Org__c.getSObjectType().getDescribe().getName())) {
            devhubOrgId = [SELECT Id, Developer_Hub_Org__c FROM Org__c WHERE Id = :jsw.scratchOrgId LIMIT 1].Developer_Hub_Org__c;
        } else {
            throw new UnlockPackageServiceException(Schema.SObjectType.Org__c.label + ': ' + Label.Insufficient_Access_Rights);
        }

        if(String.isBlank(devhubOrgId)){
            throw new UnlockPackageServiceException(Label.Developer_Hub_not_null);
        }

        Map<String, Sensitive_Information__c> sensitiveInfoMap = Sensitive_Information__c.getAll();
        List<PackageDetail> packageDetailList = new List<PackageDetail>();
        for(Artifact_Version__c av : jsw.artifactVersionList){
            PackageDetail packageDetail = new PackageDetail(av.Artifact__r.Package_Id__c, av.Subscriber_Version_Id__c, av.Name, av.Version_number__c);
            Sensitive_Information__c thisInformation = sensitiveInfoMap.get(av.Id);
            if(thisInformation != null) {
                try {
                    packageDetail.setInstallationKey(DeployAPI.decryptAPIKey(thisInformation.Password__c));
                } catch(Exception ex) {
                    throw new UnlockPackageServiceException(ex.getMessage());
                }
            }
            packageDetailList.add(packageDetail);
        }

        String jsonStr = '{"packages":' + JSON.serialize(packageDetailList) + '}';
        if(String.isNotBlank(jsonStr)) {
            attachmentMap.put(SfdxAPIHelper.DX_PACKAGE_DETAILS, jsonStr);
        }

        String callUrl = Settings.server_url + '/json/v1/package/install?targetOrgId=' + EncodingUtil.urlEncode(jsw.scratchOrgId, 'UTF-8') + '&devHubOrgId=' + EncodingUtil.urlEncode(devhubOrgId, 'UTF-8');
        if(String.isNotBlank(jsw.dxRepositoryId)) {
            callURL += '&dxRepositoryId=' + EncodingUtil.urlEncode(jsw.dxRepositoryId, 'UTF-8');
        }
        SfdxAPIHelper.callDxJob('POST', callUrl, JSON.serialize(attachmentMap), true, CopadoNotificationHelper.DX_INSTALLED_PACKAGES);
    }*/

    /**
     * It is used to define page variables based on selected metadata type
     */
    /*public DXMetadataJsonWrapper.ComponentVariablesWrapper getSelectedMetadataType(){
        DXMetadataJsonWrapper.ComponentVariablesWrapper dxJsonArtifact = new DXMetadataJsonWrapper.ComponentVariablesWrapper();
        //dxJsonArtifact.showUnlockPackages = true;
        return dxJsonArtifact;
    }*/

    /**
     * It is used to generate project json by using the sourceselection
     * @param jsonValue
     * @return
     */
    /*public DXMetadataJsonWrapper.ResponseProjectJSONWrapper generateSfdxProjectJson(String jsonValue) {
        DXMetadataJsonWrapper.ProjectJSONWrapper pjw = new DXMetadataJsonWrapper.ProjectJSONWrapper();

        if(String.isNotBlank(jsonValue)) {
            pjw = (DXMetadataJsonWrapper.ProjectJSONWrapper) JSON.deserialize(jsonValue, DXMetadataJsonWrapper.ProjectJSONWrapper.class);
        } else {
            throw new UnlockPackageServiceException(Label.Missing_value_in_call);
        }

        if(!skipInstallPackageValidation && pjw.selectedVersionWrapperList.isEmpty()) {
            throw new UnlockPackageServiceException(Label.Select_package_to_install);
        }

        DXMetadataJsonWrapper.ResponseProjectJSONWrapper rsw = new DXMetadataJsonWrapper.ResponseProjectJSONWrapper();
        //rsw.project = pjw.project;

        List<ProjectArtifact> artifactDirectoriesList = new List<ProjectArtifact>();
        artifactDirectoriesList.add(new ProjectArtifact(SfdxAPIHelper.DX_DEFAULT_PATH, true));

        if(pjw.selectedVersionWrapperList != null && !pjw.selectedVersionWrapperList.isEmpty()) {
            Map<String, ProjectArtifact> artifactDirectoriesMap = new Map<String, ProjectArtifact>();
            Map<String, String> packageAliasesMap = new Map<String, String>();
            for(ArtifactVersion avw : pjw.selectedVersionWrapperList) {
                // adding all selected artifacts to the package alias
                packageAliasesMap.put(avw.getVersion().Artifact__r.Name, avw.getVersion().Artifact__c);
                // creating package directory for each selected package
                ProjectArtifact mainPackageDirectory = new ProjectArtifact(avw.getVersion().Artifact__r.Name, avw.getVersion().Artifact__c, true);
                mainPackageDirectory.defaultArtifact = avw.getIncludedBy() != USER_SELECTED ? false : true;
                mainPackageDirectory.versionDescription = avw.getVersion().Version_Description__c;
                mainPackageDirectory.versionNumber = avw.getVersion().Version_number__c;
                mainPackageDirectory.versionName = avw.getVersion().Name;
                mainPackageDirectory.definitionFile = 'config/' + SfdxAPIHelper.DX_DEFINITION_FILE;
                artifactDirectoriesMap.put(avw.getVersion().Name, mainPackageDirectory);
                if(avw.getIncludedBy() != USER_SELECTED) {
                    ProjectArtifact existingPackageDirectory = artifactDirectoriesMap.get(avw.getIncludedBy());
                    PackageDependency pd = new PackageDependency(avw.getVersion().Name, avw.getVersion().Version_number__c);
                    existingPackageDirectory.dependencies.add(pd);
                    artifactDirectoriesMap.put(avw.getIncludedBy(), existingPackageDirectory);
                }
                // adding all artifact to the metadata json
                //rsw.mdSourcesJson.addArtifactId(avw.thisVersion.Artifact__c);
            }
            //rsw.project.packageAliases.putAll(packageAliasesMap);
            artifactDirectoriesList.addAll(artifactDirectoriesMap.values());
        }
        //rsw.mdSourcesJson = new MetadataSource(String.join(rsw.mdSourcesJson.getArtifactIds(),','), 'unlocked','');
        for(ProjectArtifact thisArtifact : artifactDirectoriesList) {
            thisArtifact.checkIfDependenciesAreEmptyAndClearArray();
        }
        //rsw.project.packageDirectories = artifactDirectoriesList;
        //rsw.project.checkIfAliasesAreEmptyAndClearMap();
        return rsw;
    }*/

    public class UnlockPackageServiceException extends Exception {}
}