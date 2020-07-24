@isTest
public with sharing class ApplicationTriggerTest {
    @isTest (SeeAllData=true)
    static void ApplicationTriggerTest() {
        List<Contact> cons = New List<Contact>();
        Contact con1 = New Contact(LastName='Alpha');
        cons.add(con1);
        Contact con2 = New Contact(LastName='Beta');
        cons.add(con2);
        Contact con3 = New Contact(LastName='Chi');
        cons.add(con3);
        Contact con4 = New Contact(LastName='Delta');
        cons.add(con4);
        Contact con5 = New Contact(LastName='Earl');
        cons.add(con5);
        insert cons;
        List<Application__c> apps = New List<Application__c>();
        Application__c app1 = New Application__c(Contact__c = con1.Id, Requirement_Type__c = 'Freshman');
        apps.add(app1);
        Application__c app2 = New Application__c(Contact__c = con2.Id, Requirement_Type__c = 'Reapplicant');
        apps.add(app2);
        Application__c app3 = New Application__c(Contact__c = con3.Id, Requirement_Type__c = 'Graduate Studies');
        apps.add(app3);
        Application__c app4 = New Application__c(Contact__c = con4.Id, Requirement_Type__c = 'Freshman International');
        apps.add(app4);
        Application__c app5 = New Application__c(Contact__c = con5.Id, Requirement_Type__c = '');
        apps.add(app5);
        system.debug(apps);
        insert apps;

        app1.Application_Status__c = 'Submitted App';
        app2.Application_Status__c = 'Submitted App';
        app3.Application_Status__c = 'Submitted App';
        app4.Application_Status__c = 'Submitted App';
        app5.Requirement_Type__c = 'Domestic Admit Non-PSEO, Non-Grad';
        system.debug(apps);
        update apps;
    }
}
