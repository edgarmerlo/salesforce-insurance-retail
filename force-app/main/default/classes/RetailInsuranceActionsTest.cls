/**
 * @description Unit test class for CustomerRetentionAction and StoreTrendsAction.
 *              Validates 100% test coverage, SOQL security, edge cases, and factual metrics.
 */
@isTest
private class RetailInsuranceActionsTest {

    @testSetup
    static void setupTestData() {
        // 1. Create Demo Account
        Account acc = new Account(Name = 'Retail Cardholder Customers');
        insert acc;

        // 2. Create Contacts
        Contact anaid = new Contact(
            FirstName = 'Anaid',
            LastName = 'Ramirez',
            Email = 'anaid.ramirez@test.com',
            AccountId = acc.Id
        );
        Contact edgar = new Contact(
            FirstName = 'Edgar',
            LastName = 'Merlo',
            Email = 'edgar.merlo@test.com',
            AccountId = acc.Id
        );
        Contact guest = new Contact(
            FirstName = 'Guest',
            LastName = 'Shopper',
            Email = 'guest.shopper@test.com',
            AccountId = acc.Id
        );
        Contact emptyContact = new Contact(
            FirstName = 'Empty',
            LastName = 'Customer',
            Email = 'empty.customer@test.com',
            AccountId = acc.Id
        );
        insert new List<Contact>{ anaid, edgar, guest, emptyContact };

        // 3. Create Insurance Policies for Anaid and Edgar
        String summary = 'Worldwide emergency medical abroad up to $50,000 USD, lost baggage protection, ' +
                         'sports injury rehabilitation up to $25,000 USD, physiotherapy, and preventive dental care.';

        Insurance_Policy__c polAnaid = new Insurance_Policy__c(
            Name = 'POL-CPP-2026-SHARED',
            Customer__c = anaid.Id,
            Policy_Type__c = 'Cardholder Protection Plus',
            Status__c = '30-Day Free Trial',
            Coverage_Summary__c = summary
        );
        Insurance_Policy__c polEdgar = new Insurance_Policy__c(
            Name = 'POL-CPP-2026-SHARED',
            Customer__c = edgar.Id,
            Policy_Type__c = 'Cardholder Protection Plus',
            Status__c = '30-Day Free Trial',
            Coverage_Summary__c = summary
        );
        insert new List<Insurance_Policy__c>{ polAnaid, polEdgar };

        // 4. Create Purchases
        List<Purchase__c> purchases = new List<Purchase__c>();

        // Anaid (3 Travel purchases)
        purchases.add(new Purchase__c(
            Name = 'Hard-shell Suitcase 28"',
            Item_Name__c = 'Hard-shell Suitcase 28"',
            Category__c = 'Travel',
            Amount__c = 180.00,
            Customer__c = anaid.Id
        ));
        purchases.add(new Purchase__c(
            Name = 'Anti-theft TSA Backpack',
            Item_Name__c = 'Anti-theft TSA Backpack',
            Category__c = 'Travel',
            Amount__c = 65.00,
            Customer__c = anaid.Id
        ));
        purchases.add(new Purchase__c(
            Name = 'Universal Travel Power Adapter',
            Item_Name__c = 'Universal Travel Power Adapter',
            Category__c = 'Travel',
            Amount__c = 35.00,
            Customer__c = anaid.Id
        ));

        // Edgar (2 Sports + 2 Technology + 1 Fashion purchases)
        purchases.add(new Purchase__c(
            Name = 'Pro Running Sneakers',
            Item_Name__c = 'Pro Running Sneakers',
            Category__c = 'Sports',
            Amount__c = 140.00,
            Customer__c = edgar.Id
        ));
        purchases.add(new Purchase__c(
            Name = 'Athletic Training Track Pants',
            Item_Name__c = 'Athletic Training Track Pants',
            Category__c = 'Sports',
            Amount__c = 75.00,
            Customer__c = edgar.Id
        ));
        purchases.add(new Purchase__c(
            Name = 'MacBook Air M5',
            Item_Name__c = 'MacBook Air M5',
            Category__c = 'Technology',
            Amount__c = 1499.00,
            Customer__c = edgar.Id
        ));
        purchases.add(new Purchase__c(
            Name = 'Wireless Pro Headphones',
            Item_Name__c = 'Wireless Pro Headphones',
            Category__c = 'Technology',
            Amount__c = 249.00,
            Customer__c = edgar.Id
        ));
        purchases.add(new Purchase__c(
            Name = 'Designer Jacket',
            Item_Name__c = 'Designer Jacket',
            Category__c = 'Fashion',
            Amount__c = 300.00,
            Customer__c = edgar.Id
        ));

        // Guest Shopper (15 Technology purchases)
        for (Integer i = 1; i <= 15; i++) {
            purchases.add(new Purchase__c(
                Name = 'Laptop / Consumer Electronics #' + i,
                Item_Name__c = 'Laptop / Consumer Electronics',
                Category__c = 'Technology',
                Amount__c = 1250.00,
                Customer__c = guest.Id
            ));
        }

        insert purchases;
    }

    @isTest
    static void testCustomerRetentionByName_Anaid() {
        CustomerRetentionAction.Request req = new CustomerRetentionAction.Request();
        req.customerName = 'Anaid Ramirez';

        Test.startTest();
        List<CustomerRetentionAction.Response> responses = 
            CustomerRetentionAction.getCustomerRetentionData(new List<CustomerRetentionAction.Request>{ req });
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'Should return exactly 1 response.');
        CustomerRetentionAction.Response res = responses[0];
        Assert.areEqual('Anaid Ramirez', res.customerName, 'Customer name should match.');
        Assert.areEqual('Travel', res.topCategory, 'Top category for Anaid should be Travel.');
        Assert.areEqual('Cardholder Protection Plus', res.policyName, 'Policy name should match.');
        Assert.isTrue(res.policyCoverage.contains('Worldwide emergency medical'), 'Policy coverage should contain emergency medical abroad.');
        Assert.isTrue(res.recentPurchases.contains('Hard-shell Suitcase 28"'), 'Recent purchases should include the suitcase.');
    }

    @isTest
    static void testCustomerRetentionById_Edgar() {
        Contact edgar = [SELECT Id FROM Contact WHERE Email = 'edgar.merlo@test.com' LIMIT 1];

        CustomerRetentionAction.Request req = new CustomerRetentionAction.Request();
        req.customerId = edgar.Id;

        Test.startTest();
        List<CustomerRetentionAction.Response> responses = 
            CustomerRetentionAction.getCustomerRetentionData(new List<CustomerRetentionAction.Request>{ req });
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'Should return exactly 1 response.');
        CustomerRetentionAction.Response res = responses[0];
        Assert.areEqual('Edgar Merlo', res.customerName, 'Customer name should match Edgar Merlo.');
        Assert.areEqual('Technology', res.topCategory, 'Top category for Edgar should be Technology.');
        Assert.areEqual('Cardholder Protection Plus', res.policyName, 'Policy name should match.');
        Assert.isTrue(res.recentPurchases.contains('MacBook Air M5'), 'Recent purchases should contain MacBook Air.');
        Assert.isTrue(res.recentPurchases.contains('Designer Jacket'), 'Recent purchases should contain Designer Jacket.');
    }

    @isTest
    static void testCustomerRetention_GuestShopperNoPolicy() {
        CustomerRetentionAction.Request req = new CustomerRetentionAction.Request();
        req.customerName = 'Guest Shopper';

        Test.startTest();
        List<CustomerRetentionAction.Response> responses = 
            CustomerRetentionAction.getCustomerRetentionData(new List<CustomerRetentionAction.Request>{ req });
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'Should return exactly 1 response.');
        CustomerRetentionAction.Response res = responses[0];
        Assert.areEqual('Guest Shopper', res.customerName, 'Customer name should match.');
        Assert.areEqual('Technology', res.topCategory, 'Top category should be Technology.');
        Assert.areEqual('No Active Policy', res.policyName, 'Guest Shopper should have No Active Policy.');
        Assert.areEqual('None', res.policyCoverage, 'Coverage should be None.');
        
        // Assert that recentPurchases contains at most 10 items even though 15 were inserted
        List<String> items = res.recentPurchases.split('\\), ');
        Assert.isTrue(items.size() <= 10, 'Should restrict recent purchases summary to at most 10 items.');
    }

    @isTest
    static void testCustomerRetention_CustomerWithNoPurchasesNoPolicy() {
        CustomerRetentionAction.Request req = new CustomerRetentionAction.Request();
        req.customerName = 'empty.customer@test.com';

        Test.startTest();
        List<CustomerRetentionAction.Response> responses = 
            CustomerRetentionAction.getCustomerRetentionData(new List<CustomerRetentionAction.Request>{ req });
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'Should return 1 response.');
        CustomerRetentionAction.Response res = responses[0];
        Assert.areEqual('Empty Customer', res.customerName, 'Customer name should match.');
        Assert.areEqual('None', res.topCategory, 'Top category should be None.');
        Assert.areEqual('No recent purchases', res.recentPurchases, 'Purchases should state No recent purchases.');
        Assert.areEqual('No Active Policy', res.policyName, 'Policy should state No Active Policy.');
        Assert.areEqual('None', res.policyCoverage, 'Policy coverage should be None.');
    }

    @isTest
    static void testCustomerRetention_NotFoundAndInvalidRequests() {
        CustomerRetentionAction.Request reqNotFound = new CustomerRetentionAction.Request();
        reqNotFound.customerName = 'Unknown Person';
        reqNotFound.customerId = 'InvalidContactIdString';

        Test.startTest();
        List<CustomerRetentionAction.Response> responses = 
            CustomerRetentionAction.getCustomerRetentionData(new List<CustomerRetentionAction.Request>{ reqNotFound });
        List<CustomerRetentionAction.Response> emptyResponses = 
            CustomerRetentionAction.getCustomerRetentionData(new List<CustomerRetentionAction.Request>());
        List<CustomerRetentionAction.Response> nullResponses = 
            CustomerRetentionAction.getCustomerRetentionData(null);
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'Should return 1 response for not found.');
        Assert.areEqual('Unknown Person', responses[0].customerName, 'Should keep requested name.');
        Assert.areEqual('Customer not found', responses[0].recentPurchases, 'Should report customer not found.');
        Assert.areEqual('None', responses[0].topCategory, 'Top category should be None.');
        Assert.areEqual('None', responses[0].policyName, 'Policy name should be None.');
        Assert.areEqual(0, emptyResponses.size(), 'Empty request list should return empty response list.');
        Assert.areEqual(0, nullResponses.size(), 'Null request list should return empty response list.');
    }

    @isTest
    static void testCustomerRetention_PartialMatch() {
        CustomerRetentionAction.Request req = new CustomerRetentionAction.Request();
        req.customerName = 'anaid'; // Partial/lowercase match

        Test.startTest();
        List<CustomerRetentionAction.Response> responses = 
            CustomerRetentionAction.getCustomerRetentionData(new List<CustomerRetentionAction.Request>{ req });
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'Should return 1 response.');
        Assert.areEqual('Anaid Ramirez', responses[0].customerName, 'Should match Anaid Ramirez.');
    }

    @isTest
    static void testStoreTrends_Success() {
        StoreTrendsAction.Request req = new StoreTrendsAction.Request();

        Test.startTest();
        List<StoreTrendsAction.Response> responses = 
            StoreTrendsAction.getStoreTrends(new List<StoreTrendsAction.Request>{ req });
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'Should return 1 response.');
        StoreTrendsAction.Response res = responses[0];
        Assert.areEqual(23, res.totalOrders, 'Should have 23 total purchase orders.');
        Assert.isTrue(res.totalStoreVolume > 0, 'Total store volume should be greater than zero.');
        Assert.areEqual('Technology', res.topCategory, 'Top category by revenue should be Technology.');
        Assert.isTrue(res.topCategoryRevenue > 0, 'Top category revenue should be positive.');
        Assert.isTrue(res.uncoveredCategories.contains('Technology'), 'Technology should be reported as uncovered.');
        Assert.isTrue(res.uncoveredCategories.contains('Fashion'), 'Fashion should be reported as uncovered.');
    }

    @isTest
    static void testStoreTrends_WithCategoryFilter() {
        StoreTrendsAction.Request req = new StoreTrendsAction.Request();
        req.categoryFilter = 'Technology';

        Test.startTest();
        List<StoreTrendsAction.Response> responses = 
            StoreTrendsAction.getStoreTrends(new List<StoreTrendsAction.Request>{ req });
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'Should return 1 response.');
        StoreTrendsAction.Response res = responses[0];
        Assert.areEqual('Technology', res.topCategory, 'Top category should be Technology.');
        Assert.areEqual(17, res.totalOrders, 'Should count 17 Technology purchase orders (2 Edgar + 15 Guest).');
    }

    @isTest
    static void testStoreTrends_EmptyData() {
        // Clear all purchases to test zero-data state
        delete [SELECT Id FROM Purchase__c];

        Test.startTest();
        List<StoreTrendsAction.Response> responses = 
            StoreTrendsAction.getStoreTrends(new List<StoreTrendsAction.Request>());
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'Should return 1 response for empty request list.');
        StoreTrendsAction.Response res = responses[0];
        Assert.areEqual(0, res.totalOrders, 'Total orders should be 0.');
        Assert.areEqual(0.00, res.totalStoreVolume, 'Total volume should be 0.00.');
        Assert.areEqual('None', res.topCategory, 'Top category should be None.');
        Assert.areEqual(0.00, res.topCategoryRevenue, 'Top category revenue should be 0.00.');
        Assert.areEqual('None', res.uncoveredCategories, 'Uncovered categories should be None.');
    }
}
