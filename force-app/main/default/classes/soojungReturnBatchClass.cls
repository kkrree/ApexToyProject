public with sharing class soojungReturnBatchClass implements Database.Batchable<sObject>{
    
    private string dummy_query;

    private Map<String, sObject> order_sj = new Map<String, sObject>();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // collect the batches of records or objects to be passed to execute
        // dummy 호출
        dummy_query = 'SELECT Id, Order_ID__c, Returned__c';
        dummy_query += ' FROM DUMMY_RETURN_SOOJUNG2__c';
        dummy_query += ' WHERE Batch_Flag__c =\'N\'';

        return Database.getQueryLocator(dummy_query);
    }
    
    public void execute(Database.BatchableContext bc, List<DUMMY_RETURN_SOOJUNG2__c> scopes){
        // process each batch of records

        for(DUMMY_RETURN_SOOJUNG2__c sc : scopes){
            // convert order's return status
            Order_Soojung__c order = new Order_Soojung__c();
            order.Order_ID__c = sc.Order_ID__c;
            if(sc.Returned__c == 'Yes'){
                order.Returned__c = True;
            }

            order_sj.put(order.Order_ID__c, order);

            //convert batchFlag
            sc.Batch_Flag__c = 'Y';
        }

        //upsert
        try{
            Database.upsert(order_sj.values(), Order_Soojung__c.Fields.Order_ID__c, True);
        //    Database.upsert(scopes, DUMMY_ORDER_SOOJUNG__c.Fields.Batch_Flag__c, True);
        }catch(DmlException e){
            System.debug(e.getMessage());
        }
    }
    
    public void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }
}
