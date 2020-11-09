/**
 * Created by ferhatozsavran on 8/21/18.
 */

public with sharing class DependencyHandler {

    // it was not working from scratch org. it need to be tested.
    /*static public String APIEndpoint {
        get {
            if (APIEndpoint == null) {
                //memoize
                String orgId = UserInfo.getOrganizationId();
                String userId = UserInfo.getUserId();
                String sessionId = UserInfo.getSessionId();
                //use getSalesforceBaseUrl within batches and schedules (not Visualforce), and fix inconsistent protocol
                if (sessionId == null) {
                    return Url.getSalesforceBaseUrl().toExternalForm().replace('http:', 'https:');
                }
                PageReference pr = new PageReference('/id/' + orgId + '/' + userId);
                pr.getParameters().put('oauth_token', sessionId);
                pr.getParameters().put('format', 'json');

                //within test context use url class, else derive from identity api
                String data = Test.isRunningTest() ? '{"urls": {"rest": "' + Url.getSalesforceBaseUrl().toExternalForm() + '"}}' : pr.getContent().toString();
                Map<String,Object> result = (Map<String,Object>)Json.deserializeUntyped(data);
                Map<String,Object> urls = (Map<String,Object>)result.get('urls');

                //compose pod from the REST endpoint
                Url rest = new Url((String)urls.get('rest'));
                APIEndpoint = rest.getProtocol() + '://' + rest.getHost();
            }
            return APIEndpoint;
        }
    }*/

    /**
     * Returns dependency api's in json string. You have to prepare where condition and pass as parameter. You have to pass each metadata one by one and put OR between each condition.
     * @param whereCondition  Example where condition (MetadataComponentType = 'ApexClass' AND (MetadataComponentName = 'KanbanBoard' OR MetadataComponentName = 'KanbanBoardEditController')) OR (MetadataComponentType = 'ApexPage' AND (MetadataComponentName = 'KanbanBoardView'))
     * @return
     */
    public String returnJsonStringMetadataDependency(String whereCondition){
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v43.0/tooling/query?q=';

        // Note the escaping on newlines and quotes
        String query = 'SELECT MetadataComponentId, MetadataComponentName, MetadataComponentType, RefMetadataComponentId, RefMetadataComponentName, RefMetadataComponentType FROM MetadataComponentDependency WHERE ' + whereCondition;
        System.debug('**f**query : ' + query);
        query = EncodingUtil.urlEncode(query, 'UTF-8');

        String body = callOut(baseUrl, query);
        return body;
    }

    /**
     * Returns dependency api's in wrapper class. You have to prepare where condition and pass as parameter. You have to pass each metadata one by one and put OR between each condition.
     * @param whereCondition  Example where condition (MetadataComponentType = 'ApexClass' AND (MetadataComponentName = 'KanbanBoard' OR MetadataComponentName = 'KanbanBoardEditController')) OR (MetadataComponentType = 'ApexPage' AND (MetadataComponentName = 'KanbanBoardView'))
     * @return
     */
    public RequestResponse returnWrapperMetadataDependency(String whereCondition){
        String body = returnJsonStringMetadataDependency(whereCondition);
        System.debug('**f**body : ' + body);
        RequestResponse resp = new RequestResponse();
        if(String.isNotBlank(body)) {
            // Parse entire JSON response.
            JSONParser parser = JSON.createParser(body);
            resp = (RequestResponse) parser.readValueAs(RequestResponse.class);
        }
        return resp;
    }

    /**
     * Returns custom field details in json string by using tooling api. You have to prepare where condition and pass as parameter.
     * @param whereCondition Example wherecondition : DeveloperName = 'SOQL_Query' OR DeveloperName = 'Columns_SOQL' OR DeveloperName = 'Field_to_read_update' OR DeveloperName = 'Kanban_Board' OR DeveloperName = 'JSON_Settings' OR DeveloperName = 'SOQL_Json' OR DeveloperName = 'Description'
     * @return
     */
    public String returnJsonStringCustomFieldMetadata(String whereCondition){
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v43.0/tooling/query?q=';

        // Note the escaping on newlines and quotes
        String query = 'SELECT Id, DeveloperName, ManageableState, Metadata, NamespacePrefix, TableEnumOrId FROM CustomField WHERE ' + whereCondition;
        System.debug('**f**query : ' + query);
        query = EncodingUtil.urlEncode(query, 'UTF-8');

        String body = callOut(baseUrl, query);
        return body;
    }

    /**
     * Returns custom field details in wrapper class by using tooling api. You have to prepare where condition and pass as parameter.
     * @param whereCondition Example wherecondition : DeveloperName = 'SOQL_Query' OR DeveloperName = 'Columns_SOQL' OR DeveloperName = 'Field_to_read_update' OR DeveloperName = 'Kanban_Board' OR DeveloperName = 'JSON_Settings' OR DeveloperName = 'SOQL_Json' OR DeveloperName = 'Description'
     * @return
     */
    public RequestResponse returnWrapperCustomFieldMetadata(String whereCondition){
        String body = returnJsonStringCustomFieldMetadata(whereCondition);
        System.debug('**f**body : ' + body);
        RequestResponse resp = new RequestResponse();
        if(String.isNotBlank(body)) {
            // Parse entire JSON response.
            JSONParser parser = JSON.createParser(body);
            resp = (RequestResponse) parser.readValueAs(RequestResponse.class);
        }
        return resp;
    }

    /**
     * Returns custom object details in json string by using tooling api. You have to prepare where condition and pass as parameter.
     * @param whereCondition Example wherecondition : DeveloperName = 'Kanban_Board_View' OR DeveloperName = 'Kanban_Board'
     * @return
     */
    public String returnJsonStringCustomObjectMetadata(String whereCondition){
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v43.0/tooling/query?q=';

        // Note the escaping on newlines and quotes
        String query = 'SELECT Id, CustomHelpId, Description, DeveloperName, ExternalName, ExternalRepository, Language, ManageableState, NamespacePrefix, SharingModel FROM CustomObject WHERE ' + whereCondition;
        System.debug('**f**query : ' + query);
        query = EncodingUtil.urlEncode(query, 'UTF-8');

        String body = callOut(baseUrl, query);
        return body;
    }

    /**
     * Returns custom object details in wrapper class by using tooling api. You have to prepare where condition and pass as parameter.
     * @param whereCondition Example wherecondition : DeveloperName = 'Kanban_Board_View' OR DeveloperName = 'Kanban_Board'
     * @return
     */
    public RequestResponse returnWrapperCustomObjectMetadata(String whereCondition){
        String body = returnJsonStringCustomObjectMetadata(whereCondition);
        System.debug('**f**body : ' + body);
        RequestResponse resp = new RequestResponse();
        if(String.isNotBlank(body)) {
            // Parse entire JSON response.
            JSONParser parser = JSON.createParser(body);
            resp = (RequestResponse) parser.readValueAs(RequestResponse.class);
        }
        return resp;
    }

    /**
     * This is place where httprequest is completed
     * @param baseUrl send string value of the base url; For instance; https://enterprise-force-5000-dev-ed--c.cs83.visual.force.com/
     * @param query send string value of query; For instance; q=SELECT Id FROM CustomField
     * @return it will return of the request body
     */
    public String callOut(String baseUrl, String query) {
        HTTPRequest req = new HTTPRequest();
        req.setEndpoint(baseUrl + query);
        req.setMethod('GET');
        // OAuth header
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Sforce-Query-Options', 'batchSize=1000');
        req.setHeader('Sforce-Limit-Info', 'api-usage=100/5000');
        req.setTimeout(120000);
        String body = '';
        HttpResponse res = null;
        try{
            Http h = new Http();
            res = h.send(req);
            body = res.getBody();
            if(res.getStatusCode()==200) {
                return body;
            }
        } catch (Exception ex) {
            throw new DependencyHandlerException('Error while doing callout ' + baseUrl + '. error= ' + ex.getMessage());
        }
        throw new DependencyHandlerException('Error while doing callout ' + baseUrl + '. errorCode= ' + res.getStatusCode() + '. status= ' + res.getStatus());

        return null;
    }

    /**
     * Wrapper class to override responses
     */
    public class RequestResponse {
        public Integer size;
        public Integer totalSize;
        public Boolean done;
        public String queryLocator;
        public String entityTypeName;
        public List<Records> records;
        public String message;
        public String errorCode;

        public RequestResponse(){
            this.size = 0;
            this.totalSize = 0;
            this.done = false;
            this.queryLocator = '';
            this.entityTypeName = '';
            this.records = new List<Records>();
            this.message = '';
            this.errorCode = '';
        }
    }

    /**
     * Wrapper class to record of responses
     */
    public class Records {
        public Attributes attributes;

        // used at response of metadata dependency api
        public String MetadataComponentId;
        public String MetadataComponentName;
        public String MetadataComponentType;
        public String RefMetadataComponentId;
        public String RefMetadataComponentName;
        public String RefMetadataComponentType;

        // used at response of custom object api and custom field api
        public String Id;
        public String DeveloperName;
        public String ManageableState;
        public String NamespacePrefix;

        // used at response of custom object api
        public String CustomHelpId;
        public String Description;
        public String ExternalName;
        public String ExternalRepository;
        public String Language;
        public String SharingModel;

        // used at response of custom field api
        public String TableEnumOrId;

        public Records(){
            this.attributes = new Attributes();
            this.MetadataComponentId = '';
            this.MetadataComponentName = '';
            this.MetadataComponentType = '';
            this.RefMetadataComponentId = '';
            this.RefMetadataComponentName = '';
            this.RefMetadataComponentType = '';
            this.Id = '';
            this.CustomHelpId = '';
            this.Description = '';
            this.DeveloperName = '';
            this.ExternalName = '';
            this.ExternalRepository = '';
            this.Language = '';
            this.ManageableState = '';
            this.NamespacePrefix = '';
            this.SharingModel = '';
            this.TableEnumOrId = '';
        }
    }

    /**
     * Wrapper class to attributes of records
     */
    public class Attributes {
        public String type;
        public String url;

        public Attributes(){
            this.type = '';
            this.url = '';
        }
    }

    public class DependencyHandlerException extends Exception {}
}