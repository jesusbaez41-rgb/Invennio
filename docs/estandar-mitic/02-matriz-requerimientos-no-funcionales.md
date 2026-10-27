# Matriz de requerimientos no funcionales (RNF)

**Proyecto:** Repositorio UNAE Análisis · **Revisión:** 1.0 · **Fecha:** 25/10/2026

Criterio de estado: ✅ implementado y verificado · 🟡 parcial (tarea abierta).

| ID | Atributo | Requerimiento (medible) | Verificación | Estado |
|---|---|---|---|---|
| RNF-01 | **Rendimiento** | Las páginas principales (`/`, `/search`, ficha de registro) deberán responder en **≤ 2 s** en el percentil 95 con carga de 20 usuarios concurrentes sobre la infraestructura de referencia (4 vCPU / 8 GB RAM). Las consultas de la API de búsqueda deberán responder en **≤ 1,5 s**. | Medición con `time`/curl sobre el despliegue actual: página principal ~0,4 s con 0 registros registrados; a repetir con carga representativa. | ✅ base / 🟡 carga |
| RNF-02 | **Seguridad** | Ver [05-especificacion-tecnica.md §16](05-especificacion-tecnica.md) (Criterios CERT.py): TLS obligatorio, CSRF en escrituras, contraseñas cifradas, RBAC, mín. privilegio, validación/sanitización de entradas, logs de acceso y errores. | Matriz de controles §16 + pruebas negativas (escritura sin sesión → 403; sin Referer → 400). | 🟡 (pendientes operativos: rotación de credenciales por defecto, secretos fuertes, cert confiable) |
| RNF-03 | **Portabilidad** | El sistema **no deberá depender de un equipamiento hardware específico** (restricción explícita del estándar, T-I §9) y deberá desplegarse en cualquier host Linux con Docker Engine ≥ 24. | `compose.yml` declara servicios sin vínculos a hardware; probado en host local; sin drivers ni binarios específicos de plataforma. | ✅ |
| RNF-04 | **Interoperabilidad** | Exponer API REST JSON documentable (OpenAPI de Invenio) y OAI-PMH (`/oai2d`) para cosecha de metadatos por terceros. | Endpoints `GET /api/records`, `GET /oai2d?verb=Identify` activos. | ✅ |
| RNF-05 | **Usabilidad e idioma** | Interfaz en español con identidad institucional; accesible en navegadores modernos y responsive en escritorio/móvil. | Revisión de páginas principales y plantillas del tema. | ✅ |
| RNF-06 | **Disponibilidad** | En producción, los servicios deberán reiniciarse ante fallo (`restart: unless-stopped` en compose de producción) y los datos deberán persistir en volúmenes dedicados (`db-data`, `search-data`, `caddy-data`, `instance-data`). | Volúmenes declarados en `compose.yml`; política de restart por definir en el entorno de producción. | 🟡 |
| RNF-07 | **Mantenibilidad** | Infraestructura como código (compose), código fuente versionado en Git, documentación técnica en `docs/` (mkdocs) y procedimientos de instalación reproducibles (`entrypoint.py`, manuales). | Estructura del repositorio; manuales §18. | ✅ |
| RNF-08 | **Escalabilidad** | El servidor web (gunicorn) deberá ser escalable horizontalmente por réplicas; el worker Celery por réplicas adicionales; la búsqueda por clúster OpenSearch. | Configuración actual: 2 workers × 2 hilos; worker Celery separado; OpenSearch con índices versionados. | ✅ (diseño) |
| RNF-09 | **Capacidad** | Los archivos de depósito deberán admitir hasta **10 GB** por archivo (límite por defecto del sistema) con cuota configurable por registro; la base de datos y los índices crecerán por partición/temporalidad. | `FILES_REST_DEFAULT_MAX_FILE_SIZE = 10 GB` verificado en configuración; subida real verificada (ver M3). | ✅ |
| RNF-10 | **Auditabilidad** | Los accesos (gunicorn access log), errores de aplicación y tareas del worker (Celery/OpenSearch) deberán quedar registrados y consultables; los registros de trabajos (job logs) se retienen según la política configurada (`JOBS_LOGGING_RETENTION_DAYS`). | Logs accesibles vía `docker logs`; data stream `invenio-rdm-job-logs` operativo (corrección verificada). | ✅ |

## Nota de verificación de rendimiento

La medición base se realizó con `curl` sobre el despliegue local (0 registros): `GET /` ≈ 0,38 s
end-to-end vía proxy TLS. La prueba de carga con usuarios concurrentes queda como tarea de la fase
de aceptación (protocolo: `docker compose up` en ambiente de pruebas + herramienta de carga),
registra en el plan de trabajo §17.
