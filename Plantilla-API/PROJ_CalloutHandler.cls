// TODO [PROYECTO]: Renombrar clase a [NombreProyecto]_[NombreEndpoint]Callout
// Ejemplo: GrandPet_RedeemCodeCallout, Glass_ProductSyncCallout
//
// OUTBOUND: Salesforce llama al sistema externo.
// Un archivo por endpoint / caso de uso. No mezclar varios endpoints en una clase.
// Responsabilidades: validar, construir payload, llamar HttpService, DML, retornar resultado.
//
// REGLA CRÍTICA: callout ANTES del DML. Salesforce no permite callout después de DML.
public class PROJ_CalloutHandler {

    // =========================================================================
    // Método principal — punto de entrada desde un Flow (@InvocableMethod),
    // un Trigger, un Batch, o cualquier otra capa.
    // TODO [PROYECTO]: Adaptar parámetros al caso de uso real.
    // =========================================================================
    public static Result execute(String externalId, String additionalParam) {

        // -- 1. Validar entrada --
        if (String.isBlank(externalId)) {
            throw new PROJ_Exception('externalId es obligatorio.');
        }
        // TODO [PROYECTO]: Agregar validaciones adicionales.

        // -- 2. Consultar datos de Salesforce necesarios para el payload --
        // SOQL aquí, antes del callout.
        // TODO [PROYECTO]: Reemplazar por el SOQL real del caso de uso.
        ExternalObject__c record = queryRecord(externalId);
        if (record == null) {
            throw new PROJ_Exception('Registro no encontrado para externalId: ' + externalId);
        }

        // -- 3. Construir el payload --
        RequestPayload payload = buildPayload(record, additionalParam);

        // -- 4. Llamar al sistema externo (callout antes del DML) --
        HttpResponse httpRes;
        try {
            // TODO [PROYECTO]: Cambiar el endpoint por el real.
            httpRes = PROJ_HttpService.post(PROJ_Constants.ENDPOINT_EXAMPLE, payload);
        } catch (PROJ_Exception e) {
            // Timeout o 5xx agotados los reintentos
            PROJ_Logger.log(
                PROJ_Constants.INTEGRATION_EXAMPLE,
                PROJ_Constants.STATUS_FAILURE,
                externalId,
                JSON.serialize(payload),
                null,
                e.getMessage()
            );
            throw e;
        }

        // -- 5. Parsear la respuesta --
        if (!PROJ_HttpService.isSuccess(httpRes)) {
            String errorMsg = 'HTTP ' + httpRes.getStatusCode() + ': ' + httpRes.getBody();
            PROJ_Logger.log(
                PROJ_Constants.INTEGRATION_EXAMPLE,
                PROJ_Constants.STATUS_FAILURE,
                externalId,
                JSON.serialize(payload),
                httpRes.getBody(),
                errorMsg
            );
            throw new PROJ_Exception(errorMsg);
        }

        ResponsePayload parsed;
        try {
            parsed = (ResponsePayload) JSON.deserialize(httpRes.getBody(), ResponsePayload.class);
        } catch (Exception e) {
            throw new PROJ_Exception('Respuesta inesperada del sistema externo: ' + httpRes.getBody());
        }

        // -- 6. DML — SIEMPRE después del callout --
        // TODO [PROYECTO]: Actualizar los campos reales con los datos de la respuesta.
        record.External_Confirmation__c = parsed.confirmationId;
        record.Status__c                = 'Sincronizado';
        update record;

        // -- 7. Log de éxito --
        PROJ_Logger.log(
            PROJ_Constants.INTEGRATION_EXAMPLE,
            PROJ_Constants.STATUS_SUCCESS,
            externalId,
            JSON.serialize(payload),
            httpRes.getBody(),
            null
        );

        // -- 8. Retornar resultado --
        return new Result(true, parsed.confirmationId, null);
    }

    // =========================================================================
    // SOQL centralizado — no poner queries dentro del método principal
    // TODO [PROYECTO]: Reemplazar objeto y campos por los reales.
    // =========================================================================
    private static ExternalObject__c queryRecord(String externalId) {
        List<ExternalObject__c> records = [
            SELECT Id, External_Id__c, Name, Status__c
            FROM   ExternalObject__c
            WHERE  External_Id__c = :externalId
            LIMIT  1
        ];
        return records.isEmpty() ? null : records[0];
    }

    // =========================================================================
    // Constructor del payload — separado para poder testearlo independientemente
    // TODO [PROYECTO]: Adaptar campos al contrato del sistema externo.
    // =========================================================================
    private static RequestPayload buildPayload(ExternalObject__c record, String additionalParam) {
        RequestPayload p = new RequestPayload();
        p.externalId      = record.External_Id__c;
        p.name            = record.Name;
        p.additionalParam = additionalParam;
        // TODO [PROYECTO]: Mapear los campos reales.
        return p;
    }

    // =========================================================================
    // DTOs
    // TODO [PROYECTO]: Adaptar al contrato real del sistema externo.
    // =========================================================================
    private class RequestPayload {
        String externalId;
        String name;
        String additionalParam;
        // TODO [PROYECTO]: Agregar campos del payload real.
    }

    private class ResponsePayload {
        String  confirmationId;
        Boolean success;
        String  errorMessage;
        // TODO [PROYECTO]: Mapear campos de la respuesta real.
    }

    // =========================================================================
    // Resultado tipado — evita devolver mapas genéricos o Strings crudos
    // =========================================================================
    public class Result {
        public Boolean success;
        public String  confirmationId;
        public String  errorMessage;

        public Result(Boolean success, String confirmationId, String errorMessage) {
            this.success        = success;
            this.confirmationId = confirmationId;
            this.errorMessage   = errorMessage;
        }
    }
}
