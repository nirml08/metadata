/*
Name       : AccountTriggerHandler_Test
Description: Test Class for AccountTriggerHandler trigger
Author     : Linda Neel
CreatedDate: 10-28-2018
*/
@isTest
public class AccountTriggerHandler_Test {

       public static Id recTypeAccount = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'US & Canada Customer' LIMIT 1].Id;
       public static Id recTypeAccountItn = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'International Customer' LIMIT 1].Id;    
       
        @testsetup
        static void testdatasetup(){
            User u = TestDataFactory.createUserBusinessAdmin(true, 'TestUser', 'BusinessAdmin');
            User u1 = TestDataFactory.createSalesUser(true, 'TestSales', 'RepUser');
        }   
       @isTest
       static void UpdateAccount_Test () {

            // NOTES: test 200 records
          
            // create custom setting class to include values needed in before insert trigger
            Default_Currency_by_Country_Code__c c = new Default_Currency_by_Country_Code__c ();
            c.Name = 'AZ';
            c.Currency_Code__c = 'USD';
            Insert c; 
           
            //use to trigger feed      
            Account acct = new Account(name='My New Account',Account_role__c='ZCSN',
                                      Transportation_Zone_Country__c = 'US',Primary_Language__c = 'EN',
                                      Country_Cluster__c = 'US&CA',Division_Account__c = 'Atlantic',Region__c = 'Central',Account_Territory__c='East OH',
                                      BillingCountryCode = 'AZ',RecordtypeId = recTypeAccount,
                                      Account_Status__c = 'Active',IsDeleted__c = false,
                                      //Validation_Status__c = 'Validated',    
                                      Transport_Zone__c='US00000001',Partner_Type__c= '0015');
           

            // get a list of accounts to use for testing
            List<Account> accountList = createAccounts(10);
            
            // create system admin to run test
            User u1 = Testdatafactory.createUser(false,'Sam', 'Test1');
            User salesUser = Testdatafactory.createSalesUser(false,'Mary', 'Test2');
            
            test.StartTest();

               AccountCreateController.isTriggerExecuting = false;
               AccountCreateController.isFirstRun = true;    
                
               // make a change to initiate update
               //accountList[0].Applix_Account__c = 20040001;
               accountList[0].Validation_Status__c = 'Awaiting Validation';
               update accountList[0];

               //System.assertEquals(20040001,accountList[0].Applix_Account__c);
               System.assertEquals('Awaiting Validation',accountList[0].Validation_Status__c);
               
               /* test no sales org  */
               System.debug('Running test for no sales org');
               AccountCreateController.isTriggerExecuting = false;
               AccountCreateController.isFirstRun = true;
               try{  
                   accountList[1].Validation_Status__c = 'Validated';
                   update accountList[1];
                   system.debug('Sales Org Found');
               }
               catch(Exception e){
                    system.debug('Error ' + e.getMessage());
                    System.assert(e.getMessage().contains('Account Record Must Include Sales Organization Data'));
               }
               
               /* test no partner type  */
               System.debug('Running test for no partner type');
               AccountCreateController.isTriggerExecuting = false;
               AccountCreateController.isFirstRun = true;
               try{
                   accountList[2].Validation_Status__c = 'Validated';
                   accountList[2].Partner_Type__c = '';        
                   SAP_Sales_Org__c sso2 = Testdatafactory.createSalesOrg(accountList[2].Id);    
                   update accountList[2]; 
                   system.debug('Partner Type Found');
               }
               catch(Exception e){
                    system.debug('Error ' + e.getMessage());
                    System.assert(e.getMessage().contains('Account Record Must Include Partner Type'));
               }
                
               /* test no transportation zone  */
               System.debug('Running test for no transportation zone');
               AccountCreateController.isTriggerExecuting = false;
               AccountCreateController.isFirstRun = true;
               try{
                   accountList[2].Validation_Status__c = 'Validated';
                   accountList[2].Partner_Type__c= '0015';
                   accountList[2].Transport_Zone__c = ''; 
                   update accountList[2];
               }
               catch(Exception e){
                    system.debug('Error ' + e.getMessage());
                    System.assert(e.getMessage().contains('Account Record Must Include Transportation Zone'));
               }
                
               /* test invalid record type */
               System.debug('Running test for invalid record type');
               AccountCreateController.isTriggerExecuting = false;
               AccountCreateController.isFirstRun = true;
               try{
                   accountList[2].Validation_Status__c = 'Validated';
                   accountList[2].Partner_Type__c= '0015';
                   accountList[2].Transport_Zone__c='US00000001'; 
                   accountList[2].RecordTypeId = recTypeAccount;
                   accountList[2].Facility_Type__c='Children\'s Hospital';
                   update accountList[2];    
                   system.debug('Valid Record Type');
               }
               catch(Exception e){
                    system.debug('Error ' + e.getMessage());
                    System.assert(e.getMessage().contains('Account Record Type Must be \'NAA Customer\' or \'International\'.'));
               }
             
               /* test validation */
               System.debug('Running test for validation');
               AccountCreateController.isTriggerExecuting = false;
               AccountCreateController.isFirstRun = true;
               accountList[2].Validation_Status__c = 'Validated';
               accountList[2].Partner_Type__c= '0015';
               accountList[2].Transport_Zone__c='US00000001'; 
               accountList[2].RecordTypeId = recTypeAccount;
               update accountList[2];
               System.assertEquals('Validated',accountList[2].Validation_Status__c);

               // test after insert
               acct.ParentId = accountList[3].Id;
               acct.Shipping_Instructions__c = 'Test01';
               insert acct;
               System.assertEquals(acct.ParentId,accountList[3].Id);
               System.assertNotEquals(null,acct.Id);
                
               // test after update
               acct.Shipping_Instructions__c = 'new01';
               update acct;
               System.assertEquals('new01',acct.Shipping_Instructions__c);   
                
               Account acct2 = new Account(name='t'+system.now().millisecond()+math.round(math.random()*10000),Account_role__c='ZCSN',
                                            Transportation_Zone_Country__c = 'US',Primary_Language__c = 'EN',
                                            Country_Cluster__c = 'US&CA',Division_Account__c = 'Atlantic',Region__c = 'Central',Account_Territory__c='East OH',
                                            BillingCountryCode = 'AZ',RecordtypeId = recTypeAccount,
                                            Account_Status__c = 'Active',IsDeleted__c = false,  
                                            Transport_Zone__c='US00000001',Partner_Type__c= '0015'); 
               // need sap account id to satisfy sales org workflow
               acct2.SAP_Account_ID__c = '500300';
               insert acct2;
  
               SAP_Sales_Org__c sso5 = Testdatafactory.createSalesOrg(acct2.Id); 
               
               System.debug('Running test for User Not Permitted');
               AccountCreateController.isTriggerExecuting = false;
               AccountCreateController.isFirstRun = true;
               try{
                    acct2.Validation_Status__c = 'Validated';
                   	acct2.Facility_Type__c='Children\'s Hospital';
                    update acct2;
               }
               catch(Exception e){
                    system.debug('Error ' + e.getMessage());
                    System.assert(e.getMessage().contains('You do not have permission to change a validated account'));
               }
   
            test.StopTest();
       } 
    static testmethod void validatedAcctest(){
        User u = [select id from User where firstname = 'TestUser'];
        System.runAs(u){
        AccountCreateController.isFirstRun= false;
        Account acc = new Account(name='t1'+system.now().millisecond()+math.round(math.random()*10000),Account_role__c='ZCSN',
                                  Account_Status__c = 'Active',IsDeleted__c = false,BillingCountryCode='US',
                         BillingStreet='200 South Bascom Avenue',BillingCountry='united states', BillingCity='San Jose', BillingState='California',
                          BillingPostalCode='95128',Transport_Zone__c='IN00000001',
                                  SAP_Account_ID__c='123456'+system.now().millisecond()+math.round(math.random()*10000),
                                  Validation_Status__c = 'Validated',Country_Cluster__c='UK&I',Division_Account__c ='MA',Region__c='',
                                  Account_Territory__c='',Facility_Type__c='Children\'s Hospital');
        Id recTypeAccount = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'International Customer' LIMIT 1].Id; 
        acc.RecordTypeId = recTypeAccount;
        insert acc; 
        //Account acc = TestDataFactory.createTestAccountQuotePrint();
        //List<Account> accList = New List<Account>();
        //accList.add(acc);
        Map<Id,SObject> accmapOld = new Map<Id,SObject>{acc.Id => acc};
        //acc.Validation_Status__c = 'Validated';
        AccountCreateController.isFirstRun= true;
        AccountCreateController.isTriggerExecuting = false;
        Test.startTest();
            AccountTriggerHandler.checkGPORelation(new List<Id>{acc.Id});
            try{
            update acc;
            }catch(DMLException e){
                System.assert(e.getMessage().contains('You do not have permission to change a validated account'));
            }
            Map<Id,SObject> accmap = new Map<Id,SObject>();
            accmap.put(acc.id, acc); 
            AccountTriggerHandler.AllowSaveWithoutPermission(accmap.values(), accmapOld);
            delete acc;
        Test.stopTest();
        }
    }
       // create account data
       static List<Account> createAccounts(Integer numberOfAccounts){
            List<Account> accList=new List<Account>();   
            for(Integer i=0;i<numberOfAccounts;i++){
                Account acc = Testdatafactory.createUSTestAccount();
                accList.add(acc);
            }
            return accList;
       }
    
    @isTest
    private static void accIsDeletedTest(){
        
        List<Account> accList = Testdatafactory.createAccounts(2);
        insert accList;
        
        Opportunity opp = Testdatafactory.createOppWithAccount();
        opp.AccountId = accList[1].id;
        update opp;
        
        User usr = Testdatafactory.createUser(true, 'TestFName', 'TestLName');
        
        AccountTeamMember atm = new AccountTeamMember(AccountId = accList[0].Id, UserId = usr.Id, TeamMemberRole = 'System Sales Director');
        insert atm;
        
        OpportunityTeamMember otm = new OpportunityTeamMember(OpportunityId = opp.Id, UserId = usr.Id, TeamMemberRole = 'System Sales Director');
        insert otm;
        
        CastIronIntegration__c  setting = new CastIronIntegration__c ();
        setting.Name = 'CastIronIntegration';
        setting.ContactInsertEndpoint__c = 'https://castirondatadev.omnicell.com/ContactSFToCRM';
        setting.ContactUpdateEndpoint__c = 'https://castirondatadev.omnicell.com/ContactSFToCRMUpdate';
        setting.AccountRole_SoldTo__c='ZCSN';
        insert setting;
        
        Contact retCon = new Contact();
        retCon.AccountId = accList[0].Id;
        retCon.Salesforce_Contact_ID__c ='5678';
        retCon.SAP_Contact_GUID__c = '3467';
        retCon.LastName = 'TestLName';
        insert retCon;
        
        
        List<Account> accList2Update = new List<Account>();
        for(Account acc: accList){
            acc.IsDeleted__c = true;
            accList2Update.add(acc);
        }
        
        update accList2Update;
    }
    // added to test changeowner method by tribhhuvan singh
   /* @isTest static void changeOwnerTest(){
        Map<Id, Account> oldMap = new Map<Id, Account>();
        Map<Id, Account> newMap = new Map<Id, Account>();
        List<Account> actlist = new List<Account>();
        //Added by Sravan
        User usr1 = Testdatafactory.createUser(true, 'TestFName1', 'TestLName1');
        User usr2 = Testdatafactory.createUser(true, 'TestFName2', 'TestLName2');
        Id recTypeAccountUS = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'US & Canada Customer' LIMIT 1].Id;
        Account act = new Account(name='My New Account',Account_role__c='ZCSN',
                                      Transportation_Zone_Country__c = 'US',Primary_Language__c = 'EN',
                                      Country_Cluster__c = 'US&CA',Division_Account__c = 'Atlantic',Region__c = 'Central',Account_Territory__c='East OH',
                                      BillingCountryCode = 'AZ',RecordtypeId = recTypeAccountUS,
                                      Account_Status__c = 'Active',IsDeleted__c = false,
                                      //Validation_Status__c = 'Validated',    
                                      Transport_Zone__c='US00000001',Partner_Type__c= '0015', ownerId= usr1.Id);
        insert act;
        oldMap.put(act.Id, act);
        
        test.startTest();
        act.OwnerId = usr2.Id;
        try{
        update act;
        newMap.put(act.id, act);
        }
        catch(Exception e){
         system.debug('Exception Message: '+e);
             //System.assert(e.getMessage().contains('You do not have permission to change a validated account'));
        }
        actlist.add(act);
        AccountTriggerHandler.changeOwner(oldMap, newMap, actlist);
        Test.stopTest();
    }*/
}