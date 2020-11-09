/**
 * Created by mertyalti on 31/08/2018.
 */

public with sharing class DXPackageAsyncJobHandler {
    public DXPackageAsyncJobHandler(ApexPages.StandardController controller) {
    }
    public DXPackageAsyncJobHandler() {
    }
    public PageReference jobStatusNotification() {
        Map<String, String> pageParameters = ApexPages.currentPage().getParameters();
        Boolean jobFinished = pageParameters.get('jobFinished') == 'true';

        if(jobFinished) {
            Boolean jobSuccess = pageParameters.get('jobSuccess') == 'true';
            if(jobSuccess) {
                String jobType = pageParameters.get('jobType');
                if(String.isNotBlank(jobType)) {
                    if(jobType == DXLabel.CREATE_PACKAGE) {
                        addPageMessage(ApexPages.Severity.CONFIRM, 'DX Package created succesfully');
                    } else if(jobType == DXLabel.CREATE_PACKAGE_VERSION) {
                        addPageMessage(ApexPages.Severity.CONFIRM, 'DX Package version created succesfully');
                    } else if(jobType == DXLabel.PROMOTE_BETA_RELEASED) {
                        addPageMessage(ApexPages.Severity.CONFIRM, 'DX Package version promoted to released succesfully');
                    } else if(jobType == DXLabel.PACKAGE_UPDATE) {
                        addPageMessage(ApexPages.Severity.CONFIRM, 'DX Package updated succesfully');
                    } else if(jobType == DXLabel.PACKAGE_VERSION_UPDATE) {
                        addPageMessage(ApexPages.Severity.CONFIRM, 'DX Package version updated succesfully');
                    }
                }
            } else {
                String jobMessage = pageParameters.get('jobMessage');
                if(String.isNotBlank(jobMessage)) {
                    addPageMessage(ApexPages.Severity.ERROR, jobMessage);
                }
            }
        }

        String jobParentId = pageParameters.get('jobParentId');
        if(String.isNotBlank(jobParentId)) {
            PageReference thisPage = new PageReference('/' + jobParentId);
            thisPage.setRedirect(true);
            return thisPage;
        }
        return null;
    }

    private void addPageMessage(ApexPages.Severity severity, String message) {
        ApexPages.addMessage(new ApexPages.Message(severity, message));
    }
}