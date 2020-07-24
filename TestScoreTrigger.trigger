trigger TestScoreTrigger on hed__Test_Score__c (after update) {
    List<Id> conIds = New List<Id>();
    for(hed__Test_Score__c score : Trigger.New){
        conIds.add(score.Contact__c);
    }
    List<Application__c> apps = [SELECT Id, Application_Status__c, Documents_Missing__c, Contact__c FROM Application__c WHERE Contact__c IN :conIds];
    if(!apps.isEmpty()){    
        ApplicationTriggerHandler.updateDocumentsMissingField(apps);
    }
}