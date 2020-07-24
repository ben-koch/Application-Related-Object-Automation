@isTest
public with sharing class EducationHistoryTriggerTest {
    @isTest
    static void EducationHistoryTriggerTest() {
        Education_History__c edu = New Education_History__c();
        insert edu;
        update edu;
    }
}
