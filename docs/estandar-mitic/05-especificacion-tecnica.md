# Especificación técnica — Repositorio UNAE Análisis (según Estándar de Software MITIC v1.0)

**Modalidad:** Título II — Desarrollo de software de titularidad del Estado.
**Submodalidad:** Desarrollo de software con requerimientos definidos.
**Revisión:** 1.0 · **Fecha:** 25/10/2026.
Cada sección lleva el código `EC-##` con el que la [matriz de cumplimiento](00-matriz-cumplimiento.md) referencia la evidencia.

---

## 1. Introducción y justificación *(EC-1, EC-2)*

La institución necesita un repositorio institucional digital que garantice la **preservación,
difusión y acceso abierto** a la producción académica y científica (trabajos de grado, tesis,
artículos, datasets de investigación y documentos institucionales), con metadatos estandarizados,
identificadores persistentes y trazabilidad de versiones.

**Justificación.** Antes de decidir el enfoque se evaluaron alternativas existentes: (a) software
repositorio de código abierto ya probado (InvenioRDM — plataforma usada por CERN/Zenodo, licencia
MIT), (b) desarrollo a medida completo, (c) adquisición de software propietario. Se adopta la
alternativa (a): una plataforma open source madura, adaptada y configurada a los requerimientos
definidos de la institución. Esto maximiza el aprovechamiento de soluciones existentes — premisa
del estándar (T-I §9) — minimiza el costo, y deja la personalización de titularidad institucional
bajo licencia abierta.

## 2. Submodalidad de adquisición *(EC-1)*

**Desarrollo de software con requerimientos definidos** (Título II, Cap. 2, Sección 1 del estándar):
las funcionalidades requeridas están definidas de forma suficiente en la
[matriz de requerimientos funcionales](01-matriz-requerimientos-funcionales.md); la base
tecnológica es software de código abierto de terceros (condición promovida por el MITIC) y el
trabajo propio consiste en instalación, configuración, personalización, integración, documentación
y pruebas.

## 3. Objetivo general *(EC-3)*

Implementar y poner en operación el **Repositorio UNAE Análisis**: una plataforma web segura,
basada en estándares abiertos, que permita a la comunidad universitaria **depositar, preservar,
buscar, recuperar y descargar** la producción académica y científica, con control de acceso por
roles, identificadores persistentes, versionado de registros e interfaces de interoperabilidad
(API REST y OAI-PMH).

## 4. Objetivos específicos *(EC-4)*

1. Desplegar la plataforma en contenedores (proxy TLS, aplicación web, worker de tareas, base de
   datos, búsqueda, caché) con infraestructura como código reproducible.
2. Configurar la identidad institucional (nombre, subtítulo, pie de página) y la interfaz en español.
3. Habilitar el flujo de depósito completo: borrador → carga de archivos con verificación de
   integridad → publicación con identificador persistente (PID y OAI).
4. Implementar la búsqueda con facetas y ordenamientos sobre índices OpenSearch.
5. Establecer el modelo de roles y permisos (administración, depósito, consulta) y el panel de
   administración con gestión de usuarios.
6. Garantizar la persistencia de archivos en almacenamiento local del servidor (o S3 compatible),
   con cuota y límite por archivo configurables.
7. Exponer interfaces de interoperabilidad (API REST JSON y OAI-PMH) para consumo por terceros.
8. Registrar eventos de uso (vistas y descargas) como estadísticas verificables.
9. Producir la documentación técnica y de cumplimiento conforme al Estándar de Software (este
   paquete) y las pruebas funcionales con evidencias.
10. Definir el plan de soporte, capacitación y garantía conforme a los ítems 6–9 de la Sección 1.

## 5. Definiciones, acrónimos y abreviaturas *(EC-5)*

Se adoptan las definiciones del Estándar (API, Arquitectura, Código Fuente/Objeto, Fábrica de
software, OEE, OT, Proveedor, Software, etc.) y se añaden las específicas del proyecto:

| Término | Definición |
|---|---|
| **InvenioRDM** | Plataforma open source (CERN) de gestión de datos de investigación; base tecnológica del proyecto. |
| **Registro** | Elemento publicado y visible en el repositorio: metadatos + archivos + identificador persistente. |
| **Borrador (draft)** | Versión editable de un registro aún no publicada. |
| **PID (Persistent Identifier)** | Identificador interno permanente del registro (`recid`) con registro OAI asociado. |
| **OAI-PMH** | Protocolo de cosecha de metadatos expuesto en `/oai2d`. |
| **Comunidad** | Agrupación curada de registros (unidad, proyecto o línea de investigación). |
| **Lápida (tombstone)** | Página de retiro visible cuando un registro publicado es retirado. |
| **Gunicorn** | Servidor de aplicación WSGI que ejecuta la aplicación web. |
| **Celery / Worker** | Sistema de tareas en segundo plano (indexación, limpieza de logs, estadísticas). |
| **OpenSearch** | Motor de búsqueda e índices documentales. |
| **Valkey** | Almacén en memoria (caché de sesiones y cola de mensajes de Celery). |
| **Caddy** | Servidor proxy inverso con terminación TLS. |
| **RBAC** | Control de acceso basado en roles. |
| **CSRF** | Falsificación de petición en sitios cruzados; se mitiga con tokens por sesión. |
| **SMLV** | Salario Mínimo Legal Vigente (referencia del estándar para montos). |
| **SII** | Sistema de Intercambio de Información del MITIC. |

## 6. Antecedentes *(EC-6)*

La producción académica de la institución se encontraba dispersa (depósitos locales, archivos
enviados por correo, copias en plataformas de terceros), sin metadatos homogéneos, sin
identificadores persistentes y sin un punto único de búsqueda. El proyecto surge como trabajo
grupal (Grupo 4) para dotar a la institución de un repositorio único, tomando como base
**InvenioRDM** y la plantilla de despliegue **InvenioRDM Starter**, adaptadas al contexto
institucional (identidad visual, español, flujo de depósito con archivos, administración de
usuarios). Forma parte de la línea de trabajo de la unidad TIC sobre gestión de información
académica y acceso abierto.

## 7. Marco legal *(EC-7)*

Normativa aplicable al sistema y a su operación:

| Norma | Relevancia para el proyecto |
|---|---|
| Ley Nº 6207/2018 (crea el MITIC) y Decreto Nº 2274/2019 | Marco que origina el Estándar de Software adoptado como guía de calidad. |
| Ley Nº 5282/2014 y Decreto Nº 4064/2015 (acceso a la información pública) | El repositorio es un instrumento de acceso abierto a la producción académica. |
| Ley Nº 1328/1998 (derecho de autor) | Régimen de titularidad y licencias sobre los contenidos depositados y sobre el código. |
| Ley Nº 4017/2010 y Nº 4610/2012 (firma electrónica/digital) | Referencia para la validez de documentos electrónicos del sistema. |
| Res. MITIC Nº 212/2020 (interoperabilidad) y Dto. Nº 8709/2018 (SII) | Obligatorios solo si el sistema consume datos interinstitucionales (ver §21). |
| Res. MITIC Nº 218/2020 (portal único) | Aplica solo si se publican trámites ciudadanos en línea (ver §23). |

*Nota:* no media un proceso de compra pública (Ley Nº 2051/03); la adopción del estándar es
voluntaria como marco de calidad del desarrollo.

## 8. Beneficiarios *(EC-8)*

| Tipo de usuario | Condición | Cantidad estimada |
|---|---|---|
| Estudiantes de grado | Beneficiario directo (consulta y depósito guiado) | ~5.000 *(estimación)* |
| Estudiantes de posgrado / tesistas | Beneficiario directo (depósito de tesis) | ~400 *(estimación)* |
| Docentes e investigadores | Beneficiario directo (depósito, gestión y curaduría) | ~450 *(estimación)* |
| Personal administrativo | Beneficiario directo (gestión institucional) | ~300 *(estimación)* |
| Administradores del sistema | Usuario interno (unidad TIC) | 2–5 |
| Comunidad académica externa y público general | Beneficiario indirecto (consulta abierta) | Sin límite |

## 9. Infraestructura para el software *(EC-9)*

| Aspecto | Especificación |
|---|---|
| **Ambiente de desarrollo** | Estación de trabajo Linux con Docker Engine ≥ 24 (probado con 29.x) y Docker Compose; 8 GB RAM recomendados. Puertos publicados: 80 y 443 (proxy). |
| **Ambiente de producción** | Máquina virtual Linux (cualquier distribución) de **4 vCPU / 8 GB RAM / 100 GB SSD**, en datacenter de proveedor externo contratado por la institución **o** en **Nube-PY** del MITIC (decisión formal pendiente; se suscribirá el acuerdo de nube/hosting correspondiente). |
| **Datacenter y responsable** | El responsable de la infraestructura depende directamente de la unidad especializada TIC de la institución. |
| **Componentes desplegados** | 6 contenedores: `proxy` (Caddy, único con puertos 80/443 publicados), `web` (gunicorn, puerto interno 5000), `worker` (Celery), `db` (PostgreSQL 17.4), `search` (OpenSearch 2.18), `cache` (Valkey 7.2.5). Los servicios de datos **no** exponen puertos al host. |
| **Volúmenes persistentes** | `db-data`, `search-data`, `caddy-data`, `caddy-config`, `instance-data` (archivos del repositorio). |
| **Estaciones de trabajo** | Navegadores web modernos (escritorio o móvil); no se requiere software cliente específico. |
| **Dispositivos especializados** | No aplica. |
| **Restricción de lotes** | No se incluye hardware en este alcance; el aprovisionamiento de la VM es un trámite separado de la unidad TIC. |

## 10. Confidencialidad *(EC-10)*

Cláusula modelo adoptada para todo el personal y proveedores del proyecto (adaptada del texto del
estándar):

1. La información y documentación provista por la institución, y los datos y resultados obtenidos
   de los servicios, son de **propiedad exclusiva** de la institución y de carácter confidencial
   según la normativa aplicable.
2. El personal desarrollador se obliga a **confidencialidad absoluta** sobre las creaciones,
   algoritmos, código fuente y objeto, manuales y documentación preparatoria, técnica y de uso.
3. Toda información facilitada —técnica, comercial, financiera u operacional, en cualquier soporte—
   se considera **Información Confidencial**, incluida la derivada de la propia información.
4. Obligaciones del desarrollador: (a) tratar la información como estrictamente secreta; (b)
   custodiarla separada de otra información; (c) usarla y transmitirla exclusivamente para los
   fines del proyecto; (d) controlar su uso y no copiarla sin consentimiento salvo para estudio
   interno; (e) restringir el acceso solo al personal que deba conocerla, garantizando que conoce
   sus obligaciones; (f) no cederla a terceros sin autorización escrita.
5. La institución es titular exclusiva de la información confidencial; nada implica licencia o
   cesión de derechos de PI. Ninguna parte usará la marca o nombre de la otra sin consentimiento
   escrito.
6. El desarrollador no podrá usar la información ni los análisis funcionales para terceros ni en
   implementaciones que lo coloquen en situación privilegiada; toda infracción genera
   responsabilidad por daños y sanciones.

**Grados de información del proyecto:** (i) *pública*: documentación técnica, código fuente,
licencias; (ii) *confidencial*: credenciales, claves de configuración (`INVENIO_SECRET_KEY`,
sal, contraseñas), datos personales de usuarios; (iii) *reservada*: datos personales depositados
en registros con acceso restringido.

## 11. Criterios y restricciones según monto *(EC-11 — no aplica)*

El proyecto **no es una adquisición** en el marco de la Ley Nº 2051/03: es un desarrollo interno
académico sin contraprestación económica. Por tanto, las restricciones por tramos de SMLV
(oferente persona jurídica, rubro TIC, antigüedad, referencias de clientes, profesionales de
relevada experiencia) **no aplican**. Se conserva esta sección como guía referencial por si el
proyecto migra a un proceso de contratación:

| Concepto | ≤ 500 SMLV | 501–2000 SMLV | 2001–5000 SMLV |
|---|---|---|---|
| Oferente | PJ radicada en el país | PJ constituida en el país | PJ constituida en el país |
| Experiencia mínima (licitaciones locales) | 2 años | 4 años | 6 años |
| Referencias de clientes (mínimo) | 3 (≥2 en Paraguay) | 6 (≥2 en Paraguay) | 8 (≥2 en Paraguay) |
| Monto de referencias | ≥ 30 % del monto referencial | ≥ 30 % + 1 ref. ≥ 500 SMLV | ≥ 30 % + 1 ref. ≥ 1000 SMLV |
| Personal técnico mínimo del OEE | Líder TIC + 1 analista | Líder + 1 desarrollador + 1 tester + 1 admin servidores + 1 implementador | Líder + analista + 2 desarrolladores + 2 testers + 1 admin servidores + 1 implementador |

## 12. Perfiles técnicos del personal *(EC-12)*

| Perfil | Cantidad | Responsabilidad en el proyecto |
|---|---|---|
| Líder / coordinador TIC del proyecto | 1 | Planificación, control de alcance, relación con la unidad TIC y aprobación de entregables. |
| Analista funcional | 1 | Relevamiento, matriz de requerimientos (Anexo I), casos de uso y validación funcional. |
| Desarrolladores (senior/junior) | 2 | Personalización, configuración, scripts de instalación, integración de componentes y corrección de defectos. |
| Tester de software | 1 | Ejecución de pruebas (matriz de trazabilidad M3), registro de evidencias e informe de calidad. |
| Administrador de servidores | 1 | Despliegue, volúmenes, proxy/TLS, respaldos y operación de contenedores. |
| Implementador / gestor del cambio | 1 | Capacitación, adopción por usuarios y acompañamiento post-implementación. |

*Requisitos del estándar:* el personal permanente del OEE deberá estar en nómina y contar con
título de grado (o último año) en carreras afines; los CVs firmados y la declaración de
compromiso del plantel se adjuntarán al expediente del proyecto por la unidad TIC.

## 13. Propiedad intelectual, derechos de autor y licencia *(EC-13 — Cap. 1 §7)*

- **Titularidad:** los derechos patrimoniales sobre la **personalización, configuración,
  documentación y desarrollos propios** del proyecto corresponden a la institución (obra realizada
  en cumplimiento de la relación académica/funcional con la institución, conforme a los artículos
  14 y 69 de la Ley Nº 1328/1998).
- **Componentes de terceros:** la plataforma base InvenioRDM y los componentes del stack son
  software de código abierto de terceros; se conservan sus licencias originales (ver inventario)
  y no se incorpora software cuyo licenciamiento impida la cesión plena al OEE.
- **Licencia adoptada:** **MIT** (dentro del enfoque open source que el estándar enuncia — lista
  enunciativa que incluye Apache-2.0 y LGPL-3, no taxativa). El código propio se publica en
  `LICENSE` del repositorio, permitiendo libre uso, distribución, reproducción, modificación y
  fusión conforme a dicha licencia.
- **Resguardos de seguridad:** la definición de licencia no compromete datos de usuarios: los
  datos personales y contenidos depositados no forman parte del código y su tratamiento se rige
  por la política de acceso del repositorio.

## 14. Arquitectura general *(EC-14)*

**Arquitectura:** cliente/servidor web multicapa en contenedores (Docker), con aplicación
monolítica modular (Invenio/Flask) sobre servicios de datos dedicados.

| Componente | Tipo de arquitectura | Base de datos / almacenamiento | Software de ejecución |
|---|---|---|---|
| Proxy TLS (`caddy`) | Web (proxy inverso) | — (certificados en volumen) | Caddy 2.10 (contenedor) |
| Aplicación web (`web`) | Web / servidor de aplicación | PostgreSQL (relacional), OpenSearch (índices), Valkey (caché de sesión) | Gunicorn 23 sobre Python 3.13 (contenedor Debian) |
| Worker de tareas (`worker`) | Servidor de aplicaciones (procesos en segundo plano) | idem web + cola Valkey | Celery sobre Python 3.13 (contenedor) |
| Base de datos (`db`) | Servicio transaccional | **Relacional** (PostgreSQL 17.4) | contenedor oficial |
| Búsqueda (`search`) | Servicio de índices | **Documental/invertido** (OpenSearch 2.18) | contenedor oficial |
| Caché/cola (`cache`) | Servicio en memoria | **En memoria** (Valkey 7.2.5) | contenedor oficial |
| Almacenamiento de archivos | Persistencia de objetos | Sistema de archivos local (o S3 compatible) | volumen `instance-data` |

**API del producto para integraciones** (opcional según estándar, implementada): API REST JSON
(`/api/records`, `/api/communities`, vocabularios, `/api/users`, `/oai2d`) apta para consumo por
otros sistemas y para futuras integraciones vía SII.

**Integraciones con sistemas existentes:** no requiere; las integraciones futuras se realizarán
por API REST u OAI-PMH (y por SII si implican datos de otras instituciones).

## 15. Tecnología *(EC-15)*

| Ítem | Tecnología adoptada | Licencia de uso (desarrollo y producción) |
|---|---|---|
| Sistema operativo (anfitrión) | Linux (distribución libre; verificado en Arch/CachyOS) | GPL y afines, sin costo |
| Sistema operativo (contenedores) | Debian 12 “bookworm” | sin costo |
| Orquestación | Docker Engine + Docker Compose | Apache-2.0 (cliente), sin costo |
| Servidor web | Caddy 2.10 | Apache-2.0 |
| Servidor de aplicaciones | Gunicorn 23 (WSGI) | MIT |
| Middleware | Celery (tareas) + Valkey 7.2.5 (broker/caché) | BSD / BSD-3 |
| Lenguajes | Python 3.13, JavaScript, LESS/CSS, HTML (Jinja2) | PSF / sin costo |
| Frameworks | Invenio 12 (invenio-app-rdm 13.0.8, invenio-rdm-records), Flask, Flask-Security, SQLAlchemy/Alembic, Webpack | MIT y afines (verificación por paquete) |
| Bases de datos | PostgreSQL 17.4 (relacional) · OpenSearch 2.18 (documental) · Valkey (memoria) | PostgreSQL / Apache-2.0 / BSD-3 |
| Repositorio de código | Git — `https://github.com/jesusbaez41-rgb/Invennio` (+ copia MITIC pendiente, EC-25) | — |
| Dependencias fijadas | `uv.lock` (Python) y `pnpm-lock.yaml` (frontend) | reproducibilidad de versión |

Todas las tecnologías son open source y de uso libre en desarrollo y producción; no existen
componentes licenciados de pago (condición promovida por el estándar, Cap. 2 §4).

## 16. Seguridad *(EC-16)*

Criterios según la guía **“Criterios mínimos de seguridad para el desarrollo y adquisición de
software”** (CERT.py) y el ítem S1 §5 del estándar. Controles implementados y verificados:

| Criterio | Control implementado | Verificación |
|---|---|---|
| Transporte cifrado | Terminación TLS en Caddy (único punto expuesto: 80/443). En desarrollo certificado autofirmado; en producción certificado confiable. | Acceso exclusivo vía `https://`; puertos internos de db/search/cache no publicados. |
| Autenticación | Cuentas con correo+contraseña (Flask-Security); contraseñas almacenadas cifradas (hash), nunca en texto plano; control de sesiones con cookie firmada. | Login verificado (P-02). |
| Autorización (RBAC) | Roles `admin` (`superuser-access`), `administration`, `administration-moderation`; permisos por servicio en API y UI. | Escrituras anónimas → 403 (P-11). |
| Protección CSRF | Token por sesión exigido en toda escritura + verificación de `Referer`/`Origin`. | Peticiones sin token/Referer → 400 (P-12). |
| Validación de entradas | Esquemas Marshmallow estrictos (campos desconocidos descartados, tipos validados); sanitización de HTML en páginas dinámicas. | Formas canónicas de la API (R-03 de M1). |
| Mínimo privilegio | El proceso de aplicación corre como usuario no privilegiado (`invenio`, uid 1654) con directorios de datos con dueño correcto. | Verificación de permisos en `/opt/invenio/var/instance/data`. |
| Gestión de secretos | Secretos vía variables de entorno (`INVENIO_SECRET_KEY`, sal de contraseñas, credenciales de BD); nunca en el código. | `compose.yml` + `.env.prod` (producción). |
| Registro y monitoreo | Access logs (gunicorn), logs de aplicación y worker, índices de job logs y eventos de uso en OpenSearch. | Logs consultables; data stream operativo (P-16). |
| Integridad de archivos | Checksum MD5 declarado en el registro del archivo y verificado en la transferencia. | P-04/P-06. |
| Respaldos | Volúmenes persistentes separados; procedimiento de respaldo de `db-data` e `instance-data` documentado para la unidad TIC. | Manual de instalación (§18). |
| Actualizaciones | Imágenes versionadas por tag; `uv.lock`/`pnpm-lock.yaml` fijan dependencias; revisión periódica de avisos de seguridad de los componentes. | Estructura del repositorio. |

**Brechas operativas abiertas (plan de cierre — responsable unidad TIC):**

1. Rotar credenciales por defecto (usuario administrador y contraseña `changeme`).
2. Definir `INVENIO_SECRET_KEY` y `INVENIO_SECURITY_PASSWORD_SALT` fuertes y únicos en producción.
3. Certificado TLS confiable para el dominio de producción.
4. Políticas de reinicio (`restart: unless-stopped`) y firewall del host en producción.
5. Copias de seguridad programadas y prueba de restauración.

## 17. Plan de trabajo *(EC-17)*

Cronograma general por iteraciones (2 semanas c/u). Metodología: iterativa-incremental con
entregas verificables por módulo (adaptada a la naturaleza académica del proyecto).

| Iteración | Actividades | Entregable | Responsable |
|---|---|---|---|
| I1 | Levantamiento y análisis de requerimientos; selección de plataforma | Matriz RF (M1) + diseño conceptual | Analista + Líder |
| I2 | Despliegue base del stack (compose, proxy TLS, BD, búsqueda, caché) | Sistema accesible en `https://localhost` | Admin servidores |
| I3 | Configuración institucional (identidad, español, roles, usuario admin) | Tema aplicado + roles/permisos | Desarrolladores |
| I4 | Flujo de depósito: borrador, archivos, publicación; corrección de almacenamiento e índices | Depósito end-to-end operativo | Desarrolladores |
| I5 | Pruebas funcionales con evidencias; corrección de defectos | Matriz de trazabilidad M3 + informe de calidad | Tester |
| I6 | Documentación de cumplimiento (este paquete), manuales, plan de soporte y garantía | Paquete `docs/estandar-mitic/` completo | Líder + equipo |
| Post | Capacitación y gestión del cambio (ver abajo) | Acta de capacitación | Implementador |

**Plan de capacitación y gestión del cambio:**

| Capacitación | Participantes | Duración | Modalidad / lugar | Materiales | Certificación |
|---|---|---|---|---|---|
| C1 — Administración del repositorio | Administradores de sistema (2–5) | 8 h | Virtual (videoconferencia) | Manual de administración, guía de respaldos | Constancia de participación |
| C2 — Depósito y gestión de registros | Docentes/investigadores (por lotes de ~30) | 4 h | Virtual | Manual del usuario + guía rápida de depósito | Constancia |
| C3 — Operación técnica | Programador/soporte interno | 6 h | Virtual | Arquitectura, operación de contenedores, monitoreo | Constancia |

## 18. Entregables *(EC-18)*

| Entregable del estándar | Artefacto real en el proyecto |
|---|---|
| Documentación del proceso de análisis | [01-matriz-requerimientos-funcionales.md](01-matriz-requerimientos-funcionales.md) y [02-matriz…no-funcionales.md](02-matriz-requerimientos-no-funcionales.md) |
| Código fuente en repositorio oficial | Git — `https://github.com/jesusbaez41-rgb/Invennio` (rama `main`) |
| Informe de entrega y evidencias de control de calidad | [03-matriz-trazabilidad-pruebas.md](03-matriz-trazabilidad-pruebas.md) (18 casos con evidencia) |
| Manual de instalación — ambiente de desarrollo | §A.1 de este documento (abajo) + `entrypoint.py` |
| Manual de instalación — ambiente de producción | §A.2 de este documento (abajo) + `compose.prod.yml` / `.env.prod` |
| Manual del usuario | Guía de uso publicada en el propio sistema (`/help`) + manual por perfil (C1–C3 del plan de capacitación) |
| Otros documentos | Matriz de cumplimiento, inventario de software, licencia MIT (`LICENSE`) |
| Instaladores | No aplica: entrega mediante contenedores versionados (imágenes declaradas en `compose.yml`) |

### §A.1 — Instalación en ambiente de desarrollo

1. Requisitos: Linux con Docker Engine ≥ 24 y Docker Compose; 8 GB RAM recomendados.
2. Clonar el repositorio: `git clone https://github.com/jesusbaez41-rgb/Invennio.git && cd Invennio`.
3. Levantar el stack: `docker compose up -d` (servicios: proxy, web, worker, db, search, cache).
4. Inicializar datos la primera vez: `docker compose exec web invenio db init create`,
   `docker compose exec web invenio index init`, crear ubicación de archivos
   (`invenio files location create default file:///opt/invenio/var/instance/data`) y usuario
   administrador (`invenio users create <email> --password … --active --confirm`).
   *Alternativa:* ejecutar el script de inicialización `entrypoint.py` (ver §25).
5. Ajustar dueños del directorio de datos si el volumen se recreó:
   `docker exec -u root <web> chown -R 1654:0 /opt/invenio/var/instance/data`.
6. Verificar: `curl -k https://localhost/` y la API `curl -k https://localhost/api/records`.

### §A.2 — Instalación en ambiente de producción

1. Aprovisionar la VM (4 vCPU / 8 GB / 100 GB) y Docker; abrir solo 80/443.
2. Copiar el repositorio y crear `.env` desde `.env.prod` con: dominio
   (`INVENIO_SITE_UI_URL/API_URL`), `INVENIO_TRUSTED_HOSTS`, credenciales de BD fuertes,
   `INVENIO_SECRET_KEY` y `INVENIO_SECURITY_PASSWORD_SALT` únicos, correo del administrador.
3. Certificado TLS confiable para el dominio (Caddy lo gestiona automáticamente con dominio real).
4. Levantar `docker compose -f compose.yml -f compose.prod.yml --env-file .env up -d` y ejecutar la
   inicialización igual que en desarrollo (paso 4 del §A.1).
5. Configurar respaldos programados de `db-data` e `instance-data` y política de reinicio
   (`restart: unless-stopped`).

## 19. Soporte y asistencia técnica *(EC-19)*

| Aspecto | Compromiso |
|---|---|
| Duración | **12 meses** desde la recepción satisfactoria (proyecto con duración estimada > 6 meses ⇒ mínimo del estándar). Incluido en el costo del proyecto. |
| Modalidades | Correctivo (fallas), preventivo (actualizaciones de seguridad y parches), y a solicitud de la unidad TIC; canales: correo institucional del equipo, sistema de seguimiento de incidencias del repositorio (issues), y asistencia virtual/in situ en horario hábil (lunes a viernes, 8:00–17:00). |
| Horas de especialista | Hasta **40 horas** sin costo adicional para consultas, ajustes de errores en cualquier componente y cooperación con otros contratistas. |
| Niveles de servicio | N1 consultas de uso (respuesta ≤ 2 días hábiles) · N2 fallas funcionales (≤ 2 días hábiles, corrección ≤ 5 días) · N3 fallas de servicio total (respuesta ≤ 4 horas hábiles, mitigación inmediata). |
| Actualizaciones | Suministro de actualizaciones y parches de versiones del software propio y del stack durante la vigencia, sin costo adicional. |
| Supervisión y monitoreo | Revisión periódica de logs (web/worker), estado de índices y capacidad de volúmenes. |

## 20. Garantía *(EC-20 — Anexo II del estándar)*

El funcionamiento adecuado del software, en las condiciones vigentes a su recepción final y según
los requerimientos funcionales y no funcionales especificados, queda **garantizado por un periodo
mínimo de 24 (veinticuatro) meses** a partir de la terminación del proyecto, periodo durante el
cual el equipo desarrollador responde por todo **vicio oculto, falla o defecto** que afecte su
funcionamiento, siempre que tengan origen en el código fuente y/o código objeto del software. El
software deberá funcionar en las mismas condiciones y funcionalidades alcanzadas a la recepción
final, con hardware de características equivalentes, de forma perpetua.

- **Vigencia de garantía = vigencia de soporte** (12 meses de soporte activo + garantía residual
  de 24 meses sobre defectos de código, conforme al Anexo II).
- **Obligación de defensa, indemnización y continuidad:** el desarrollador asume la
  responsabilidad total ante reclamos por infracción de derechos de propiedad intelectual o
  industrial de terceros atribuibles a las creaciones entregadas, defendiendo a su costo las
  acciones entabladas (notificadas dentro de los 5 días hábiles) e indemnizando íntegramente a la
  institución; mientras dure el conflicto, proveerá alternativas efectivas y a su costo para que
  la institución continúe operando.
- **Consorcios:** no aplica (desarrollo interno, sin consorcio).

## 21. Interoperabilidad (SII) *(EC-21 — Cap. 1 §2)*

El sistema **no consume datos de personas físicas (cédula) ni jurídicas (RUC)** y no necesita hoy
interoperar con otras instituciones. Regla de diseño registrada: si en el futuro se integra
información de otras instituciones, se hará **exclusivamente por el Sistema de Intercambio de
Información** (Decreto Nº 8709/2018, Res. MITIC Nº 212/2020). El propio sistema expone API REST y
OAI-PMH (§14), que son las interfaces de interoperabilidad hacia terceros.

## 22. Identificación del ciudadano *(EC-22 — Cap. 1 §4)*

No aplica en la versión actual: la autenticación es institucional (cuentas locales de docentes,
estudiantes y administración). Si el OEE decidiera extender el acceso a trámites ciudadanos con
identificación digital, se coordinará con el MITIC la integración de la **Identidad Electrónica**
(`https://www.paraguay.gov.py/identidad-electronica`) conforme a la Res. MITIC Nº 218/2020 Anexo B.

## 23. Portal único y datos abiertos *(EC-23 — Cap. 1 §5)*

- **Trámites en línea para ciudadanos:** no aplica (el sistema no expone trámites del portal
  único). Si en el futuro se publica un trámite, se seguirán los lineamientos de la Res. MITIC
  Nº 218/2020 y se dará de alta en `https://www.paraguay.gov.py`.
- **Datos abiertos y transparencia:** el repositorio **produce datos de interés público** (metadatos
  de producción académica) y ya los expone para consumo y catalogación mediante API REST y
  OAI-PMH; la catalogación formal del dataset en el portal de datos abiertos queda como acción
  recomendada de la unidad TIC.

## 24. Línea gráfica *(EC-24 — Cap. 1 §6)*

No aplica el uso de la línea gráfica del Gobierno Nacional: se trata de un sistema institucional
universitario que aplica la **identidad visual propia de la institución** (nombre
“Repositorio UNAE Análisis”, subtítulo institucional, pie de página) implementada en las plantillas
del tema. Si el sistema llegara a prestar servicios directos a la ciudadanía en nombre del Estado,
se incorporará la línea gráfica gubernamental disponible en el MITIC.

## 25. Repositorio de código y custodia *(EC-25 — Cap. 1 §2)*

- El código fuente y su documentación se administran y custodian por el área TIC mediante **Git**
  (historial completo y versionado): `https://github.com/jesusbaez41-rgb/Invennio`.
- **Copia de resguardo en el repositorio del MITIC:** pendiente de trámite — el responsable TIC
  solicitará el acceso/remitirá el código a `gobiernoelectronico@mitic.gov.py` para el resguardo
  del bien público y posibilitar contribuciones/auditorías (tarea abierta en la
  [matriz de cumplimiento](00-matriz-cumplimiento.md)).
- **Script de inicialización:** `entrypoint.py` automatiza la primera puesta en marcha (BD, roles,
  usuario administrador, ubicación de archivos — local por defecto o S3 si se configura —,
  índices y objetos de búsqueda); se ejecuta manualmente o al construir la imagen de arranque. No
  está cableado como entrypoint de los contenedores para evitar destruir índices en cada reinicio
  (`index destroy --force`); el procedimiento vigente está en los manuales §A.1/§A.2.
