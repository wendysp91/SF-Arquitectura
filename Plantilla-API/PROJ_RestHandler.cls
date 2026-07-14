// TODO [PROYECTO]: Renombrar clase a [NombreProyecto]RestHandler
// TODO [PROYECTO]: Cambiar urlMapping por el path real del endpoint.
//
// INBOUND: sistema externo llama a Salesforce.
// Responsabilidades: recibir, validar, procesar en bulk, responder, loguear.
@RestResource(urlMapping='/v1/resource/*')
global class PROJ_RestHandler {

    // =========================================================================
    // POST — el más común para recibir datos del sistema externo
    // =========================================================================
    @HttpPost
    global static ResponseWrapper doPost() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        String correlationId = req.headers.get('X-Correlation-Id'); // optional
        String rawBody       = req.requestBody?.toString();
        RequestWrapper input;

        // ---------------------------------------------------------------------
        // 1. Parsear el body
        // ---------------------------------------------------------------------
        try {
            input = (RequestWrapper) JSON.deserialize(rawBody, RequestWrapper.class);
        } catch (Exception e) {
            res.statusCode = 400;
            ResponseWrapper badRequest = ResponseWrapper.failure(
                0, 'Body inválido o malformado: ' + e.getMessage()
            );
            PROJ_Logger.log(
                PROJ_Constants.INTEGRATION_EXAMPLE, PROJ_Constants.STATUS_FAILURE,
                null, rawBody, null, e.getMessage(), correlationId
            );
            return badRequest;
        }

        // ---------------------------------------------------------------------
        // 2. Validar campos obligatorios del request
        // TODO [PROYECTO]: Adaptar las validaciones al contrato del sistema externo.
        // ---------------------------------------------------------------------
        String validationError = validate(input);
        if (validationError != null) {
            res.statusCode = 400;
            ResponseWrapper invalid = ResponseWrapper.failure(0, validationError);
            PROJ_Logger.log(
                PROJ_Constants.INTEGRATION_EXAMPLE, PROJ_Constants.STATUS_FAILURE,
                null, rawBody, null, validationError, correlationId
            );
            return invalid;
        }

        // ---------------------------------------------------------------------
        // 3. Procesar en bulk
        // ---------------------------------------------------------------------
        ResponseWrapper result = process(input, correlationId);

        // ---------------------------------------------------------------------
        // 4. Determinar HTTP status code de la respuesta
        // ---------------------------------------------------------------------
        if (result.status == PROJ_Constants.STATUS_SUCCESS) {
            res.statusCode = 200;
        } else if (result.status == PROJ_Constants.STATUS_PARTIAL_SUCCESS) {
            res.statusCode = 207; // Multi-Status
        } else {
            res.statusCode = 500;
        }

        // ---------------------------------------------------------------------
        // 5. Log (transacción separada — sobrevive al rollback)
        // ---------------------------------------------------------------------
        PROJ_Logger.log(
            PROJ_Constants.INTEGRATION_EXAMPLE,
            result.status,
            null,
            rawBody,
            JSON.serialize(result),
            result.errorCount > 0 ? result.errorCount + ' registros con error' : null,
            correlationId
        );

        return result;
    }

    // =========================================================================
    // GET — para consultas (si aplica)
    // =========================================================================
    @HttpGet
    global static ResponseWrapper doGet() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        // TODO [PROYECTO]: Implementar lógica de consulta si el endpoint lo requiere.
        // String externalId = req.requestParams.get('id');

        res.statusCode = 200;
        return ResponseWrapper.success(0, 0, new List<FailedRecord>());
    }

    // =========================================================================
    // Lógica de procesamiento bulk
    // TODO [PROYECTO]: Reemplazar ExternalObject__c por el objeto real.
    // =========================================================================
    private static ResponseWrapper process(RequestWrapper input, String correlationId) {
        // TODO [PROYECTO]: Adaptar el tipo de item a lo que envía el sistema externo.
        List<ExternalItem> items = input.items;
        if (items == null || items.isEmpty()) {
            return ResponseWrapper.success(0, 0, new List<FailedRecord>());
        }

        // -- Paso 1: buscar registros existentes para upsert (idempotencia) --
        // TODO [PROYECTO]: Adaptar el campo de búsqueda al identificador único del proyecto.
        Set<String> externalIds = new Set<String>();
        for (ExternalItem item : items) {
            if (item.externalId != null) externalIds.add(item.externalId);
        }

        Map<String, ExternalObject__c> existing = new Map<String, ExternalObject__c>();
        for (ExternalObject__c record : [
            SELECT Id, External_Id__c
            FROM   ExternalObject__c
            WHERE  External_Id__c IN :externalIds
        ]) {
            existing.put(record.External_Id__c, record);
        }

        // -- Paso 2: mapear items a SObjects --
        List<ExternalObject__c> toUpsert = new List<ExternalObject__c>();
        for (ExternalItem item : items) {
            ExternalObject__c record = existing.containsKey(item.externalId)
                ? existing.get(item.externalId)
                : new ExternalObject__c();

            // TODO [PROYECTO]: Mapear los campos del item al objeto de Salesforce.
            record.External_Id__c = item.externalId;
            record.Name           = item.name;
            // record.Campo__c    = item.campo;

            toUpsert.add(record);
        }

        // -- Paso 3: upsert con fallos parciales --
        // El false permite que un error en un registro no tire todo el lote.
        // TODO [PROYECTO]: Cambiar External_Id__c por el External ID field del objeto.
        List<Database.UpsertResult> results = Database.upsert(toUpsert, ExternalObject__c.External_Id__c, false);

        // -- Paso 4: recolectar errores --
        Integer successCount = 0;
        List<FailedRecord> failed = new List<FailedRecord>();

        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                successCount++;
            } else {
                String errorMsg = results[i].getErrors()[0].getMessage();
                failed.add(new FailedRecord(items[i].externalId, errorMsg));
            }
        }

        // -- Paso 5: determinar status de la respuesta --
        Integer total = items.size();
        if (failed.isEmpty()) {
            return ResponseWrapper.success(total, successCount, failed);
        } else if (successCount > 0) {
            return ResponseWrapper.partialSuccess(total, successCount, failed);
        } else {
            return ResponseWrapper.failure(total, 'Todos los registros fallaron.');
        }
    }

    // =========================================================================
    // Validación de entrada
    // TODO [PROYECTO]: Agregar las validaciones específicas del proyecto.
    // Retorna null si todo está bien, o un mensaje de error si algo falla.
    // =========================================================================
    private static String validate(RequestWrapper input) {
        if (input == null) return 'El body no puede estar vacío.';
        if (input.items == null || input.items.isEmpty()) return 'La lista de items no puede estar vacía.';

        for (ExternalItem item : input.items) {
            if (String.isBlank(item.externalId)) return 'El campo externalId es obligatorio en todos los items.';
            if (String.isBlank(item.name))       return 'El campo name es obligatorio en todos los items.';
            // TODO [PROYECTO]: Agregar validaciones adicionales por campo.
        }
        return null;
    }

    // =========================================================================
    // DTOs — Request
    // TODO [PROYECTO]: Adaptar los campos al contrato del sistema externo.
    // =========================================================================
    global class RequestWrapper {
        global List<ExternalItem> items;
    }

    global class ExternalItem {
        global String externalId; // TODO [PROYECTO]: Renombrar al identificador real (sku, sapId, etc.)
        global String name;
        // TODO [PROYECTO]: Agregar campos adicionales según el contrato.
    }

    // =========================================================================
    // DTOs — Response (esquema estandarizado — nunca cambia entre proyectos)
    // =========================================================================
    global class ResponseWrapper {
        global String            status;
        global Integer           totalProcessed;
        global Integer           successCount;
        global Integer           errorCount;
        global List<FailedRecord> failedRecords;
        global String            message;

        private ResponseWrapper() {}

        public static ResponseWrapper success(Integer total, Integer success, List<FailedRecord> failed) {
            ResponseWrapper r = new ResponseWrapper();
            r.status         = PROJ_Constants.STATUS_SUCCESS;
            r.totalProcessed = total;
            r.successCount   = success;
            r.errorCount     = 0;
            r.failedRecords  = failed;
            return r;
        }

        public static ResponseWrapper partialSuccess(Integer total, Integer success, List<FailedRecord> failed) {
            ResponseWrapper r = new ResponseWrapper();
            r.status         = PROJ_Constants.STATUS_PARTIAL_SUCCESS;
            r.totalProcessed = total;
            r.successCount   = success;
            r.errorCount     = failed.size();
            r.failedRecords  = failed;
            return r;
        }

        public static ResponseWrapper failure(Integer total, String message) {
            ResponseWrapper r = new ResponseWrapper();
            r.status         = PROJ_Constants.STATUS_FAILURE;
            r.totalProcessed = total;
            r.successCount   = 0;
            r.errorCount     = total;
            r.failedRecords  = new List<FailedRecord>();
            r.message        = message;
            return r;
        }
    }

    global class FailedRecord {
        global String externalId;
        global String error;

        public FailedRecord(String externalId, String error) {
            this.externalId = externalId;
            this.error      = error;
        }
    }
}
