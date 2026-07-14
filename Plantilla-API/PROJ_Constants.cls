// TODO [PROYECTO]: Renombrar clase a [NombreProyecto]Constants
public class PROJ_Constants {

    // -------------------------------------------------------------------------
    // Named Credential
    // El nombre debe coincidir exactamente con el Named Credential en Setup.
    // Nunca poner URLs ni tokens directamente aquí.
    // TODO [PROYECTO]: Cambiar por el nombre del Named Credential del proyecto.
    // -------------------------------------------------------------------------
    public static final String NAMED_CREDENTIAL = 'callout:PROJ_ExternalSystem_NC';

    // -------------------------------------------------------------------------
    // Endpoints (solo el path — la URL base viene del Named Credential)
    // TODO [PROYECTO]: Agregar un entry por cada endpoint que se consuma.
    // -------------------------------------------------------------------------
    public static final String ENDPOINT_EXAMPLE = '/v1/resource';

    // -------------------------------------------------------------------------
    // HTTP Config
    // -------------------------------------------------------------------------
    public static final Integer HTTP_TIMEOUT_MS  = 10000; // 10 segundos
    public static final Integer MAX_RETRY_COUNT  = 2;     // reintentos en 5xx/timeout

    // -------------------------------------------------------------------------
    // Procesamiento
    // -------------------------------------------------------------------------
    public static final Integer BATCH_SIZE = 200; // registros por solicitud

    // -------------------------------------------------------------------------
    // Valores de status en la respuesta estandarizada
    // -------------------------------------------------------------------------
    public static final String STATUS_SUCCESS         = 'SUCCESS';
    public static final String STATUS_PARTIAL_SUCCESS = 'PARTIAL_SUCCESS';
    public static final String STATUS_FAILURE         = 'FAILURE';

    // -------------------------------------------------------------------------
    // Nombres de integraciones para el log
    // TODO [PROYECTO]: Agregar un entry por cada integración.
    // -------------------------------------------------------------------------
    public static final String INTEGRATION_EXAMPLE = 'PROJ - Resource Sync';
}
