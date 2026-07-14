# PLANTILLA: BPD — Business Process Document
# (Documento de Proceso de Negocio)

> **Instrucciones de uso:** Este documento es para el CLIENTE (usuario clave, gerente de proyecto).
> Lenguaje de negocio, sin código, sin "Apex", sin "REST API".
> El cliente lo revisa, corrige y FIRMA. Sin firma no se desarrolla.
> 
> El BPD describe QUÉ hará el sistema. El FSD describe CÓMO se construye.

---

## Información del Documento

| Campo | Valor |
|-------|-------|
| **Cliente** | [Nombre del cliente] |
| **Proyecto** | [Nombre del proyecto] |
| **Número de documento** | [AAAA-MM-BPD-CLIENTE-v01] |
| **Versión** | 01 |
| **Fecha** | [DD/MM/AAAA] |
| **Elaborado por** | [Tu nombre] — Punto Commerce |

---

## Historial de Versiones

| Versión | Fecha | Responsable | Cambio |
|---------|-------|-------------|--------|
| 01 | [DD/MM/AAAA] | [Nombre] | Versión inicial |
| 02 | | | [Describir cambio tras revisión del cliente] |

---

## Aprobación del Documento

> **El cliente firma aquí para confirmar que el sistema descrito en este documento
> corresponde exactamente a lo que se acordó. El desarrollo comienza después de esta firma.**

| Rol | Nombre | Firma | Fecha |
|-----|--------|-------|-------|
| Usuario Clave — [Área de Ventas] | [Nombre] | | |
| Gerente de Proyecto — [Cliente] | [Nombre] | | |
| Gerente de Proyecto — Punto Commerce | [Nombre] | | |
| Arquitecto — Punto Commerce | [Tu nombre] | | |

---

## 1. Propósito del Documento

Este documento describe cómo funcionará el sistema [nombre del proyecto] desde
la perspectiva del usuario de negocio. Define los procesos, las reglas, y los
comportamientos esperados del sistema.

**Este documento NO es un contrato de precio ni de tiempo.** El alcance contractual
está definido en el SOW firmado con fecha [fecha].

---

## 2. Glosario de Términos

> Define los términos del negocio para que no haya ambigüedad.

| Término | Definición |
|---------|-----------|
| Pedido | [Definición del cliente: un pedido en Salesforce representa...] |
| Cliente | [Cuenta en Salesforce, corresponde a un cliente en SAP identificado por...] |
| SKU | Código único que identifica un producto tanto en SAP como en Salesforce |
| Lista de precios | [Definición específica del cliente] |
| [Término] | [Definición] |

---

## 3. Actores del Sistema

> Quién interactúa con el sistema y qué puede hacer.

| Actor | Descripción | Acceso |
|-------|-------------|--------|
| Vendedor | Usuario que crea pedidos y consulta clientes | Crear pedidos, ver inventario, ver CxC |
| Gerente de Ventas | Supervisa el equipo de ventas | Ver reportes, gestionar clientes |
| Administrador SAP | Equipo de SAP del cliente | Acceso a SAP (externo a Salesforce) |
| [Rol] | [Descripción] | [Qué puede hacer] |

---

## 4. Procesos del Sistema

> Un proceso por sección. Cada proceso describe cómo funciona algo
> desde el punto de vista del usuario, no desde el código.

---

### 4.1 [Nombre del Proceso — ej: Creación de Pedido]

**Descripción:** [Qué hace este proceso en 2-3 oraciones de negocio]

**Actor principal:** [Quién inicia el proceso]

**Disparador:** [Qué hace que inicie — ej: "El vendedor presiona el botón Crear Pedido"]

#### Flujo Principal (Camino Feliz)

```
Paso 1: El vendedor abre el perfil del cliente en Salesforce.
Paso 2: El vendedor hace clic en "Nuevo Pedido".
Paso 3: El sistema valida que el cliente tiene número de cliente en SAP.
         → Si NO tiene número en SAP: muestra error "El cliente no está registrado
           en SAP. Registre el cliente antes de crear el pedido." El proceso termina.
Paso 4: El vendedor agrega los productos al pedido seleccionándolos de la lista.
Paso 5: El vendedor selecciona la cantidad y el sistema muestra el precio de la
         lista de precios asignada al cliente.
Paso 6: El vendedor hace clic en "Enviar Pedido a SAP".
Paso 7: El sistema envía el pedido a SAP.
         → Si SAP confirma: el pedido muestra el número de pedido de SAP y
           cambia su estado a "Confirmado en SAP".
         → Si SAP rechaza: el sistema muestra el mensaje de error de SAP y
           registra el fallo para que el administrador pueda revisarlo.
```

#### Reglas de Negocio

| # | Regla |
|---|-------|
| R1 | No se puede crear un pedido si el cliente no tiene número de cliente en SAP. |
| R2 | El pedido debe tener al menos 1 producto para poder enviarse a SAP. |
| R3 | [Agregar reglas específicas del cliente] |

#### Campos del Pedido

| Campo | Descripción | ¿Requerido? | Notas |
|-------|-------------|-------------|-------|
| Cliente | Cliente al que pertenece el pedido | Sí | |
| Fecha de solicitud | Fecha en que se crea el pedido | Sí | Automático (fecha actual) |
| Tipo de venta | Crédito o Contado | Sí | |
| Domicilio de entrega | Dirección de entrega | Sí | |
| Comentarios | Notas adicionales | No | |
| No. de Pedido SAP | Número asignado por SAP | No editable | Lo asigna SAP automáticamente |
| [Campo] | [Descripción] | [Sí/No] | [Notas] |

#### ¿Qué queda FUERA de este proceso?

- El seguimiento del pedido una vez en SAP (SAP es el sistema maestro del pedido).
- La facturación del pedido (la maneja SAP).
- [Otras exclusiones específicas]

---

### 4.2 [Nombre del Proceso — ej: Consulta de Inventario]

**Descripción:**

**Actor principal:**

**Disparador:**

#### Flujo Principal

```
Paso 1: 
Paso 2: 
Paso 3: 
```

#### Reglas de Negocio

| # | Regla |
|---|-------|
| R1 | |

#### ¿Qué queda FUERA de este proceso?

-

---

### 4.3 [Nombre del Proceso — ej: Registro de Nuevo Cliente]

[Continuar el mismo patrón para cada proceso]

---

## 5. Sincronizaciones Automáticas

> Procesos que ocurren en segundo plano sin que el usuario haga nada.

| # | Sincronización | Dirección | Frecuencia | Qué hace |
|---|---------------|-----------|------------|----------|
| 1 | Productos | SAP → Salesforce | 1 vez al día (noche) | Los productos nuevos o actualizados en SAP aparecen en Salesforce al día siguiente. |
| 2 | Precios | SAP → Salesforce | 1 vez al día (noche) | Las listas de precios de SAP se actualizan en Salesforce al día siguiente. |
| 3 | [Nombre] | | | |

> **¿Qué pasa si una sincronización falla?**
> El administrador del sistema podrá ver los errores en el Monitor de Logs de Salesforce.
> Se mostrará el registro que falló y el motivo del error.

---

## 6. Manejo de Errores (Perspectiva de Usuario)

> El cliente necesita saber qué verá cuando algo salga mal.

| Escenario | Lo que ve el usuario | Lo que hace el sistema en segundo plano |
|-----------|---------------------|----------------------------------------|
| SAP no responde al enviar pedido | Mensaje: "No fue posible enviar el pedido a SAP. Intente más tarde o contacte al administrador." | Registra el error en el log de Salesforce. |
| Producto no existe en SAP | Mensaje: "El producto [SKU] no fue encontrado en SAP." | Registra el intento fallido. |
| [Escenario] | [Mensaje al usuario] | [Acción del sistema] |

---

## 7. Lo Que NO Hará el Sistema

> Sección crítica. El cliente firma que entendió estas limitaciones.

1. Salesforce **no modifica datos directamente en SAP.** Salesforce envía solicitudes; SAP decide si las acepta o rechaza.
2. El inventario en Salesforce **no se guarda.** Solo se muestra en el momento de la consulta. Si el vendedor quiere ver inventario actualizado, debe presionar el botón de consulta.
3. Las cuentas por cobrar en Salesforce **no se guardan en tiempo real.** Se muestran al presionar el botón; los datos de factura son solo de visualización.
4. Salesforce **no genera facturas.** La facturación sigue siendo responsabilidad de SAP.
5. [Agregar más limitaciones específicas del proyecto]

---

## 8. Preguntas Abiertas y Decisiones Pendientes

> Durante el levantamiento surgieron preguntas que el cliente debe responder
> antes de que el documento esté completo. Este listado permite dar seguimiento.

| # | Pregunta | Responsable de responder | Fecha límite | Respuesta |
|---|---------|--------------------------|-------------|-----------|
| 1 | [Ejemplo: ¿El vendedor puede editar un pedido después de enviarlo a SAP?] | [Nombre del cliente] | [Fecha] | |
| 2 | [Ejemplo: ¿Qué pasa si un cliente tiene dos RFC en SAP?] | | | |

---

## Anexo A — Pantallas y Mockups (Opcional)

> Si se diseñaron wireframes o mockups durante el discovery, adjuntarlos aquí.
> El cliente los valida como parte de la firma de este documento.

[Imágenes o referencias a los diseños]
