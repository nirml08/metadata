/***********************************************************************************************************
Name:  AccountBusinessSegment_DELETE_Bacth
Copyright © 2018
============================================================================================================
============================================================================================================
Purpose: 
This Batch was scheduled at 1:00 AM, this Batch will delete all the Account_Business_Segment__c

============================================================================================================
=============================================================================================================
History                                                            
-------                                                            
VERSION      AUTHOR                      DATE             DETAIL               Description
0.1          Sravan          17/09/2019                             INITIAL DEVELOPMENT
*************************************************************************************************************/
global class AccountBusinessSegment_DELETE_Bacth implements DataBase.Batchable<sObject>{
    global AccountBusinessSegment_DELETE_Bacth(){        
    }
    
    global DataBase.QueryLocator start(Database.BatchableContext BC){        
        String query = 'select id,name from Account_Business_Segment__c where CreatedDate != TODAY';
        return Database.getQueryLocator(query);
    }
    
    global void execute(DataBase.BatchableContext BC, List<Account_Business_Segment__c> prodLineList){
    	if(prodLineList.size()>0){
        	delete prodLineList;
        }
    }
    //hello
    global void finish(DataBase.BatchableContext BC){
        AccountBusinessSegment_Batch_NEW schedule = new AccountBusinessSegment_Batch_NEW();
        database.executeBatch(schedule,300);
    }

}
