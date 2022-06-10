public with sharing class soojungBatchClass implements Database.Batchable<sObject>{
    
    private string dummy_query;
    
    //collection 선언
    private Map<String, sObject> contact_sj = new Map<String, sObject>();
    private Map<String, sObject> order_sj = new Map<String, sObject>();
    private Map<String, sObject> product_sj = new Map<String, sObject>();
    private Map<String, sObject> store_sj = new Map<String, sObject>();
    private Map<String, sObject> user_sj = new Map<String, sObject>();
    private Map<String, sObject> orderProduct_sj = new Map<String, sObject>(); // order-MD | product-LK
    private Map<String, sObject> productStore_sj = new Map<String, sObject>(); // store-LK | user-LK
    
    //external Id 선언
    //Schema.SObjectField exId_contact = Contact_Soojung__c.Fields.Customer_ID__c;
    Schema.SObjectField exId_order = Order_Soojung__c.Fields.Order_ID__c;
    Schema.SObjectField exId_product = Product_Soojung__c.Fields.Product_ID__c;
    Schema.SObjectField exId_store = Store_Soojung__c.Fields.Postal_Code__c;
    Schema.SObjectField exId_orderProd = OrderProduct_Soojung__c.Fields.RowID__c;
    Schema.SObjectField exId_prodStore = ProductStore_Soojung__c.Fields.RowID__c;

    private Date dateParsing(String batchDate){
        //dummy date mm/dd/yy
        //saleforce date yyyy-mm-dd
        String [] dateParser = batchDate.split('/');
        
        String month = dateParser[0];
        String day = dateParser[1];
        String year = '20'+ dateParser[2];

        if(month.length() < 2){
            month = '0'+month;
        }
        if(day.length() < 2){
            day = '0'+day;
        }

        batchDate = year+'-'+month+'-'+day;
        return Date.valueOf(batchDate);
        
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // collect the batches of records or objects to be passed to execute
        // dummy 호출

        dummy_query = 'SELECT Customer_ID__c, Customer_Name__c, Segment__c';
        dummy_query +=       ',Order_ID__c, Order_Date__c, Ship_Date__c, Ship_Mode__c';
        dummy_query +=       ', Product_ID__c, Category__c, Sub_Category__c, Product_Name__c';
        dummy_query +=       ', Sales__c, Quantity__c, Profit__c, Discount__c, Cost__c';
        dummy_query +=       ', CountryRegion__c, City__c, State__c, Postal_Code__c, Region__c';
        dummy_query += ' FROM DUMMY_ORDER_SOOJUNG__c';
        dummy_query += ' WHERE Batch_Flag__c =\'N\'';

        return Database.getQueryLocator(dummy_query);
    }
    
    public void execute(Database.BatchableContext bc, List<DUMMY_ORDER_SOOJUNG__c> scopes){
        // process each batch of records
        // object 별 정리, data type 정리

        //prodStore ID
        Integer orderProdId = 0;
        Integer prodStoreId = 0;

        //check user 
        user_sj = new Map<String, sObject>();
        //List<String> regions = new List<String>{'West' ,'East', 'Central', 'South'};
        //List<User_Soojung__c> getUser = Database.Query('SELECT Id, Region__c FROM User_Soojung__c WHERE Region__c IN '+regions);
        List<User_Soojung__c> getUser = Database.Query('SELECT Id, Region__c FROM User_Soojung__c WHERE Region__c IN (\'West\' ,\'East\', \'Central\', \'South\')');
        for(User_Soojung__c obj : getUser){
            user_sj.put(obj.Region__c, obj);
        }


        for(DUMMY_ORDER_SOOJUNG__c sc : scopes){
            //contact
            Contact_Soojung__c contact = new Contact_Soojung__c();
            contact.Customer_ID__c = sc.Customer_ID__c;
            contact.Name = sc.Customer_Name__c; 
            if(sc.Segment__c == 'Consumer' || sc.Segment__c == 'Corporate' || sc.Segment__c == 'Home Office'){ //picklist value list
                contact.Segment__c = sc.Segment__c;
            }else{
                contact.Segment__c = '';
            }
            
            contact_sj.put(contact.Customer_ID__c, contact);


            //order
            Order_Soojung__c order = new Order_Soojung__c();
            order.Order_ID__c = sc.Order_ID__c;
            order.Order_Date__c = dateParsing(sc.Order_Date__c);
            order.Ship_Date__c = dateParsing(sc.Ship_Date__c);
            if(sc.Ship_Mode__c == 'First Class' || sc.Ship_Mode__c == 'Second Class' || sc.Ship_Mode__c == 'Standard Class' || sc.Ship_Mode__c == 'Same Day'){
                order.Ship_Mode__c = sc.Ship_Mode__c;
            }else{
                order.Ship_Mode__c = '';
            }
            order.Contact_Soojung__r = new Contact_Soojung__c(Customer_ID__c = sc.Customer_ID__c);
            
            order_sj.put(order.Order_ID__c, order);


            //product
            Product_Soojung__c product = new Product_Soojung__c();
            product.Product_ID__c = sc.Product_ID__c;
            product.Product_Name__c = sc.Product_Name__c;
            if(sc.Category__c == 'Furniture' || sc.Category__c == 'Office Supplies' || sc.Category__c == 'Technology'){
                product.Category__c = sc.Category__c;
            }else{
                product.Category__c = '';
            }
            product.Sub_Category__c = sc.Sub_Category__c;
            product.Cost__c = Decimal.valueof(sc.Cost__c);
            
            product_sj.put(product.Product_ID__c, product);


            //orderProduct
            OrderProduct_Soojung__c orderProduct = new OrderProduct_Soojung__c();
            orderProduct.RowID__c = String.valueOf(orderProdId++);
            orderProduct.Sales__c = Decimal.valueof(sc.Sales__c);
            orderProduct.Quantity__c = Integer.valueof(sc.Quantity__c);
            orderProduct.Profit__c = Decimal.valueof(sc.Profit__c);
            orderProduct.Discount__c = Decimal.valueof(sc.Discount__c);
            orderProduct.Order_Soojung__r = new Order_Soojung__c(Order_ID__c = sc.Order_ID__c);
            orderProduct.Product_Soojung__r = new Product_Soojung__c(Product_ID__c = sc.Product_ID__c);
            
            orderProduct_sj.put(orderProduct.RowID__c, orderProduct);


            //store
            Store_Soojung__c store = new Store_Soojung__c();
            store.CountryRegion__c = sc.CountryRegion__c;
            store.City__c = sc.City__c;
            store.State__c = sc.State__c;
            if(sc.Postal_Code__c != ''){
            store.Postal_Code__c = sc.Postal_Code__c;
            }else{
                store.Postal_Code__c = '-';
            } //need to create unique key 
            store.Name = sc.Region__c;
            store.RegionalManager__r = new User_Soojung__c(Region__c = sc.Region__c);
            
            store_sj.put(sc.Postal_Code__c, store);


            //productStore
            ProductStore_Soojung__c productStore = new ProductStore_Soojung__c();
            productStore.RowID__c = String.valueOf(prodStoreId++); //need to create unique key 
            productStore.Product_Soojung__r = new Product_Soojung__c(Product_ID__c = sc.Product_ID__c);
            productStore.Store_Soojung__r = new Store_Soojung__c(Postal_Code__c = sc.Postal_Code__c);

            productStore_sj.put(productStore.RowID__c, productStore);


            //convert batchFlag
            sc.Batch_Flag__c = 'Y';
        }
        

        //upsert
        try{
            Database.upsertResult[] re1 = Database.upsert(contact_sj.values(), Contact_Soojung__c.Fields.Customer_ID__c, true);
            Database.upsertResult[] re2 = Database.upsert(order_sj.values(), exId_order, true);
            Database.upsertResult[] re3 = Database.upsert(product_sj.values(), exId_product, true);
            Database.upsertResult[] re4 = Database.upsert(store_sj.values(), exId_store, true);
            Database.upsertResult[] re5 = Database.upsert(orderProduct_sj.values(), exId_orderProd, true);
            Database.upsertResult[] re6 = Database.upsert(productStore_sj.values(), exId_prodStore, true); // true 일때는 X
            //Database.upsertResult[] re6 = Database.upsert(productStore_sj.values(), exId_prodStore, False);

            Database.upsert(scopes, DUMMY_ORDER_SOOJUNG__c.Fields.Batch_Flag__c, true);
        }catch(DmlException e){
            System.debug(e.getMessage());
        }
    }
    
    public void finish(Database.BatchableContext bc){
        // execute any post-processing operations
        // returnBatch으로 chainning
        soojungReturnBatchClass reBat = new soojungReturnBatchClass();
        Database.executeBatch(reBat, 2000);
    }
}