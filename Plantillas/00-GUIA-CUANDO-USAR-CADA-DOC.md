# Guía: Sistema de Documentación para Proyectos Salesforce

## El Problema que Resuelve Este Sistema

El scope creep ocurre porque el cliente y el equipo no tienen la misma comprensión
de qué está incluido. La solución no es más detalle técnico, sino documentos
enfocados en la persona correcta con el nivel de detalle correcto.

---

## Los 3 Documentos y Para Quién Son

```
CLIENTE (negocio/stakeholder)
    └── SOW / Propuesta de Alcance
        → Firma este. Define lo que pagaron. Tiene exclusiones explícitas.

CLIENTE (usuario clave / llave)
    └── BPD (Business Process Document)
        → Valida esto. Define qué hará el sistema en lenguaje de negocio.
           Sin código. Sin "Apex". Sin "REST".

EQUIPO TÉCNICO (desarrollador, tú)
    └── FSD / TDD (Technical Design Document)
        → Lo construyes con base en el BPD aprobado.
           Tiene el detalle técnico real.
```

---

## Cuándo se Genera Cada Uno

| Documento | Cuándo | Quién lo aprueba |
|-----------|--------|-----------------|
| SOW/Alcance | Antes de firmar el contrato | Gerente del cliente + PM |
| BPD | Fase de Discovery/Análisis (primeras 2 semanas) | Usuario clave + Gerente proyecto |
| FSD/TDD | Después de BPD aprobado | Desarrollador + Arquitecto |

**Regla clave:** El FSD no existe hasta que el BPD esté firmado.
Si desarrollas sin BPD aprobado, el cliente puede decir "eso no era lo que quería."

---

## La Sección Más Importante: Exclusiones Explícitas

Cada documento debe tener una sección "FUERA DE ALCANCE" redactada
en lenguaje de negocio que el cliente pueda leer y entender.

Ejemplo malo (no sirve):
> "Límites y exclusiones del proyecto: ver 5.4"

Ejemplo bueno (protege el proyecto):
> **FUERA DE ALCANCE:**
> - Configuración o desarrollo del lado de SAP. Punto Commerce no es responsable
>   de que el equipo de SAP entregue los endpoints en el formato acordado.
> - Entrenamiento a usuarios finales (se entrega guía de usuario, no capacitación presencial).
> - Soporte post go-live. El proyecto termina en UAT aceptado. El soporte
>   tiene contrato separado.
> - Cualquier campo o funcionalidad no listada en la sección 3 de este documento.

---

## El Proceso de Change Request (CR)

Cuando el cliente pide algo no contemplado:
1. Detener el trabajo en ese ítem.
2. Registrar el cambio en el formato CR (ver Plantilla 04 cuando aplique).
3. Estimar impacto en tiempo y costo.
4. Cliente firma el CR antes de que se trabaje.
5. El CR se adjunta al SOW original.

**Sin CR firmado = sin trabajo.** Esta política se establece en el SOW desde el inicio.
