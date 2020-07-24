@isTest
public with sharing class AdmissionsDocumentTriggerTest {
    @isTest (SeeAllData=true)
    static void AdmissionsDocumentTriggerTest() {
        Contact con = New Contact(LastName='Test');
        insert con;
        Application__c app = New Application__c(Contact__c = con.Id, Requirement_Type__c = 'Freshman');
        insert app;
        Admissions_Document__c adm = New Admissions_Document__c(Application__c = app.Id);
        insert adm;
        update adm;
    }
}
