# Cumplimiento del Estándar de Software (MITIC — Paraguay)

**Proyecto:** Repositorio UNAE Análisis (plataforma institucional basada en InvenioRDM)
**Norma de referencia:** *Estándar de Software — Desarrollo y adquisición*, Versión 1.0, 26-05-2020 (MITIC / DGGE / VMTIC, Asunción – Paraguay), elaborado en el marco de la Ley Nº 6207/2018 y el Decreto Nº 2274/2019.
**Versión de este paquete:** 1.0 — 25/10/2026
**Responsable:** Equipo de desarrollo del proyecto (Grupo 4) / Unidad TIC de la institución.

---

## 1. Objeto de este paquete

Documentar el cumplimiento del proyecto frente al Estándar de Software del MITIC, modalidad
**Desarrollo de software de titularidad del Estado — Submodalidad “Desarrollo de software con
requerimientos definidos”**, mediante:

1. **Matrices de revisión** (verificación, cumplimiento, trazabilidad y requerimientos),
2. la **especificación técnica** con todos los ítems exigidos por el estándar completados, y
3. el **inventario de software** exigido por el Capítulo 1 del Título II.

## 2. Estructura del paquete

| Documento | Contenido | Ítem del estándar que cumple |
|---|---|---|
| [00-matriz-cumplimiento.md](00-matriz-cumplimiento.md) | Matriz de revisión de cumplimiento ítem por ítem del estándar, con estado y evidencia | Títulos I y II (transversal) |
| [01-matriz-requerimientos-funcionales.md](01-matriz-requerimientos-funcionales.md) | Requerimientos funcionales bien formados (Anexo I) con verificación | Cap. 2 Sección 1 §1 + Anexo I |
| [02-matriz-requerimientos-no-funcionales.md](02-matriz-requerimientos-no-funcionales.md) | Atributos de calidad del producto | Cap. 2 Sección 1 §2 |
| [03-matriz-trazabilidad-pruebas.md](03-matriz-trazabilidad-pruebas.md) | Matriz de trazabilidad requerimiento ↔ módulo ↔ prueba ↔ evidencia | Cap. 2 §1 y Sección 1 §7 (entregables de calidad) |
| [04-inventario-software.md](04-inventario-software.md) | Inventario de software con los campos mínimos exigidos | Cap. 1 §1 |
| [05-especificacion-tecnica.md](05-especificacion-tecnica.md) | Introducción, justificación, objetivos, marco legal, beneficiarios, infraestructura, confidencialidad, perfiles, arquitectura, tecnología, seguridad, plan de trabajo, entregables, soporte, garantía y propiedad intelectual | Cap. 2 §1–§12, Sección 1 §1–§9, Anexo II |

## 3. Notas de alcance

- La adhesión de la institución al estándar es **voluntaria** (proyecto universitario); el documento
  adopta el estándar como marco de calidad y, donde un ítem solo aplica a procesos de compra
  (Ley Nº 2051/03), se declara **No aplica** con su justificación.
- Los componentes base del sistema (InvenioRDM, PostgreSQL, OpenSearch, etc.) son **software de
  código abierto de terceros**, condición expresamente promovida por el MITIC (Cap. 2 §4). La
  personalización, configuración e integración realizadas en este proyecto son de titularidad de la
  institución y se publican bajo licencia MIT.
- Los datos marcados como *estimación* son referenciales y deben actualizarse por la unidad TIC.
