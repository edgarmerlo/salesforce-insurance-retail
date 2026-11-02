/**
 * @description Invocable action for Salesforce 360 Insurance Retail Agent.
 *              Fetches raw factual business data for a customer (Contact, active Policy, recent Purchases)
 *              to allow the AI Agent to perform retention reasoning without business logic bias.
 */
public with sharing class CustomerRetentionAction {

    public class Request {
        @InvocableVariable(
            label='Customer Name' 
            description='Full or partial name or email of the customer' 
            required=false
        )
        public String customerName;

        @InvocableVariable(
            label='Customer ID' 
            description='18-character Salesforce Contact Id' 
            required=false
        )
        public String customerId;
    }

    public class Response {
        @InvocableVariable(
            label='Customer Name' 
            description='Full name of the retrieved customer'
        )
        public String customerName;

        @InvocableVariable(
            label='Top Category' 
            description='The purchase category with the highest spend for this customer'
        )
        public String topCategory;

        @InvocableVariable(
            label='Recent Purchases' 
            description='Summary of up to the last 10 purchase items and their amounts'
        )
        public String recentPurchases;

        @InvocableVariable(
            label='Policy Name' 
            description='Name or identifier of the active insurance policy'
        )
        public String policyName;

        @InvocableVariable(
            label='Policy Coverage' 
            description='Summary of coverage included in the active policy'
        )
        public String policyCoverage;
    }

    /**
     * @description Invocable method called by Agentforce or Flow to retrieve factual customer retention data.
     * @param requests List of customer search requests (by name or ID)
     * @return List<Response> Structured retention factual metrics
     */
    @InvocableMethod(
        label='Get Customer Retention Details' 
        description='Fetches factual customer purchases, top category, and policy coverage for retention analysis' 
        category='Insurance Retail'
    )
    public static List<Response> getCustomerRetentionData(List<Request> requests) {
        List<Response> responses = new List<Response>();

        if (requests == null || requests.isEmpty()) {
            return responses;
        }

        // 1. Gather all requested IDs and search terms for bulk query
        Set<Id> requestedContactIds = new Set<Id>();
        Set<String> searchTerms = new Set<String>();

        for (Request req : requests) {
            if (String.isNotBlank(req.customerId)) {
                try {
                    requestedContactIds.add((Id) req.customerId.trim());
                } catch (Exception ex) {
                    // In case of non-valid Id format, treat as search term
                    searchTerms.add(req.customerId.trim());
                }
            }
            if (String.isNotBlank(req.customerName)) {
                searchTerms.add(req.customerName.trim());
            }
        }

        // 2. Query Contacts in user mode
        Map<Id, Contact> contactsById = new Map<Id, Contact>();
        if (!requestedContactIds.isEmpty()) {
            for (Contact c : [
                SELECT Id, Name, FirstName, LastName, Email 
                FROM Contact 
                WHERE Id IN :requestedContactIds 
                WITH USER_MODE
            ]) {
                contactsById.put(c.Id, c);
            }
        }

        if (!searchTerms.isEmpty()) {
            for (Contact c : [
                SELECT Id, Name, FirstName, LastName, Email 
                FROM Contact 
                WHERE Name IN :searchTerms 
                   OR Email IN :searchTerms 
                   OR FirstName IN :searchTerms 
                   OR LastName IN :searchTerms
                WITH USER_MODE
            ]) {
                contactsById.put(c.Id, c);
            }
        }

        // Build search lookup map by lower-cased name and email
        Map<String, Contact> contactsByTerm = new Map<String, Contact>();
        for (Contact c : contactsById.values()) {
            if (String.isNotBlank(c.Name)) {
                contactsByTerm.put(c.Name.toLowerCase(), c);
            }
            if (String.isNotBlank(c.Email)) {
                contactsByTerm.put(c.Email.toLowerCase(), c);
            }
            if (String.isNotBlank(c.FirstName)) {
                contactsByTerm.put(c.FirstName.toLowerCase(), c);
            }
            if (String.isNotBlank(c.LastName)) {
                contactsByTerm.put(c.LastName.toLowerCase(), c);
            }
        }

        // 3. Query Active Policies for matched contacts
        Set<Id> matchedContactIds = contactsById.keySet();
        Map<Id, Insurance_Policy__c> policiesByContactId = new Map<Id, Insurance_Policy__c>();
        if (!matchedContactIds.isEmpty()) {
            for (Insurance_Policy__c pol : [
                SELECT Id, Name, Customer__c, Policy_Type__c, Status__c, Coverage_Summary__c, CreatedDate 
                FROM Insurance_Policy__c 
                WHERE Customer__c IN :matchedContactIds 
                WITH USER_MODE 
                ORDER BY CreatedDate DESC
            ]) {
                // Keep the most recent policy per customer
                if (!policiesByContactId.containsKey(pol.Customer__c)) {
                    policiesByContactId.put(pol.Customer__c, pol);
                }
            }
        }

        // 4. Query Recent Purchases for matched contacts
        Map<Id, List<Purchase__c>> purchasesByContactId = new Map<Id, List<Purchase__c>>();
        if (!matchedContactIds.isEmpty()) {
            for (Purchase__c p : [
                SELECT Id, Name, Item_Name__c, Category__c, Amount__c, Customer__c, CreatedDate 
                FROM Purchase__c 
                WHERE Customer__c IN :matchedContactIds 
                WITH USER_MODE 
                ORDER BY CreatedDate DESC
            ]) {
                if (!purchasesByContactId.containsKey(p.Customer__c)) {
                    purchasesByContactId.put(p.Customer__c, new List<Purchase__c>());
                }
                purchasesByContactId.get(p.Customer__c).add(p);
            }
        }

        // 5. Construct Response for each Request
        for (Request req : requests) {
            Response res = new Response();
            Contact matchedContact = null;

            // Match by ID first
            if (String.isNotBlank(req.customerId)) {
                try {
                    Id cId = (Id) req.customerId.trim();
                    if (contactsById.containsKey(cId)) {
                        matchedContact = contactsById.get(cId);
                    }
                } catch (Exception ignored) {
                    // Checked below via term
                }
            }

            // Match by name or term if not matched by ID
            if (matchedContact == null && String.isNotBlank(req.customerName)) {
                String term = req.customerName.trim().toLowerCase();
                if (contactsByTerm.containsKey(term)) {
                    matchedContact = contactsByTerm.get(term);
                } else {
                    // Try partial match across values
                    for (Contact c : contactsById.values()) {
                        if (c.Name != null && c.Name.toLowerCase().contains(term)) {
                            matchedContact = c;
                            break;
                        }
                    }
                }
            }

            if (matchedContact == null) {
                res.customerName = String.isNotBlank(req.customerName) ? req.customerName : 'Unknown';
                res.topCategory = 'None';
                res.recentPurchases = 'Customer not found';
                res.policyName = 'None';
                res.policyCoverage = 'None';
                responses.add(res);
                continue;
            }

            // Customer details found
            res.customerName = matchedContact.Name;

            // Policy details
            if (policiesByContactId.containsKey(matchedContact.Id)) {
                Insurance_Policy__c pol = policiesByContactId.get(matchedContact.Id);
                res.policyName = String.isNotBlank(pol.Policy_Type__c) 
                    ? pol.Policy_Type__c 
                    : pol.Name;
                res.policyCoverage = String.isNotBlank(pol.Coverage_Summary__c) 
                    ? pol.Coverage_Summary__c 
                    : 'None';
            } else {
                res.policyName = 'No Active Policy';
                res.policyCoverage = 'None';
            }

            // Purchases details
            List<Purchase__c> customerPurchases = purchasesByContactId.get(matchedContact.Id);
            if (customerPurchases == null || customerPurchases.isEmpty()) {
                res.topCategory = 'None';
                res.recentPurchases = 'No recent purchases';
            } else {
                Map<String, Decimal> categorySpend = new Map<String, Decimal>();
                List<String> purchaseSummaries = new List<String>();

                Integer limitCount = Math.min(customerPurchases.size(), 10);
                for (Integer i = 0; i < limitCount; i++) {
                    Purchase__c p = customerPurchases[i];
                    String itemName = String.isNotBlank(p.Item_Name__c) ? p.Item_Name__c : p.Name;
                    Decimal amt = p.Amount__c != null ? p.Amount__c.setScale(2) : 0.00;
                    purchaseSummaries.add(itemName + ' ($' + amt + ')');
                }

                // Compute top category based on total spend across all customer purchases
                for (Purchase__c p : customerPurchases) {
                    if (String.isNotBlank(p.Category__c)) {
                        Decimal current = categorySpend.containsKey(p.Category__c) ? categorySpend.get(p.Category__c) : 0.00;
                        Decimal amt = p.Amount__c != null ? p.Amount__c : 0.00;
                        categorySpend.put(p.Category__c, current + amt);
                    }
                }

                String topCat = 'None';
                Decimal highestSpend = -1;
                for (String cat : categorySpend.keySet()) {
                    if (categorySpend.get(cat) > highestSpend) {
                        highestSpend = categorySpend.get(cat);
                        topCat = cat;
                    }
                }

                res.topCategory = topCat;
                res.recentPurchases = String.join(purchaseSummaries, ', ');
            }

            responses.add(res);
        }

        return responses;
    }
}
