public without sharing class AccountValidationRequestController {
    @AuraEnabled
    public static string updateAccountValue(Account acc) {
        
      if(acc.Request_Flag__c){
            acc.Request_Flag__c = false;
        }
        else{
            acc.Request_Flag__c = true;
        }
        system.debug('acc ' + acc);
        try{
            update acc;
            return 'SUCCESS';
        }catch(exception e)
        {
            return e.getMessage();
        }
        
    }
    
    @AuraEnabled
    public static DataWrap getAccInitValue(String sAccId) {
        
        DataWrap data = new DataWrap();
        data.acc = [select id, Request_Flag__c,Request_Comment__c,Request_Type__c, Require_Review__c from account where id=:sAccId ];
        Schema.DescribeFieldResult fieldResult = Account.Request_Type__c.getDescribe();
        
        system.debug('----'+fieldResult);
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            data.pickListValuesList.add(pickListVal.getvalue());
            
        }
        
        return data;
    }
    
    public class DataWrap{
        
        @AuraEnabled
        public account acc = new account();
        @AuraEnabled
        public List<string> pickListValuesList = new List<String>();   
    }
}