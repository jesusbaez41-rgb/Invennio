# Matriz de revisión de cumplimiento — Estándar de Software MITIC v1.0

**Proyecto:** Repositorio UNAE Análisis · **Revisión:** 1.0 · **Fecha:** 25/10/2026
**Moda­lidad adoptada:** Título II — Desarrollo de software de titularidad del Estado · Submodalidad: **Desarrollo de software con requerimientos definidos**.

**Leyenda de estado:**

| Símbolo | Significado |
|---|---|
| ✅ | Cumplido y verificado (con evidencia referenciada) |
| 🟡 | Parcial / en curso (queda tarea abierta para la unidad TIC) |
| ⚪ | No aplica, con justificación registrada en esta matriz |

**Códigos de evidencia:** `EC-##` apuntan a secciones de [05-especificacion-tecnica.md](05-especificacion-tecnica.md); `M1`–`M3` a las matrices 01–03; `INV` al inventario ([04](04-inventario-software.md)); `REPO/…` a archivos del repositorio.

---

## Título I — Introducción (aplicabilidad)

| Ref. | Ítem / requisito | Aplicabilidad | Estado | Evidencia | Observaciones |
|---|---|---|---|---|---|
| T-I §7 | Alcance: el sistema es incorporado al patrimonio institucional con titularidad del OEE | Sí | ✅ | EC-1, EC-13 | Desarrollo a medida sobre plataforma open source; la personalización es propiedad de la institución. |
| T-I §9 | Sin dependencia de hardware específico; despliegue en infraestructura estándar de OEE | Sí | ✅ | M2 RNF-03, EC-8 | Todo el stack corre en contenedores Docker sobre Linux x86_64; sin vínculos a un equipo concreto. |
| T-I §9 | Justificación previa: búsqueda de soluciones existentes / open source antes de desarrollar | Sí | ✅ | EC-2 | Se adopta InvenioRDM (open source, MIT, usado por CERN/Zenodo) en lugar de desarrollar desde cero: cumple la premisa de aprovechar soluciones existentes. |
| T-I §9 | Software y hardware en lotes/procesos separados | ⚪ | ⚪ | — | No hay compra de hardware asociada al proyecto. |

## Título II, Capítulo 1 — Lineamientos generales

| Ref. | Ítem / requisito | Aplicabilidad | Estado | Evidencia | Observaciones |
|---|---|---|---|---|---|
| C1 §1 | Inventario de software con los campos mínimos (nombre, objeto, área responsable, lenguajes, BD, frameworks, años, vigencia, enlace a repositorio, licencia, soporte, datacenter, costos, desarrolladores) | Sí | ✅ | INV | Inventario completo en [04-inventario-software.md](04-inventario-software.md); pendiente de alta en el sistema de administración del OEE (🟡 en ese trámite externo). |
| C1 §2 | Código fuente versionado con sistema de control de versiones y custodiado por el área TIC | Sí | ✅ | REPO/.git, INV | Git con historial completo en `https://github.com/jesusbaez41-rgb/Invennio`. |
| C1 §2 | Copia del código fuente y documentación en repositorio provisto por MITIC | Sí | 🟡 | EC-25 | Repositorio de origen: GitHub. Trámite de copia al repositorio MITIC pendiente (contacto `gobiernoelectronico@mitic.gov.py`). |
| C1 §3 | Uso del SII para datos de personas físicas (cédula) o jurídicas (RUC) | ⚪ | ⚪ | EC-21 | El sistema no captura ni valida cédulas ni RUC; solo utiliza cuentas institucionales. Si en el futuro integra esos datos, deberá hacerlo vía SII (registrado como regla de diseño). |
| C1 §4 | Identificación del ciudadano vía Identidad Electrónica | ⚪ | ⚪ | EC-22 | Autenticación local institucional (docentes/estudiantes/admin). Integración futura opcional documentada. |
| C1 §5 | Presencia en el portal único / trámites en línea | ⚪ | ⚪ | EC-23 | No expone trámites ciudadanos en línea. Datos abiertos: API REST + OAI-PMH disponibles para consumo y catalogación. |
| C1 §6 | Línea gráfica gubernamental en sistemas de cara a la ciudadanía | ⚪ | ⚪ | EC-24 | Sistema institucional universitario con línea gráfica propia (UNAE) aplicada en plantillas; sin uso de marca del Gobierno Nacional. |
| C1 §7 | Titularidad de la PI cedida al OEE; licencias open source adoptables (Apache-2.0, LGPL-3, etc.) | Sí | ✅ | EC-13, REPO/LICENSE | Personalización publicada bajo **MIT** (licencia open source dentro del listado enunciativo del estándar). Componentes de terceros mantienen sus licencias originales (ver EC-13). |

## Título II, Capítulo 2 — Ítems comunes (requerimientos definidos / fábrica)

| Ref. | Ítem / requisito | Aplicabilidad | Estado | Evidencia | Observaciones |
|---|---|---|---|---|---|
| C2 §1 | Introducción y justificación | Sí | ✅ | EC-1, EC-2 | `05-especificacion-tecnica.md` §1–§2. |
| C2 §2 | Submodalidad de adquisición declarada | Sí | ✅ | EC-1 | Desarrollo de software con requerimientos definidos. |
| C2 §3 | Objetivo general | Sí | ✅ | EC-3 | Ítem §3 de la especificación. |
| C2 §4 | Objetivos específicos / hitos | Sí | ✅ | EC-4 | Ítem §4. |
| C2 §5 | Definiciones, acrónimos y abreviaturas | Sí | ✅ | EC-5 | Ítem §5. |
| C2 §6 | Antecedentes | Sí | ✅ | EC-6 | Ítem §6. |
| C2 §7 | Marco legal | Sí | ✅ | EC-7 | Ítem §7. |
| C2 §8 | Beneficiarios (tipos de usuario, directos/indirectos, cuantificación) | Sí | ✅ | EC-8 | Ítem §8 con estimaciones referenciables. |
| C2 §9 | Infraestructura para el software (datacenter, servidores, estaciones) | Sí | ✅ | EC-9 | Ítem §9; sin lotes de hardware. |
| C2 §10 | Confidencialidad (cláusulas mínimas) | Sí | ✅ | EC-10 | Ítem §10: cláusula modelo adaptada al proyecto. |
| C2 §11 | Criterios y restricciones según monto (SMLV) | ⚪ | ⚪ | EC-11 | Sin proceso de compra Ley Nº 2051/03: desarrollo interno académico. Se conserva la tabla referencial como guía. |
| C2 §12 | Perfiles técnicos del personal (mínimo del OEE + CV) | Sí | ✅ | EC-12 | Plantel definido por rol; CVs a reposar por la unidad TIC. |

## Título II, Capítulo 2, Sección 1 — Ítems específicos (requerimientos definidos)

| Ref. | Ítem / requisito | Aplicabilidad | Estado | Evidencia | Observaciones |
|---|---|---|---|---|---|
| S1 §1 | Requerimientos funcionales bien formados (Anexo I) + diseño conceptual, lista de módulos, detalle de funcionalidades | Sí | ✅ | M1 | Matriz RF-01…RF-14 con los 6 atributos de calidad por requisito. |
| S1 §2 | Requerimientos no funcionales (rendimiento, seguridad, portabilidad, interoperabilidad, interfaz) | Sí | ✅ | M2 | Matriz RNF-01…RNF-10. |
| S1 §3 | Arquitectura general: componentes, tipo de arquitectura, tipos de BD, software de ejecución, API para integraciones | Sí | ✅ | EC-14 | Ítem §14 con tabla de componentes; API REST + OAI-PMH implementadas. |
| S1 §4 | Tecnología: SO, servidores, middleware, lenguajes/frameworks, BD, repositorio + licencias de uso | Sí | ✅ | EC-15 | Ítem §15 con stack y licencias por componente. |
| S1 §5 | Seguridad según “Criterios mínimos de seguridad para el desarrollo y adquisición de software” (CERT.py) | Sí | 🟡 | EC-16 | Controles implementados y verificados (TLS, CSRF, RBAC, hash de contraseñas, mín. privilegio, logs). Pendientes operativos: rotación de credenciales por defecto (`changeme`), secretos fuertes en producción, certificado confiable. |
| S1 §6 | Plan de trabajo + plan de capacitación y gestión del cambio | Sí | ✅ | EC-17 | Ítem §17: cronograma por iteraciones y plan de capacitación. |
| S1 §7 | Entregables: análisis, código fuente, informe de calidad, manuales (dev, producción, usuario) | Sí | ✅ | EC-18, M3 | Entregables mapeados a artefactos reales del repositorio + informe de pruebas con evidencias (M3). |
| S1 §8 | Soporte y asistencia técnica (≥6 meses si proyecto ≤6 meses; ≥12 meses si >6) | Sí | ✅ | EC-19 | Compromiso: 12 meses de soporte correctivo + preventivo documentado. |
| S1 §9 | Garantía ≥ 2 años según Anexo II | Sí | ✅ | EC-20 | Garantía de 24 meses, plantilla del Anexo II completada. |

## Anexos y verificación cruzada

| Ref. | Ítem / requisito | Estado | Evidencia | Observaciones |
|---|---|---|---|---|
| Anexo I | Requerimientos: Necesario, Único, Completo, Verificable, Claro, Factible | ✅ | M1 | Columna de calidad por requisito en la matriz RF. |
| Anexo II | Plantilla de garantía completada (vicios ocultos, defensa e indemnización, continuidad) | ✅ | EC-20 | Plazo fijado: 24 meses. |

## Resumen de estado

| Estado | Cantidad | Ítems |
|---|---|---|
| ✅ Cumplido | 30 | — |
| 🟡 Parcial / en curso | 2 | Repositorio MITIC (C1 §2), Seguridad operativa (S1 §5) |
| ⚪ No aplica (justificado) | 5 | Hardware aparte (T-I §9), SII (C1 §3), Identidad Electrónica (C1 §4), Portal único (C1 §5), Línea gráfica (C1 §6), Criterios por monto (C2 §11) |

## Plan de cierre de ítems 🟡

| Tarea | Responsable | Fecha objetivo |
|---|---|---|
| Solicitar alta del código y documentación en repositorio MITIC (`gobiernoelectronico@mitic.gov.py`) | Unidad TIC | 30/11/2026 |
| Rotar credenciales por defecto (`admin` / `changeme`), definir `INVENIO_SECRET_KEY` y `INVENIO_SECURITY_PASSWORD_SALT` fuertes en producción y certificado TLS confiable | Unidad TIC | 30/11/2026 |

---

**Registro de revisiones de esta matriz**

| Versión | Fecha | Revisor | Cambios |
|---|---|---|---|
| 1.0 | 25/10/2026 | Equipo de desarrollo (Grupo 4) | Emisión inicial: 37 ítems evaluados. |
