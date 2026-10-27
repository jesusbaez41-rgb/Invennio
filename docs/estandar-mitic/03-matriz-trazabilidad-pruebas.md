# Matriz de trazabilidad: requerimiento ↔ módulo ↔ prueba ↔ evidencia

**Proyecto:** Repositorio UNAE Análisis · **Revisión:** 1.0 · **Fecha:** 25/10/2026
**Referencia estándar:** Cap. 2 Sección 1 §7 (informe de entrega y evidencias de control de calidad).

Esta matriz constituye el **informe de control de calidad** del entregable: cada caso de prueba
queda vinculado al requerimiento que verifica y a su evidencia observable. Las pruebas P-01 a P-12
se ejecutaron el **26/10/2026 (UTC)** sobre el despliegue real vía proxy (`https://localhost`)
con el usuario administrador de prueba.

| ID | Caso de prueba | RF / RNF | Módulo | Método | Resultado | Evidencia |
|---|---|---|---|---|---|---|
| P-01 | Página principal y rutas públicas responden 200 (`/`, `/search`, `/communities`) | RNF-05 | Presentación | A | ✅ 200/200/200 | Log de acceso del proxy |
| P-02 | Inicio de sesión con credenciales válidas (302 a dashboard) | RF-08 | Cuentas | A | ✅ 302 + cookie de sesión | Cookie jar de la sesión de prueba |
| P-03 | Crear borrador con metadatos completos (título, `resource_type`, `creators`, fecha, editor, licencia) | RF-01 | Depósito | A | ✅ HTTP 201; metadatos persistidos y devueltos con vocabularios resueltos (`dataset`, `researcher`, `cc-by-4.0`) | Respuesta JSON de `POST /api/records` |
| P-04 | Registrar archivo en borrador con checksum MD5 | RF-02 | Archivos | A | ✅ HTTP 201 | Respuesta JSON de `POST /draft/files` |
| P-05 | Transferir contenido del archivo | RF-02 | Archivos | A | ✅ HTTP 200 | Respuesta JSON de `PUT …/content` |
| P-06 | Confirmar (commit) el archivo | RF-02 | Archivos | A | ✅ HTTP 200; `status=completed`, `size=42` | Respuesta JSON de `POST …/commit` |
| P-07 | Publicar el borrador | RF-03 | Depósito | A | ✅ HTTP 202; `is_published=true` | Respuesta JSON de `POST …/actions/publish` |
| P-08 | Búsqueda por texto del registro publicado | RF-04 | Búsqueda | A | ✅ `total=1` con `q=funcional`; `/search` web 200 | Respuesta JSON de `GET /api/records?q=…` |
| P-09 | Ficha pública del registro | RF-03 | Presentación | A | ✅ HTTP 200 en `/records/<id>` | Log de acceso |
| P-10 | Descarga del archivo del registro publicado con contenido íntegro | RF-05 | Archivos | A | ✅ HTTP 200; contenido idéntico al original | Contenido descargado (`prueba.txt`) |
| P-11 | Escritura sin sesión autenticada | RNF-02 | Acceso | A (negativa) | ✅ bloqueada: HTTP 403 `Permission denied` | Respuesta JSON |
| P-12 | Escritura autenticada sin `Referer`/CSRF | RNF-02 | CSRF | A (negativa) | ✅ bloqueada: HTTP 400 `Referer checking failed` | Respuesta JSON |
| P-13 | Borrado de borradores de prueba | RF-14 | Ciclo de vida | A | ✅ HTTP 204 por borrador | Respuestas JSON |
| P-14 | Retiro de registro publicado (lápidas) | RF-14 | Ciclo de vida | A | ✅ HTTP 204 con `DELETE /records/<pid>/delete` + JSON `{}`; `GET` posterior → 410 `Record deleted` con tombstone | Respuesta JSON |
| P-15 | Panel de administración accesible solo con rol autorizado | RF-09, RF-10 | Administración | M | ✅ 200 con sesión admin | Log de acceso |
| P-16 | Tareas del worker sin errores (job logs) | RNF-10 | Worker | A | ✅ `delete_logs` ejecutado sin excepción tras crear el data stream | Log del worker |
| P-17 | Almacenamiento de archivos persistente en la ubicación local por defecto | RNF-03 | Archivos | A | ✅ `files location list` → `local file:///opt/invenio/var/instance/data (default True)`; archivos físicos verificados en disco | Salida de CLI + `find` |
| P-18 | Base de datos e índices consistentes tras limpieza (0 registros, 0 borradores, 0 PIDs de prueba) | RNF-07 | BD/Búsqueda | A | ✅ conteos `0` en `rdm_records_metadata`, `rdm_drafts_metadata`, `pidstore_pid (recid/oai)` y en los índices de OpenSearch | Consultas SQL + `_count` |

## Resumen de cobertura

| Requerimiento | Cubierto por |
|---|---|
| RF-01…RF-05, RF-08, RF-09, RF-14 | P-01…P-15 (directo) |
| RF-04, RNF-04 | P-08 + API/OAI activos (verificación estructural) |
| RF-06, RF-07, RF-11…RF-13 | Verificación estructural del sistema desplegado (rutas y funciones nativas de la plataforma); pruebas funcionales específicas pendientes de la fase de aceptación |

## Pendientes de la fase de aceptación

1. Prueba de carga (20 usuarios concurrentes) para RNF-01.
2. Pruebas funcionales de versionado (RF-06) y comunidades (RF-07) con flujo completo UI.
3. Capturas de pantalla por rol para el manual de usuario (entregable §18).

*Firmado por el coordinador de pruebas del equipo (Grupo 4) — 25/10/2026.*
