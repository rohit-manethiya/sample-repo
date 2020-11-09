public with sharing class usersStepController {
    public Step__c dummy;
    
    public Step__c getDummy(){ return dummy;}
    public void setDummy(Step__c e){}
    
    public usersStepController(){
        dummy = new Step__c();        
    }
    static testMethod void runTest(){
    	usersStepController con = new usersStepController();
    	system.assert(con.dummy != null);
    	Step__c testStep = new Step__c();
    	testStep.Name = 'testMethodStep';
    	con.dummy = testStep;
    	con.setDummy(testStep);
    	Step__c s = con.getDummy();
    	system.assertEquals('testMethodStep', s.Name);
    }
}