// TODO [PROYECTO]: Renombrar clase a [NombreProyecto]HttpMock
//
// Mock reutilizable para todos los tests del proyecto que hagan callouts.
// Permite simular cualquier respuesta del sistema externo sin llamadas reales.
@isTest
public class PROJ_HttpMock implements HttpCalloutMock {

    private Integer statusCode;
    private String  body;

    public PROJ_HttpMock(Integer statusCode, String body) {
        this.statusCode = statusCode;
        this.body       = body;
    }

    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(statusCode);
        res.setHeader('Content-Type', 'application/json');
        res.setBody(body);
        return res;
    }

    // =========================================================================
    // Factories — un método por escenario estándar.
    // Agregar uno nuevo por cada respuesta específica del proyecto.
    // TODO [PROYECTO]: Adaptar los bodies JSON al contrato del sistema externo.
    // =========================================================================

    // Respuesta exitosa genérica
    public static PROJ_HttpMock success() {
        return new PROJ_HttpMock(200, '{"success": true, "confirmationId": "CONF-001"}');
    }

    // Respuesta exitosa con datos específicos
    // TODO [PROYECTO]: Agregar factories con los payloads reales del proyecto.
    public static PROJ_HttpMock successWithData(String confirmationId) {
        return new PROJ_HttpMock(200,
            '{"success": true, "confirmationId": "' + confirmationId + '"}'
        );
    }

    // Error del servidor (5xx) — para probar retry logic
    public static PROJ_HttpMock serverError() {
        return new PROJ_HttpMock(500, '{"error": "Internal Server Error"}');
    }

    // Error del cliente (4xx) — para probar validación
    public static PROJ_HttpMock clientError() {
        return new PROJ_HttpMock(400, '{"error": "Bad Request", "detail": "Campo requerido faltante"}');
    }

    // Sistema externo retorna success:false con HTTP 200
    public static PROJ_HttpMock businessError() {
        return new PROJ_HttpMock(200,
            '{"success": false, "errorMessage": "Registro no encontrado en sistema externo"}'
        );
    }

    // Respuesta con body vacío — para probar manejo de null
    public static PROJ_HttpMock emptyBody() {
        return new PROJ_HttpMock(200, '');
    }

    // Respuesta con JSON malformado — para probar manejo de parse errors
    public static PROJ_HttpMock malformedJson() {
        return new PROJ_HttpMock(200, 'esto no es json {{{');
    }
}
