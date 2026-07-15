# Setup: Integration_Log__c + Reportes + Dashboard

Antes de que el Logger funcione, hay que crear el objeto y sus campos en Salesforce.
Después, con ese objeto, se crean los 5 reportes base y el dashboard.

---

## Paso 1 — Crear el objeto Integration_Log__c

**Setup → Object Manager → Create → Custom Object**

| Campo del asistente | Valor |
|--------------------|-------|
| Label | Integration Log |
| Plural Label | Integration Logs |
| Object Name | Integration_Log (API name queda Integration_Log__c) |
| Record Name | Log Number |
| Data Type | Auto Number — formato: LOG-{00000} |
| Allow Reports | ✅ Sí |
| Allow Activities | No |
| Track Field History | No |
| Allow in Chatter | No |

---

## Paso 2 — Crear los campos

**Object Manager → Integration_Log__c → Fields & Relationships → New**

Crear en este orden:

| # | Field Label | API Name | Type | Length / Values | Required |
|---|------------|----------|------|-----------------|----------|
| 1 | Integration | Integration__c | Text | 255 | ✅ |
| 2 | Status | Status__c | Picklist | SUCCESS, PARTIAL_SUCCESS, FAILURE | ✅ |
| 3 | External Id | External_Id__c | Text | 255 | No |
| 4 | Correlation Id | Correlation_Id__c | Text | 255 | No |
| 5 | Timestamp | Timestamp__c | Date/Time | — | No |
| 6 | Error Message | Error_Message__c | Long Text Area | 32,768 | No |
| 7 | Request Payload | Request_Payload__c | Long Text Area | 131,072 | No |
| 8 | Response Payload | Response_Payload__c | Long Text Area | 131,072 | No |

> **Nota sobre Request/Response Payload:** Long Text Area no es searchable ni filtrable
> en reportes. Si necesitas filtrar por contenido del payload, usa Text Area (Rich)
> o guarda solo los campos clave como campos separados (ej: SKU__c, Order_Id__c).

### Picklist de Status — valores y colores

En **Setup → Object Manager → Integration_Log__c → Fields → Status__c → Edit Values**:

| Valor | Color sugerido |
|-------|---------------|
| SUCCESS | Verde |
| PARTIAL_SUCCESS | Amarillo |
| FAILURE | Rojo |

---

## Paso 3 — Verificar el Logger

Con el objeto creado, el Logger ya puede escribir. Verificar en Developer Console:

```apex
// Ejecutar en Anonymous Apex para confirmar que funciona
PROJ_Logger.log(
    'Test Integration',
    'SUCCESS',
    'EXT-001',
    '{"test": "request"}',
    '{"test": "response"}',
    null,
    'test-correlation-id'
);
```

Esperar 10-15 segundos (es @future) y verificar en:
**App Launcher → Integration Logs** que el registro aparece.

---

## Paso 4 — Crear el Custom Report Type

Sin esto, los reportes no pueden acceder al objeto.

**Setup → Report Types → New Custom Report Type**

| Campo | Valor |
|-------|-------|
| Primary Object | Integration Log |
| Report Type Label | Integration Logs |
| Report Type Name | Integration_Logs |
| Category | Administrative Reports (o crear "Monitoring") |
| Deployment Status | Deployed |

En el paso de campos: marcar todos los campos del objeto como disponibles en reportes.

---

## Paso 5 — Crear los 5 reportes base

Ir a **Reports → New Report → Integration Logs**

---

### Reporte 1: Llamadas de Hoy por Integración

**Propósito:** ver cuántas llamadas hizo cada integración hoy y si el volumen es normal.

| Configuración | Valor |
|--------------|-------|
| Report Format | Summary |
| Group By (rows) | Integration__c |
| Columns | Integration__c, Status__c, Count |
| Filter 1 | Created Date = TODAY |
| Sort | Count descendente |
| Nombre | [PROYECTO] - Llamadas de Hoy por Integración |

---

### Reporte 2: Error Rate últimos 7 días (por día)

**Propósito:** ver la tendencia de errores. Un día malo es normal; varios días seguidos es un problema.

| Configuración | Valor |
|--------------|-------|
| Report Format | Summary |
| Group By (rows) | Created Date (agrupar por: Day) |
| Group By (columns) | Status__c |
| Columns | Count |
| Filter 1 | Created Date = LAST 7 DAYS |
| Chart | Line chart — eje X: fecha, eje Y: count, series: Status |
| Nombre | [PROYECTO] - Error Rate Últimos 7 Días |

---

### Reporte 3: Top Errores Más Frecuentes

**Propósito:** saber dónde concentrar el esfuerzo. El error más frecuente es el primero en resolver.

| Configuración | Valor |
|--------------|-------|
| Report Format | Summary |
| Group By (rows) | Error_Message__c |
| Columns | Error_Message__c, Integration__c, Count |
| Filter 1 | Status__c = FAILURE |
| Filter 2 | Created Date = THIS MONTH |
| Sort | Count descendente |
| Row Limit | 10 |
| Nombre | [PROYECTO] - Top Errores Este Mes |

> Si los mensajes de error son muy variados (incluyen IDs dinámicos como "SKU-123 not found"),
> considera guardar solo el tipo de error en un campo separado (ej: Error_Type__c = "SKU_NOT_FOUND")
> para que los reportes puedan agrupar correctamente.

---

### Reporte 4: Últimos Registros Fallidos (con detalle)

**Propósito:** debugging inmediato. Ver qué falló en las últimas horas con suficiente detalle para actuar.

| Configuración | Valor |
|--------------|-------|
| Report Format | Tabular |
| Columns | Timestamp__c, Integration__c, External_Id__c, Correlation_Id__c, Error_Message__c |
| Filter 1 | Status__c = FAILURE |
| Filter 2 | Created Date = TODAY (o LAST 7 DAYS) |
| Sort | Timestamp__c descendente |
| Row Limit | 50 |
| Nombre | [PROYECTO] - Errores Recientes con Detalle |

---

### Reporte 5: Resumen del Mes por Integración y Status

**Propósito:** el reporte ejecutivo. Cuántas llamadas hizo cada integración este mes y cuántas fallaron.

| Configuración | Valor |
|--------------|-------|
| Report Format | Matrix |
| Group By (rows) | Integration__c |
| Group By (columns) | Status__c |
| Summary | Count of rows |
| Filter 1 | Created Date = THIS MONTH |
| Nombre | [PROYECTO] - Resumen Mensual por Integración |

---

## Paso 6 — Crear el Dashboard

**Dashboards → New Dashboard**

Nombre: `[PROYECTO] - Monitoring API`

Agregar 5 componentes en este orden:

---

### Componente 1 — Llamadas de hoy (métrica rápida)

| Campo | Valor |
|-------|-------|
| Tipo | Metric |
| Reporte | Reporte 1 (Llamadas de Hoy) |
| Mostrar | Record Count total |
| Subtítulo | "Llamadas totales hoy" |

---

### Componente 2 — Éxito vs Error hoy (donut)

| Campo | Valor |
|-------|-------|
| Tipo | Donut Chart |
| Reporte | Reporte 1 (Llamadas de Hoy) |
| Wedges | Status__c |
| Measure | Count |
| Colores | SUCCESS=verde, FAILURE=rojo, PARTIAL=amarillo |

---

### Componente 3 — Tendencia de errores (línea)

| Campo | Valor |
|-------|-------|
| Tipo | Line Chart |
| Reporte | Reporte 2 (Error Rate 7 días) |
| X Axis | Fecha |
| Y Axis | Count |
| Series | Status__c |

---

### Componente 4 — Top errores del mes (barra)

| Campo | Valor |
|-------|-------|
| Tipo | Horizontal Bar Chart |
| Reporte | Reporte 3 (Top Errores) |
| Bars | Error_Message__c |
| Measure | Count |
| Max barras | 5 |

---

### Componente 5 — Últimos errores (tabla)

| Campo | Valor |
|-------|-------|
| Tipo | Lightning Table |
| Reporte | Reporte 4 (Errores Recientes) |
| Columnas | Timestamp, Integration, External Id, Error |
| Filas visibles | 10 |

---

## Resultado final

Con esto tienes:

```
GRATIS, dentro de Salesforce, sin herramientas externas:

✅ Objeto Integration_Log__c creando registros por cada llamada
✅ Logger que sobrevive rollbacks (@future)
✅ 5 reportes que responden las preguntas clave de monitoreo
✅ Dashboard con vista en tiempo real del estado de las integraciones
```

## Cuándo esto ya no es suficiente

Cuando necesites:
- Alertas automáticas (email/Slack si el error rate sube)
- Response time en milisegundos (Salesforce no lo captura nativo)
- Correlacionar errores entre Salesforce y el sistema externo
- Monitoreo en tiempo real (no refrescando el dashboard manualmente)

→ En ese punto agregar New Relic o UptimeRobot encima de esto.
