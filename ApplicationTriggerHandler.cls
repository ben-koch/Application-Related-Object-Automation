public with sharing class ApplicationTriggerHandler {

    public static List<Admissions_Document__c> globalDocs = New List<Admissions_Document__c>();
    public static List<Education_History__c> globalEdus = New List<Education_History__c>();
    public static List<hed__Test_Score__c> globalScores = New List<hed__Test_Score__c>();
    
    public static void createChecklistRequirementItems(List<Application__c> apps){

        List<Id> appIds = New List<Id>();
        List<Id> relatedContactIds = New List<Id>();
        for(Application__c app : apps){
            appIds.add(app.Id);
            relatedContactIds.add(app.Contact__c);
        }
        Map<String,List<Checklist_Requirement_Item__c>> requirementsMap = New Map<String,List<Checklist_Requirement_Item__c>>();

        List<Checklist_Requirement_Item__c> cris = [SELECT Name, Item_Name__c, Requirement_Type__c, Checklist_Requirement__c FROM Checklist_Requirement_Item__c];

        for (Checklist_Requirement__c cr : [SELECT Id, Name FROM Checklist_Requirement__c]){
            //List<Checklist_Requirement_Item__c> cri = [SELECT Name, Item_Name__c, Requirement_Type__c FROM Checklist_Requirement_Item__c WHERE Checklist_Requirement__c = :cr.Id];
            List<Checklist_Requirement_Item__c> mapList = New List<Checklist_Requirement_Item__c>();
            for(Checklist_Requirement_Item__c cri : cris){
                if(cri.Checklist_Requirement__c == cr.Id){
                    mapList.add(cri);
                }
            }
            requirementsMap.put(cr.Name, mapList);
        }
        
        // query for a list of each requirement type object that's related to the app(s) in this Trigger
        List<Admissions_Document__c> admissionsDocs = [SELECT Application__c, Document_Name__c FROM Admissions_Document__c WHERE Application__c IN :appIds];
        List<Education_History__c> eduHistorys = [SELECT Applicant__c, Contact__c, Document_Type__c, Institution__r.Name FROM Education_History__c WHERE (Contact__c IN :relatedContactIds) OR (Applicant__c IN :relatedContactIds)];
        List<hed__Test_Score__c> testScores = [SELECT Contact__c, hed__Test_Type__c, RecordTypeId, RecordType.Name, RecordType.DeveloperName FROM hed__Test_Score__c WHERE Contact__c IN :relatedContactIds];
        
        // store our lists globally so they can be accessed by other methods
        globalDocs = admissionsDocs;
        globalEdus = eduHistorys;
        globalScores = testScores;

        // we will use these record type ids when checking for existing test score types
        List<String> tests = New List<String>{'ACT','LSAT','PSAT','PSAT_NMSQT','SAT_2005','SAT_I','SAT_II'};
        List<Id> actSATrecTypeIds = New List<Id>();
        for(String s : tests){
            Id i = Schema.SObjectType.hed__Test_Score__c.getRecordTypeInfosByDeveloperName().get(s).getRecordTypeId();
            actSATrecTypeIds.add(i);
        }
        // we will use this record type to specify an admissions document as a recommendation
        Id recommendationRT = Schema.SObjectType.Admissions_Document__c.getRecordTypeInfosByDeveloperName().get('Recommendations').getRecordTypeId();
        Id admissionsDocRT = Schema.SObjectType.Admissions_Document__c.getRecordTypeInfosByDeveloperName().get('Admissions_Document').getRecordTypeId();

        // we will use this list to bulkify all of the default shell objects we need to insert
        List<SObject> objectsToInsert = New List<SObject>();

        // iterate through each application that was inserted
        for (Application__c app : apps){ 

            // compare to requirement checklist object name
            List<Checklist_Requirement_Item__c> reqItems = requirementsMap.get(app.Requirement_Type__c);

            // iterate through the list of checklist requirement items to check what type it is, and see whether a record of that type exists
            for(Checklist_Requirement_Item__c cri : reqItems){
                // check the requirement type of the current cri, then once we identify it,
                if(cri.Requirement_Type__c == 'Admissions Document'){
                    // iterate through each of the objects of that type that are related to this app or its contact (queried for above)
                    List<Admissions_Document__c> matchingDocs = New List<Admissions_Document__c>();
                    for (Admissions_Document__c doc : admissionsDocs){
                        if(doc.Document_Name__c == cri.Item_Name__c && doc.Application__c == app.Id){
                            matchingDocs.add(doc);
                        }
                    }
                    // If we do not find a record that matches the specific requirement type and belongs to this app or applicant, create a default shell object record of that type
                    if(matchingDocs.isEmpty()){
                        // if the requirement is one of the recommendations, specify the record type of the new admissions doc as such
                        if(cri.Item_Name__c.contains('Recommendation')){
                            Admissions_Document__c newDoc = New Admissions_Document__c(RecordTypeId = recommendationRT, Application__c = app.Id, Document_Name__c = cri.Item_Name__c, Document_Status__c = 'Required');
                            objectsToInsert.add(newDoc);
                        }else{
                            Admissions_Document__c newDoc = New Admissions_Document__c(RecordTypeId = admissionsDocRT, Application__c = app.Id, Document_Name__c = cri.Item_Name__c, Document_Status__c = 'Required');
                            objectsToInsert.add(newDoc);
                        }
                    }
                }else if(cri.Requirement_Type__c == 'Education History'){
                    List<Education_History__c> matchingEduHistorys = New List<Education_History__c>();
                    for (Education_History__c eduHistory : eduHistorys){
                        if((eduHistory.Contact__c == app.Contact__c || eduHistory.Applicant__c == app.Contact__c) && eduHistory.Document_Type__c == cri.Item_Name__c){
                            matchingEduHistorys.add(eduHistory);
                        }
                    }
                    if(matchingEduHistorys.isEmpty()){
                        Education_History__c newEduHistory = New Education_History__c(Contact__c = app.Contact__c, Applicant__c = app.Contact__c, Document_Type__c = cri.Item_Name__c, Document_Status__c = 'Not Received');
                        objectsToInsert.add(newEduHistory);
                    }
                // check to see if the requirement item is TOEFL for an international student. If it is, check for that record type and create if necessary
                }else if(cri.Requirement_Type__c == 'Test Score' && cri.Item_Name__c.contains('TOEFL')){
                    Id TOEFLRecordTypeId = Schema.SObjectType.hed__Test_Score__c.getRecordTypeInfosByDeveloperName().get('TOEFL_IBT').getRecordTypeId();
                    List<hed__Test_Score__c> matchingTestScores = New List<hed__Test_Score__c>();
                    for (hed__Test_Score__c score : testScores){
                        if(score.Contact__c == app.Contact__c && score.RecordTypeId == TOEFLRecordTypeId){
                            matchingTestScores.add(score);
                        }
                    }
                    if(matchingTestScores.isEmpty()){
                        hed__Test_Score__c newScore = New hed__Test_Score__c(Contact__c = app.Contact__c, RecordTypeId = TOEFLRecordTypeId, Document_Status__c = 'Not Received');
                        objectsToInsert.add(newScore);
                    }
                // if the requirement item is a test score and anything other than TOEFL and we don't find a matching record, we create a shell test score of record type ACT
                }else if(cri.Requirement_Type__c == 'Test Score'){
                    List<hed__Test_Score__c> matchingTestScores = New List<hed__Test_Score__c>();
                    for (hed__Test_Score__c score : testScores){
                        for (Id recType : actSATrecTypeIds){
                            if(score.Contact__c == app.Contact__c && score.RecordTypeId == recType){
                                matchingTestScores.add(score);
                            }
                        }
                    }
                    if(matchingTestScores.isEmpty()){
                        hed__Test_Score__c newScore = New hed__Test_Score__c(Contact__c = app.Contact__c, RecordTypeId = Schema.SObjectType.hed__Test_Score__c.getRecordTypeInfosByDeveloperName().get('ACT').getRecordTypeId(), Document_Status__c = 'Not Received');
                        objectsToInsert.add(newScore);
                    }
                }
            }
        }
        // insert all of the default shell objects that we created while looking through each app that was created
        if (!objectsToInsert.isEmpty()){
            insert objectsToInsert;
        }
    }

    public static void updateDocumentsMissingField(List<Application__c> apps){

        // now that all necessary requirement items have been created and inserted, query for the related checklist requirements related to each app
        // if any of the items are in the status "not received", display them in the field Documents_Missing__c
        List<Admissions_Document__c> unreceivedDocs = New List<Admissions_Document__c>();
        List<String> statuses = New List<String>{'Received','Received - Initial','Received - Final','Waived'};
        for(Admissions_Document__c doc : globalDocs){
            if(!statuses.contains(doc.Document_Status__c)){
                unreceivedDocs.add(doc);
            }
        }
        List<Education_History__c> unreceivedEdus = New List<Education_History__c>();
        for(Education_History__c edu : globalEdus){
            if(edu.Document_Status__c == 'Not Received'){
                unreceivedEdus.add(edu);
            }
        }
        List<hed__Test_Score__c> unreceivedScores = New List<hed__Test_Score__c>();
        for(hed__Test_Score__c score : globalScores){
            if(score.Document_Status__c == 'Not Received'){
                unreceivedScores.add(score);
            }
        }
        // we need to query for and clone all of the apps we're looking at because the apps being passed here have been written, but not committed, to the database (due to after insert trigger)
        // this means we can't make changes to the actual records, so we need to make clones of them first and then update those clones
        List<Application__c> appClones = [SELECT Id, Contact__c, Documents_Missing__c FROM Application__c WHERE Id IN :apps];

        List<Application__c> appsToUpdate = New List<Application__c>();
        for (Application__c app : appClones){
            String richText = '<ul>';
            List<Admissions_Document__c> relatedDocs = New List<Admissions_Document__c>();
            List<Education_History__c> relatedEdus = New List<Education_History__c>();
            List<hed__Test_Score__c> relatedScores = New List<hed__Test_Score__c>();
            for (Admissions_Document__c doc : unreceivedDocs){
                if (doc.Application__c == app.Id){
                    relatedDocs.add(doc);
                }
            }
            for (Education_History__c edu : unreceivedEdus){
                if (edu.Applicant__c == app.Contact__c || edu.Contact__c == app.Contact__c){
                    relatedEdus.add(edu);
                }
            }
            for (hed__Test_Score__c score : unreceivedScores){
                if (score.Contact__c == app.Contact__c){
                    relatedScores.add(score);
                }
            }
            for (Admissions_Document__c doc : relatedDocs){
                richText += '<li>' + doc.Document_Name__c + '</li>';
            }
            for (Education_History__c edu : relatedEdus){
                if(edu.Institution__c == null){
                    richText += '<li>Transcript</li>';
                }else{
                    richText += '<li>' + edu.Institution__r.Name + '</li>';
                }
            }
            for (hed__Test_Score__c score : relatedScores){
                richText += '<li>' + score.RecordType.Name + ' Test Score</li>';
            }
            richText += '</ul>';
            app.Documents_Missing__c = richText;

            if(app.Documents_Missing__c == '<ul></ul>'){
                app.Documents_Missing__c = '';
            }
            appsToUpdate.add(app);
        }
        if(!appsToUpdate.isEmpty()){
        update appsToUpdate;
        }
    }
}
