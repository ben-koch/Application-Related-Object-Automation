trigger EducationHistoryTrigger on Education_History__c (after update) {
    List<Id> conIds = New List<Id>();
    for(Education_History__c edu : Trigger.New){
        conIds.add(edu.Contact__c);
    }
    List<Application__c> apps = [SELECT Id, Application_Status__c, Documents_Missing__c, Contact__c FROM Application__c WHERE Contact__c IN :conIds];
    if(!apps.isEmpty()){
        ApplicationTriggerHandler.updateDocumentsMissingField(apps);
    }
}