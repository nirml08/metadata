@isTest
public class AccountValidationRequestController_Test
{
    private testMethod static void testMethod1(){
    
    	Account a = TestDataFactory.createAccounts(1)[0];
        insert a;
        
        test.startTest();
        AccountValidationRequestController.getAccInitValue(a.id);
        a.Request_Flag__c = true;
        string result1 = AccountValidationRequestController.updateAccountValue(a);
        system.assertEquals('SUCCESS', result1);
        
        a.Request_Flag__c = false;
        a.Request_Type__c = 'ABC';
        string result2 = AccountValidationRequestController.updateAccountValue(a);
        system.assertNotEquals('SUCCESS', result2);
        test.stopTest();
        
    }

}