// TODO [PROYECTO]: Renombrar clase a [NombreProyecto]Test o una clase por handler.
//
// Estructura base de tests. Cada test cubre un escenario específico.
// Naming: test_[ClaseQueTestea]_[Escenario]_[ResultadoEsperado]
// Cobertura mínima en Salesforce: 75% para deploy. Meta real: 85%+.
// Todos los escenarios negativos deben estar cubiertos, no solo el camino feliz.
@isTest
private class PROJ_Test {

    // =========================================================================
    // @TestSetup — datos que comparten todos los tests
    // Se ejecuta una sola vez y cada test corre en su propia transacción.
    // TODO [PROYECTO]: Crear los registros base que necesitan los tests.
    // =========================================================================
    @TestSetup
    static void setupData() {
        // TODO [PROYECTO]: Reemplazar por los objetos reales del proyecto.
        ExternalObject__c record = new ExternalObject__c(
            External_Id__c = 'EXT-001',
            Name           = 'Registro de prueba',
            Status__c      = 'Pendiente'
        );
        insert record;
    }

    // =========================================================================
    // Tests del CalloutHandler (Outbound: Salesforce → Sistema externo)
    // =========================================================================

    @isTest
    static void test_CalloutHandler_success_updatesRecord() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, PROJ_HttpMock.successWithData('CONF-999'));

        // Act
        Test.startTest();
        PROJ_CalloutHandler.Result result = PROJ_CalloutHandler.execute('EXT-001', 'paramValue');
        Test.stopTest();

        // Assert
        System.assert(result.success,           'Debería retornar success = true');
        System.assertEquals('CONF-999', result.confirmationId, 'confirmationId incorrecto');

        ExternalObject__c updated = [
            SELECT External_Confirmation__c, Status__c
            FROM   ExternalObject__c
            WHERE  External_Id__c = 'EXT-001'
        ];
        System.assertEquals('CONF-999',     updated.External_Confirmation__c, 'Campo no actualizado');
        System.assertEquals('Sincronizado', updated.Status__c,                'Status no actualizado');
    }

    @isTest
    static void test_CalloutHandler_recordNotFound_throwsException() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, PROJ_HttpMock.success());

        // Act & Assert
        Test.startTest();
        try {
            PROJ_CalloutHandler.execute('ID-INEXISTENTE', null);
            System.assert(false, 'Debería haber lanzado excepción');
        } catch (PROJ_Exception e) {
            System.assert(e.getMessage().contains('no encontrado'), 'Mensaje de error incorrecto');
        }
        Test.stopTest();
    }

    @isTest
    static void test_CalloutHandler_blankExternalId_throwsException() {
        Test.startTest();
        try {
            PROJ_CalloutHandler.execute('', null);
            System.assert(false, 'Debería haber lanzado excepción');
        } catch (PROJ_Exception e) {
            System.assert(e.getMessage().contains('obligatorio'), 'Mensaje de error incorrecto');
        }
        Test.stopTest();
    }

    @isTest
    static void test_CalloutHandler_serverError_throwsException() {
        // Arrange — simula 500 del sistema externo (agota los reintentos)
        Test.setMock(HttpCalloutMock.class, PROJ_HttpMock.serverError());

        // Act & Assert
        Test.startTest();
        try {
            PROJ_CalloutHandler.execute('EXT-001', null);
            System.assert(false, 'Debería haber lanzado excepción');
        } catch (PROJ_Exception e) {
            System.assert(e.getMessage() != null, 'Debería tener mensaje de error');
        }
        Test.stopTest();
    }

    @isTest
    static void test_CalloutHandler_businessError_throwsException() {
        // Sistema externo responde HTTP 200 pero con success:false en el body
        Test.setMock(HttpCalloutMock.class, PROJ_HttpMock.businessError());

        Test.startTest();
        try {
            PROJ_CalloutHandler.execute('EXT-001', null);
            System.assert(false, 'Debería haber lanzado excepción');
        } catch (PROJ_Exception e) {
            System.assert(e.getMessage() != null);
        }
        Test.stopTest();
    }

    // =========================================================================
    // Tests del RestHandler (Inbound: Sistema externo → Salesforce)
    // =========================================================================

    @isTest
    static void test_RestHandler_post_success_createsRecord() {
        // Arrange
        RestContext.request  = buildRestRequest('POST',
            '{"items": [{"externalId": "EXT-NEW", "name": "Producto nuevo"}]}');
        RestContext.response = new RestResponse();

        // Act
        Test.startTest();
        PROJ_RestHandler.ResponseWrapper result = PROJ_RestHandler.doPost();
        Test.stopTest();

        // Assert
        System.assertEquals(PROJ_Constants.STATUS_SUCCESS, result.status);
        System.assertEquals(1, result.totalProcessed);
        System.assertEquals(1, result.successCount);
        System.assertEquals(0, result.errorCount);
        System.assertEquals(200, RestContext.response.statusCode);

        List<ExternalObject__c> created = [
            SELECT External_Id__c FROM ExternalObject__c WHERE External_Id__c = 'EXT-NEW'
        ];
        System.assertEquals(1, created.size(), 'Debería haberse creado el registro');
    }

    @isTest
    static void test_RestHandler_post_existingRecord_updatesNotDuplicates() {
        // Verifica idempotencia: llamar dos veces no crea duplicados
        String body = '{"items": [{"externalId": "EXT-001", "name": "Nombre actualizado"}]}';

        RestContext.request  = buildRestRequest('POST', body);
        RestContext.response = new RestResponse();

        Test.startTest();
        PROJ_RestHandler.doPost();
        PROJ_RestHandler.doPost(); // segunda llamada con mismo payload
        Test.stopTest();

        List<ExternalObject__c> records = [
            SELECT Id FROM ExternalObject__c WHERE External_Id__c = 'EXT-001'
        ];
        System.assertEquals(1, records.size(), 'No debe haber duplicado — idempotencia fallida');
    }

    @isTest
    static void test_RestHandler_post_malformedBody_returns400() {
        RestContext.request  = buildRestRequest('POST', 'esto no es json');
        RestContext.response = new RestResponse();

        Test.startTest();
        PROJ_RestHandler.ResponseWrapper result = PROJ_RestHandler.doPost();
        Test.stopTest();

        System.assertEquals(PROJ_Constants.STATUS_FAILURE, result.status);
        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void test_RestHandler_post_missingRequiredField_returns400() {
        // Item sin externalId
        RestContext.request  = buildRestRequest('POST',
            '{"items": [{"name": "Sin ID externo"}]}');
        RestContext.response = new RestResponse();

        Test.startTest();
        PROJ_RestHandler.ResponseWrapper result = PROJ_RestHandler.doPost();
        Test.stopTest();

        System.assertEquals(PROJ_Constants.STATUS_FAILURE, result.status);
        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void test_RestHandler_post_emptyList_returnsSuccess() {
        RestContext.request  = buildRestRequest('POST', '{"items": []}');
        RestContext.response = new RestResponse();

        Test.startTest();
        PROJ_RestHandler.ResponseWrapper result = PROJ_RestHandler.doPost();
        Test.stopTest();

        // Lista vacía no es un error — simplemente no hay nada que procesar
        System.assertEquals(0, result.totalProcessed);
    }

    // =========================================================================
    // Tests del HttpService
    // =========================================================================

    @isTest
    static void test_HttpService_post_success_returnsResponse() {
        Test.setMock(HttpCalloutMock.class, PROJ_HttpMock.success());

        Test.startTest();
        HttpResponse res = PROJ_HttpService.post(PROJ_Constants.ENDPOINT_EXAMPLE,
            new Map<String, String>{'key' => 'value'});
        Test.stopTest();

        System.assertEquals(200, res.getStatusCode());
        System.assert(PROJ_HttpService.isSuccess(res));
    }

    @isTest
    static void test_HttpService_serverError_throwsAfterRetry() {
        Test.setMock(HttpCalloutMock.class, PROJ_HttpMock.serverError());

        Test.startTest();
        try {
            PROJ_HttpService.post(PROJ_Constants.ENDPOINT_EXAMPLE, null);
            System.assert(false, 'Debería haber lanzado excepción tras reintentos');
        } catch (PROJ_Exception e) {
            System.assert(e.getMessage().contains('reintentos'));
        }
        Test.stopTest();
    }

    // =========================================================================
    // Helper: construir RestRequest para tests de inbound
    // =========================================================================
    private static RestRequest buildRestRequest(String method, String body) {
        RestRequest req   = new RestRequest();
        req.httpMethod    = method;
        req.requestURI    = '/services/apexrest/v1/resource';
        req.requestBody   = Blob.valueOf(body);
        req.addHeader('Content-Type', 'application/json');
        // Opcional: agregar correlationId para tests que lo validen
        // req.addHeader('X-Correlation-Id', 'test-correlation-id-001');
        return req;
    }
}
