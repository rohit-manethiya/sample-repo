/**
 * @description this class provides all the available operations for installing an unlocked artifact in a Scratch Org.
 * @see AbstractPackage
 */
public with sharing class UnlockedArtifact extends AbstractPackage {
    private Boolean skipPackageVersionValidation = false;

    /**
     * @description this method sets a flag to bypass the package version validation when an unlocked artifact is
     * installed in a Scratch Org.
     *
     * @param skipValidation is the flag that indicates whether a package version validation should be skipped or not
     * while installing the unlocked package.
     */
    public void setSkipPackageVersionValidation(Boolean skipValidation) {
        this.skipPackageVersionValidation = skipValidation;
    }

    /**
     * @description a setter for the artifactSource private variable.
     *
     * @param sourceSelections is a string containing comma-separated ids of artifacts or the name of a DX branch
     * from where the source is to be pulled for installation.
     */
    public override void setMetadataSource(String sourceSelections) {
        List<Id> artifactIds = sourceSelections.split(',');
        artifactSource = new MetadataSource(sourceSelections, DXLabel.UNLOCKPACKAGE, null);
        artifactSource.setArtifactIds(artifactIds);
    }

    /**
     * @description a getter for the artifactSource private variable.
     *
     * @return a MetadataSource object with the source artifact and/or git repository information from where all sources
     * will be installed into a Scratch Org.
     */
    public override MetadataSource getMetadataSource() {
        return artifactSource;
    }

    /**
     * TODO: REFACTOR THIS METHOD
     */
    private void throwArtifactException() {
        if(!skipPackageVersionValidation) {
            throw new PackageException(Label.Select_package_to_install);
        }
    }
}