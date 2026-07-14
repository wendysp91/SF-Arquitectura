# PLANTILLA: FSD / TDD — Technical Design Document
# (Functional & Technical Specification Document)

> **Instrucciones de uso:** Este documento es para el equipo técnico.
> Se elabora DESPUÉS de que el BPD esté firmado.
> Contiene el "cómo" construir lo que el BPD describe.
> El cliente NO necesita leer este documento, pero puede pedirlo como entregable.
>
> REGLA: Cada campo en el mapeo debe tener "¿Obligatorio?" completado.
> Ninguna sección puede quedar con "[placeholder]" cuando se entregue.

---

## Información del Documento

| Campo | Valor |
|-------|-------|
| **Cliente** | [Nombre del cliente] |
| **Proyecto** | [Nombre del proyecto] |
| **Número de documento** | [AAAA-MM-FSD-CLIENTE-v01] |
| **Versión** | 01 |
| **Fecha** | [DD/MM/AAAA] |
| **Elaborado por** | [Tu nombre] — Punto Commerce |
| **Referencia BPD** | [Número de documento del BPD aprobado] |

---

## Historial de Versiones

| Versión | Fecha | Responsable | Cambio |
|---------|-------|-------------|--------|
| 01 | [DD/MM/AAAA] | [Nombre] | Versión inicial |

---

## Aprobación

| Rol | Nombre | Firma | Fecha |
|-----|--------|-------|-------|
| Arquitecto Punto Commerce | [Tu nombre] | | |
| Desarrollador Punto Commerce | [Nombre] | | |
| Responsable técnico Cliente | [Nombre — solo si aplica] | | |

---

## 1. Resumen Ejecutivo Técnico

- **Plataforma:** Salesforce [Sales Cloud / Service Cloud / etc.] — [versión de API, ej: API v59]
- **Sistema externo:** [SAP versión X / otro sistema]
- **Patrón de integración:** [Integración directa REST / Middleware / Event-driven]
- **Autenticación principal:** OAuth 2.0 con Named Credentials
- **Número de integraciones:** [N]
- **Número de objetos custom:** [N]
- **Ambiente target:** [Sandbox: nombre] | [Producción: org ID]

---

## 2. Arquitectura de la Solución

### 2.1 Diagrama de Arquitectura

> [Insertar diagrama aquí — usar draw.io, Lucidchart, o similar]
> El diagrama debe mostrar: sistemas involucrados, dirección de flujo de datos,
> protocolos, y componentes de Salesforce.

### 2.2 Componentes de Salesforce

| Componente | Tipo | Descripción |
|-----------|------|-------------|
| [Nombre] | Apex Class / Trigger / Flow / LWC / Named Credential | [Para qué sirve] |
| ApexRESTHandler | Apex Class | Recibe llamadas entrantes de SAP |
| SAPCalloutService | Apex Class | Realiza llamadas salientes a SAP |
| LogManager | Apex Class | Centraliza el registro de logs |
| ErrorLog__c | Custom Object | Almacena errores de integración |
| [Nombre] | | |

### 2.3 Named Credentials

| Nombre | Sistema | URL base | Autenticación |
|--------|---------|----------|--------------|
| SAP_ERP_NC | SAP | [URL base de SAP] | OAuth 2.0 — Client Credentials |
| [Nombre] | | | |

### 2.4 Consideraciones de Seguridad

- **Autenticación:** OAuth 2.0 con Named Credentials (las credenciales no se hardcodean en Apex).
- **Perfiles:** [Listar qué perfil tiene acceso a qué API/objeto].
- **Datos sensibles:** [RFC, datos bancarios] — se manejan con field-level security.
- **IP Whitelisting:** [Especificar si aplica].

---

## 3. Objetos de Salesforce

### 3.1 Objetos Standard Modificados

| Objeto | Campos nuevos | Descripción del cambio |
|--------|--------------|----------------------|
| Account | SAP_Customer_Number__c (Text 20) | Número de cliente asignado por SAP |
| Account | Credit_Limit__c (Currency) | Límite de crédito desde SAP |
| [Objeto] | [Campo (tipo)] | |

### 3.2 Objetos Custom Creados

| Objeto API | Etiqueta | Descripción |
|-----------|---------|-------------|
| Order__c | Pedido | Pedido creado en Salesforce para enviar a SAP |
| OrderItem__c | Línea de Pedido | Productos del pedido |
| ErrorLog__c | Log de Errores | Registro de errores de integración |
| [NombreAPI__c] | [Etiqueta] | |

---

## 4. Detalle de Integraciones

> Una sección por integración. Cada campo DEBE tener valor — no dejar vacíos al entregar.

---

### 4.1 [Nombre de la Integración — ej: Sincronización de Productos SAP → Salesforce]

| Campo | Valor |
|-------|-------|
| **Dirección** | SAP → Salesforce |
| **Método HTTP** | POST |
| **Endpoint (Salesforce)** | `/services/apexrest/v1/products` |
| **Autenticación** | OAuth 2.0 — SAP autentica contra Salesforce |
| **Formato** | JSON |
| **Frecuencia** | 1 vez al día — [hora] — batch de máx. [N] registros |
| **Middleware** | No aplica (integración directa) |
| **Clase Apex** | `ProductSyncHandler.cls` |

#### Proceso Técnico

```
1. SAP envía POST a /services/apexrest/v1/products con lista de productos (JSON).
2. ProductSyncHandler.cls recibe y deserializa el payload.
3. Busca cada producto en Salesforce por SKU (campo SKU__c en Product2).
   - Si no existe → INSERT en Product2.
   - Si existe → UPDATE en Product2.
4. Procesa en bloques (bulkification) respetando governor limits.
5. Registra en ErrorLog__c los registros que fallaron.
6. Retorna respuesta JSON con:
   - totalProcessed: N
   - successCount: N
   - failedRecords: [{sku, error}]
```

#### Payload de Entrada (Request)

```json
{
  "products": [
    {
      "sku": "ABC123",
      "name": "Nombre del producto",
      "line": "Perfumería",
      "description": "Descripción",
      "piecesPerPallet": 40
    }
  ]
}
```

#### Payload de Salida (Response)

```json
{
  "status": "PARTIAL_SUCCESS",
  "totalProcessed": 40,
  "successCount": 38,
  "failedRecords": [
    {
      "sku": "XYZ999",
      "error": "Duplicate SKU found"
    }
  ]
}
```

#### Mapeo de Campos

| Campo JSON (SAP) | Objeto Salesforce | Campo API Salesforce | Tipo | Obligatorio | Notas |
|-----------------|------------------|---------------------|------|-------------|-------|
| sku | Product2 | SKU__c | Text(50) | **Sí** | Identificador único. Usado para dedup. |
| name | Product2 | Name | Text(255) | **Sí** | |
| line | Product2 | ProductLine__c | Picklist | **Sí** | Valores: Perfumería, Vinos, Cristalería |
| description | Product2 | Description | TextArea | No | |
| piecesPerPallet | Product2 | PiecesPerPallet__c | Number | No | |

#### Manejo de Errores

| Escenario | Comportamiento |
|-----------|---------------|
| Campo obligatorio vacío en SAP | Rechazar ese registro. Continuar con los demás. Registrar en ErrorLog__c. |
| SKU duplicado dentro del mismo batch | Procesar el primero. Registrar el duplicado en ErrorLog__c. |
| Salesforce DML error | Registrar en ErrorLog__c. Informar en la respuesta a SAP. |
| Timeout / SAP no llega | No aplica (SAP llama a Salesforce). |

#### Governor Limits y Consideraciones

- Procesamiento en bulk con `Database.insert(records, false)` para fallos parciales.
- Batch máximo: [N] registros para no superar límites DML.
- [Otras consideraciones específicas]

#### Dependencia con SAP

> Esto es lo que SAP debe cumplir para que la integración funcione.
> Si SAP no cumple, se levanta un CR.

- SAP debe exponer el endpoint en el formato JSON especificado arriba.
- SAP debe autenticarse con OAuth 2.0 usando las credenciales que se proveerán.
- [Otras dependencias técnicas de SAP]

---

### 4.2 [Nombre de la Integración — ej: Consulta de Inventario Salesforce → SAP]

| Campo | Valor |
|-------|-------|
| **Dirección** | Salesforce → SAP |
| **Método HTTP** | GET |
| **Endpoint (SAP)** | `[URL base SAP]/inventory/{sku}` |
| **Autenticación** | OAuth 2.0 — Named Credential: `SAP_ERP_NC` |
| **Formato** | JSON |
| **Frecuencia** | Bajo demanda (botón en pantalla) |
| **Clase Apex** | `InventoryCalloutService.cls` |

#### Proceso Técnico

```
1. Usuario presiona botón "Consultar Inventario" en la pantalla de Producto.
2. LWC/Aura Component llama al método Apex getInventory(sku).
3. InventoryCalloutService.cls hace GET a SAP usando Named Credential.
4. SAP responde con datos de inventario.
5. Apex deserializa la respuesta y retorna al componente.
6. El componente muestra los datos al usuario (sin guardar en Salesforce).
7. Si SAP retorna error o timeout: mostrar mensaje de error al usuario y
   registrar en ErrorLog__c.
```

#### Mapeo de Campos

| Campo JSON (SAP Response) | Mostrar en pantalla | Guardado en SF | Notas |
|--------------------------|--------------------|--------------:|-------|
| availableQuantity | Sí | **No** | Solo visualización |
| warehouse | Sí | **No** | Solo visualización |
| sku | Sí | N/A | |

---

### 4.N [Continuar el mismo patrón para cada integración]

---

## 5. Objeto de Log de Errores (ErrorLog__c)

| Campo API | Etiqueta | Tipo | Descripción |
|-----------|---------|------|-------------|
| Name | Nombre | Auto-number | Identificador automático del log |
| Integration__c | Integración | Text(100) | Nombre de la integración que generó el error |
| ErrorMessage__c | Mensaje de error | LongTextArea | Descripción técnica del error |
| RequestPayload__c | Request | LongTextArea | Payload que causó el error (JSON) |
| ResponsePayload__c | Response | LongTextArea | Respuesta recibida |
| RecordId__c | ID del Registro | Text(18) | SF record ID afectado (si aplica) |
| ExternalId__c | ID Externo | Text(100) | SKU, SAP ID u otro ID del sistema externo |
| Status__c | Estado | Picklist | Pendiente / Resuelto / Ignorado |
| CreatedDate | Fecha | DateTime | Auto — cuándo ocurrió |

---

## 6. Estrategia de Testing

### 6.1 Unit Tests (Responsabilidad Punto Commerce)

- Cobertura mínima: 85% por clase Apex.
- Incluir test para: camino feliz, campos obligatorios vacíos, registro duplicado, fallo de callout (mock).

### 6.2 Integration Tests (Sandbox con SAP de cliente)

| # | Escenario | Resultado esperado | Responsable |
|---|-----------|-------------------|-------------|
| 1 | Enviar 1 producto válido desde SAP | Producto creado en Salesforce | Punto Commerce + SAP cliente |
| 2 | Enviar producto con SKU duplicado | Error en log, no falla el batch | |
| 3 | Crear pedido válido desde Salesforce | Número de pedido SAP aparece en SF | |
| [N] | | | |

### 6.3 UAT (User Acceptance Testing — Responsabilidad del Cliente)

- El cliente designará [N] usuarios para hacer pruebas.
- Duración: [N] semanas.
- Criterio de aceptación: [N]% de los casos de prueba pasan sin errores bloqueantes.
- Los errores se clasifican en: Bloqueante (impide go-live) / Mayor (afecta funcionalidad) / Menor (cosmético).

---

## 7. Preguntas Técnicas Abiertas

> Igual que en el BPD, pero técnicas. Seguir hasta que todas tengan respuesta.

| # | Pregunta | Dirigida a | Fecha límite | Respuesta |
|---|---------|-----------|-------------|-----------|
| 1 | ¿Cuál es la versión exacta de la API de SAP? | Equipo SAP cliente | [Fecha] | |
| 2 | ¿SAP puede hacer OAuth 2.0 Client Credentials o necesita otro flujo? | Equipo SAP cliente | | |
| 3 | [Pregunta técnica] | | | |

---

## 8. Checklist de Entrega

> Completar antes de pasar a UAT.

- [ ] Todas las clases Apex tienen cobertura ≥ 85%
- [ ] Todos los campos en el mapeo tienen tipo y obligatorio definido
- [ ] Named Credentials configuradas en sandbox
- [ ] ErrorLog__c con datos de prueba verificados
- [ ] Flows/Triggers probados en sandbox
- [ ] Documento actualizado con endpoints reales (no [URL placeholder])
- [ ] Revisión de seguridad: ninguna credencial hardcodeada en Apex
- [ ] Revisión de governor limits: bulk patterns implementados
