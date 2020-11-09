global with sharing class WebhookSchedulable implements Schedulable, Database.AllowsCallouts{
    private Id scheduledJobID;
    public WebhookSchedulable(Id jobId){
        this.scheduledJobID = jobId;
    }
    global void execute(SchedulableContext sc) {
        Scheduled_Job__c sched = [select Id, Name, Webhook_URL__c, Run_as_User__c from Scheduled_Job__c where Id = :this.scheduledJobID];
        String url = sched.Webhook_URL__c;
        if (String.isNotBlank(sched.Run_as_User__c)){
            String apikey = DeployAPI.getUserAPIKey();
            if(url.indexOf('api_key=')>0){
                url = url.left(url.indexOf('api_key=')-1);
            }
            if(url.indexOf('&') > -1 && url.indexOf('?') == -1){
                url = url.replace('&','?');
            }
            url += (url.indexOf('?') > -1 ? '&' : '?')+'api_key=' + apikey;
        }
        WebhookAPI.callGenericWebhookAtFuture(url, this.scheduledJobID);
    }
}