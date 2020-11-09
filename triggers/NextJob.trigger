trigger NextJob on Deployment_Job__c(before update, after update) {
    List<Id> depJobIds = new List<Id>();

    final String ON_PROMISE_ID = 'copado-deployer-service-async-id';
    final String PENDING = 'Pending';
    final String IN_PROGRESS = 'In Progress';
    Map<Id, String> deploymentId_depJobAsyncJobIdMap = new Map<Id, String>();
    Map<Id, Deployment_Job__c> deploymentJobsWithParentFieldsById = new Map<Id, Deployment_Job__c>(

        [
            SELECT
                Id,
                Step__c,
                Destination_Org__c,
                Validation_ID__c,
                Async_Job_ID__c,
                Status__c,
                Step__r.Type__c,
                Step__r.Status__c,
                Step__r.Order__c,
                Step__r.dataJson__c,
                Step__r.Deployment__c,
                Step__r.Deployment__r.Name,
                Step__r.Deployment__r.Status__c,


                Step__r.Deployment__r.Promotion__c,
                Step__r.Deployment__r.From_Org__r.Environment__r.Org_ID__c,
                Step__r.Name,
                Destination_Org__r.To_Org__r.Environment__r.Org_ID__c


            FROM Deployment_Job__c
            WHERE Id IN :Trigger.newmap.keySet()
        ]
    );

    if (Trigger.isAfter) {
        List<Id> lDestinations = new List<Id>();

        Integer triggerNewSize = deploymentJobsWithParentFieldsById.size();
        for (Integer i = 0; i < triggerNewSize; i++) {
            Deployment_Job__c depJobItem = deploymentJobsWithParentFieldsById.get(Trigger.new[i].Id);

            lDestinations.add(depJobItem.Destination_Org__c);
            if (
                depJobItem.Validation_ID__c != ON_PROMISE_ID &&
                depJobItem.Step__r.Order__c == 1 &&
                depJobItem.Step__r.Name == 'CCD Validation' &&
                String.isNotBlank(Trigger.new[i].Validation_ID__c) &&
                Trigger.old[i].Validation_ID__c != Trigger.new[i].Validation_ID__c
            ) {
                deploymentId_depJobAsyncJobIdMap.put(depJobItem.Step__r.Deployment__c, depJobItem.Validation_ID__c);
            }
        }

        List<Deployment_Job__c> depJobList2Update = [
            SELECT Id, Async_Job_ID__c, Step__c, Step__r.Order__c, Step__r.Type__c, Step__r.Deployment__c
            FROM Deployment_Job__c
            WHERE
                Step__r.Deployment__c IN :deploymentId_depJobAsyncJobIdMap.keySet()
                AND Step__r.Type__c != 'URL Callout'
                AND Step__r.CheckOnly__c = false
        ];

        for (Deployment_Job__c djItem : depJobList2Update) {
            djItem.Async_Job_ID__c = deploymentId_depJobAsyncJobIdMap.get(djItem.Step__r.Deployment__c);
            djItem.Validation_ID__c = deploymentId_depJobAsyncJobIdMap.get(djItem.Step__r.Deployment__c);
        }
        //Above is populated to be able to perform quick deploy feature for CCD feature

        List<Deployment_Job__c> nexts = [
            SELECT
                Id,
                Step__c,
                Name,
                Status__c,
                Destination_Org__c,
                Step__r.dataJson__c,
                Step__r.Deployment__c,
                Step__r.Deployment__r.Name,
                Step__r.Order__c,
                Step__r.Type__c,
                Step__r.Name
            FROM Deployment_Job__c
            WHERE Destination_Org__c IN :lDestinations
        ];
        List<Deployment_Job__c> updatedJobs = new List<Deployment_Job__c>();

        Map<String, Deployment_Job__c> Mnexts = new Map<String, Deployment_Job__c>();

        for (Deployment_Job__c dj : nexts) {
            if(!Mnexts.containsKey('' + dj.Destination_Org__c + dj.Status__c + String.valueOf(dj.Step__r.Order__c))) {
            Mnexts.put('' + dj.Destination_Org__c + dj.Status__c + String.valueOf(dj.Step__r.Order__c), dj);
        }
        }
        List<Deployment__c> updateDeployments = new List<Deployment__c>();
        Map<Id, List<Deployment_Job__c>> djToDeployment = new Map<Id, List<Deployment_Job__c>>();

        for (Deployment_Job__c dj : Trigger.new) {

            Deployment_Job__c currentJob = deploymentJobsWithParentFieldsById.get(dj.Id);

            if (
                dj.Status__c == 'Success' &&
                Trigger.oldMap.get(dj.Id).Status__c != 'Success' ||
                dj.Status__c == 'Failed' &&
                Trigger.oldMap.get(dj.Id).Status__c != 'Failed' ||
                dj.Status__c == 'Cancelled' &&
                Trigger.oldMap.get(dj.Id).Status__c != 'Cancelled'
            ) {
                Deployment_Job__c next = null;
                //we DON'T try to deploy all the steps even if some fails
                if (dj.Status__c == 'Success' && Trigger.oldMap.get(dj.Id).Status__c != 'Success') {
                    Integer nextOrder = Integer.valueOf(currentJob.Step__r.Order__c) + 1;

                    // First, we try to fire next step if there is another with the same order value than the current one
                    // otherwise we look for the next step with the next order value
                    if (Mnexts.containsKey('' + dj.Destination_Org__c + PENDING + currentJob.Step__r.Order__c)) {
                        next = Mnexts.get('' + dj.Destination_Org__c + PENDING + currentJob.Step__r.Order__c);
                        //Prevent Manual Tasks and Salesforce Flow from calling the backend
                        if (next.Step__r.Type__c != 'Manual Task' && next.Step__r.Type__c != 'Salesforce Flow') {
                            depJobIds.add(next.Id);
                        } else {
                            next.Status__c = IN_PROGRESS;
                            updatedJobs.add(next);
                        }
                    } else if (Mnexts.containsKey('' + dj.Destination_Org__c + PENDING + String.valueOf(nextOrder))) {
                        next = Mnexts.get('' + dj.Destination_Org__c + PENDING + String.valueOf(nextOrder));

                        //Prevent Manual Tasks and Salesforce Flow from calling the backend
                        if (next.Step__r.Type__c != 'Manual Task' && next.Step__r.Type__c != 'Salesforce Flow') {
                            depJobIds.add(next.Id);
                        } else {
                            next.Status__c = IN_PROGRESS;
                            updatedJobs.add(next);
                        }
                    }
                }
                Id deploymentId = currentJob.Step__r.Deployment__c;
                if (djToDeployment.containsKey(deploymentId)) {
                    List<Deployment_Job__c> temp = djToDeployment.get(deploymentId);
                    temp.add(dj);
                    djToDeployment.put(deploymentId, temp);
                } else {
                    List<Deployment_Job__c> temp = new List<Deployment_Job__c>();
                    temp.add(dj);
                    djToDeployment.put(deploymentId, temp);
                }
            }
            //Bulkified

            if (dj.Status__c == IN_PROGRESS && currentJob.Step__r.Deployment__r.Status__c != IN_PROGRESS) {
                Boolean isPaused = false;
                if (
                    currentJob.Step__r.Order__c == 1 &&
                    currentJob.Step__r.Type__c == 'Manual Task' &&
                    !currentJob.Step__r.Status__c.containsIgnoreCase('Completed')
                ) {
                    isPaused = true;
                }
                updateDeployments.add(new Deployment__c(Id = currentJob.Step__r.Deployment__c, Status__c = IN_PROGRESS, Paused__c = isPaused));
            }
        }

        Utilities.Secure_DML(updatedJobs, Utilities.DML_Action.UPD, Schema.Sobjecttype.Step__c);
        if (!depJobList2Update.isEmpty()) {
            Utilities.Secure_DML(depJobList2Update, Utilities.DML_Action.UPD, Schema.Sobjecttype.Deployment_Job__c);
        }

        //Bulkified
        //DEFINE THE STATUS OF STEPS, DESTINATION ORGS AND DEPLOYMENT
        Map<Id, String> statuses = DeployJobHelper.updateStatus(djToDeployment);
        for (Id dId : statuses.keySet()) {
            if (statuses.get(dId).startsWith('Completed') && !Test.isRunningTest()) {
                DeployAPI.cleanDeploy(dId);
            }
        }

        if (depJobIds.size() > 0) {
            DeployAPI.deployJob(depJobIds, UserInfo.getSessionId());
        }
        if (!updateDeployments.isEmpty()) {
            Utilities.Secure_DML(updateDeployments, Utilities.DML_Action.UPD, Schema.Sobjecttype.Deployment__c);
        }
    } else {
        final List<Attachment> flowAttachmentResults = new List<Attachment>();
        final Map<Id, Attachment> existentRelatedAttachmentResultsByParentId = new Map<Id, Attachment>();
        final Set<String> attachmentNames = new Set<String>();

        for (Id deploymentJobId : deploymentJobsWithParentFieldsById.keySet()) {

            attachmentNames.add(deploymentJobId + '.json');
        }
        for (Attachment attachmentResult : [
            SELECT Id, Body, Name, ParentId
            FROM Attachment

            WHERE Name IN :attachmentNames AND ParentId IN :deploymentJobsWithParentFieldsById.keySet()

        ]) {
            // If a parent has more than 1 attachment (this should not happen) they will be overriden by the last one, since we only need 1
            existentRelatedAttachmentResultsByParentId.put(attachmentResult.ParentId, attachmentResult);
        }

        for (Deployment_Job__c deploymentJob : Trigger.new) {

            final Deployment_Job__c deploymentJobWithParentFields = deploymentJobsWithParentFieldsById.get(deploymentJob.Id);

            if (
                deploymentJob.Status__c == 'In progress' &&
                deploymentJob.Status__c != Trigger.oldMap.get(deploymentJob.Id).Status__c &&
                deploymentJobWithParentFields.Step__r.Type__c == 'Salesforce Flow'
            ) {
                final Boolean isFlowExecutionSuccessful;


                final Map<String, Object> selectedFlowWithParameters;
                final String result;
                try {
                    selectedFlowWithParameters = (Map<String, Object>) JSON.deserializeUntyped(deploymentJobWithParentFields.Step__r.dataJson__c);
                    final Map<String, Object> flowParameters = new Map<String, Object>();
                    for (Object attributes : (List<Object>) selectedFlowWithParameters.get('flowParameters')) {
                        final List<Object> parsedAttributes = (List<Object>) attributes;
                        flowParameters.put((String) parsedAttributes[0], parsedAttributes[1]);
                    }
                    selectedFlowWithParameters.put(
                        'flowParameters',
                        DynamicVariablesInterpreter.getDynamicVariablesInterpreted(deploymentJobWithParentFields, flowParameters)
                    );
                    result = SalesforceFlowStepController.executeSelectedFlow(selectedFlowWithParameters);


                    isFlowExecutionSuccessful = result == Label.FLOW_EXECUTED_SUCCESSFULLY;
                } catch (final Exception e) {
                    result = String.format(Label.ERROR_PARSING_FLOW_INFORMATION, new List<Object>{ e.getMessage() });
                    isFlowExecutionSuccessful = false;

                }

                if (!isFlowExecutionSuccessful || (String) selectedFlowWithParameters.get('type') == 'continue') {
                    deploymentJob.Status__c = isFlowExecutionSuccessful ? 'Success' : 'Failed';
                    final Attachment attachmentResult;
                    if (existentRelatedAttachmentResultsByParentId.containsKey(deploymentJob.Id)) {
                        attachmentResult = existentRelatedAttachmentResultsByParentId.get(deploymentJob.Id);
                    } else {
                        attachmentResult = new Attachment();
                        attachmentResult.Name = deploymentJob.Id + '.json';
                        attachmentResult.ParentId = deploymentJob.Id;
                    }

                    attachmentResult.Body = Blob.valueOf(
                        '[{"m":"NEW STATUS: ' +
                        deploymentJob.Status__c +
                        ' on \\"' +
                        String.valueOf(System.now()) +
                        '\\"","l":"INFO","t":""},{"m": "Comment: ' +
                        result +
                        '","l":"INFO","t":""}]'
                    );
                    flowAttachmentResults.add(attachmentResult);
                }
            }
        }
        upsert flowAttachmentResults;
    }
}