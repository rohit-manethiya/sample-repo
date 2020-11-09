@IsTest
private with sharing class TestHttpCalloutBuilder {
    @IsTest
    static void testBuildCalloutRequest() {
        final String testEndpoint = 'https://www.testEndpoint.com';
        final String testBody = '{"key": "value"}';

        Test.startTest();
        final MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator(200, 'Complete', 'testResponse', null);
        Test.setMock(HttpCalloutMock.class, mockResponse);
        final HttpResponse response = new HttpCalloutBuilder(testEndpoint, 'POST').setDefaultConfig().setBody(testBody).sendRequest();
        Test.stopTest();

        System.assertEquals('testResponse', response.getBody(), 'Unexpected HttpResponse');
    }
}