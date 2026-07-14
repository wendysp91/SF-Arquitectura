// TODO [PROYECTO]: Renombrar clase a [NombreProyecto]Logger
//
// PATRÓN CLAVE: el log se escribe en una transacción separada (@future).
// Esto garantiza que el log sobrevive aunque el DML principal haga rollback.
// Si el log estuviera en la misma transacción, desaparecería justo cuando más se necesita.
public class PROJ_Logger {

    // -------------------------------------------------------------------------
    // Método público — llamar desde cualquier clase para registrar un evento.
    // correlationId: ID único del request (opcional pero recomendado).
    // -------------------------------------------------------------------------
    public static void log(
        String integration,
        String status,
        String externalId,
        String requestPayload,
        String responsePayload,
        String errorMessage,
        String correlationId
    ) {
        // Truncar payloads grandes para no exceder el límite del campo LongTextArea
        String reqTrunc  = truncate(requestPayload,  131072);
        String respTrunc = truncate(responsePayload, 131072);
        String errTrunc  = truncate(errorMessage,    32768);

        insertLogAsync(
            integration, status, externalId,
            reqTrunc, respTrunc, errTrunc, correlationId
        );
    }

    // Sobrecarga sin correlationId para llamadas simples
    public static void log(
        String integration,
        String status,
        String externalId,
        String requestPayload,
        String responsePayload,
        String errorMessage
    ) {
        log(integration, status, externalId,
            requestPayload, responsePayload, errorMessage, null);
    }

    // -------------------------------------------------------------------------
    // @future garantiza transacción separada.
    // Si el proceso principal falla y hace rollback, este método ya está
    // encolado y se ejecuta de todas formas.
    // LIMITACIÓN: @future no puede recibir SObjects, solo primitivos y colecciones.
    // -------------------------------------------------------------------------
    @future
    private static void insertLogAsync(
        String integration,
        String status,
        String externalId,
        String requestPayload,
        String responsePayload,
        String errorMessage,
        String correlationId
    ) {
        try {
            // TODO [PROYECTO]: Reemplazar Integration_Log__c y sus campos
            // por el objeto de log real del proyecto.
            Integration_Log__c logRecord = new Integration_Log__c(
                Integration__c       = integration,
                Status__c            = status,
                External_Id__c       = externalId,
                Request_Payload__c   = requestPayload,
                Response_Payload__c  = responsePayload,
                Error_Message__c     = errorMessage,
                Correlation_Id__c    = correlationId,
                Timestamp__c         = System.now()
            );
            insert logRecord;
        } catch (Exception e) {
            // Si el log falla, no lanzar excepción — nunca dejar que el logger
            // rompa el flujo principal. Solo System.debug para visibilidad en dev.
            System.debug(LoggingLevel.ERROR,
                'PROJ_Logger: fallo al insertar log — ' + e.getMessage());
        }
    }

    private static String truncate(String s, Integer maxLen) {
        if (s == null) return null;
        return s.length() > maxLen ? s.substring(0, maxLen) : s;
    }
}
