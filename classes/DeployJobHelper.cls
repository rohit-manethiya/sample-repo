public with sharing class DeployJobHelper {
    public static void upsertDeployJobs(Set<Id> deploymentIds) {
        List<Step__c> steps = [select id, name, deployment__c from Step__c where deployment__c in:deploymentIds];
        List<Destination_Org__c> dests = [select id, deployment__c, To_Org__r.Environment__r.Run_all_tests__c from Destination_Org__c where deployment__c in:deploymentIds];
        List<Deployment_Job__c> djs = new List<Deployment_Job__c>();
        for (Step__c s : steps) {
            for (Destination_Org__c d : dests) {
                if (s.Deployment__c == d.Deployment__c)djs.add(new Deployment_Job__c(
                                step__c = s.id,
                                destination_org__c = d.id,
                                external_id__c = s.id + '_' + d.id));
            }
        }
        try {
            Utilities.Secure_DML(djs, Utilities.DML_Action.UPS, schema.Sobjecttype.Deployment_Job__c, schema.sObjectType.Deployment_Job__c.fields.external_id__c);
        } catch (DmlException e) {
            system.debug(e);
            //If we are in visualforce context
            if (ApexPages.currentPage() != null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '' + e));
            }
        }
    }
    public static String updateStatus(Deployment_Job__c dj, Id deploymentId) {
        //get all Deployment jobs for the current Deployment
        List<Deployment_Job__c> djs = [select Id, Status__c, Step__c, Step__r.Status__c, Destination_Org__c, Destination_Org__r.Status__c from Deployment_Job__c where step__r.deployment__c = :deploymentId order by Destination_Org__c, Step__r.Order__c];

        //map the status of all destination orgs
        Map<Id, String> dos = new Map<Id, String>();
        for (Deployment_Job__c t : djs) {
            dos.put(t.Destination_Org__c, '');
        }
        System.debug('1*** dos = ' + dos);
        for (Id k : dos.keySet()) {
            dos.put(k, getDOstatus(djs, k));
        }
        System.debug('2*** dos = ' + dos);
        //define status of the destination org
        Destination_Org__c deo = new Destination_Org__c(Id = dj.destination_org__c, Status__c = dos.get(dj.destination_org__c));
        Utilities.Secure_DML(deo, Utilities.DML_Action.UPD, schema.Sobjecttype.Destination_Org__c);

        //define status of the step
        Step__c s = new Step__c(Id = dj.step__c);
        String ss = '';
        for (Deployment_Job__c t : djs) {
            if (t.Step__c == dj.Step__c) {
                if (t.Status__c == 'Pending') {
                    ss = dos.get(t.Destination_Org__c);
                    break;
                } else if (t.Status__c == 'Success' && ss == '') {
                    ss = 'Completed Successfully';
                } else if (t.Status__c == 'Failed') {
                    ss = 'Completed with Errors';
                } else if (t.Status__c == 'Cancelled') {
                    ss = 'Cancelled';
                    break;
                }
            }
        }
        s.Status__c = ss;
        Utilities.Secure_DML(s, Utilities.DML_Action.UPD, schema.Sobjecttype.Step__c);


        //define status of the deployment
        Deployment__c d = new Deployment__c(Id = deploymentId);
        String ds = '';
        Boolean isAllcompleted = true;
        Boolean isCancelled = false;
        for (Id k : dos.keySet()) {
            String dostat = dos.get(k);
            if (dostat == 'In progress' || dostat == 'Pending' || dostat == 'In Progress' || dostat == 'Not started') {
                ds = 'In progress';
                isAllcompleted = false;
                break;
            } else if (dostat == 'Completed Successfully' && ds == '') {
                ds = 'Completed Successfully';
            } else if (dostat == 'Completed with Errors' && ds != 'Cancelled') {
                ds = 'Completed with Errors';
            } else if (dostat == 'Cancelled') {
                ds = 'Cancelled';
                isCancelled = true;
            }
            System.debug('2.5***' + k + '=' + dostat + ' -- ds = ' + ds + ' all Completed = ' + isAllcompleted);
        }
        System.debug('3*** -- ds = ' + ds + ' all Completed = ' + isAllcompleted);
        if (isAllcompleted) {
            d.Status__c = ds;
            Utilities.Secure_DML(d, Utilities.DML_Action.UPD, schema.Sobjecttype.Deployment__c);
        }

        return ds;
    }
    public static Map<Id, String> updateStatus(Map<Id, List<Deployment_Job__c>> djToDeployment) {

        //get all Deployment jobs for the current Deployment
        List<Deployment_Job__c> djs = [SELECT Id, Status__c, Step__c, Step__r.Status__c, Destination_Org__c, Destination_Org__r.Status__c FROM Deployment_Job__c WHERE Step__r.Deployment__c IN: djToDeployment.KeySet() ORDER BY Destination_Org__c, Step__r.Order__c];

        //map the status of all destination orgs
        Map<Id, String> dos = new Map<Id, String>();
        for (Deployment_Job__c t : djs) {
            dos.put(t.Destination_Org__c, '');
        }

        for (Id k : dos.keySet()) {
            dos.put(k, getDOstatus(djs, k));
        }


        Set<Destination_Org__c> destinationSet = new Set<Destination_Org__c>();
        Set<Step__c> stepSet = new Set<Step__c>();
        Set<Deployment__c> deploymentSet = new Set<Deployment__c>();
        Map<Id, String> deploymentStatuses = new Map<Id, String>();
        for (Id dId : djToDeployment.keySet()) {
            for (Deployment_Job__c djob : djToDeployment.Get(dId)) {

                //define status of the destination org
                Destination_Org__c deo = new Destination_Org__c(Id = djob.Destination_org__c, Status__c = dos.get(djob.Destination_org__c));
                destinationSet.add(deo);

                //define status of the step
                Step__c s = new Step__c(Id = djob.step__c);
                String ss = '';
                for (Deployment_Job__c t : djs) {
                    if (t.Step__c == djob.Step__c) {
                        if (t.Status__c == 'Pending') {
                            ss = dos.get(t.Destination_Org__c);
                            break;
                        } else if (t.Status__c == 'Success' && ss == '') {
                            ss = 'Completed Successfully';
                        } else if (t.Status__c == 'Failed') {
                            ss = 'Completed with Errors';
                        } else if (t.Status__c == 'Cancelled') {
                            ss = 'Cancelled';
                            break;
                        }
                    }
                }
                s.Status__c = ss;
                stepSet.add(s);

                //define status of the deployment
                Deployment__c d = new Deployment__c(Id = dId);
                String ds = '';
                Boolean isAllcompleted = true;
                Boolean isCancelled = false;
                for (Id k : dos.keySet()) {
                    String dostat = dos.get(k);
                    if (dostat == 'In progress' || dostat == 'Pending' || dostat == 'In Progress' || dostat == 'Not started') {
                        ds = 'In progress';
                        isAllcompleted = false;
                        break;
                    } else if (dostat == 'Completed Successfully' && ds == '') {
                        ds = 'Completed Successfully';
                    } else if (dostat == 'Completed with Errors' && ds != 'Cancelled') {
                        ds = 'Completed with Errors';
                    } else if (dostat == 'Cancelled') {
                        ds = 'Cancelled';
                        isCancelled = true;
                    }
                }
                if (isAllcompleted) {
                    d.Status__c = ds;
                    deploymentSet.add(d);
                }

                deploymentStatuses.put(dId, ds);
            }
        }
        List<Destination_Org__c> destinations =new  List<Destination_Org__c>();
        List<Step__c> steps =new  List<Step__c>();
        List<Deployment__c> deployments =new  List<Deployment__c>();
        destinations.addAll(destinationSet);
        steps.addAll(stepSet);
        deployments.addAll(deploymentSet);
        Utilities.Secure_DML(destinations, Utilities.DML_Action.UPD, schema.Sobjecttype.Destination_Org__c);
        Utilities.Secure_DML(steps, Utilities.DML_Action.UPD, schema.Sobjecttype.Step__c);
        Utilities.Secure_DML(deployments, Utilities.DML_Action.UPD, schema.Sobjecttype.Deployment__c);


        return deploymentStatuses;
    }
    public static String getDOstatus(List<Deployment_Job__c> djs, Id destOrgId) {
        String sdo = '';
        for (Deployment_Job__c t : djs) {
            if (t.Destination_Org__c == destOrgId) {
                if ((t.Status__c == 'Pending' || t.Status__c == 'In progress') && sdo != 'Completed with Errors') {
                    sdo = 'In progress';
                    break;
                } else if (t.Status__c == 'Success' && sdo == '') {
                    sdo = 'Completed Successfully';
                } else if (t.Status__c == 'Failed') {
                    sdo = 'Completed with Errors';
                } else if (t.Status__c == 'Cancelled') {
                    sdo = 'Cancelled';
                    break;
                }
            }
        }
        return sdo;
    }
}