/**
* @author Umit Can Uckan
* @description Controls Connection Behavior driven scheduled operations
* @date 6/9/19
*/
public with sharing class ConnectionBehaviorTriggerHelper {
    //CONSTANT variables
    public static final String C_SCHEDULEDBEHAVIOR = 'Scheduled';
    //NON-CONSTANT variables
    private static Map<Id, Connection_Behavior__c> connectionBehaviorMap = new Map<Id, Connection_Behavior__c>();
    public static List<Connection_Behavior__c> backScheduleList = new List<Connection_Behavior__c>();
    public static List<Connection_Behavior__c> forwardScheduleList = new List<Connection_Behavior__c>();
    public static List<Connection_Behavior__c> listToAbortForwardJobs = new List<Connection_Behavior__c>();
    public static List<Connection_Behavior__c> listToAbortBackJobs = new List<Connection_Behavior__c>();
    /**
    *  If the schedule is changed for either promotions or back-promotions we should update the schedule for the scheduled Job
    *  If the promotion or backpromotion behavior is changed to "Scheduled" we should ensure that the corresponding Scheduled Job exists, and we should overwrite the existing schedule with the schedule from the Connection Behavior
    *  If a promotion or backpromotion behavior is changed to something different than "Scheduled", we should delete the corresponding Scheduled Job
    *
    * @param newList
    * @param oldList
    */
    public static void schedulePromotionsForConnectionBehavior(List<Connection_Behavior__c> newList, List<Connection_Behavior__c> oldList) {
        Integer listSize = null != newList ? newList.size() : 0;
        Boolean isInsert = (null == oldList);
        if(listSize != 0) {
            Set<Id> cbIds = new Set<Id>();
            for(Integer i = 0; i < listSize; i++) {
                cbIds.add(newList[i].Id);
            }
            connectionBehaviorMap = new Map<Id, Connection_Behavior__c>([SELECT Id, (SELECT Id, Source_Environment__c, Destination_Environment__c FROM Pipeline_Connections__r), (SELECT Id, Connection_Behavior__c FROM Environments__r), Back_Promotion_Scheduled_Job_ID__c, Back_Promotion_Schedule__c, Max_Scheduled_Back_Promotion_Batch_Size__c, Back_Promotion_Behavior__c, Promotion_Schedule__c, Promotion_Behavior__c, Max_Scheduled_Promotion_Batch_Size__c, Promotion_Scheduled_Job_ID__c FROM Connection_Behavior__c WHERE Id IN :cbIds]);

            for(Integer i = 0; i < listSize; i++) {
                defineForwardAbortAndSchedule(newList[i], (isInsert ? null : oldList[i]), isInsert);

                defineBackAbortAndSchedule(newList[i], (isInsert ? null : oldList[i]), isInsert);
            }

            handleAbortOperation();

            handleReScheduleOperation();
        }
    }
    /**
     * check if we need to schedule or abort any schedule job for forward promotion based on changes of current connection behavior item
     *
     * @param newItem current new record
     * @param OldItem current old record
     * @param isInsert
     */
    public static void defineForwardAbortAndSchedule(Connection_Behavior__c newItem, Connection_Behavior__c oldItem, Boolean isInsert) {
        Boolean proScheduleHasChanged = isInsert ? true : newItem.Promotion_Schedule__c != oldItem.Promotion_Schedule__c;
        Boolean proBehaviorHasChanged = isInsert ? true : newItem.Promotion_Behavior__c != oldItem.Promotion_Behavior__c;
        Boolean proBatchSizeHasChanged = isInsert ? true : newItem.Max_Scheduled_Promotion_Batch_Size__c != oldItem.Max_Scheduled_Promotion_Batch_Size__c;
        if(newItem.Promotion_Behavior__c == C_SCHEDULEDBEHAVIOR && ((String.isNotBlank(newItem.Promotion_Schedule__c) && isInsert) || (!isInsert && String.isNotBlank(newItem.Promotion_Schedule__c) && (proScheduleHasChanged || proBehaviorHasChanged || proBatchSizeHasChanged)))) {
            forwardScheduleList.add(newItem);
        } else if(String.isNotBlank(newItem.Promotion_Scheduled_Job_ID__c) && ((!isInsert && proScheduleHasChanged && String.isEmpty(newItem.Promotion_Schedule__c)) || (!isInsert && newItem.Promotion_Behavior__c != C_SCHEDULEDBEHAVIOR && proBehaviorHasChanged) || (!isInsert && proBatchSizeHasChanged))) {
            listToAbortForwardJobs.add(newItem);
        }
    }
    /**
     * check if we need to schedule or abort any schedule job for back promotion based on changes of current connection behavior item
     *
     * @param newItem current new record
     * @param OldItem current old record
     * @param isInsert
     */
    public static void defineBackAbortAndSchedule(Connection_Behavior__c newItem, Connection_Behavior__c oldItem, Boolean isInsert) {
        Boolean backProScheduleHasChanged = isInsert ? true : newItem.Back_Promotion_Schedule__c != oldItem.Back_Promotion_Schedule__c;
        Boolean backProBehaviorHasChanged = isInsert ? true : newItem.Back_Promotion_Behavior__c != oldItem.Back_Promotion_Behavior__c;
        Boolean backProBatchSizeHasChanged = isInsert ? true : newItem.Max_Scheduled_Back_Promotion_Batch_Size__c != oldItem.Max_Scheduled_Back_Promotion_Batch_Size__c;
        if(newItem.Back_Promotion_Behavior__c == C_SCHEDULEDBEHAVIOR && ((String.isNotBlank(newItem.Back_Promotion_Schedule__c) && isInsert) || (!isInsert && String.isNotBlank(newItem.Back_Promotion_Schedule__c) && (backProScheduleHasChanged || backProBehaviorHasChanged || backProBatchSizeHasChanged)))) {
            backScheduleList.add(newItem);
        } else if(String.isNotBlank(newItem.Back_Promotion_Scheduled_Job_ID__c) && ((!isInsert && backProScheduleHasChanged && String.isEmpty(newItem.Back_Promotion_Schedule__c)) || (!isInsert && newItem.Back_Promotion_Behavior__c != C_SCHEDULEDBEHAVIOR && backProBehaviorHasChanged) || (!isInsert && backProBatchSizeHasChanged))) {
            listToAbortBackJobs.add(newItem);
        }
    }
    /**
     * handles re-scheduling operation of changed Connection behaviors
     */
    public static void handleReScheduleOperation() {
        Set<Id> sourceEnvIds = calculateDestionationIds(null, forwardScheduleList);
        for(Connection_Behavior__c cb : forwardScheduleList) {
            abortJob(cb.Promotion_Scheduled_Job_ID__c);
            Integer batchSize = (null != cb.Max_Scheduled_Promotion_Batch_Size__c ? (Integer) cb.Max_Scheduled_Promotion_Batch_Size__c : 1);
            CCD_PromotionSchedule susf = new CCD_PromotionSchedule(batchSize, sourceEnvIds);
            cb.Promotion_Scheduled_Job_ID__c = System.schedule('CCD Forward Promotion Schedule - ' + DateTime.now() + '.' + Math.mod(DateTime.now().getTime(), 1000), cb.Promotion_Schedule__c, Susf);
        }
        Set<Id> destEnvIds = calculateDestionationIds(backScheduleList, null);
        for(Connection_Behavior__c cb : backScheduleList) {
            abortJob(cb.Back_Promotion_Scheduled_Job_ID__c);
            Integer batchSize = (null != cb.Max_Scheduled_Back_Promotion_Batch_Size__c ? (Integer) cb.Max_Scheduled_Back_Promotion_Batch_Size__c : 10);
            CCD_BackPromotionSchedule susf = new CCD_BackPromotionSchedule(batchSize, destEnvIds);
            cb.Back_Promotion_Scheduled_Job_ID__c = System.schedule('CCD Back Promotion Schedule - ' + DateTime.now() + '.' + Math.mod(DateTime.now().getTime(), 1000), cb.Back_Promotion_Schedule__c, Susf);
        }
    }

    /**
     * calculates the environments to use on a related batch class queries for filtering down records purpose
     *
     * @param connectionBehaviorListForDest
     * @param connectionBehaviorListForSource
     *
     * @return identified Environment Ids to run the batch job via
     */
    private static Set<Id> calculateDestionationIds(List<Connection_Behavior__c> connectionBehaviorListForDest, List<Connection_Behavior__c> connectionBehaviorListForSource) {
        Set<Id> destEnvIds = new Set<Id>();
        Set<Id> sourceEnvIds = new Set<Id>();
        List<Connection_Behavior__c> connectionBehaviorList = (null != connectionBehaviorListForDest ? connectionBehaviorListForDest : connectionBehaviorListForSource);
        for(Connection_Behavior__c cbItem : connectionBehaviorList) {
            System.debug('connectionBehaviorMap.get(cbItem.Id).Pipeline_Connections__r==> ' + connectionBehaviorMap.get(cbItem.Id).Pipeline_Connections__r);
            for(Deployment_Flow_Step__c dfs : connectionBehaviorMap.get(cbItem.Id).Pipeline_Connections__r) {
                destEnvIds.add(dfs.Destination_Environment__c);
                sourceEnvIds.add(dfs.Source_Environment__c);
            }
            for(Environment__c env : connectionBehaviorMap.get(cbItem.Id).Environments__r) {
                destEnvIds.add(env.Id);
                sourceEnvIds.add(env.Id);
            }
        }
        return (null != connectionBehaviorListForDest ? destEnvIds : sourceEnvIds);
    }

    /**
     * Handles job abort operation before re-scheduling them
     */
    public static void handleAbortOperation() {
        for(Connection_Behavior__c cb : listToAbortForwardJobs) {
            abortJob(cb.Promotion_Scheduled_Job_ID__c);
            cb.Promotion_Scheduled_Job_ID__c = '';
        }

        for(Connection_Behavior__c cb : listToAbortBackJobs) {
            abortJob(cb.Back_Promotion_Scheduled_Job_ID__c);
            cb.Back_Promotion_Scheduled_Job_ID__c = '';
        }
    }

    /**
     * Aborts the job via jobId if it exist
     *
     * @param jobId
     */
    public static void abortJob(String jobId) {
        if(String.isNotBlank(jobId)) {
            try {
                System.abortJob(jobId);
            } catch(Exception ex) {
                System.debug('exception ===> ' + ex.getMessage());
            }
        }
    }

    /**
     * deletes the related Quality gates before delete of connection behavior records
     *
     * @param oldMap before update old Map
     */
    public static void deepDelete(Map<Id, SObject> oldMap) {
        try {
            Utilities.Secure_DML([SELECT Id FROM Quality_Gate__c WHERE Connection_Behavior__c IN :oldMap.keySet()], Utilities.DML_Action.DEL, Schema.SObjectType.Quality_Gate__c);
        } catch(DmlException exp) {
            System.debug('exception===> ' + exp.getMessage());
        }
    }
}