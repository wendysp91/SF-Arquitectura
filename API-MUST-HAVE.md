# API & Integración — Estándares de Calidad

## Obligatorio (Must Have)

### 1. Single Responsibility — Clases por capa
Cada clase tiene una sola responsabilidad. Nadie mezcla lógica de negocio con HTTP o con DML.

```
Controller / Handler   ← punto de entrada (REST Resource, trigger handler)
Service / Callout      ← lógica de negocio y orquestación
DAO                    ← toda la SOQL y DML aquí
Utils / Helpers        ← funciones reutilizables sin estado
```

### 2. Bulkification
Nunca SOQL, DML ni callout dentro de un loop. Siempre operar sobre colecciones.

```apex
// MAL
for (Order__c o : orders) {
    insert o;  // DML en loop — explota en el registro 151
}

// BIEN
insert orders;
```

### 3. Idempotencia
Si el sistema externo llama dos veces con el mismo payload (retry, bug, timeout),
el resultado debe ser el mismo — sin duplicados.

Implementar con `upsert` usando External ID en lugar de `insert` ciego.

```apex
// MAL — crea duplicado si llega dos veces
insert new Product2(Name = p.name, SKU__c = p.sku);

// BIEN — segunda llamada actualiza, no duplica
upsert products SKU__c;
```

> Es el error más común y el más difícil de limpiar después en producción.

### 4. Named Credentials — cero hardcoding
URLs, tokens, usuarios y contraseñas nunca van en el código Apex.
Van en Named Credentials o Custom Metadata.

```apex
// MAL
req.setEndpoint('https://api.mescalina.com/v1/redeem?token=abc123');

// BIEN
req.setEndpoint('callout:Mescalina_NC/v1/redeem');
```

### 5. Validación de entrada
Validar campos obligatorios y formato antes de tocar la base de datos o hacer callout.
Devolver error claro con campo y motivo. No dejar que el sistema falle con una
NullPointerException genérica en la línea 47.

```apex
if (String.isBlank(req.sku)) {
    return errorResponse('sku', 'Campo obligatorio vacío');
}
```

### 6. Retry logic para callouts
Reintentar automáticamente en timeout o 5xx (errores del servidor).
No reintentar en 4xx (errores del cliente — no se van a resolver solos).
Límite de 2-3 intentos máximo.

```
200, 201        → éxito, no reintentar
400, 401, 403   → error del cliente, no reintentar
500, 503        → error del servidor, reintentar hasta 2 veces
timeout         → reintentar hasta 2 veces
```

### 7. Timeout explícito en HttpRequest
Siempre definir `request.setTimeout(N)`. Sin esto, Salesforce usa el default
y puede dejar la transacción colgada. El timeout debe ser realista para lo que
el sistema externo puede responder y menor al límite de Salesforce (120s sync).

```apex
HttpRequest req = new HttpRequest();
req.setTimeout(10000); // 10 segundos
```

### 8. Respuesta estandarizada — siempre el mismo esquema
Éxito, error parcial o error total: la respuesta siempre tiene la misma estructura.
El consumidor no debe adivinar el formato según el escenario.

```json
{
  "status": "PARTIAL_SUCCESS",
  "totalProcessed": 40,
  "successCount": 38,
  "errorCount": 2,
  "failedRecords": [
    { "externalId": "SKU-999", "error": "Producto no encontrado" }
  ]
}
```

Valores de `status`: `SUCCESS` / `PARTIAL_SUCCESS` / `FAILURE`

### 9. Database.insert(list, false) — fallos parciales
El `false` permite que un error en un registro no tire todo el lote.
Procesar los demás y registrar los que fallaron individualmente.

```apex
List<Database.SaveResult> results = Database.insert(records, false);
for (Integer i = 0; i < results.size(); i++) {
    if (!results[i].isSuccess()) {
        logError(records[i], results[i].getErrors());
    }
}
```

### 10. Log en transacción separada — sobrevive al rollback
Si la integración falla y Salesforce hace rollback, el log también desaparece
porque está en la misma transacción. El log debe escribirse en una transacción
independiente para que sobreviva aunque todo lo demás falle.

Opciones:
- `@future` para insertar el log de forma asíncrona
- Platform Events — el subscriber inserta el log en su propia transacción
- `Database.Savepoint` + rollback selectivo

> Cuando más necesitas el log es exactamente cuando algo falló.
> Sin esto, en el peor momento no tienes trazabilidad.

### 11. Callout siempre antes del DML
Salesforce no permite hacer un callout HTTP después de haber ejecutado DML
en la misma transacción — lanza excepción. El orden es siempre:
callout primero, DML después.

```apex
// ORDEN CORRECTO
String sapResponse = SAPCallout.post(payload);   // 1. callout
insert new Order__c(...);                         // 2. DML
```

---

## Eleva la API (Nice to Have)

### Correlation ID por request
El sistema externo envía un UUID en el header o body del request.
Tú lo guardas en el log y lo devuelves en la response.
Cuando hay un problema, el cliente comparte el ID y en segundos
encuentras exactamente qué pasó, cuándo y con qué datos.

```json
// Request entrante
{ "correlationId": "a1b2-c3d4-e5f6", "products": [...] }

// Log guardado
{ "correlationId": "a1b2-c3d4-e5f6", "timestamp": "...", "status": "FAILURE" }

// Response devuelta
{ "correlationId": "a1b2-c3d4-e5f6", "status": "FAILURE", ... }
```

### Circuit Breaker
Si el sistema externo falla N veces seguidas en un período corto, dejar de llamarlo
temporalmente (ej: 30 minutos) en lugar de seguir acumulando errores.
Protege ambos sistemas.

Se implementa con un campo en Custom Metadata que guarda el estado del sistema
externo y una clase que lo consulta antes de hacer el callout.

```
Estado: CLOSED   → llamadas normales
Estado: OPEN     → sistema caído, no llamar por X minutos
Estado: HALF-OPEN → probar una llamada para ver si se recuperó
```

### Health Check endpoint
Un endpoint `/api/health` que devuelve el estado de la API.
Permite que el sistema externo verifique disponibilidad antes de enviar datos,
y al equipo hacer un ping rápido sin efecto secundario.

```json
GET /services/apexrest/v1/health
→ { "status": "ok", "version": "v1", "timestamp": "2026-03-01T10:00:00Z" }
```

### Versionado en la URL
Incluir la versión en el path desde el inicio.
Cuando necesites cambiar el contrato de la API, creas `/v2/` y el cliente migra cuando puede.
Sin versión, cualquier cambio breaking obliga a coordinar todo al mismo tiempo.

```
/services/apexrest/v1/products   ← versión actual
/services/apexrest/v2/products   ← nueva versión con cambios breaking
```

### Alertas proactivas por error rate
En lugar de esperar a que el cliente reporte el problema, disparar una alerta
automática cuando el error rate supera un umbral (ej: más del 10% de fallos
en la última hora). Cambia la postura de reactivo a proactivo.

Opciones de implementación: email, Slack, caso en Salesforce, alerta en dashboard.

### Dead Letter Queue
Un objeto o mecanismo donde van los registros que fallaron y pueden reintentarse
sin que el sistema externo tenga que reenviar el payload.

Útil cuando el error es temporal (sistema externo caído, ahora disponible → reintentar).

```
ErrorLog__c con campo Status__c = Pendiente / Reintentando / Resuelto / Ignorado
+ Scheduled Job que reintenta los Pendiente cada N horas
```

### Paginación para respuestas grandes
Si un endpoint puede devolver miles de registros, nunca devolverlos todos de una vez.

```json
{
  "page": 1,
  "pageSize": 200,
  "totalRecords": 5000,
  "totalPages": 25,
  "data": [...]
}
```

### Custom Metadata para configuración por ambiente
URLs, tamaños de batch, thresholds de reintentos — en Custom Metadata en lugar
del código. Permite cambiar configuración en producción sin un deploy.

```
// En lugar de constantes en Apex
public static final Integer BATCH_SIZE = 200;

// Custom Metadata — configurable sin deploy
Integration_Config__mdt config = [SELECT Batch_Size__c FROM Integration_Config__mdt LIMIT 1];
```

---

## Resumen rápido

```
OBLIGATORIO
├── Single Responsibility (clases por capa)
├── Bulkification (nunca SOQL/DML/callout en loop)
├── Idempotencia (upsert con External ID)           ← el más subestimado
├── Named Credentials (cero hardcoding)
├── Validación de entrada antes de procesar
├── Retry logic (solo en 5xx / timeout)
├── Timeout explícito en HttpRequest
├── Respuesta estandarizada (siempre mismo esquema)
├── Database.insert(list, false) — fallos parciales
├── Log en transacción separada (sobrevive al rollback)  ← el más ignorado
└── Callout antes del DML (regla de Salesforce)

ELEVA LA API
├── Correlation ID por request
├── Circuit Breaker
├── Health Check endpoint
├── Versionado en URL (/v1/)
├── Alertas proactivas por error rate
├── Dead Letter Queue
├── Paginación para respuestas grandes
└── Custom Metadata para configuración por ambiente
```
