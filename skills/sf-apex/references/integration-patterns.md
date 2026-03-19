# Apex Integration Patterns Reference

## 1. REST Callout

Making outbound HTTP requests from Apex to external services.

### Basic REST Callout
```apex
public class RestCalloutService {

    public static String doGet(String endpoint) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Accept', 'application/json');
        req.setTimeout(30000); // 30 seconds

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            return res.getBody();
        } else {
            throw new CalloutException(
                'GET failed: ' + res.getStatusCode() + ' ' + res.getStatus()
            );
        }
    }

    public static String doPost(String endpoint, Object body) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setTimeout(30000);
        req.setBody(JSON.serialize(body));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
            return res.getBody();
        } else {
            throw new CalloutException(
                'POST failed: ' + res.getStatusCode() + ' ' + res.getBody()
            );
        }
    }
}
```

### Parsing JSON Response
```apex
public class AccountApiService {

    public class AccountData {
        public String name;
        public String industry;
        public String externalId;
    }

    public static List<AccountData> fetchAccounts(String endpoint) {
        String responseBody = RestCalloutService.doGet(endpoint);

        // Typed deserialization
        List<AccountData> accounts =
            (List<AccountData>) JSON.deserialize(
                responseBody, List<AccountData>.class
            );
        return accounts;
    }

    public static Map<String, Object> fetchUntyped(String endpoint) {
        String responseBody = RestCalloutService.doGet(endpoint);

        // Untyped deserialization for dynamic JSON
        Map<String, Object> result =
            (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        return result;
    }
}
```

### Comprehensive Error Handling
```apex
public class ResilientCalloutService {

    public class CalloutResult {
        public Boolean success;
        public Integer statusCode;
        public String body;
        public String errorMessage;
    }

    public static CalloutResult makeCallout(HttpRequest req) {
        CalloutResult result = new CalloutResult();
        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            result.statusCode = res.getStatusCode();
            result.body = res.getBody();

            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                result.success = true;
            } else {
                result.success = false;
                result.errorMessage = 'HTTP ' + res.getStatusCode() +
                    ': ' + res.getStatus();
            }
        } catch (CalloutException e) {
            result.success = false;
            result.errorMessage = 'Callout exception: ' + e.getMessage();
        }
        return result;
    }
}
```

---

## 2. Named Credential Callout

Secure credential storage and automatic authentication — no hardcoded URLs or secrets in code.

### Using Named Credentials
```apex
public class NamedCredentialService {

    public static String callExternalApi(String path) {
        HttpRequest req = new HttpRequest();
        // Named Credential handles auth headers automatically
        req.setEndpoint('callout:My_External_Service' + path);
        req.setMethod('GET');
        req.setHeader('Accept', 'application/json');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            return res.getBody();
        }
        throw new CalloutException('Failed: ' + res.getStatusCode());
    }

    public static String postData(String path, String jsonBody) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:My_External_Service' + path);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);

        Http http = new Http();
        HttpResponse res = http.send(req);
        return res.getBody();
    }
}
```

### Benefits Over Hardcoded URLs
- Credentials stored securely in Salesforce metadata, not in code.
- Supports OAuth 2.0, Basic Auth, JWT, AWS Signature, and custom auth.
- Endpoint URL manageable per environment (sandbox vs. production).
- Can merge fields from Named Credential into headers and body.
- Deployable via metadata API / change sets.

---

## 3. @RestResource — Apex REST Service

Expose custom REST endpoints for external systems to call into Salesforce.

### Full REST Resource
```apex
@RestResource(urlMapping='/accounts/*')
global with sharing class AccountRestService {

    @HttpGet
    global static Account getAccount() {
        RestRequest req = RestContext.request;
        // Extract ID from URL: /services/apexrest/accounts/<Id>
        String accountId = req.requestURI.substringAfterLast('/');

        return [
            SELECT Id, Name, Industry, BillingCity, Phone
            FROM Account
            WHERE Id = :accountId
            WITH USER_MODE
            LIMIT 1
        ];
    }

    @HttpPost
    global static Id createAccount(
        String name,
        String industry,
        String phone
    ) {
        Account acc = new Account(
            Name = name,
            Industry = industry,
            Phone = phone
        );
        insert acc;
        return acc.Id;
    }

    @HttpPut
    global static Account upsertAccount(
        String externalId,
        String name,
        String industry
    ) {
        Account acc = new Account(
            External_Id__c = externalId,
            Name = name,
            Industry = industry
        );
        upsert acc External_Id__c;
        return acc;
    }

    @HttpPatch
    global static Account updateAccount() {
        RestRequest req = RestContext.request;
        String accountId = req.requestURI.substringAfterLast('/');
        Map<String, Object> params =
            (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());

        Account acc = [SELECT Id FROM Account WHERE Id = :accountId LIMIT 1];
        for (String field : params.keySet()) {
            acc.put(field, params.get(field));
        }
        update acc;
        return acc;
    }

    @HttpDelete
    global static void deleteAccount() {
        RestRequest req = RestContext.request;
        String accountId = req.requestURI.substringAfterLast('/');
        delete [SELECT Id FROM Account WHERE Id = :accountId LIMIT 1];
    }
}
```

### Custom Response with RestResponse
```apex
@RestResource(urlMapping='/account-search/*')
global with sharing class AccountSearchService {

    @HttpGet
    global static void searchAccounts() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        String searchTerm = req.params.get('q');
        if (String.isBlank(searchTerm)) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(
                JSON.serialize(new Map<String, String>{
                    'error' => 'Missing required parameter: q'
                })
            );
            return;
        }

        List<Account> results = [
            SELECT Id, Name, Industry
            FROM Account
            WHERE Name LIKE :('%' + searchTerm + '%')
            WITH USER_MODE
            LIMIT 50
        ];

        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json');
        res.responseBody = Blob.valueOf(JSON.serialize(results));
    }
}
```

### URL Mapping Rules
- Endpoint is accessible at `/services/apexrest/<urlMapping>`.
- Wildcards: `/accounts/*` matches `/accounts/001xx000003DGb2`.
- Only one wildcard `*` at the end is supported.
- The class must be `global`.
- Each HTTP method annotation can appear only once per class.

---

## 4. SOAP Callout

Consuming external SOAP web services using WSDL2Apex-generated classes.

### Using WSDL2Apex Generated Code
```apex
public class SoapIntegrationService {

    public static String getAccountInfo(String accountNumber) {
        // Generated classes from WSDL import
        externalService.AccountServicePort port = new externalService.AccountServicePort();

        // Set endpoint if not using Named Credential
        // port.endpoint_x = 'https://api.example.com/soap/AccountService';

        // Set timeout
        port.timeout_x = 30000;

        // Set authentication headers
        port.inputHttpHeaders_x = new Map<String, String>{
            'Authorization' => 'Basic ' +
                EncodingUtil.base64Encode(Blob.valueOf('user:pass'))
        };

        // Call the SOAP operation
        externalService.AccountInfoResponse response =
            port.getAccountInfo(accountNumber);

        return response.accountName;
    }
}
```

### WebServiceCallout Pattern
```apex
public class SoapCalloutExample {

    public class AccountRequest {
        public String accountNumber;
    }

    public class AccountResponse {
        public String accountName;
        public String status;
    }

    public static AccountResponse getAccount(String accountNumber) {
        AccountRequest request = new AccountRequest();
        request.accountNumber = accountNumber;

        AccountResponse response = new AccountResponse();

        // Direct WebServiceCallout invocation
        Map<String, String> ns = new Map<String, String>{
            'tns' => 'http://example.com/AccountService'
        };

        WebServiceCallout.invoke(
            null,                        // stub
            response,                    // response object
            new String[]{
                'https://api.example.com/soap/AccountService',
                'getAccount',            // operation name
                'http://example.com/AccountService', // namespace
                'getAccountRequest',     // request element
                'http://example.com/AccountService', // response namespace
                'getAccountResponse'     // response element
            },
            new Object[]{ request }
        );

        return response;
    }
}
```

---

## 5. WebServiceMock — Testing SOAP Callouts

### Mock Implementation
```apex
@IsTest
global class AccountServiceMock implements WebServiceMock {

    global void doInvoke(
        Object stub,
        Object request,
        Map<String, Object> response,
        String endpoint,
        String soapAction,
        String requestName,
        String responseNS,
        String responseName,
        String responseType
    ) {
        // Create mock response
        externalService.AccountInfoResponse mockResponse =
            new externalService.AccountInfoResponse();
        mockResponse.accountName = 'Mock Account';
        mockResponse.status = 'Active';

        // Put the response in the response map
        response.put('response_x', mockResponse);
    }
}

@IsTest
private class SoapIntegrationServiceTest {

    @IsTest
    static void testGetAccountInfo() {
        Test.setMock(WebServiceMock.class, new AccountServiceMock());

        Test.startTest();
        String result = SoapIntegrationService.getAccountInfo('ACC-001');
        Test.stopTest();

        System.assertEquals('Mock Account', result);
    }
}
```

---

## 6. System.Callable Interface

Loosely-coupled Apex integration for managed packages and dynamic method invocation.

### Implementing Callable
```apex
public class DiscountCalculator implements System.Callable {

    public Object call(String action, Map<String, Object> args) {
        switch on action.toLowerCase() {
            when 'calculatediscount' {
                Decimal amount = (Decimal) args.get('amount');
                String tier = (String) args.get('tier');
                return calculateDiscount(amount, tier);
            }
            when 'getdiscounttiers' {
                return getDiscountTiers();
            }
            when else {
                throw new ExtensionMalformedCallException(
                    'Unknown action: ' + action
                );
            }
        }
    }

    private Decimal calculateDiscount(Decimal amount, String tier) {
        Map<String, Decimal> rates = new Map<String, Decimal>{
            'Bronze' => 0.05,
            'Silver' => 0.10,
            'Gold' => 0.15,
            'Platinum' => 0.20
        };
        Decimal rate = rates.containsKey(tier) ? rates.get(tier) : 0;
        return amount * rate;
    }

    private List<String> getDiscountTiers() {
        return new List<String>{ 'Bronze', 'Silver', 'Gold', 'Platinum' };
    }

    public class ExtensionMalformedCallException extends Exception {}
}
```

### Consuming Callable Dynamically
```apex
public class CallableConsumer {

    public static Decimal getDiscount(Decimal amount, String tier) {
        // Dynamically instantiate — no compile-time dependency
        Type calcType = Type.forName('DiscountCalculator');
        if (calcType == null) {
            throw new TypeException('DiscountCalculator class not found');
        }

        System.Callable calculator = (System.Callable) calcType.newInstance();
        Decimal discount = (Decimal) calculator.call('calculateDiscount',
            new Map<String, Object>{
                'amount' => amount,
                'tier' => tier
            }
        );
        return discount;
    }
}
```

### Use Cases
- Managed package extensibility: subscriber orgs can invoke logic without namespace knowledge at compile time.
- Plugin architectures: dynamically call different implementations.
- Cross-package communication without direct dependencies.

---

## 7. Composite API from Apex

Making composite requests to the Salesforce REST API from Apex for multi-step operations in a single call.

### Composite Request
```apex
public class CompositeApiService {

    public class SubRequest {
        public String method;
        public String url;
        public String referenceId;
        public Map<String, Object> body;
    }

    public class CompositeRequest {
        public Boolean allOrNone;
        public List<SubRequest> compositeRequest;
    }

    public class SubResponse {
        public Integer httpStatusCode;
        public Object body;
        public String referenceId;
    }

    public class CompositeResponse {
        public List<SubResponse> compositeResponse;
    }

    public static CompositeResponse executeComposite(
        List<SubRequest> subRequests,
        Boolean allOrNone
    ) {
        CompositeRequest compReq = new CompositeRequest();
        compReq.allOrNone = allOrNone;
        compReq.compositeRequest = subRequests;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(
            URL.getOrgDomainUrl().toExternalForm() +
            '/services/data/v60.0/composite'
        );
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setBody(JSON.serialize(compReq));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            return (CompositeResponse) JSON.deserialize(
                res.getBody(), CompositeResponse.class
            );
        }
        throw new CalloutException('Composite API failed: ' + res.getBody());
    }
}
```

### Using Composite with Reference IDs
```apex
public class CompositeUsageExample {

    public static void createAccountWithContact() {
        List<CompositeApiService.SubRequest> subRequests =
            new List<CompositeApiService.SubRequest>();

        // Sub-request 1: Create Account
        CompositeApiService.SubRequest createAccount =
            new CompositeApiService.SubRequest();
        createAccount.method = 'POST';
        createAccount.url = '/services/data/v60.0/sobjects/Account';
        createAccount.referenceId = 'newAccount';
        createAccount.body = new Map<String, Object>{
            'Name' => 'Composite Test Account',
            'Industry' => 'Technology'
        };
        subRequests.add(createAccount);

        // Sub-request 2: Create Contact referencing the Account
        CompositeApiService.SubRequest createContact =
            new CompositeApiService.SubRequest();
        createContact.method = 'POST';
        createContact.url = '/services/data/v60.0/sobjects/Contact';
        createContact.referenceId = 'newContact';
        createContact.body = new Map<String, Object>{
            'FirstName' => 'John',
            'LastName' => 'Doe',
            'AccountId' => '@{newAccount.id}'  // Reference ID from sub-request 1
        };
        subRequests.add(createContact);

        // Sub-request 3: Query the created Account
        CompositeApiService.SubRequest queryAccount =
            new CompositeApiService.SubRequest();
        queryAccount.method = 'GET';
        queryAccount.url = '/services/data/v60.0/sobjects/Account/@{newAccount.id}';
        queryAccount.referenceId = 'getAccount';
        subRequests.add(queryAccount);

        CompositeApiService.CompositeResponse response =
            CompositeApiService.executeComposite(subRequests, true);

        for (CompositeApiService.SubResponse sub : response.compositeResponse) {
            System.debug(sub.referenceId + ': HTTP ' + sub.httpStatusCode);
        }
    }
}
```

### Key Points
- Maximum 25 subrequests per composite call.
- `allOrNone = true` rolls back all subrequests if any fail.
- Reference IDs let later subrequests use values from earlier ones (e.g., `@{refId.id}`).
- Subrequests execute sequentially in order.
- Counts against API request limits (each composite = 1 API call, but each subrequest counts toward governor limits).
