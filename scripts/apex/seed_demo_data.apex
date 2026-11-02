// ==============================================================================
// Script: seed_demo_data.apex
// Description: Idempotent demo data seeder for Salesforce 360 Insurance Retail Agent.
// Objects: Account, Contact, Insurance_Policy__c, Purchase__c
// Usage: sf apex run -f scripts/apex/seed_demo_data.apex
//        Or execute in VS Code via "SFDX: Execute Anonymous Apex with Editor Contents"
// ==============================================================================

// 1. Target Demo Identifiers
String accountName = 'Retail Cardholder Customers';
Set<String> demoEmails = new Set<String>{
    'anaid.ramirez@test.com',
    'edgar.merlo@test.com',
    'guest.shopper@test.com'
};

System.debug('>>> [1/5] Starting Demo Data Seeding...');

// 2. Cleanup prior demo data to guarantee an idempotent and clean execution
List<Purchase__c> oldPurchases = [
    SELECT Id 
    FROM Purchase__c 
    WHERE Customer__r.Email IN :demoEmails
];
if (!oldPurchases.isEmpty()) {
    delete oldPurchases;
    System.debug('Removed ' + oldPurchases.size() + ' existing demo Purchase records.');
}

List<Insurance_Policy__c> oldPolicies = [
    SELECT Id 
    FROM Insurance_Policy__c 
    WHERE Customer__r.Email IN :demoEmails
];
if (!oldPolicies.isEmpty()) {
    delete oldPolicies;
    System.debug('Removed ' + oldPolicies.size() + ' existing demo Insurance Policy records.');
}

List<Contact> oldContacts = [
    SELECT Id 
    FROM Contact 
    WHERE Email IN :demoEmails
];
if (!oldContacts.isEmpty()) {
    delete oldContacts;
    System.debug('Removed ' + oldContacts.size() + ' existing demo Contact records.');
}

// 3. Ensure Demo Account exists
Account demoAccount;
List<Account> existingAccounts = [
    SELECT Id, Name 
    FROM Account 
    WHERE Name = :accountName 
    LIMIT 1
];
if (!existingAccounts.isEmpty()) {
    demoAccount = existingAccounts[0];
    System.debug('Found existing Account: ' + demoAccount.Name + ' (Id: ' + demoAccount.Id + ')');
} else {
    demoAccount = new Account(Name = accountName);
    insert demoAccount;
    System.debug('Created Account: ' + demoAccount.Name + ' (Id: ' + demoAccount.Id + ')');
}

// 4. Create Contacts
Contact anaid = new Contact(
    FirstName = 'Anaid',
    LastName = 'Ramirez',
    Email = 'anaid.ramirez@test.com',
    AccountId = demoAccount.Id
);

Contact edgar = new Contact(
    FirstName = 'Edgar',
    LastName = 'Merlo',
    Email = 'edgar.merlo@test.com',
    AccountId = demoAccount.Id
);

Contact guest = new Contact(
    FirstName = 'Guest',
    LastName = 'Shopper',
    Email = 'guest.shopper@test.com',
    AccountId = demoAccount.Id
);

List<Contact> contactsToInsert = new List<Contact>{ anaid, edgar, guest };
insert contactsToInsert;
System.debug('>>> [2/5] Inserted 3 Contacts: Anaid Ramirez, Edgar Merlo, Guest Shopper.');

// 5. Create Shared Insurance Policies for Anaid and Edgar
// Both share the same policy number and coverage details
String policyNumber = 'POL-CPP-2026-SHARED';
String policyType = 'Cardholder Protection Plus';
String policyStatus = '30-Day Free Trial';
String coverageSummary = 'Worldwide emergency medical abroad up to $50,000 USD, lost baggage protection, ' +
                         'sports injury rehabilitation up to $25,000 USD, physiotherapy, and preventive dental care.';

Insurance_Policy__c anaidPolicy = new Insurance_Policy__c(
    Name = policyNumber,
    Customer__c = anaid.Id,
    Policy_Type__c = policyType,
    Status__c = policyStatus,
    Coverage_Summary__c = coverageSummary
);

Insurance_Policy__c edgarPolicy = new Insurance_Policy__c(
    Name = policyNumber,
    Customer__c = edgar.Id,
    Policy_Type__c = policyType,
    Status__c = policyStatus,
    Coverage_Summary__c = coverageSummary
);

List<Insurance_Policy__c> policiesToInsert = new List<Insurance_Policy__c>{ anaidPolicy, edgarPolicy };
insert policiesToInsert;
System.debug('>>> [3/5] Inserted 2 shared Insurance Policy records for Anaid and Edgar (Guest Shopper omitted).');

// 6. Create Purchases
List<Purchase__c> purchasesToInsert = new List<Purchase__c>();

// (a) Anaid Ramirez: 3 Travel items
purchasesToInsert.add(new Purchase__c(
    Name = 'Hard-shell Suitcase 28"',
    Item_Name__c = 'Hard-shell Suitcase 28"',
    Category__c = 'Travel',
    Amount__c = 180.00,
    Customer__c = anaid.Id
));
purchasesToInsert.add(new Purchase__c(
    Name = 'Anti-theft TSA Backpack',
    Item_Name__c = 'Anti-theft TSA Backpack',
    Category__c = 'Travel',
    Amount__c = 65.00,
    Customer__c = anaid.Id
));
purchasesToInsert.add(new Purchase__c(
    Name = 'Universal Travel Power Adapter',
    Item_Name__c = 'Universal Travel Power Adapter',
    Category__c = 'Travel',
    Amount__c = 35.00,
    Customer__c = anaid.Id
));

// (b) Edgar Merlo: 2 Sports items + 2 Technology items
purchasesToInsert.add(new Purchase__c(
    Name = 'Pro Running Sneakers',
    Item_Name__c = 'Pro Running Sneakers',
    Category__c = 'Sports',
    Amount__c = 140.00,
    Customer__c = edgar.Id
));
purchasesToInsert.add(new Purchase__c(
    Name = 'Athletic Training Track Pants',
    Item_Name__c = 'Athletic Training Track Pants',
    Category__c = 'Sports',
    Amount__c = 75.00,
    Customer__c = edgar.Id
));
purchasesToInsert.add(new Purchase__c(
    Name = 'MacBook Air M5',
    Item_Name__c = 'MacBook Air M5',
    Category__c = 'Technology',
    Amount__c = 1499.00,
    Customer__c = edgar.Id
));
purchasesToInsert.add(new Purchase__c(
    Name = 'Wireless Pro Headphones',
    Item_Name__c = 'Wireless Pro Headphones',
    Category__c = 'Technology',
    Amount__c = 249.00,
    Customer__c = edgar.Id
));

// (c) Guest Shopper: 15 generic store purchases under Technology ($1,250 each)
for (Integer i = 1; i <= 15; i++) {
    purchasesToInsert.add(new Purchase__c(
        Name = 'Laptop / Consumer Electronics #' + i,
        Item_Name__c = 'Laptop / Consumer Electronics',
        Category__c = 'Technology',
        Amount__c = 1250.00,
        Customer__c = guest.Id
    ));
}

insert purchasesToInsert;
System.debug('>>> [4/5] Inserted ' + purchasesToInsert.size() + ' Purchases in total.');

// 7. Output Final Verification Summary
System.debug('=================== DEMO DATA SEEDING COMPLETE ===================');
System.debug('Account : ' + demoAccount.Name + ' [' + demoAccount.Id + ']');
System.debug('Customer 1: ' + anaid.FirstName + ' ' + anaid.LastName + ' (3 Travel purchases, 1 Policy)');
System.debug('Customer 2: ' + edgar.FirstName + ' ' + edgar.LastName + ' (2 Sports + 2 Tech purchases, 1 Policy)');
System.debug('Customer 3: ' + guest.FirstName + ' ' + guest.LastName + ' (15 Tech purchases, No Policy)');
System.debug('Total Policies Created  : ' + policiesToInsert.size());
System.debug('Total Purchases Created : ' + purchasesToInsert.size());
System.debug('===================================================================');
