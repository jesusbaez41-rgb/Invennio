# Inventario de software del OEE — Registro 001

**Referencia estándar:** Título II, Capítulo 1 §1 (campos mínimos del inventario).
**Proyecto:** Repositorio UNAE Análisis · **Fecha de registro:** 25/10/2026 · **Actualizado por:** Unidad TIC / Grupo 4.

> El registro original de este inventario debe darse de alta además en el sistema de
> administración de software del estado (`https://admin.paraguay.gov.py`) — trámite administrativo
> pendiente (ver [00-matriz-cumplimiento.md](00-matriz-cumplimiento.md), C1 §1).

## Ficha del software

| Campo exigido | Valor |
|---|---|
| **Nombre del software** | Repositorio UNAE Análisis (personalización del *InvenioRDM Starter*) |
| **Objeto o propósito** | Repositorio institucional para preservar, compartir y descubrir la producción académica y científica de la universidad (metadatos + archivos de investigación, con búsqueda, comunidades y acceso abierto). |
| **Área técnica responsable** | Unidad especializada TIC de la institución (proyecto ejecutado por el equipo de desarrollo Grupo 4). |
| **Tipo de uso** | Docentes e investigadores (depósito y gestión), estudiantes y comunidad académica (consulta), administración (gestión del sistema); público general (acceso abierto a registros publicados). |
| **Lenguajes de programación** | Python 3.13 (backend/CLI), JavaScript (frontend empaquetado con Webpack), LESS/CSS y HTML/Jinja2 (plantillas). |
| **Bases de datos** | PostgreSQL 17.4 (datos transaccionales), OpenSearch 2.18 (índices de búsqueda y eventos), Valkey 7.2.5 (caché y cola de mensajes de Celery). |
| **Frameworks** | Invenio RDM (invenio-app-rdm 13.0.8 / invenio-rdm-records), Flask + Flask-Security, Celery, SQLAlchemy/Alembic, Gunicorn 23, Webpack/Flask-Collect, Caddy 2.10 (proxy TLS), Docker Compose (orquestación). |
| **Año de creación** | 2026 |
| **Año de implementación** | 2026 |
| **Vigente (Si/No)** | Sí — vigencia desde 25/10/2026, en operación. |
| **Enlace al repositorio de código fuente** | `https://github.com/jesusbaez41-rgb/Invennio` (rama `main`, commit `0ef7467…`; copia MITIC pendiente — ver matriz C1 §2). |
| **Enlaces al sistema** | Desarrollo: `https://localhost` (proxy Caddy local) · Producción: `https://lasi.soteweb.com` (configurada en `.env.prod`). |
| **Software licenciado (Si/No)** | No — software de código abierto. Licencia del código propio: **MIT** (archivo `LICENSE`). Componentes de terceros conservan sus licencias open source (ver especificación §15). |
| **Soporte / mantenimiento (Si/No)** | Sí — soporte y mantenimiento **interno** por el equipo de desarrollo (12 meses según compromiso §19 de la especificación). No existe soporte externo contratado. |
| **Datacenter / infraestructura** | Desarrollo: estación de trabajo Linux con Docker Engine (local). Producción: máquina virtual Linux en proveedor de hosting externo (o alternativa Nube-PY del MITIC, pendiente de decisión formal — ver especificación §9). |
| **Detalle de costos estimativos** | Desarrollo: horas-hombre del equipo (académico, sin costo monetario registrado). Operación estimada: VM 4 vCPU / 8 GB RAM / 100 GB SSD ≈ USD 25–50/mes de hosting; dominio TLS según proveedor. Mantenimiento: ~2 h/mes de operaciones internas. *(estimación referencial)* |
| **Lista de desarrolladores** | Grupo 4 del curso (ver EC-12 de la especificación para el plantel por rol). Nombres a completar por la unidad TIC al dar de alta el registro. |

## Componentes de terceros integrados (para auditoría de licencias)

| Componente | Versión | Rol | Licencia |
|---|---|---|---|
| InvenioRDM / invenio-app-rdm | 13.0.8 | Plataforma de repositorio | MIT |
| PostgreSQL | 17.4 | Base de datos | PostgreSQL License (BSD-like) |
| OpenSearch | 2.18.0 | Búsqueda e índices | Apache-2.0 |
| Valkey | 7.2.5 | Caché / broker | BSD-3 |
| Caddy | 2.10 | Proxy inverso + TLS | Apache-2.0 |
| Gunicorn | 23.0 | Servidor de aplicación WSGI | MIT |
| Docker / Compose | Engine 29.x | Orquestación | Apache-2.0 (cliente) |
| InvenioRDM Starter (base) | 14.0.0 | Plantilla de despliegue | MIT |
