trigger ApplicationTrigger on Application__c (after update) {
        List<Application__c> apps = New List<Application__c>();
        // if the app is created, check to see if the status is submitted. If so, create the related records
        /*
        if(trigger.isInsert){
                for (Application__c app : Trigger.New){
                        if(app.Application_Status__c == 'Submitted App'){
                                apps.add(app);
                        }
                }
                ApplicationTriggerHandler.createChecklistRequirementItems(apps);
                ApplicationTriggerHandler.updateDocumentsMissingField(apps);
        }
        
        // if the app is being updated, compare the Application Status field before and after the update.
        // if it is being changed from not submitted to submitted, create the related records
        
        if(trigger.isUpdate){     
        */  
                for(Application__c app : Trigger.New){
                        Application__c oldApp = Trigger.oldMap.get(app.Id);
                        if(oldApp.Application_Status__c != 'Submitted App' && app.Application_Status__c == 'Submitted App'){
                                apps.add(app);
                        }
                        if(app.Requirement_Type__c != null && app.Requirement_Type__c.contains('Admit')){
                                if((oldApp.Requirement_Type__c != null) && (!oldApp.Requirement_Type__c.contains('Admit'))){
                                        apps.add(app);
                                }else if(oldApp.Requirement_Type__c == null){
                                        apps.add(app);
                                }
                        }
                }
                //if(!Test.isRunningTest()){
                        ApplicationTriggerHandler.createChecklistRequirementItems(apps);
                        ApplicationTriggerHandler.updateDocumentsMissingField(apps);
                //}
        //}
}