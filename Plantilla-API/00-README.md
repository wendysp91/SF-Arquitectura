# Plantilla Base — API & Integración Salesforce

## Cómo usar esta plantilla

1. Copiar toda la carpeta y renombrarla con el nombre del proyecto.
2. Reemplazar el prefijo `PROJ_` por el prefijo del proyecto (ej: `GrandPet_`, `Glass_`, `Grin_`).
3. Buscar todos los comentarios `// TODO [PROYECTO]:` y completarlos.
4. No eliminar ningún patrón base (logging, retry, validación, etc.) — solo agregar encima.

## Archivos incluidos

| Archivo | Propósito | Cuándo usarlo |
|---------|-----------|---------------|
| `PROJ_Exception.cls` | Tipo de excepción custom del proyecto | Siempre |
| `PROJ_Constants.cls` | URLs, timeouts, config centralizada | Siempre |
| `PROJ_Logger.cls` | Log en transacción separada (sobrevive rollback) | Siempre |
| `PROJ_HttpService.cls` | HTTP con retry, timeout, Named Credential | Salesforce llama a sistema externo |
| `PROJ_RestHandler.cls` | REST Resource — sistema externo llama a Salesforce | Sistema externo llama a Salesforce |
| `PROJ_CalloutHandler.cls` | Lógica de un callout específico (un caso de uso) | Salesforce llama a sistema externo |
| `PROJ_HttpMock.cls` | Mock para tests de callouts | Siempre (testing) |
| `PROJ_Test.cls` | Estructura base de tests | Siempre (testing) |

## Las dos direcciones de integración

```
INBOUND  → Sistema externo llama a Salesforce
           Usar: PROJ_RestHandler.cls

OUTBOUND → Salesforce llama a sistema externo
           Usar: PROJ_HttpService.cls + PROJ_CalloutHandler.cls
```

## Must-haves ya implementados en la plantilla

- Single Responsibility (una clase por responsabilidad)
- Bulkification (nunca SOQL/DML/callout en loop)
- Idempotencia (upsert con External ID)
- Named Credentials (sin hardcoding)
- Validación de entrada
- Retry logic (2 intentos en 5xx/timeout)
- Timeout explícito
- Respuesta estandarizada (siempre mismo esquema)
- Database.insert(list, false) — fallos parciales
- Log en transacción separada (@future)
- Callout antes del DML
