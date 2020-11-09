//This batch is called in two scenarios:
//1) When Index Metadata Field is set to true in Project.
//2) When Attachment on User Story is created, Updated ('MetaData','Delete MetaData', 'Git MetaData')
//The batch is executed twice, with the following behaviors respectively:
//1) The batch will create User_Story_Metadata__c record per key Type.ApiName of whatever was committed in the User Story
//2) The batch will look for all the possible duplicates across all the User_Story_Metadata__c records and mark them as potentially conflicted

global with sharing class IndexMetadataJob implements Database.batchable<sObject>, Schedulable, Database.Stateful {
    public String userstoryId { get; set; }
    //Flag to specify which behavior will this batch run.
    public Boolean checkPotentialConflict;
    public Boolean zeroizePotentialConflicts;
    // Constants
    public final String DELETEMETADATA = 'Delete MetaData';

    global void execute(SchedulableContext sc) {
        IndexMetadataJob b = new IndexMetadataJob();
        Database.executebatch(b, 50);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        if(zeroizePotentialConflicts == true && checkPotentialConflict == false) {
            return Database.getQueryLocator([SELECT Id, Status__c FROM User_Story_Metadata__c WHERE User_Story__c = :userstoryId AND Status__c = 'Potential Conflict']);
        } else if(zeroizePotentialConflicts == true && checkPotentialConflict == true) {
            Set<String> mapiNames = new Set<String>();
            Set<String> mapiNames2send = new Set<String>();
            for(User_Story_Metadata__c usm : [SELECT Metadata_API_Name__c FROM User_Story_Metadata__c WHERE User_Story__c = :userstoryId AND User_Story__r.Project__r.Index_Metadata__c = true AND User_Story__r.Stop_Indexing_Metadata__c = false]) {
                mapiNames.add(usm.Metadata_API_Name__c);
            }

            AggregateResult[] groupedResults = [
                    SELECT Metadata_API_Name__c, COUNT(Id)
                    FROM User_Story_Metadata__c
                    WHERE Metadata_API_Name__c IN:mapiNames
                    AND User_Story__r.Project__r.Index_Metadata__c = TRUE AND User_Story__r.Stop_Indexing_Metadata__c = FALSE
                    GROUP BY Metadata_API_Name__c
                    HAVING COUNT(Id) > 1
            ];
            for(AggregateResult ar : groupedResults) {
                String gname = Settings.ns + 'Metadata_API_Name__c';
                String gr = '' + ar.get(gname);
                mapiNames2send.add(gr);
            }

            return Database.getQueryLocator([
                    SELECT Id
                    FROM User_Story_Metadata__c
                    WHERE Metadata_API_Name__c IN:mapiNames2send
                    AND User_Story__r.Project__r.Index_Metadata__c = TRUE AND User_Story__r.Stop_Indexing_Metadata__c = FALSE
            ]);
        } else if(null != userstoryId && checkPotentialConflict != TRUE) {
            return Database.getQueryLocator([
                    SELECT Id
                    FROM User_Story__c
                    WHERE Id = :userstoryId
                    AND Stop_Indexing_Metadata__c = FALSE AND Project__r.Index_Metadata__c = TRUE
            ]);
        } else if(null == userstoryId && checkPotentialConflict != TRUE) {
            return Database.getQueryLocator([
                    SELECT Id
                    FROM User_Story__c
                    WHERE Stop_Indexing_Metadata__c = FALSE
                    AND Project__r.Index_Metadata__c = TRUE
            ]);
        } else {
            Set<String> dupes = new Set<String>();
            AggregateResult[] groupedResults = [
                    SELECT Metadata_API_Name__c, COUNT(Id)
                    FROM User_Story_Metadata__c
                    WHERE Status__c = ''
                    AND User_Story__r.Project__r.Index_Metadata__c = TRUE AND User_Story__r.Stop_Indexing_Metadata__c = FALSE
                    GROUP BY Metadata_API_Name__c
                    HAVING COUNT(Id) > 1
            ];
            for(AggregateResult ar : groupedResults) {
                dupes.add(String.valueOf(ar.get(Schema.SObjectType.User_Story_Metadata__c.fields.Metadata_API_Name__c.getName())));
            }

            return Database.getQueryLocator([
                    SELECT Id
                    FROM User_Story_Metadata__c
                    WHERE Metadata_API_Name__c IN :dupes AND Status__c = ''
                    AND User_Story__r.Project__r.Index_Metadata__c = TRUE AND User_Story__r.Stop_Indexing_Metadata__c = FALSE
            ]);
        }
    }
    global void execute(Database.BatchableContext BC, List<User_Story__c> scope) {
        System.debug('Old execute');
        execute(BC, (List<SObject>) scope);
    }


    public void execute(Database.BatchableContext BC, List<SObject> sList) {
        if(zeroizePotentialConflicts == true && checkPotentialConflict == false) {
            List<User_Story_Metadata__c> scope = (List<User_Story_Metadata__c>) sList;
            for(User_Story_Metadata__c usM : scope) {
                usM.Status__c = '';
            }
            Utilities.Secure_DML(scope, Utilities.DML_Action.UPD, schema.SObjectType.User_Story_Metadata__c);
        } else if(checkPotentialConflict == true) {
            List<User_Story_Metadata__c> scope = (List<User_Story_Metadata__c>) sList;
            for(User_Story_Metadata__c usM : scope) {
                usM.Status__c = 'Potential Conflict';
            }
            Utilities.Secure_DML(scope, Utilities.DML_Action.UPD, schema.SObjectType.User_Story_Metadata__c);
        } else {
            List<User_Story__c> scope = (List<User_Story__c>) sList;

            Set<Id> uids = new Set<Id>();
            for(User_Story__c us : scope) {
                uids.add(us.Id);
            }
            Map<String, User_Story_Metadata__c> usMetadataMap = new Map<String, User_Story_Metadata__c>();
            for(Attachment att : [SELECT Id, Name, Body, ParentId, Parent.Name FROM Attachment WHERE ParentId IN :uids AND Name IN ('MetaData', 'Delete MetaData', 'Git MetaData')]) {
                try {
                    String jsonInput = att.Body.toString();
                    List<Object> objList = (List<Object>) JSON.deserializeUntyped(jsonInput);
                    for(Object obj : objList) {
                        Map<String, Object> objectMap = (Map<String, Object>) obj;
                        if(!objectMap.containsKey('t') || !objectMap.containsKey('n')) {
                            continue; // malformed JSON node in the (git) metadata attachment so skip
                        }
                        User_Story_Metadata__c usMetadata = new User_Story_Metadata__c();
                        usMetadata.User_Story__c = att.ParentId;
                        // In order to make overlap awareness work for Vlocity metadata we need API Name of their metadata
                        //However we have the label which is equal to API_Name+(ID)
                        //So below if condition removes the id part from the Vlocity metadata for overlap awareness
                        Map<String, Schema.SObjectType> gdesc = Schema.getGlobalDescribe();
                        if(objectMap.get('n').toString().endsWith(')') && !gdesc.containsKey(objectMap.get('t').toString())) {
                            usMetadata.Metadata_API_Name__c = objectMap.get('t') + '.' + objectMap.get('n');
                            usMetadata.Metadata_API_Name__c = usMetadata.Metadata_API_Name__c.left(255);
                            usMetadata.Metadata_API_Name__c = usMetadata.Metadata_API_Name__c.replaceFirst('^(.+) \\([a-zA-Z0-9]{18}\\)$', '$1');
                        } else {
                            usMetadata.Metadata_API_Name__c = objectMap.get('t') + '.' + objectMap.get('n');
                            usMetadata.Metadata_API_Name__c = usMetadata.Metadata_API_Name__c.left(255);
                        }

                        usMetadata.Unique_ID__c = att.ParentId + (att.Name == DELETEMETADATA ? ' _delete_' : '_') + usMetadata.Metadata_API_Name__c;
                        usMetadata.Unique_ID__c = usMetadata.Unique_ID__c.left(255);
                        usMetadata.Name = att.Parent.Name + (att.Name == DELETEMETADATA ? 'Delete ' : ' ') + usMetadata.Metadata_API_Name__c;
                        usMetadata.Name = usMetadata.Name.left(80);
                        usMetadata.Last_Commit_Date__c = System.now();
                        usMetadataMap.put(usMetadata.Unique_ID__c, usMetadata);
                    }
                } catch(Exception e) {
                    System.debug('ERROR while parsing attachment ' + att.Name + ' - ' + att.Id + ' exception: ' + e.getMessage());
                }
            }
            Utilities.Secure_DML(usMetadataMap.values(), Utilities.DML_Action.UPS, schema.SObjectType.User_Story_Metadata__c, schema.SObjectType.User_Story_Metadata__c.fields.Unique_ID__c);
        }
    }

    global void finish(Database.BatchableContext BC) {
        if(checkPotentialConflict != true) { //Entry only once
            IndexMetadataJob imJob = new IndexMetadataJob();
            imJob.checkPotentialConflict = true;
            Database.executebatch(imJob);
        }
    }
}