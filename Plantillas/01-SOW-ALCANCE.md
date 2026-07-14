# PLANTILLA: SOW / Propuesta de Alcance
# (Statement of Work — Documento de Control de Scope)

> **Instrucciones de uso:** Este es el documento que firma el cliente ANTES de iniciar.
> Es el contrato técnico-funcional. Sin este documento firmado, no hay proyecto.
> Redactarlo en lenguaje de negocio, no técnico.
> Reemplaza todo lo que está entre [corchetes].

---

## Información del Proyecto

| Campo | Valor |
|-------|-------|
| **Cliente** | [Nombre del cliente] |
| **Proyecto** | [Nombre del proyecto] |
| **Número de documento** | [AAAA-MM-SOW-CLIENTE-v01] |
| **Versión** | 01 |
| **Fecha** | [DD/MM/AAAA] |
| **Elaborado por** | [Tu nombre] |
| **Revisado por** | [Gerente de proyecto Punto Commerce] |

---

## Historial de Versiones

| Versión | Fecha | Responsable | Cambio |
|---------|-------|-------------|--------|
| 01 | [DD/MM/AAAA] | [Nombre] | Versión inicial |

---

## Aprobación

> **IMPORTANTE:** La firma de este documento indica que el cliente ha leído,
> entendido y aceptado el alcance definido. Cualquier funcionalidad no listada
> en la sección "Alcance Incluido" requiere una Solicitud de Cambio (CR) formal.

| Rol | Nombre | Firma | Fecha |
|-----|--------|-------|-------|
| Gerente de Proyecto — [Cliente] | [Nombre] | | |
| Responsable Técnico — [Cliente] | [Nombre] | | |
| Gerente de Proyecto — Punto Commerce | [Nombre] | | |
| Arquitecto — Punto Commerce | [Tu nombre] | | |

---

## 1. Contexto del Negocio

> ¿Por qué el cliente contrató este proyecto? Escríbelo en 3-5 oraciones.
> Referencia el problema de negocio, no la solución técnica.

[Ejemplo: La empresa [Cliente] utiliza SAP como sistema central de gestión y Salesforce
como herramienta de ventas. Actualmente los vendedores no tienen visibilidad de
inventario ni cuentas por cobrar en tiempo real, lo que genera pedidos duplicados
y pérdida de tiempo en consultas manuales. Este proyecto automatiza el flujo de
información entre ambos sistemas.]

---

## 2. Objetivo del Proyecto

> Una oración. Qué se va a construir y cuál es el resultado esperado.

[Ejemplo: Implementar la integración entre SAP y Salesforce Sales Cloud para que
los vendedores puedan crear pedidos, consultar inventario y ver cuentas por cobrar
directamente desde Salesforce.]

---

## 3. Alcance — Lo Que SÍ Está Incluido

> Lista cada entregable de forma específica y verificable.
> "Implementar la integración de X" es vago. "API que sincroniza productos de SAP
> a Salesforce, incluyendo los campos listados en el Anexo A, con frecuencia diaria"
> es específico.

### 3.1 Integraciones

Cada integración = una fila. Si no está en esta tabla, no está incluido.

| # | Nombre | Dirección | Descripción funcional | Frecuencia |
|---|--------|-----------|----------------------|------------|
| 1 | Sincronización de Productos | SAP → Salesforce | Los productos creados/actualizados en SAP se reflejarán automáticamente en Salesforce | 1 vez al día |
| 2 | Sincronización de Precios | SAP → Salesforce | Las listas de precios de SAP se actualizarán en Salesforce | 1 vez al día |
| 3 | Consulta de Inventario | Salesforce → SAP | El vendedor puede ver la cantidad disponible de un producto desde Salesforce | Bajo demanda (botón) |
| 4 | Creación de Pedidos | Salesforce → SAP | Los pedidos creados en Salesforce se envían a SAP automáticamente | Tiempo real |
| 5 | [Agregar más filas] | | | |

### 3.2 Objetos / Pantallas de Salesforce

| # | Objeto/Pantalla | Descripción |
|---|----------------|-------------|
| 1 | [Ejemplo: Objeto Pedidos personalizado] | [Qué campos tiene, qué pantalla] |
| 2 | [Ejemplo: Botón "Consultar Inventario" en el objeto Producto] | |

### 3.3 Automatizaciones

| # | Automatización | Descripción |
|---|---------------|-------------|
| 1 | [Ejemplo: Validación que no permite crear pedido si el cliente no tiene No. de SAP] | |

### 3.4 Carga Inicial de Datos

| # | Entidad | Volumen estimado | Tipo |
|---|---------|-----------------|------|
| 1 | [Ejemplo: Clientes históricos de SAP] | ~10,000 registros | Única (one-time) |
| 2 | [Ejemplo: Contactos históricos de SAP] | ~10,000 registros | Única (one-time) |

> **Nota:** La carga inicial se hará una sola vez antes del go-live. Migración de datos
> posteriores al go-live NO están incluidas en este alcance.

---

## 4. Alcance — Lo Que NO Está Incluido (Exclusiones Explícitas)

> Esta sección es la más importante para evitar scope creep.
> Sé específico en lo que NO se hace.

Los siguientes ítems NO están incluidos en este proyecto:

1. **Desarrollo en SAP:** Punto Commerce es responsable del lado de Salesforce únicamente. Cualquier desarrollo, configuración o cambio en SAP es responsabilidad del equipo técnico de [Cliente] o su proveedor de SAP.

2. **Endpoints de SAP:** Se asume que SAP proveerá los endpoints documentados en el Anexo A. Si SAP no tiene los endpoints disponibles o cambia su estructura, se levantará un CR.

3. **Campos no listados en el Anexo A:** Cualquier campo adicional que no aparezca en el mapeo de campos del Anexo A requiere una Solicitud de Cambio.

4. **Entrenamiento a usuarios finales:** No se incluye capacitación presencial. Se entrega documentación de usuario (manual de uso).

5. **Soporte post go-live:** Este proyecto finaliza con la aceptación de UAT. El soporte operativo es un contrato separado.

6. **Reportes y dashboards:** No se incluye ningún reporte, dashboard ni análisis en Salesforce, a menos que esté listado en la sección 3.2.

7. **Módulos de Salesforce no mencionados:** Solo Sales Cloud en el alcance listado. Service Cloud, Marketing Cloud, Experience Cloud u otros módulos no están incluidos.

8. **Integraciones con sistemas distintos a SAP:** Solo se integra con SAP [versión X]. Ningún otro sistema.

9. **[Agregar exclusiones específicas del proyecto]**

---

## 5. Supuestos del Proyecto

> Los supuestos son condiciones que asumimos que son verdad.
> Si un supuesto resulta falso, puede convertirse en un CR o un riesgo.

| # | Supuesto |
|---|----------|
| 1 | El cliente dispondrá de un sandbox/ambiente de pruebas de SAP durante todo el proyecto. |
| 2 | SAP expone los endpoints REST en el formato JSON especificado en el Anexo A. |
| 3 | El cliente asignará un usuario clave técnico de SAP para resolver dudas de integración. |
| 4 | El cliente proveerá acceso al sandbox de Salesforce dentro de los 5 días hábiles de inicio. |
| 5 | Los volúmenes de datos estimados en la sección 3.4 son correctos. Volúmenes significativamente mayores pueden requerir un CR. |
| 6 | [Agregar supuestos específicos] |

---

## 6. Dependencias del Cliente

> Qué necesitamos del cliente para avanzar. Si el cliente no entrega esto,
> el proyecto se bloquea y los tiempos se ajustan.

| # | Entregable del cliente | Necesario para | Fecha límite esperada |
|---|----------------------|----------------|----------------------|
| 1 | Acceso a sandbox de Salesforce | Iniciar configuración | [Fecha] |
| 2 | Documentación de endpoints SAP (Productos, Precios) | Sprint 1 de integración | [Fecha] |
| 3 | Documentación de endpoints SAP (Pedidos, Clientes) | Sprint 2 de integración | [Fecha] |
| 4 | Usuario clave SAP disponible para pruebas | Fase de QA | [Fecha] |
| 5 | Aprobación del BPD | Inicio de desarrollo | [Fecha] |
| 6 | Disponibilidad para UAT (2 semanas) | Fase de UAT | [Fecha] |

---

## 7. Entregables de Punto Commerce

| # | Entregable | Descripción | Fase |
|---|-----------|-------------|------|
| 1 | BPD aprobado | Documento de proceso de negocio | Discovery |
| 2 | FSD/TDD aprobado | Documento técnico de diseño | Diseño |
| 3 | APIs desarrolladas y en sandbox | Integraciones funcionando en ambiente de prueba | Desarrollo |
| 4 | Manual de usuario | Documento de uso para usuarios finales | QA |
| 5 | Resultado de UAT firmado | Acta de aceptación de pruebas | UAT |
| 6 | Deploy a producción | Migración al ambiente productivo | Go-Live |

---

## 8. Fases y Tiempos Estimados

> Estos tiempos son estimados desde la fecha de inicio REAL (cuando el cliente
> entrega los accesos y el BPD está aprobado). No desde la firma del contrato.

| Fase | Descripción | Duración estimada |
|------|-------------|-----------------|
| Discovery/Análisis | Levantamiento de requisitos, BPD | [X semanas] |
| Diseño Técnico | FSD/TDD | [X semanas] |
| Desarrollo Sprint 1 | [Integraciones X, Y] | [X semanas] |
| Desarrollo Sprint 2 | [Integraciones A, B] | [X semanas] |
| QA interno | Pruebas técnicas Punto Commerce | [X semanas] |
| UAT | Pruebas con el cliente | [X semanas] |
| Go-Live | Deploy a producción | [X días] |
| **Total estimado** | | **[X semanas]** |

> **Nota:** El cronograma inicia cuando: (1) el contrato está firmado, (2) el cliente
> ha entregado los ítems de la sección 6 correspondientes a la fase inicial.

---

## 9. Proceso de Solicitud de Cambio (Change Request)

Todo requerimiento que no esté listado en la sección 3 de este documento se
considera un cambio de alcance y sigue este proceso:

1. Cualquiera de las partes puede solicitar un CR por escrito (email o formato CR).
2. Punto Commerce evaluará el impacto en tiempo y costo en máximo 3 días hábiles.
3. El cliente aprueba o rechaza el CR por escrito.
4. **Solo se trabaja en el cambio una vez que el CR está aprobado y firmado.**
5. El CR se adjunta como anexo a este SOW y forma parte del contrato.

> El cliente comprende que solicitudes de cambio frecuentes o no aprobadas
> pueden impactar el calendario del proyecto.

---

## Anexo A — Mapeo de Campos por Integración

> Este anexo es técnico pero se adjunta al SOW para que el cliente
> firme explícitamente qué campos están incluidos.

[Referencia al FSD/TDD o incluir tablas de mapeo de campos aquí]

---

## Firmas Finales

Al firmar este documento, ambas partes confirman que han leído y acordado
el alcance definido en este SOW.

| Parte | Nombre | Cargo | Firma | Fecha |
|-------|--------|-------|-------|-------|
| [Cliente] | | | | |
| Punto Commerce | | | | |
