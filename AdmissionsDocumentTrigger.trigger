trigger AdmissionsDocumentTrigger on Admissions_Document__c (after update) {
    List<Id> appIds = New List<Id>();
    for(Admissions_Document__c doc : Trigger.New){
        appIds.add(doc.Application__c);
    }
    List<Application__c> apps = [SELECT Id, Application_Status__c, Documents_Missing__c, Contact__c FROM Application__c WHERE Id IN :appIds];
    if(!apps.isEmpty()){
        ApplicationTriggerHandler.updateDocumentsMissingField(apps);
    }
}