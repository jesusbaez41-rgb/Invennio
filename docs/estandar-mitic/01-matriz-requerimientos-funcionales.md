# Matriz de requerimientos funcionales (Anexo I del estándar)

**Proyecto:** Repositorio UNAE Análisis · **Revisión:** 1.0 · **Fecha:** 25/10/2026

Los requerimientos se redactan siguiendo las pautas de calidad del **Anexo I** del estándar
(Necesario, Único/Inequívoco, Completo, Verificable, Claro, Factible — ISO/IEC/IEEE 29148).
La columna **Calidad (A1)** registra el chequeo de los 6 atributos por requisito.

**Verificación:** M = manual (UI), A = automatizable (API REST), E = evidencia existente (ver [03-matriz-trazabilidad-pruebas.md](03-matriz-trazabilidad-pruebas.md)).

| ID | Requerimiento (bien formado) | Módulo | Prioridad | Verificación | Calidad (A1: N/U/C/V/C/F) | Estado |
|---|---|---|---|---|---|---|
| RF-01 | El sistema **deberá permitir crear un borrador de registro** con metadatos obligatorios: título (≥3 caracteres), tipo de recurso, al menos un creador y fecha de publicación; y metadatos opcionales: descripción, editor, derechos/licencia, idiomas, temas, fechas, tamaño y formato. | Depósito (records) | Alta | A/E | ✅ ✅ ✅ ✅ ✅ ✅ | ✅ |
| RF-02 | El sistema **deberá permitir registrar, transferir y confirmar archivos** en un borrador, validando el checksum MD5 declarado al registro y transitando el estado del archivo: `pending → completed`. | Archivos (files) | Alta | A/E | ✅ ✅ ✅ ✅ ✅ ✅ | ✅ |
| RF-03 | El sistema **deberá permitir publicar un borrador** cuando cumpla la validación de esquema; la publicación **deberá** asignar un identificador permanente (PID tipo recid y OAI) y habilitar el registro como público. | Depósito / PID | Alta | A/E | ✅ ✅ ✅ ✅ ✅ ✅ | ✅ |
| RF-04 | El sistema **deberá ofrecer búsqueda de registros públicos** por texto libre sobre título, creadores y descripción, con filtros por tipo de recurso, licencia, fecha, afiliación e idioma, y orden por relevancia, más nuevo y más antiguo. | Búsqueda (OpenSearch) | Alta | A/E | ✅ ✅ ✅ ✅ ✅ ✅ | ✅ |
| RF-05 | El sistema **deberá permitir descargar el archivo** de un registro publicado por cualquier usuario (incluido anónimo) cuando el acceso al registro y a archivos sea público. | Archivos | Alta | A/E | ✅ ✅ ✅ ✅ ✅ ✅ | ✅ |
| RF-06 | El sistema **deberá permitir crear una nueva versión** de un registro publicado conservando el identificador del registro padre y mostrando la versión más reciente en la ficha pública. | Versionado | Media | A | ✅ ✅ ✅ ✅ ✅ ✅ | ✅ (nativo InvenioRDM, verificado estructuralmente) |
| RF-07 | El sistema **deberá permitir crear comunidades** con su ficha pública, **deberá** permitir definir política de envío y administrar la inclusión de registros en la comunidad. | Comunidades | Media | M | ✅ ✅ ✅ ✅ ✅ ✅ | ✅ |
| RF-08 | El sistema **deberá autenticar usuarios** con correo y contraseña (Flask-Security), y **deberá** mantener la sesión con cookie firmada y protección CSRF en toda escritura. | Cuentas | Alta | A/E | ✅ ✅ ✅ ✅ ✅ ✅ | ✅ |
| RF-09 | El sistema **deberá aplicar control de acceso por roles**: el rol `admin` posee `superuser-access`; los roles `administration` y `administration-moderation` habilitan el panel y la moderación. | Acceso (RBAC) | Alta | A/E | ✅ ✅ ✅ ✅ ✅ ✅ | ✅ |
| RF-10 | El sistema **deberá ofrecer un panel de administración** (`/administration/`) accesible solo para roles autorizados, con gestión de usuarios, registros, comunidades y colas de trabajo. | Administración | Alta | M/E | ✅ ✅ ✅ ✅ ✅ ✅ | ✅ |
| RF-11 | El sistema **deberá exponer una API REST JSON** (`/api/records`, `/api/communities`, vocabularios) y **deberá** exponer OAI-PMH para cosecha de metadatos. | API / OAIServer | Alta | A | ✅ ✅ ✅ ✅ ✅ ✅ | ✅ |
| RF-12 | El sistema **deberá registrar eventos de uso** (vista de registro, descarga de archivo) y **deberá** presentarlos como estadísticas en la ficha y en el panel. | Estadísticas (stats) | Baja | A | ✅ ✅ ✅ ✅ ✅ ✅ | ✅ (índices de eventos creados) |
| RF-13 | El sistema **deberá presentar la interfaz en español** con la identidad visual de la institución (nombre, subtítulo, pie de página) en todas las páginas. | Tema (UI) | Media | M | ✅ ✅ ✅ ✅ ✅ ✅ | ✅ |
| RF-14 | El sistema **deberá permitir eliminar** un borrador (borrado físico) y **deberá** permitir retirar un registro publicado dejando una lápida (tombstone) visible solo con acceso de administración. | Ciclo de vida | Media | A/E | ✅ ✅ ✅ ✅ ✅ ✅ | ✅ |

## Reglas transversales de la API (derivan del análisis del sistema real)

| Regla | Detalle |
|---|---|
| R-01 | Escrituras (`POST/PUT/DELETE`) requieren `X-CSRFToken` (cookie `csrftoken`), cabecera `X-Requested-With: XMLHttpRequest` y `Referer` del sitio; sin ellas la petición responde `400 Referer checking failed`. |
| R-02 | Operaciones sin sesión autenticada responden `403 Permission denied`. |
| R-03 | El esquema de metadatos exige la forma canónica: `resource_type: {"id": …}`, `creators[].person_or_org`, `rights[].id`. |
| R-04 | El borrado de un registro publicado se ejecuta con `DELETE /records/<pid>/delete` y cuerpo JSON `{}`; sin cuerpo responde `400 Invalid input type`. |

## Diseño conceptual y módulos (lista exigida por S1 §1)

- **Módulo Depósito** (borradores, metadatos, validación, publicación) — RF-01, RF-03, RF-14.
- **Módulo Archivos** (buckets, transferencias, checksums, descargas) — RF-02, RF-05.
- **Módulo Búsqueda** (indexación OpenSearch, facetas, ordenamientos) — RF-04.
- **Módulo Comunidades** — RF-07.
- **Módulo Cuentas y Acceso** (usuarios, roles, sesiones) — RF-08, RF-09.
- **Módulo Administración** — RF-10.
- **Módulo Interoperabilidad** (API REST, OAI-PMH) — RF-11.
- **Módulo Estadísticas** — RF-12.
- **Módulo Presentación** (tema institucional, i18n) — RF-13.

*Prototipos de pantalla:* opcionales según el estándar; se sustituyen por la interfaz viva del
sistema desplegado (capturas disponibles en la documentación del usuario).
