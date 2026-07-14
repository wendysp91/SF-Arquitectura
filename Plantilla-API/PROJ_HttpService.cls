// TODO [PROYECTO]: Renombrar clase a [NombreProyecto]HttpService
//
// Capa HTTP compartida para todos los callouts salientes del proyecto.
// Responsabilidades: Named Credential, timeout, retry, response parsing.
// No contiene lógica de negocio — eso va en PROJ_CalloutHandler.
public class PROJ_HttpService {

    // -------------------------------------------------------------------------
    // POST — envía JSON, recibe JSON
    // -------------------------------------------------------------------------
    public static HttpResponse post(String endpoint, Object payload) {
        String body = JSON.serialize(payload);
        return execute('POST', endpoint, body);
    }

    // -------------------------------------------------------------------------
    // GET — sin body
    // -------------------------------------------------------------------------
    public static HttpResponse get(String endpoint) {
        return execute('GET', endpoint, null);
    }

    // -------------------------------------------------------------------------
    // PATCH
    // -------------------------------------------------------------------------
    public static HttpResponse patch(String endpoint, Object payload) {
        String body = JSON.serialize(payload);
        return execute('PATCH', endpoint, body);
    }

    // -------------------------------------------------------------------------
    // Motor de ejecución con retry
    // Reintenta solo en 5xx o timeout. En 4xx falla inmediatamente.
    // -------------------------------------------------------------------------
    private static HttpResponse execute(String method, String endpoint, String body) {
        HttpRequest req = buildRequest(method, endpoint, body);
        HttpResponse res;
        Integer attempts = 0;

        while (attempts <= PROJ_Constants.MAX_RETRY_COUNT) {
            try {
                res = new Http().send(req);

                // Éxito o error del cliente (4xx) → no reintentar
                if (res.getStatusCode() < 500) {
                    return res;
                }

                // Error del servidor (5xx) → reintentar
                attempts++;
                if (attempts > PROJ_Constants.MAX_RETRY_COUNT) {
                    throw new PROJ_Exception(
                        'Sistema externo respondió ' + res.getStatusCode() +
                        ' después de ' + PROJ_Constants.MAX_RETRY_COUNT + ' reintentos.'
                    );
                }

            } catch (System.CalloutException e) {
                // Timeout u error de conexión → reintentar
                attempts++;
                if (attempts > PROJ_Constants.MAX_RETRY_COUNT) {
                    throw new PROJ_Exception(
                        'Timeout o error de conexión después de ' +
                        PROJ_Constants.MAX_RETRY_COUNT + ' reintentos: ' + e.getMessage()
                    );
                }
            }
        }

        return res;
    }

    // -------------------------------------------------------------------------
    // Construye el HttpRequest con Named Credential y timeout explícito.
    // Nunca hardcodear la URL base — viene del Named Credential.
    // -------------------------------------------------------------------------
    private static HttpRequest buildRequest(String method, String endpoint, String body) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(PROJ_Constants.NAMED_CREDENTIAL + endpoint);
        req.setMethod(method);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setTimeout(PROJ_Constants.HTTP_TIMEOUT_MS);

        // TODO [PROYECTO]: Agregar headers adicionales si el sistema externo los requiere.
        // Ejemplos: Authorization custom, X-Api-Key, X-Correlation-Id, etc.

        if (body != null) {
            req.setBody(body);
        }
        return req;
    }

    // -------------------------------------------------------------------------
    // Helper: verifica que la respuesta fue exitosa según el contrato del sistema externo.
    // Muchos sistemas devuelven HTTP 200 con { "success": false } en el body.
    // TODO [PROYECTO]: Adaptar esta lógica al contrato del sistema externo.
    // -------------------------------------------------------------------------
    public static Boolean isSuccess(HttpResponse res) {
        if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) return false;

        // Si el sistema externo usa un campo "success" en el body, validarlo aquí.
        // Ejemplo:
        // Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        // return parsed.containsKey('success') ? (Boolean) parsed.get('success') : true;

        return true;
    }
}
