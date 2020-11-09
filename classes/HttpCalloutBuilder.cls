public inherited sharing class HttpCalloutBuilder {
    private final HttpRequest request;
    private final Id userId {
        get {
            if (userId == null) {
                userId = UserInfo.getUserId();
            }
            return userId;
        }
        set;
    }
    private final Id orgId {
        get {
            if (orgId == null) {
                orgId = UserInfo.getOrganizationId();
            }
            return orgId;
        }
        set;
    }

    public HttpCalloutBuilder(final String endpointURL, final String method) {
        request = new HttpRequest();
        request.setEndpoint(endpointURL);
        request.setMethod(method);
    }

    public HttpCalloutBuilder setDefaultConfig() {
        setHeader('userId', userId);
        setHeader('orgId', orgId);
        setHeader('token', getAuthenticationToken());
        setHeader('Accept', 'application/json');
        setHeader('content-type', 'application/json');
        request.setTimeout(30000);
        return this;
    }

    public HttpCalloutBuilder setHeader(final String headerKey, final String headerValue) {
        request.setHeader(headerKey, headerValue);
        return this;
    }

    private String getAuthenticationToken() {
        final String fakeSessionId = '<sessionId might change>';
        final String currentDate = Datetime.now().formatGmt('yyyy-MM-dd');
        final String dummyData = 'Copado Deployer by Copado Ltd' + userId + orgId + fakeSessionId + currentDate;
        final Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(dummyData));
        return EncodingUtil.convertToHex(hash);
    }

    public HttpCalloutBuilder setBody(final String body) {
        request.setBody(body);
        return this;
    }

    public HttpResponse sendRequest() {
        return new Http().send(request);
    }
}