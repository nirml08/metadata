/**********************************************************************
Name:      AccountTriggerHandler
Purpose:   Calls AccountCreateController to update a SAP Account
Copyright © 2018
=======================================================================
History :
-----------------------------------------------------------------------
Developer                  Date                Description
-------------------------------------------------------------- --------
Linda Neel                 7/1/2018            Initial Creation
Andrew Hilsher             8/29/2018           Added setting Transportation Zone Country in Before Update

************************************************************************/
public class AccountTriggerHandler implements ITriggerHandler{
    // Allows unit test (or other code) to disable this trigger for the transaction
    public static boolean TriggerDisabled= false;
    public boolean isDisabled;
    public boolean isValidationStatusChanged;
    public static boolean isOppInsert = false;//added by sravan for SF-BUG-518
    // Check to see if the trigger has been disabled by either custom setting or code
    public boolean IsDisabled(){
        
        Trigger_Configuration__c tc = Trigger_Configuration__c.getInstance('AccountTriggerDisabled');
        if(tc != null) isDisabled = tc.isDisabled__c;
        if(isDisabled == true)
            return true;
        else
            return TriggerDisabled;
    }
    
    //=============================================================================
    // BEFORE INSERT
    //=============================================================================
    public void beforeInsert(List<SObject> newItems){
        
        //Method to populate top level parent
        // getTopLevelParent(newItems);
        
        // update the currency of newly created account according to the table in custom settings
        List<Account> newAccnts= newItems;     
        for (Account a : newAccnts) { 
            a.CurrencyIsoCode = Default_Currency_by_Country_Code__c.getValues(a.BillingCountryCode) != null ? Default_Currency_by_Country_Code__c.getValues(a.BillingCountryCode).Currency_Code__c : 'USD'; 
        }           
        definitivePopulate(newAccnts);
        //checkGDPR(newAccnts);
        
    }
    //=============================================================================
    // BEFORE DELETE
    //=============================================================================
    public void beforeDelete(Map<Id, SObject> oldItems){
        // mark custom isDeleted so doesnot move to salesforce delete 
        //List<Account> accnts= oldItems.values();
        //for (Account a : accnts) {
        //    a.IsDeleted__c = true;
        //} 
    }
    //=============================================================================
    // BEFORE UPDATE
    //=============================================================================
    
    public void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newItems){
        
        //Method to populate top level parent
        // getTopLevelParent(newItems.values());
        System.Debug('Account Trigger Before Update '); 
        System.Debug('Account Trigger Is Executing ' + AccountCreateController.isTriggerExecuting); 
        System.Debug('Account Trigger first Run ' + AccountCreateController.isFirstRun);
	    //comment added
        List<Account> newAccounts= newItems.values();     
        system.debug('newAccounts----' + newAccounts);      
        
        definitivePopulate(newItems.values());
        if (!AccountCreateController.isTriggerExecuting && AccountCreateController.isFirstRun ){
            
            boolean user_has_permission = checkUserPermission();
            Map<string,id> recordTypeMap = getRecordTypes();
            
            List<Account> newAccnts = newItems.values();
            List<Account> oldAccnts = oldMap.values(); 
            Map<Id, Account> oldItems = new Map<Id, Account>(oldAccnts);
            /* allow change to validate if user has persmission to validate account
if((newAccnts != null && newAccnts.size() > 0) && (oldAccnts != null && oldAccnts.size() > 0)){         
for(Account n : newAccnts){
Account pv = (Account)oldItems.get(n.Id);           
// if incommng status is validate and its not the same as previous
if( (n.Validation_Status__c != pv.Validation_Status__c)){
isValidationStatusChanged = true;
}
else{
isValidationStatusChanged = false;
}
}
}
*/
            
            if((newAccnts != null && newAccnts.size() > 0) && (oldAccnts != null && oldAccnts.size() > 0)){  
                for (Account a : newAccnts) {
                    System.debug('User is Permitted  ' + user_has_permission);
                    if(a.Name == oldItems.get(a.Id).Name && a.Account_Name2__c == oldItems.get(a.Id).Account_Name2__c 
                       && a.Account_Name3__c == oldItems.get(a.Id).Account_Name3__c && a.Account_Name4__c == oldItems.get(a.Id).Account_Name4__c
                       && a.Address_Line_2__c == oldItems.get(a.Id).Address_Line_2__c
                       && a.Validation_Status__c == oldItems.get(a.Id).Validation_Status__c 
                       && a.IsDeleted__c == oldItems.get(a.Id).IsDeleted__c && a.Transport_Zone__c == oldItems.get(a.Id).Transport_Zone__c 
                       && a.Website == oldItems.get(a.Id).Website && a.Search_Term__c == oldItems.get(a.Id).Search_Term__c
                       && a.Account_Territory__c == oldItems.get(a.Id).Account_Territory__c && a.Primary_Language__c == oldItems.get(a.Id).Primary_Language__c
                       && a.Master_Agreement__c == oldItems.get(a.Id).Master_Agreement__c && a.Partner_Type__c == oldItems.get(a.Id).Partner_Type__c 
                       && a.BillingCountryCode == oldItems.get(a.Id).BillingCountryCode && a.BillingStreet == oldItems.get(a.Id).BillingStreet 
                       && a.BillingStateCode == oldItems.get(a.Id).BillingStateCode && a.BillingCity == oldItems.get(a.Id).BillingCity
                       && a.BillingCountry == oldItems.get(a.Id).BillingCountry && a.BillingPostalCode == oldItems.get(a.Id).BillingPostalCode
                       && a.Account_Status__c == oldItems.get(a.Id).Account_Status__c && a.Account_Role__c  == oldItems.get(a.Id).Account_Role__c
                       && a.Phone == oldItems.get(a.Id).Phone && a.Classification__c    == oldItems.get(a.Id).Classification__c
                       && a.Po_Box__c == oldItems.get(a.Id).Po_Box__c/* && a.Customer_Class__c == oldItems.get(a.Id).Customer_Class__c*/
                       /*&& a.Pricing_Code__c == oldItems.get(a.Id).Pricing_Code__c && a.Agreement_Type__c  == oldItems.get(a.Id).Agreement_Type__c
&& a.Credit_Rating__c == oldItems.get(a.Id).Credit_Rating__c*/) continue;
                    
                    //set the Transportation Zone Country based upon the Billing Address Country
                    //so the dependent picklist on Transportation Zone shows filtered list.
                    if ((a.BillingCountryCode!=null)&&(a.BillingCountryCode!='')) {
                        a.Transportation_Zone_Country__c=a.BillingCountryCode;
                    }
                    
                    // Must have permission and set status to Validated
                    if(user_has_permission && a.Validation_Status__c == 'Validated') {
                        
                        // Must be International Or US Customer
                        Id us_customer = recordTypeMap.get('US & Canada Customer');
                        Id international_customer = recordTypeMap.get('International Customer');
                        Id uk_customer = recordTypeMap.get('UK Customer');
                        
                        // Must include Sales Organization
                        integer orgCount = checkSalesOrgData(a.Id);
                        
                        boolean has_sales_org = (orgCount > 0) ? true : false;
                        boolean has_transport_zone = (a.Transport_Zone__c != null && a.Transport_Zone__c != '') ? true : false;
                        boolean has_partner_type = (a.Partner_Type__c != null && a.Partner_Type__c != '') ? true : false;
                        boolean has_customer_type = (a.RecordTypeId == us_customer || a.RecordTypeId == international_customer || a.RecordTypeId == uk_customer) ? true : false;
                        boolean has_master_agree  = (a.Master_Agreement__c != null && a.Master_Agreement__c != '') ? true : false;
                        
                        System.debug(has_sales_org + ' ' + has_transport_zone + ' ' + has_partner_type + ' ' + has_customer_type);
                        
                        //if (has_sales_org && has_customer_type && has_transport_zone && has_partner_type && has_master_agree){
                        if (has_sales_org && has_customer_type && has_transport_zone && has_partner_type ){    
                            System.debug('Calling Controller  ' + AccountCreateController.isFirstRun);
                            
                            // get old values from map - use if callout fails
                            Account olditem = (Account)oldItems.get(a.Id);
                            String oldAccountValues = json.serialize(olditem); 
                            
                            if(!Test.isRunningTest()){
                                AccountCreateController.CreateAccountFromProspect(a.Id, oldAccountValues);
                            }
                        }
                        else {
                            if (!has_sales_org){
                                System.debug('Trigger Update no sales org  ');
                                a.addError('Account Record Must Include Sales Organization Data.');
                            }
                            else if (!has_partner_type) { 
                                System.debug('Trigger Update no partner type  ');
                                a.addError('Account Record Must Include Partner Type.');
                            }
                            else if (!has_transport_zone) { 
                                System.debug('Trigger Update no transportation zone  ');
                                a.addError('Account Record Must Include Transportation Zone.'); 
                            }
                            else if (!has_customer_type) { 
                                System.debug('Trigger Update invalid account type ');
                                a.addError('Account Record Type Must be \'NAA Customer\' or \'International\'.');
                            } 
                            else if (!has_master_agree) { 
                                //edited by Andrew 12/5
                                //   System.debug('Trigger Update invalid master agreement ');
                                //   a.addError('Account Record Must Include Master Agreement Number.');
                            }
                        } 
                    }
                    else{ 
                        // user does not have persmission
                        if(a.Validation_Status__c == 'Validated') {
                            // status is 'Validated" and user does not have persmission
                            // only allow non SAP fields to be updated
                            boolean allowUpdate = AllowSaveWithoutPermission(newAccnts, oldItems);
                            system.debug('Allow ' + allowUpdate);
                            
                            if (!allowUpdate){ 
                                System.debug('User Not authorized');
                                a.addError('You do not have permission to change a validated account.'); 
                            }
                        }
                    }
                }
            } 
        }
        System.Debug('Account Trigger Reset First Run '); 
        AccountCreateController.isFirstRun = false;
        
        /* List<Account> newAccnts = newItems.values();
List<Id> newIds = new List<Id>();
for(Account a : newAccnts){
newIds.add(a.Id);
}
checkGPORelation(newIds);*/
    }
    //=============================================================================
    // AFTER DELETE
    //=============================================================================
    public void afterDelete(Map<Id, SObject> oldItems){
        
    }
    
    //=============================================================================
    // AFTER UNUPDATE
    //=============================================================================
    public void afterUndelete(Map<Id, SObject> oldItems){
        
    }
    //=============================================================================
    // AFTER INSERT
    //=============================================================================
    public void afterInsert(Map<Id, SObject> newItems){
        List<FeedItem> listofFeed = new List<FeedItem>();
        List<Account> accnts= newItems.values();
        
        accountOwnerToATM(accnts);
        
        for (Account a : accnts) { 
            if(a.parentId != null){
                FeedItem fd = new FeedItem();
                fd.ParentId = a.parentId;
                fd.Body = 'New Child Account Created '+ 'Name : '+a.name+'  Id : '+a.id;
                listofFeed.add(fd);
            }
        }
        insert listofFeed;
        System.debug('listofFeed');    
    } 
    //=============================================================================
    // AFTER UPDATE
    //=============================================================================
    public void afterUpdate(Map<Id, SObject> oldItems, Map<Id, SObject> newItems){
        //Written By Venu Kukkapalli
        List<Account> accList = newItems.values();
        List<Account> delAccList = new List<Account>();
        List<Account> gdprAccList = new List<Account>();
        List<Account> oldAccountOwnerList = new List<Account>();
        List<Account> ownerChangeAccList = new List<Account>();
        Map<Id,Id> ownerChangeAccMap = new Map<Id, Id>();
        for(Account acc: accList){
            Account ac = (Account)oldItems.get(acc.id);
            if(ac.IsDeleted__c != acc.IsDeleted__c && acc.IsDeleted__c == TRUE && !delAccList.contains(acc)){
                delAccList.add(acc);                
            }
            if(ac.GDPR__c != acc.GDPR__c && !gdprAccList.contains(acc)){
                gdprAccList.add(acc);
            }
            // Added by Venu Kukkapalli as part of bug -266 fix 
            if(ac.OwnerId != acc.OwnerId){
                if(!ownerChangeAccList.contains(acc))
                    ownerChangeAccList.add(acc);
                if(!ownerChangeAccMap.containsKey(acc.Id))
                    ownerChangeAccMap.put(acc.Id,ac.OwnerId);
                if(!oldAccountOwnerList.contains(ac))
                    oldAccountOwnerList.add(ac);
            }
        }
        if(ownerChangeAccList.size()>0)
            deleteAccOwnerFromATM(ownerChangeAccMap);
        if(ownerChangeAccList.size()>0)
            accountOwnerToATM(ownerChangeAccList);
        if(oldAccountOwnerList.size()>0)
            deleteAccOwner(oldAccountOwnerList);
        List<Opportunity> optyList = [SELECT Id,AccountId,CustomerType__c, IV_Product_Line__c,Performance_Center_Product_Line__c   FROM Opportunity WHERE stageName != '6 Closed Won' AND stageName !='7 Closed Lost' AND AccountId IN: ownerChangeAccList];
        OpportunityTriggerHandler oth = new OpportunityTriggerHandler();
        System.debug(optyList);
        if(optyList.size()>0)
            oth.populateOpportunityTeam(optyList);
        
        //
        //Added by Sravan
        /*List<Account> oldacnts = oldItems.values();
for(Integer i=0;i<accList.size();i++){
if(oldacnts[i].Account_Territory__c != accList[i].Account_Territory__c){
delAccList.add(accList[i]);
}
}*/
        System.debug(delAccList);
        if(delAccList.size()>0){
            deleteAccountTeam(delAccList);      
            //Commented by Venu Kukkapalli on 25-05-2019 
            //deleteOpportunityTeam(delAccList);
            updateContactOwner(delAccList);
        }
        //////////////////
        System.debug('oldItems'+oldItems); 
        List<FeedItem> listofFeed = new List<FeedItem>();
        List<Account> accnts= newItems.values();
        List<Account> oldAccnts = oldItems.values();
        System.debug('accnts'+accnts);
        List<Id> accIds = new List<Id>();
        for(Account a : accnts){
            for(Account old : oldAccnts){
                if((a.id == old.id) && a.Shipping_Instructions__c  != old.Shipping_Instructions__c )
                    accIds.add(a.id);
            }
            
            
        }
        for (Account a : accnts) {
            
            if(a.parentId != null){
                FeedItem fd = new FeedItem();
                fd.ParentId = a.parentId;
                fd.Body = 'Child Account updated : '+'  Name : '+a.name+'  Id : '+a.id;
                listofFeed.add(fd);
            }
            
        }
        insert listofFeed;
        System.debug('listofFeed');
        if(accIds.size()>0){
            updateQuotes(accIds);
            
        }
        if(!isOppInsert){//added by sravan for SF-BUG-518
            updateHasOpportunityOnTargetInitiativeAccount(accnts,oldAccnts);
            sendAllContactsToCastIron(accnts,oldAccnts);
            //changeOwner(oldItems, newItems, accnts);
        }
       // updateChildAccounts(oldItems, newItems);
    }
   /* public static void updateChildAccounts(Map<Id, SObject> oldItems, Map<Id, SObject> newItems)
    {        
        list<Account> parentAccounts = new list<Account>();
        for(Account newAcc : (list<Account>)newItems.values())
        {            
            Account oldAcc = (Account)oldItems.get(newAcc.Id);
            if(newAcc.Is_Top_200__c != oldAcc.Is_Top_200__c && newAcc.Account_Role__c == 'ZCSN')
            {
               parentAccounts.add(newAcc);
            }
        }
        if(parentAccounts.isEmpty()) return;
        
        list<Account> childAccounts = [SELECT Id,Name,Parent.Is_Top_200__c FROM Account WHERE ParentId IN: parentAccounts AND Account_Role__c = 'ZCSN'];
        for(Account acc : childAccounts)
        {
            acc.Is_Top_200__c = acc.Parent.Is_Top_200__c;
        }
        update childAccounts;
    }*/
    //If Account has Opportunity, then updates "Has Opportunity" check box as true on Target_Initiative_Account__c object
    public void updateHasOpportunityOnTargetInitiativeAccount(List<Account> accnts,List<Account> oldAccnts)
    {
        system.debug('accnts....'+trigger.New);
        set<Id> acctid = new set<Id>();
        set<Id> taregtid = new set<Id>();
        List<Target_Initiative_Account__c> tiaList = new List<Target_Initiative_Account__c>();
        //soumyad
        set<Target_Initiative_Account__c> updatetiaList = new set<Target_Initiative_Account__c>();
        List<Target_Initiative_Account__c> updatetiaList1 = new List<Target_Initiative_Account__c>();           
        //soumyad
        
        if(accnts.size()>0)
        {
            for(Account act : accnts)
            {
                acctid.add(act.Id);
                system.debug('acctid....'+acctid);
            }
        }
        
        tiaList = [select id,Has_Opportunities__c,Account__c,Target_Initiative__r.id from Target_Initiative_Account__c where Account__r.Id IN:acctid];
        system.debug('tiaList...'+tiaList);
        
        //soumyad
        List<Target_Initiative_Opportunity__c> tiopList = new List<Target_Initiative_Opportunity__c>();
        //string tarint = tiaList[0].Target_Initiative__r.id;
        //system.debug('tarint ...'+tarint);
        for(Target_Initiative_Account__c ti: tiaList)
        {
            tiopList = [select Opportunity__r.Account.NAME from Target_Initiative_Opportunity__c where Target_Initiative__r.id= :ti.Target_Initiative__r.id];
        }
        system.debug('tiopList ...'+tiopList);
        List<opportunity> oppid = new List<opportunity>();
        oppid = [SELECT Id, name FROM Opportunity WHERE Account.Id IN:acctid];
        system.debug('oppid ...'+oppid);
        
        //soumyad
        
        for(Account a: accnts)
        {
            if(a.of_Active_Commit_Opportunities__c>0 || a.Num_of_Active_Opportunities__c>0 || a.of_Active_Pipeline_Opportunities__c>0 ||
               a.of_Active_Strong_Upside_Opportunities__c >0 || a.of_Active_Upside_Opportunities__c >0)
            {
                if(tiaList.size()>0)
                {
                    //system.debug('size ...'+tiaList.size());
                    for(Target_Initiative_Account__c t: tiaList)
                    {
                        //soumyad
                        
                        for(Target_Initiative_Opportunity__c t1: tiopList)
                        {
                            //system.debug('t1 ...'+t1.Opportunity__r.id);
                            for(opportunity t2: oppid)
                            {
                                //system.debug('t2 ...'+t2.id);
                                if(t1.Opportunity__r.id == t2.id){
                                    //system.debug('t2 ...'+t2.id);
                                    t.Has_Opportunities__c= true;
                                    //system.debug('t.Has_Opportunities__c...'+t.Has_Opportunities__c);
                                    updatetiaList.add(t);
                                    
                                }
                            }                            
                        }
                        //soumyad             
                    }
                }   
            }
        }
        
        updatetiaList1.addall(updatetiaList);
        try{
            if(updatetiaList.size()>0)
            {
                update updatetiaList1;
            }
        }  
        catch(Exception e){
            System.debug('Exception : '+e.getMessage()+' Line no. : '+e.getLineNumber());
        }
        
    }
    // Added by Venu Kukkapalli as part of bug 266 fix to delete account owner from opportunity Team when account owner gets updated
    public void deleteAccOwner(List<Account> oldAccList){
        Map<Id, List<OpportunityTeamMember>> accOtmMap= new Map<Id, List<OpportunityTeamMember>>();
        List<OpportunityTeamMember> delOtmList = new List<OpportunityTeamMember>();
        for(Opportunity opp: [SELECT Id,AccountId, (SELECT Id, OpportunityId, UserId, TeamMemberRole FROM OpportunityTeamMembers) FROM Opportunity WHERE stageName != '6 Closed Won' AND stageName !='7 Closed Lost' AND AccountId  IN: oldAccList]){
            for(OpportunityTeamMember otm: opp.OpportunityTeamMembers){
                if(!accOtmMap.containsKey(opp.AccountId))
                    accOtmMap.put(opp.AccountId, new List<OpportunityTeamMember>());
                accOtmMap.get(opp.AccountId).add(otm);
            }
        }
        for(Account acc: oldAccList){
            if(accOtmMap.containsKey(acc.Id)){
                for(OpportunityTeamMember otm : accOtmMap.get(acc.Id)){
                    if(acc.OwnerId == otm.UserId && !delOtmList.contains(otm))
                        delOtmList.add(otm);
                }
            }
        }
        delete delOtmList;
    }
    //Written Venu Kukkapalli to delete old account owner from Account team members when account owner updated
    public void deleteAccOwnerFromATM(Map<Id,Id> accOwnerMap){
        List<AccountTeamMember> atmList = new List<AccountTeamMember>();
        for(Account acc:[SELECT Id, OwnerId,(SELECT Id, userId FROM AccountTeamMembers) FROM Account WHERE Id IN: accOwnerMap.keyset()]){
            for(AccountTeamMember atm:acc.AccountTeamMembers){
                if(atm.UserId == accOwnerMap.get(acc.Id) && !atmList.contains(atm))
                    atmList.add(atm);
            }
        }
        delete atmList;
    }
    //Written by Venu Kukkapalli to populate account owner to account team members with the role Account owner
    public void accountOwnerToATM(List<Account> accList){
        List<AccountTeamMember> atmList = new List<AccountTeamMember>();
        for(Account acc:accList){
            AccountTeamMember atm = new AccountTeamMember();
            atm.UserId = acc.ownerId;
            atm.TeamMemberRole = 'Account Owner';
            atm.AccountId = acc.Id;
            atm.AccountAccessLevel = 'Read';
            atm.OpportunityAccessLevel = 'Edit';
            atm.ContactAccessLevel = 'Edit';            
            if(!atmList.contains(atm))
                atmList.add(atm);
        }
        if(atmList.size()>0)
            insert atmList;
    }
    public static void definitivePopulate(List<Account> accList){
        for(Account acc: accList){
            acc.Definitive_Id__c = String.valueof(acc.texcellency__DefHC_HospitalID__c);
        }
    }
    public static void checkGPORelation(List<Id> accIds){
        List<Account> accList = [select id,GPOCheck__c from Account where id=:accIds];
        List<Relationship__c> relgpo = [select id from Relationship__c where primary_account__c =:accIds and relationship__c = 'ZG'];
        if(relgpo.size()>0){
            for(Account a : accList){
                a.GPOCheck__c = true;
            }
        }
    }
    public static void updateQuotes(List<Id> accIds){
        System.debug('Inside Update Quotes');
        List<Quote> quotes = [select id,Opportunity.Account.shipping_instructions__c,AccountId,OpportunityId,shipping_instructions__c from Quote where accountid =:accIds];
        List<Quote> quotes1 = new List<Quote>();
        System.debug('Quotes Before update : '+quotes);
        for(Quote q:quotes){
            q.Shipping_Instructions__c = q.Opportunity.Account.shipping_instructions__c;
            q.Master_Agreement__c = q.Opportunity.Account.Master_Agreement__c;
            quotes1.add(q);
        }
        update quotes1;
        System.debug('Quotes After update : '+quotes1);
    }
    
    public static boolean checkUserPermission(){
        
        Boolean user_has_permission = false;
        List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>([SELECT PermissionSet.Name FROM PermissionSetAssignment 
                                                                                   WHERE AssigneeId=:UserInfo.getUserId() AND PermissionSet.Name ='Permission_to_update_SAP_Accounts']);
        User u = [SELECT UserRole.Name,Profile.Name FROM User WHERE Id=:UserInfo.getUserId()];
        if ( !psaList.isEmpty() || u.Profile.Name=='System Administrator' ){        
            user_has_permission= true;  
        }
        return user_has_permission;
    }
    
    public static boolean AllowSaveWithoutPermission(List<Account> newAccnts,Map<Id, SObject> oldItems){
        
        boolean hasFieldChanged = true;
        string accountRole;
        
        if((newAccnts != null && newAccnts.size() > 0) && (oldItems != null && oldItems.size() > 0)) {
            
            for(Account n : newAccnts){
                
                // if this is a validated account
                if (n.Validation_Status__c == 'Validated') {
                    
                    //translate account role for new account
                    if (n.Account_Role__c == 'ZGPO' || n.Account_Role__c == 'ZIDN'){ accountRole = 'ZCSP'; } else accountRole = n.Account_Role__c; 
                    
                    // get the old values
                    Account pv = (Account)oldItems.get(n.Id);
                    
                    // has required fields been changed
                    if( (n.Validation_Status__c != pv.Validation_Status__c)){
                        hasFieldChanged = false;
                    }
                    else if( (n.RecordTypeId != pv.RecordTypeId)){
                        hasFieldChanged = false;
                    }
                    else if( (n.IsDeleted__c != pv.IsDeleted__c)){
                        hasFieldChanged = false;
                    }                   
                    else if( (n.Transport_Zone__c != pv.Transport_Zone__c)){
                        hasFieldChanged = false;
                    }
                    else if( (accountrole != pv.Account_Role__c)){
                        hasFieldChanged = false;
                    }
                    else if( (n.Transport_Zone__c != pv.Transport_Zone__c)){
                        hasFieldChanged = false;
                    }
                    else if( (n.Account_Territory__c != pv.Account_Territory__c)){
                        hasFieldChanged = false;
                    }
                    else if( (n.SAP_Account_ID__c != pv.SAP_Account_ID__c)){
                        hasFieldChanged = false;
                    }
                    /* Below lines are commented and replaced for SF-BUG-547
                    else if( (n.Primary_Language__c != pv.Primary_Language__c)){
                        hasFieldChanged = false;
                    }*/
                    /* Below lines are added for SF-BUG-547 */
                    else if( (n.Primary_Language__c != pv.Primary_Language__c)){
					   User u = [select profile.Name from User where profileid =: UserInfo.getProfileId() limit 1];
								System.debug('User Profile : '+u.profile.name);
								
								if ( u.profile.name == 'Sales Manager' ||
									 u.profile.name == 'Sales Representative' ||
									 u.profile.name == 'Sales Development' ||
									 u.profile.name == 'International Sales Representative' ||
									 u.profile.name == 'International Sales UK' ||
									 u.profile.name == 'International Sales France' ||
									 u.profile.name == 'International Sales Ops'  ||
									 u.profile.name == 'System Administrator' ||
									 u.profile.name == 'Business Administrator' )							 
									 {
                        				hasFieldChanged = true;}
						        else {  hasFieldChanged = false;}
							
                    }
                    
                    /* Above lines are added for SF-BUG-547 */
                    else if( (n.Master_Agreement__c != pv.Master_Agreement__c)){
                        hasFieldChanged = false;
                    }
                    else if( (n.Partner_Type__c != pv.Partner_Type__c)){
                        hasFieldChanged = false;
                    }
                    else if( (n.BillingCountryCode != pv.BillingCountryCode)){
                        hasFieldChanged = false;
                    }
                    else if( (n.BillingStreet != pv.BillingStreet)){
                        hasFieldChanged = false;
                    }
                    else if( (n.BillingStateCode != pv.BillingStateCode)){
                        hasFieldChanged = false;
                    }
                    else if( (n.BillingCity != pv.BillingCity)){
                        hasFieldChanged = false;
                    }
                    else if( (n.BillingCountry != pv.BillingCountry)){
                        hasFieldChanged = false;
                    }
                    else if( (n.BillingPostalCode != pv.BillingPostalCode)){
                        hasFieldChanged = false;
                    }
                    else if( (n.Account_Status__c != pv.Account_Status__c)){
                        hasFieldChanged = false;
                    }
                    else if( (n.Master_Agreement__c != pv.Master_Agreement__c)){
                        hasFieldChanged = false;
                    }
                } 
            }
        }
        return hasFieldChanged;
    }
    
    // check if sales org record exists for given account
    public static integer checkSalesOrgData(ID accountId){
        Integer count = [SELECT count() FROM SAP_Sales_Org__c where Account__c =: accountId];
        return count; 
    }
    
    //Method to get the map of recordType Name as key and recordTypeId as value 
    Public static Map<String,Id> getRecordTypes(){
        String obj='Account';
        Map<String,Id> recordTypeMap=new Map<String,Id>();
        if(obj!= null){
            for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByName().values()){
                recordTypeMap.put(recInfo.getName(),recInfo.getRecordTypeId());
            }
        }        
        return recordTypeMap;       
    }
    
    public static void deleteAccountTeam(List<Account> accList){
        List<AccountTeamMember> atmList = new List<AccountTeamMember>();
        List<Account> accList1 = [SELECT Id,(SELECT Id FROM AccountTeamMembers) FROM Account WHERE Id in: accList];
        for(Account acc: accList1){
            If(acc.accountTeamMembers.size()>0){
                for(AccountTeamMember atm : acc.accountTeamMembers){
                    atmList.add(atm);
                }
            }
        }
        if(atmList.size()>0)
            delete atmList;
    }
    /*public static void deleteOpportunityTeam(List<Account> accList){
List<OpportunityTeamMember> otmList = new List<OpportunityTeamMember>();
for(Opportunity opp:[SELECT Id,AccountId,(SELECT Id FROM OpportunityTeamMembers) FROM Opportunity WHERE AccountId In: accList]){
If(opp.OpportunityTeamMembers.size()>0){
for(OpportunityTeamMember otm : opp.OpportunityTeamMembers){
otmList.add(otm);
}
}
}
if(otmList.size()>0)
delete otmList;
}*/
    public static void updateContactOwner(List<Account> accnts){
        System.debug(accnts);
        List<Contact> updateConList = new List<Contact>();
        List<Contact> conList = [SELECT Id, OwnerId, AccountId FROM Contact WHERE AccountId In: accnts];
        Id ownerId = (Id)Label.Admin_Integration_User_Id;
        System.debug(conList);
        for(Contact con : conList){
            if(ownerId!=NULL){
                con.OwnerId = ownerId; 
                con.Is_Active__c= 'N';
                con.Inactive_Reason__c=Label.ContactInactiveReason;
                System.debug('con' +con);
                if(!updateConList.contains(con))
                    updateConList.add(con);
            } 
        }
        try{    
            System.debug(updateConList);
            Database.update(updateConList,false);
        }
        Catch(Exception e){
            System.debug(e);
        }
    }
    
    //This method is to update associated contacts owner to Admin integration when account is_deleted__c =true
    /*public static void updateContactOwner1(List<Account> accnts){
System.debug(accnts);
List<Contact> conList = [SELECT Id, OwnerId, AccountId FROM Contact WHERE AccountId In: accnts];
List<AccountContactRelation> acrDelList = new List<AccountContactRelation>();
List<Contact> updateConList = new List<Contact>();

Map<Id, Integer> acrCountMap = new Map<Id, Integer>();
Map<String, AccountContactRelation> conAcrMap = new Map<String, AccountContactRelation>();

for(AccountContactRelation acr : [SELECT Id, ContactId, AccountId, IsDirect,roles FROM AccountContactRelation WHERE ContactId In: conList]){
String str = (String)acr.ContactId+(String)acr.AccountId; 
Integer count = 0; 
conAcrMap.put(str,acr);
if(!acrCountMap.containsKey(acr.ContactId))
acrCountMap.put(acr.ContactId,0);
count = acrCountMap.get(acr.ContactId);
count++;
acrCountMap.put(acr.ContactId,count);
}
Id ownerId = (Id)Label.Admin_Integration_User_Id;
for(Contact con : conList){
//if(acrCountMap.get(con.id)>1)
//{
//  String str = (String)con.Id+(String)con.AccountId;
//  if(!acrDelList.contains(conAcrMap.get(str)))
//  acrDelList.add(conAcrMap.get(str));
//}
//else
if(acrCountMap.get(con.id)==1){
System.debug('ownerId' +ownerId);
if(ownerId!=NULL){
con.OwnerId = ownerId;
con.Is_Active__c= 'N';
con.Inactive_Reason__c=Label.ContactInactiveReason;
System.debug('con' +con);
if(!updateConList.contains(con))
updateConList.add(con);
}
} 
}
try{
System.debug('updateConList' +updateConList);
Database.update(updateConList,false);
// Database.delete(acrDelList,false);
}
Catch(Exception e){
System.debug(e);
}       
}*/
    
    //If Account.Validation_Status__c=Validated && Account. SAP_Account_ID__c!=null and contacts which have SAP_Contact_ID__c='' then sending all those contacts to SAP,which are currently associated to this account.
    public void sendAllContactsToCastIron(List<Account> accnts,List<Account> oldAccnts)
    {
        
        List<Contact> conlist = new List<Contact>();
        set<Id> newconIds = new set<Id>();
        set<Id> oldaccid = new set<Id>();
        string sapacctid='';
        
        for(Account oldact: oldAccnts)
        {
            oldaccid.add(oldact.Id);
            system.debug('oldaccid..'+oldaccid);
            sapacctid = oldact.SAP_Account_ID__c;
            system.debug('sapacctid..'+sapacctid);
            
        }
        
        conlist=[select id,AccountId from contact where AccountId IN:oldaccid and SAP_Contact_ID__c=null];
        system.debug('conlist..'+conlist);
        
        
        
        for(Account a : accnts){
            if(a.Validation_Status__c=='Validated' && a.SAP_Account_ID__c!=null){
                system.debug('a.Validation_Status__c..'+a.Validation_Status__c);
                system.debug('a.SAP_Account_ID__c..'+a.SAP_Account_ID__c);
                if(conlist.size()>0)
                {
                    for(contact con : conlist)
                    {
                        if(con.AccountId == a.Id)
                        { 
                            system.debug('con.AccountId...'+con.AccountId);
                            newconIds.add(con.Id);
                            system.debug('newconIds...'+newconIds);
                        }
                    }
                }       
            }
        }         
        //if(System.IsBatch() == false && System.isFuture() == false && newconIds.size()>0)
        if(System.IsBatch() == false){
            system.debug('Check batch is running..');
            if(System.isFuture() == true){
                system.debug('Check future is running..');
                if(newconIds.size()>0)
                { 
                    system.debug('Check list size..');
                    //OmnicellContactToCastIron_Class.callOutMethodInsert(newconIds); // code added for the bulkification in the same insert method
                }
            }
        }
        
    }      
    // This method is to populate Top Level Parent of An Account
    /*Public void getTopLevelParent(List<Account> accList){
for(Account acc: accList){
Boolean topLevelParent = false;
Id id=acc.ParentId;
while ( !topLevelParent ) {
if(id!=null){
Account a = [ Select Id, ParentId From Account where Id =: id ];
if ( a.ParentID != null ) {
id = a.ParentID;
}
else {
id=a.id;
topLevelParent = true;
}
}
else{
topLevelParent = true;
}

}
if(id!=acc.Id)
acc.Top_Level_Parent__c =id;
}
}*/
    
    public static void validationBasedOnUsers(map<id, sObject>oldmap, map<id, sObject> newmap, list<Account> lstAcc){
        Schema.FieldSet fs1 = Schema.SObjectType.Account.fieldSets.getMap().get('AccountTeamPer');
        
        for(Account objAcNew : lstAcc){
            //Object o = objAcNew.get(fieldName);
            //String returnValue = String.valueOf(o);
        }
        //schema.describefieldresult dfield = sfield.getDescribe();
        //fieldsName.add(new SelectOption(dfield.getName(),dfield.getLabel()));
        /*<apex:repeat value="{!$ObjectType.Contact.FieldSets.properNames}" var="f"> 
        <apex:outputText value="{!Contact[f]}" /><br/>
    </apex:repeat>*/
        
    }
}
