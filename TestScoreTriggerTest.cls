@isTest
public with sharing class TestScoreTriggerTest {
    @isTest
    static void TestScoreTriggerTest() {
        hed__Test_Score__c score = New hed__Test_Score__c();
        insert score;
        update score;
    }
}