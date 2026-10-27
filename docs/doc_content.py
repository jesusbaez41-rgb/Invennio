# -*- coding: utf-8 -*-
"""Contenido editorial del documento DOCX del Repositorio HGI.

Se separa del generador (build_docx.py) para facilitar el mantenimiento:
aquí vive la redacción; allí, la composición tipográfica.

Las matrices del Estándar de Software MITIC se insertan desde
docs/estandar-mitic/*.md mediante los marcadores {{DOC:ruta}}.
"""

PART1 = r"""
# Ficha del documento

| Campo | Contenido |
|---|---|
| **Nombre del sistema** | Repositorio HGI — Repositorio Institucional de Ciencia Abierta |
| **Denominación del proyecto** | Repositorio HGI (originado como «Repositorio UNAE Análisis») |
| **Institución** | Ministerio de Salud Pública y Bienestar Social — Hospital General de Itapúa |
| **Ubicación** | Encarnación, Departamento de Itapúa, República del Paraguay |
| **Tipo de sistema** | Repositorio institucional digital para la gestión, preservación y difusión de la producción académica y científica |
| **Base tecnológica** | InvenioRDM 13.0.8 sobre la plantilla de despliegue InvenioRDM Starter 14.0.0 |
| **Versión del documento** | 1.0 |
| **Fecha de emisión** | 27 de octubre de 2026 |
| **Estado** | Emitido para revisión y aprobación de la Unidad TIC |
| **Clasificación** | Documento técnico de uso institucional |
| **Idioma** | Español (es-PY) |
| **Marco normativo** | Estándar de Software — Desarrollo y adquisición, MITIC v1.0 (26-05-2020), en el marco de la Ley N.º 6207/2018 y el Decreto N.º 2274/2019 |
| **Repositorio de código** | `https://github.com/jesusbaez41-rgb/Invennio` (rama `main`) |
| **Entorno de desarrollo** | `https://localhost` (proxy Caddy con certificado autofirmado) |
| **Entorno de producción** | `https://lasi.soteweb.com` (Apache institucional delante de la aplicación) |
| **Elaboración** | Equipo de desarrollo del proyecto (Grupo 4) y Unidad TIC |
| **Documentos fuente** | `docs/index.md` y `docs/estandar-mitic/*.md` |

## Propósito del documento

Este documento consolida, en un único artefacto formal, la documentación del
Repositorio HGI «de pies a cabeza»: su origen y justificación, el modelo funcional
completo, la arquitectura y el stack tecnológico, las personalizaciones realizadas
sobre InvenioRDM, los procedimientos de instalación y operación, los controles de
seguridad y el cumplimiento del Estándar de Software del MITIC.

Se trata de un documento vivo: acompaña al código y a la configuración del sistema,
y debe actualizarse cuando se modifiquen funcionalidades, infraestructura o
requerimientos normativos.

## Aprobación

| Rol | Responsable | Fecha | Firma |
|---|---|---|---|
| Líder / coordinador TIC del proyecto |  |  |  |
| Analista funcional |  |  |  |
| Responsable de la Unidad TIC |  |  |  |

# Control de versiones

| Versión | Fecha | Autor | Descripción del cambio |
|---|---|---|---|
| 0.9 | 25/10/2026 | Equipo de desarrollo | Borrador de trabajo: consolidación de las matrices MITIC y de la especificación técnica. |
| 1.0 | 27/10/2026 | Equipo de desarrollo / Unidad TIC | Emisión inicial del documento integral en formato DOCX, con arquitectura, módulos, operación, seguridad y anexos. |

## Convenciones de lectura

- **Idioma y estilo.** El documento se redacta en español institucional, con tono formal y orientado a la evidencia verificable.
- **Códigos de requerimiento.** `RF-##` identifica requerimientos funcionales; `RNF-##`, requerimientos no funcionales; `P-##`, casos de prueba; `EC-##`, secciones de la especificación técnica; `M1`–`M3`, las matrices de requerimientos y trazabilidad; `INV`, el inventario de software.
- **Estados de cumplimiento.** *Cumplido* (implementado y verificado), *Parcial* (existe avance y queda una tarea abierta) y *No aplica* (excluido con justificación registrada).
- **Denominación.** El sistema se denomina actualmente **Repositorio HGI**. Las matrices y la especificación conservan, en algunos pasajes, el nombre original del proyecto (**«Repositorio UNAE Análisis»**) por trazabilidad documental; ambos nombres refieren a la misma plataforma y al mismo código.
- **Referencias internas.** Las referencias a archivos `.md` del repositorio se conservan como texto para preservar la trazabilidad con la fuente. Las direcciones externas se presentan como hipervínculos.
- **Cifras y estimaciones.** Las magnitudes de usuarios y costos son referenciales y se identifican como estimaciones cuando no provienen de una medición directa.

# Tabla de contenido

<<TOC>>

# Resumen ejecutivo

El **Repositorio HGI** es la plataforma institucional del Hospital General de Itapúa
para preservar, compartir y descubrir la producción académica y científica de la
institución. Está construida sobre **InvenioRDM 13.0.8**, la plataforma de gestión de
datos de investigación de código abierto coordinada por el CERN y utilizada por
Zenodo, desplegada mediante la plantilla **InvenioRDM Starter 14.0.0**. El trabajo
propio del proyecto comprende la instalación, la configuración institucional, la
personalización visual y funcional, la automatización del despliegue, las pruebas y
la documentación de cumplimiento.

El sistema cubre el ciclo completo de la información científica: **depósito** de
metadatos y archivos, **verificación de integridad**, **publicación** con identificador
persistente, **búsqueda** con facetas, **acceso y descarga**, **versionado**,
**comunidades** y **administración de usuarios y del sitio**. Expone además interfaces
de interoperabilidad —API REST JSON y OAI-PMH— y registra eventos de uso con fines
estadísticos. Todo el stack se ejecuta en contenedores: proxy TLS, aplicación web,
worker de tareas, base de datos relacional, motor de búsqueda y caché/cola.

La adecuación institucional incluye una identidad visual propia basada en la paleta
roja del MITIC (`#ea2428` y `#8c1618`), la portada con la fotografía aérea del
hospital, una pantalla de acceso institucional, un panel de administración de usuarios
enriquecido con indicadores y el cierre del registro público de cuentas. La
instalación se automatiza con `setup.sh`, probado desde cero en modo local y en modo
producción.

En materia normativa, el proyecto se evaluó contra el **Estándar de Software del
MITIC v1.0**, modalidad *Título II — Desarrollo de software de titularidad del Estado*,
submodalidad *Desarrollo de software con requerimientos definidos*. Se relevaron **37
ítems**, de los cuales **30 resultan cumplidos y verificados**, **2 se encuentran en
estado parcial** con plan de cierre y **5 no aplican** con justificación expresa. El
paquete de evidencia comprende la matriz de cumplimiento, las matrices de
requerimientos funcionales y no funcionales, la matriz de trazabilidad con **18 casos
de prueba ejecutados**, el inventario de software y la especificación técnica con sus
25 secciones y apéndices de instalación.

| Indicador | Valor |
|---|---|
| Módulos funcionales documentados | 12 |
| Requerimientos funcionales especificados | 14 |
| Requerimientos no funcionales especificados | 10 |
| Casos de prueba ejecutados y evidenciados | 18 |
| Ítems del estándar MITIC evaluados | 37 |
| Contenedores en el stack de ejecución | 6 |
| Componentes de terceros inventariados | 8 |
| Plazo de soporte comprometido | 12 meses |
| Plazo de garantía sobre defectos de código | 24 meses |

El documento se organiza en once capítulos y cuatro anexos. Los capítulos 1 a 3
describen el contexto y el sistema funcional; los capítulos 4 y 5 abordan arquitectura
y seguridad; los capítulos 6 y 7 cubren instalación, operación y calidad; el capítulo
8 reproduce íntegramente el paquete de cumplimiento MITIC; los capítulos 9 a 11
ofrecen el manual de usuario, el modelo de soporte y las conclusiones. Los anexos
aportan el inventario de artefactos, la referencia de la plantilla base, la
trazabilidad documental y una lista de verificación para producción.

# 1. Introducción y contexto

## 1.1 Propósito y alcance del documento

Este documento tiene por objeto describir el Repositorio HGI en todos sus aspectos
relevantes para la operación, el mantenimiento, la auditoría y la transferencia de
conocimiento. Se dirige a la Unidad TIC de la institución, al equipo de desarrollo, a
los administradores del repositorio y a los evaluadores del cumplimiento normativo.

El alcance abarca la totalidad del sistema en su estado actual: la base InvenioRDM y
su plantilla de despliegue, las personalizaciones del proyecto, los módulos
funcionales disponibles, la arquitectura de contenedores, los procedimientos de
instalación local y producción, los controles de seguridad, las pruebas ejecutadas y
las matrices de cumplimiento del Estándar de Software del MITIC.

Quedan fuera del alcance de esta versión la aplicación móvil nativa, la integración
efectiva con el Sistema de Intercambio de Información (SII) —prevista como regla de
diseño— y la catalogación formal del conjunto de metadatos en el portal nacional de
datos abiertos, que constituye una acción recomendada a la Unidad TIC.

## 1.2 Antecedentes y justificación

La producción académica y científica de la institución se encontraba dispersa en
depósitos locales, archivos enviados por correo electrónico y copias alojadas en
plataformas de terceros. Esa dispersión impedía aplicar metadatos homogéneos,
garantizar identificadores persistentes, preservar los archivos a largo plazo y
ofrecer un punto único de búsqueda para la comunidad.

Antes de definir la solución se evaluaron tres alternativas:

| Alternativa | Ventajas | Limitaciones | Decisión |
|---|---|---|---|
| **Adoptar InvenioRDM** (open source, MIT, usado por CERN y Zenodo) | Plataforma madura, estándares abiertos, comunidad activa, API y OAI-PMH, coste nulo de licencia | Requiere configuración y personalización | **Adoptada** |
| Desarrollar un repositorio a medida | Control total del alcance | Coste y plazo elevados; reinvención de funciones ya resueltas; mayor deuda de mantenimiento | Descartada |
| Adquirir software propietario | Soporte de proveedor | Coste recurrente, dependencia de proveedor, menor interoperabilidad | Descartada |

La alternativa adoptada maximiza el aprovechamiento de soluciones existentes —premisa
explícita del estándar MITIC— y concentra el esfuerzo propio en la adecuación
institucional, la calidad y la documentación. El código de la plataforma base y de los
componentes de terceros conserva sus licencias originales; la personalización y la
documentación se publican bajo licencia MIT.

## 1.3 Objetivos

**Objetivo general.** Implementar y poner en operación un repositorio institucional
seguro, basado en estándares abiertos, que permita a la comunidad depositar,
preservar, buscar, recuperar y descargar la producción académica y científica, con
control de acceso por roles, identificadores persistentes, versionado e interfaces de
interoperabilidad.

**Objetivos específicos.**

1. Desplegar la plataforma en contenedores reproducibles (proxy TLS, aplicación web,
   worker, base de datos, búsqueda y caché).
2. Configurar la identidad institucional, la interfaz en español y la experiencia de
   acceso del Repositorio HGI.
3. Habilitar el flujo completo de depósito: borrador, carga de archivos con
   verificación de integridad y publicación con identificador persistente.
4. Implementar búsqueda con facetas y ordenamientos sobre índices OpenSearch.
5. Establecer el modelo de roles y permisos, y un panel de administración con gestión
   de usuarios y supervisión del sitio.
6. Garantizar la persistencia de archivos en almacenamiento local o compatible con
   S3, con límites configurables.
7. Exponer interfaces de interoperabilidad (API REST JSON y OAI-PMH).
8. Registrar eventos de uso (vistas y descargas) como estadísticas verificables.
9. Producir la documentación técnica y de cumplimiento, y ejecutar las pruebas con
   evidencias.
10. Definir el plan de soporte, capacitación y garantía conforme al estándar.

## 1.4 Beneficiarios y perfiles de usuario

| Tipo de usuario | Condición | Cantidad estimada |
|---|---|---|
| Estudiantes de grado | Beneficiario directo: consulta y depósito guiado | ~5.000 |
| Estudiantes de posgrado y tesistas | Beneficiario directo: depósito de tesis | ~400 |
| Docentes e investigadores | Beneficiario directo: depósito, gestión y curaduría | ~450 |
| Personal administrativo | Beneficiario directo: gestión institucional | ~300 |
| Administradores del sistema | Usuario interno de la Unidad TIC | 2–5 |
| Comunidad académica externa y público general | Beneficiario indirecto: consulta abierta | Sin límite |

Las cifras son estimaciones referenciales y deben validarse con los registros
académicos de la institución antes de su uso en planificación presupuestaria.

## 1.5 Marco normativo y estándares aplicables

| Norma o estándar | Relevancia para el proyecto |
|---|---|
| **Estándar de Software — Desarrollo y adquisición (MITIC v1.0, 26-05-2020)** | Marco de calidad, documentación y garantía adoptado para el desarrollo. |
| Ley N.º 6207/2018 y Decreto N.º 2274/2019 | Creación del MITIC y marco que origina el estándar. |
| Ley N.º 5282/2014 y Decreto N.º 4064/2015 | Acceso a la información pública; el repositorio es un instrumento de acceso abierto. |
| Ley N.º 1328/1998 | Derecho de autor; titularidad y licencias sobre contenidos y código. |
| Ley N.º 4017/2010 y N.º 4610/2012 | Firma electrónica y digital; referencia para documentos electrónicos. |
| Resolución MITIC N.º 212/2020 y Decreto N.º 8709/2018 | Interoperabilidad y SII, aplicables solo ante intercambio de datos interinstitucionales. |
| Resolución MITIC N.º 218/2020 | Portal único y datos abiertos, aplicable si se publican trámites ciudadanos. |
| ISO/IEC/IEEE 29148 | Criterios de calidad de requerimientos (Anexo I del estándar). |
| CERT.py — Criterios mínimos de seguridad | Guía de controles de seguridad para desarrollo y adquisición. |
| Dublin Core, DataCite, OAI-PMH | Estándares de metadatos, identificadores y cosecha. |

No media un proceso de compra pública regido por la Ley N.º 2051/03: se trata de un
desarrollo interno académico sin contraprestación económica. La adopción del estándar
es voluntaria y constituye el marco de calidad del proyecto.

## 1.6 Metodología y fuentes de elaboración

El documento se construyó por consolidación y verificación de las siguientes fuentes:

- El código y la configuración del repositorio (`compose.yml`, `compose.prod.yml`,
  `invenio.cfg`, `setup.sh`, `entrypoint.py`, plantillas y hoja de estilos).
- La documentación existente en `docs/index.md` y en `docs/estandar-mitic/`
  (matrices 00 a 05 y documento de presentación del paquete).
- La observación directa del sistema desplegado en el entorno local, incluidas las
  pantallas de portada, acceso y administración que ilustran este documento.
- La ejecución de la batería de pruebas P-01 a P-18 registrada en la matriz de
  trazabilidad.

La redacción sigue un enfoque de **evidencia primero**: cada afirmación relevante se
vincula con un artefacto, una prueba o una sección de la especificación técnica.

# 2. Visión general del sistema

## 2.1 Qué es el Repositorio HGI

El Repositorio HGI es un sistema web institucional que administra **registros**:
unidades de información compuestas por metadatos descriptivos, archivos digitales y
un identificador persistente. Los registros se crean como borradores, se completan
con metadatos normalizados, se les adjuntan archivos verificados por checksum y se
publican para consulta. Una vez publicados, pueden agruparse en comunidades, citarse,
versionarse y retirarse con una página de lápida cuando corresponde.

La plataforma base aporta el modelo de datos, los flujos de depósito y publicación,
la búsqueda, la administración, la API y el protocolo OAI-PMH. El proyecto HGI aporta
la identidad institucional, la configuración de acceso cerrado, la experiencia de
usuario en español, el panel de administración enriquecido, la automatización de
despliegue y el paquete de cumplimiento normativo.

## 2.2 Capacidades principales

| Capacidad | Descripción | Evidencia |
|---|---|---|
| Depósito guiado | Formulario por pasos con validación de metadatos obligatorios y opcionales | RF-01, P-03 |
| Gestión de archivos | Carga, checksum MD5, transferencia por partes, confirmación y descarga | RF-02, P-04 a P-06, P-10 |
| Publicación | Cambio de estado con identificador persistente y registro OAI | RF-03, P-07, P-09 |
| Búsqueda y facetas | Índice OpenSearch con consultas por texto, filtros y ordenamientos | RF-04, P-08 |
| Versionado | Nueva versión de un registro publicado conservando el historial | RF-06 |
| Comunidades | Agrupación curada de registros por unidad, proyecto o línea de investigación | RF-07 |
| Cuentas y sesiones | Autenticación local, sesiones firmadas y perfiles de usuario | RF-08, P-02 |
| Administración | Panel con usuarios, comunidades, páginas, banners, dominios, vocabularios, moderación y trabajos | RF-09, RF-10, P-15 |
| Estadísticas | Registro de vistas y descargas para métricas de uso | RF-11 |
| Interoperabilidad | API REST JSON y OAI-PMH | RF-12, RF-13 |
| Ciclo de vida | Borrado de borradores y retiro de registros con lápida | RF-14, P-13, P-14 |
| Acceso abierto | Consulta y descarga pública de registros publicados | RF-05, P-10 |

## 2.3 Mapa funcional

| Dominio | Módulos | Usuarios principales |
|---|---|---|
| **Descubrimiento** | Portada, búsqueda, facetas, ficha de registro, comunidades | Público general, estudiantes, investigadores |
| **Depósito** | Borradores, metadatos, archivos, publicación, versiones | Docentes, investigadores, tesistas |
| **Acceso** | Login institucional, sesiones, perfiles | Todos los usuarios registrados |
| **Administración** | Panel, usuarios, roles, comunidades, páginas, banners, dominios, vocabularios, moderación, trabajos | Administradores de la Unidad TIC |
| **Interoperabilidad** | API REST, OAI-PMH | Sistemas externos, cosechadores |
| **Operación** | Contenedores, respaldos, registros, índices, colas | Administradores de servidores |

## 2.4 Flujo general de uso

El recorrido típico de un depósito se desarrolla en siete pasos:

1. El usuario ingresa con su cuenta institucional; las cuentas las crea la
   administración (el registro público está deshabilitado).
2. Crea un borrador y completa los metadatos obligatorios: título, tipo de recurso,
   al menos un creador y fecha de publicación.
3. Añade metadatos opcionales: descripción, editor, derechos, idiomas, temas, fechas,
   tamaño y formato.
4. Carga los archivos; el sistema calcula y verifica el checksum MD5.
5. Revisa el borrador y publica. El sistema asigna el identificador persistente y
   expone el registro en la búsqueda y en OAI-PMH.
6. El registro puede agruparse en una comunidad, citarse y descargarse.
7. Si se requiere una corrección sustantiva, se crea una nueva versión; si debe
   retirarse, se conserva una lápida con la trazabilidad del retiro.

```
Usuario → [Portada / Búsqueda] → [Ficha de registro] → Descarga
                     │
                     └→ [Mi panel] → [Nuevo depósito] → Borrador → Archivos
                                                          → Publicar → PID + OAI
                                                          → Nueva versión
                                                          → Retirar (lápida)
```

## 2.5 Roles y permisos

| Rol | Alcance | Permisos principales |
|---|---|---|
| **Visitante** | Público | Consultar registros publicados, buscar, descargar archivos abiertos, cosechar OAI-PMH |
| **Usuario registrado** | Comunidad institucional | Depositar borradores, gestionar sus registros, solicitar acceso a comunidades |
| **Administrador de comunidad** | Comunidad asignada | Gestionar miembros, revisar solicitudes y curar registros de la comunidad |
| **Administrador** (`admin`) | Global | Superusuario; acceso total a la plataforma y a la administración |
| **Administración** (`administration`) | Global | Acceso al panel de administración y a la gestión de usuarios |
| **Moderación** (`administration-moderation`) | Global | Revisión y moderación de contenidos |

Los roles se implementan con el sistema de control de acceso de Invenio y se asignan
mediante la CLI (`invenio roles add`) o el panel de administración. El principio
aplicado es el de **mínimo privilegio**: las capacidades administrativas no se
conceden por defecto y las escrituras anónimas se rechazan.

## 2.6 Identidad institucional y experiencia de usuario

La identidad visual se apoya en la paleta institucional del MITIC y en la marca del
Ministerio de Salud Pública y Bienestar Social. El rojo `#ea2428` se usa como color
de acción y el rojo profundo `#8c1618` como color de marca y de superficies
principales; ambos se complementan con neutros cálidos y tipografías sans serif.

| Token | Valor | Uso |
|---|---|---|
| `--u-brand` | `#ea2428` | Botones primarios, enlaces y acentos |
| `--u-brand-600` | `#c81c21` | Estados hover y énfasis |
| `--u-brand-700` | `#8c1618` | Cabecera, footer y superficies de marca |
| `--u-brand-soft` | `#fdecec` | Fondos suaves y tarjetas |
| `--u-navy` | `#2a1518` | Barra de administración y contraste |
| `--u-ink` | `#221518` | Títulos |
| `--u-text` | `#3c3234` | Texto corrido |
| `--u-muted` | `#6f6163` | Texto secundario |
| `--u-bg` | `#fdf7f7` | Fondo general |
| `--u-line` | `#eee2e3` | Bordes y separadores |

La portada presenta un *hero* con la fotografía aérea del Hospital General de Itapúa,
un buscador central, accesos directos a la exploración, las comunidades y el depósito,
y una tarjeta institucional con los atributos del repositorio. El diseño es
responsive: en pantallas pequeñas la navegación se simplifica, la marca permanece
visible y se evita el desplazamiento horizontal.

<<FIG:../static/images/hgi-hospital-2.jpg|Figura 1. Hospital General de Itapúa, sede institucional del repositorio.|15.5>>

La imagen institucional se completa con el logotipo del MSPBS en la cabecera y en la
pantalla de acceso, el favicon institucional y un pie de página con la denominación
del repositorio y los enlaces de interés.

## 2.7 Estados y ciclo de vida del registro

| Estado | Visible | Editable | Descripción |
|---|---|---|---|
| Borrador | Solo el propietario y administradores | Sí | Registro en construcción; no aparece en búsquedas públicas. |
| Publicado | Público según acceso | Limitado | Registro con PID y registro OAI; aparece en búsqueda y ficha. |
| Nueva versión | Según acceso | Sí (nueva versión) | Versión derivada de un registro publicado, con historial. |
| Retirado | Lápida pública | No | Registro retirado; se conserva la lápida y la trazabilidad. |
| Eliminado | No | No | Borrador eliminado; no deja lápida. |

El retiro de un registro publicado no borra físicamente la información: genera una
lápida (tombstone) que informa el estado y preserva el identificador persistente, en
línea con las buenas prácticas de preservación digital.
"""

PART2 = r"""
# 3. Descripción funcional por módulo

## 3.1 Portada institucional y navegación

La portada es el punto de entrada del repositorio y concentra la propuesta de valor
institucional. Presenta la marca, el buscador global, los accesos a «Explorar todo»,
«Comunidades» y «Depositar un trabajo», y una tarjeta con los atributos del servicio:
acceso abierto, identificadores persistentes y preservación digital.

<<FIG:assets/documentacion/portada.png|Figura 2. Portada institucional del Repositorio HGI con la fotografía del Hospital General de Itapúa.|16.0>>

La cabecera mantiene la marca y la navegación principal. Se eliminó la barra superior
institucional que duplicaba información y se ajustó el comportamiento responsive para
que la marca permanezca visible y la navegación se resuelva con iconos en dispositivos
móviles, sin desbordamiento horizontal.

## 3.2 Cuentas, autenticación y perfiles

El acceso es **institucional y cerrado**: no existe registro público de cuentas
(`SECURITY_REGISTERABLE = False`). La administración crea las cuentas y comunica las
credenciales por los canales internos. La pantalla de acceso se presenta como una
tarjeta de dos paneles: identidad institucional a la izquierda y formulario a la
derecha.

<<FIG:assets/documentacion/acceso.png|Figura 3. Pantalla de acceso institucional del Repositorio HGI.|15.5>>

Características del módulo:

- Autenticación por correo electrónico y contraseña mediante Flask-Security.
- Contraseñas almacenadas con función de hash y sal; nunca en texto plano.
- Sesiones firmadas, con cookie `Secure`, `HttpOnly` y `SameSite=Lax`.
- Perfiles de usuario en modo lectura (`USERPROFILES_READ_ONLY = True`) para evitar
  campos libres no controlados.
- Recuperación de contraseña sujeta a la configuración de correo institucional.
- Compatibilidad con OIDC si en el futuro se integra un proveedor de identidad.

## 3.3 Depósito y gestión de registros

El módulo de depósito implementa el flujo de creación y edición de registros. El
formulario se organiza en secciones y aplica validaciones de esquema antes de permitir
la publicación.

**Metadatos obligatorios:** título (mínimo tres caracteres), tipo de recurso, al menos
un creador y fecha de publicación. **Metadatos opcionales:** descripción, editor,
derechos o licencia, idiomas, temas, fechas adicionales, tamaño y formato, entre otros
campos configurables.

| Función | Comportamiento | Requerimiento |
|---|---|---|
| Crear borrador | Genera un registro editable con estado `draft` | RF-01 |
| Editar metadatos | Formulario con validación por esquema y vocabularios | RF-01 |
| Guardar y reanudar | El borrador persiste y puede retomarse | RF-01 |
| Eliminar borrador | Borrado lógico/físico del borrador sin lápida | RF-14 |
| Publicar | Valida, asigna PID y hace visible el registro | RF-03 |
| Crear versión | Deriva una nueva versión de un registro publicado | RF-06 |

El sistema admite registros solo de metadatos y registros con archivos, según la
configuración (`RDM_ALLOW_METADATA_ONLY_RECORDS`). Los registros restringidos están
deshabilitados en la configuración actual (`RDM_ALLOW_RESTRICTED_RECORDS = False`),
lo que simplifica el modelo de acceso y evita exponer archivos con permisos
inconsistentes.

## 3.4 Gestión de archivos y preservación

El módulo de archivos implementa un protocolo de carga en tres fases para garantizar
integridad y reanudación:

1. **Inicialización.** El cliente declara el nombre y el checksum MD5 del archivo.
2. **Transferencia.** El contenido se envía por partes o en una sola operación.
3. **Confirmación.** El servidor verifica el checksum y marca el archivo como
   completado (`status = completed`).

Los archivos se almacenan en la ubicación por defecto
`file:///opt/invenio/var/instance/data`, montada sobre el volumen `instance-data`.
Si se configura un backend compatible con S3, la ubicación por defecto se crea como
`s3://<bucket>` y los archivos se almacenan en el servicio externo. Los límites de
tamaño y la cuota son configurables por la Unidad TIC.

| Aspecto | Implementación |
|---|---|
| Integridad | Checksum MD5 declarado y verificado en la confirmación |
| Persistencia | Volumen Docker `instance-data` o bucket S3 |
| Descarga | Endpoint autenticado o público según el registro y el archivo |
| Reanudación | Protocolo por partes del API de archivos |
| Preservación | Copias de respaldo del volumen y verificación periódica |
| Cuota | Límites configurables por archivo y por usuario |

## 3.5 Publicación, identificadores persistentes y versionado

Al publicar, el sistema valida el registro, genera el identificador persistente
interno (`recid`), lo registra en el almacén de PIDs y lo expone en OAI-PMH. La ficha
pública presenta metadatos, archivos, licencia, citación y acciones disponibles.

| Elemento | Descripción |
|---|---|
| **PID interno** | Identificador `recid` administrado por Invenio; URL estable `/records/<id>` |
| **DOI** | Opcional; requiere configuración de DataCite (`DATACITE_ENABLED`) |
| **OAI-PMH** | Registro cosechable en `/oai2d` con prefijo configurable |
| **Versionado** | Nueva versión con historial; la versión anterior queda accesible |
| **Citación** | Estilos APA y otros configurables; exportación de metadatos |
| **Lápida** | Página de retiro que conserva el identificador y el motivo |

El versionado permite corregir o ampliar un registro publicado sin perder la
trazabilidad científica. Cada versión conserva su propio conjunto de archivos y
metadatos, y el registro padre mantiene la relación entre versiones.

## 3.6 Búsqueda, recuperación y facetas

La búsqueda se apoya en OpenSearch y ofrece:

- Consulta por texto libre sobre título, descripción, creadores y temas.
- Filtros por tipo de recurso, fecha, creador, idioma, licencia y comunidad.
- Ordenamiento por relevancia, fecha de publicación y fecha de actualización.
- Paginación y exportación de resultados.
- Búsqueda dentro de comunidades y de borradores (según permisos).

El índice se reconstruye con `invenio rdm rebuild-all-indices` y se mantiene
actualizado por el worker mediante tareas asíncronas. La disponibilidad del índice es
un requisito operativo: si OpenSearch no responde, la búsqueda falla aunque la base de
datos permanezca íntegra.

## 3.7 Acceso, consulta y descarga

Los registros publicados son accesibles desde la portada, la búsqueda y la ficha. La
ficha muestra los metadatos, los archivos, la licencia, la citación sugerida y los
enlaces persistentes. La descarga de archivos abiertos no requiere sesión; los
archivos restringidos, si se habilitaran en el futuro, exigirían autorización.

El sistema registra eventos de vista y descarga, que alimentan las estadísticas de uso
y permiten reportar el impacto del repositorio.

## 3.8 Comunidades

Las comunidades agrupan registros por unidad académica, proyecto o línea de
investigación. Cada comunidad tiene una página pública, miembros, roles internos y un
flujo de solicitud de inclusión. La administración global puede crear, editar y
despublicar comunidades, y la moderación revisa los contenidos cuando corresponde.

| Función | Descripción |
|---|---|
| Crear comunidad | Alta con nombre, identificador, descripción y política de acceso |
| Gestionar miembros | Invitación, aceptación, roles y bajas |
| Solicitudes | Flujo de solicitud y aprobación de ingreso |
| Curaduría | Revisión de registros y metadatos de la comunidad |
| Página pública | Presentación, buscador interno y listado de registros |

## 3.9 Panel de administración

El panel de administración concentra las tareas de gobierno del repositorio. Se
accede con los roles `admin` o `administration` y se organiza en tres áreas: gestión
del sitio, moderación y registros, y sistema.

| Área | Funciones |
|---|---|
| **Panel** | Vista general del estado del repositorio |
| **Comunidades** | Alta, edición, miembros y publicación |
| **Dominios** | Dominios institucionales y verificación |
| **Banners** | Mensajes y avisos en la interfaz |
| **Páginas** | Páginas estáticas de contenido institucional |
| **OAI-PMH** | Configuración y estado del proveedor de datos |
| **Vocabularios** | Tipos de recursos, licencias, idiomas y otros vocabularios |
| **Moderación** | Revisión de registros y comunidades |
| **Borradores y registros** | Supervisión y gestión de contenidos |
| **Usuarios** | Altas, estados, roles y actividad |
| **Trabajos (jobs)** | Estado de las tareas asíncronas |
| **Sistema** | Configuración y utilidades de mantenimiento |

### 3.9.1 Gestión de usuarios enriquecida

El proyecto HGI amplió la pantalla estándar de usuarios con un panel de indicadores y
actividad, manteniendo la tabla React original para no perder búsqueda, filtros ni
acciones. El enriquecimiento se calcula en el servidor mediante un *context
processor* y se cachea durante 60 segundos para no penalizar cada carga.

<<FIG:assets/documentacion/admin-usuarios.png|Figura 4. Panel de gestión de usuarios con indicadores, colaboradores destacados y actividad reciente.|16.0>>

| Componente | Contenido |
|---|---|
| Indicadores | Usuarios registrados, cuentas activas, administradores y depósitos publicados |
| Colaboradores destacados | Usuarios con mayor número de depósitos publicados |
| Actividad reciente | Últimos accesos y altas de cuentas |
| Tabla de usuarios | Búsqueda, filtros por estado, ordenamiento y acciones originales |

La implementación vive en `docker/live/unae_admin/insights.py` (cálculo y caché) y
`docker/live/unae_admin/views.py` (context processor restringido a
`/administration/users`); la plantilla es
`templates/semantic-ui/invenio_app_rdm/administration/users_search.html`.

## 3.10 Estadísticas y analítica de uso

El repositorio registra vistas y descargas por registro y por comunidad. Los datos se
almacenan en los índices de eventos y se consultan desde el panel y desde la API de
estadísticas. La información permite reportar impacto, identificar contenidos más
consultados y sustentar memorias institucionales.

| Métrica | Fuente | Uso |
|---|---|---|
| Vistas de registro | Eventos de uso | Impacto y demanda |
| Descargas | Eventos de archivo | Uso real de los contenidos |
| Depósitos por usuario | Metadatos de registros | Reconocimiento y seguimiento |
| Accesos | Registro de sesiones | Actividad y seguridad |

## 3.11 Interoperabilidad: API REST y OAI-PMH

La plataforma expone dos interfaces principales:

- **API REST JSON** (`/api/records`, `/api/communities`, vocabularios, `/api/users`),
  con autenticación por token para operaciones protegidas. Permite crear, consultar,
  actualizar y eliminar recursos según permisos.
- **OAI-PMH** (`/oai2d`), para la cosecha de metadatos por parte de agregadores y
  portales científicos. El prefijo de identificador es configurable
  (`OAISERVER_ID_PREFIX = "invenio-rdm"`).

Estas interfaces constituyen el mecanismo previsto para futuras integraciones. Si la
institución intercambiara datos personales con otros organismos, la integración deberá
realizarse exclusivamente a través del SII, conforme al Decreto N.º 8709/2018 y a la
Resolución MITIC N.º 212/2020.

## 3.12 Personalizaciones del proyecto HGI

| Elemento | Archivo principal | Descripción |
|---|---|---|
| Nombre y subtítulo institucional | `compose.yml`, `invenio.cfg`, `.env.prod` | «Repositorio HGI» y subtítulo de ciencia abierta |
| Paleta y sistema de diseño | `static/images/unae-theme.css` | Rojo institucional, componentes, admin y responsive |
| Cabecera y *hero* | `templates/.../header_frontpage.html` | Portada con fotografía del hospital y tarjeta institucional |
| Eliminación de topbar | `templates/.../header.html` | Se retiró la barra superior duplicada |
| Pie de página | `templates/.../site_footer.html` | Identidad, enlaces y créditos |
| Acceso institucional | `templates/.../invenio_accounts/login_user.html` | Tarjeta de dos paneles con marca MSPBS |
| Panel de usuarios | `templates/.../administration/users_search.html` + `docker/live/unae_admin/` | Indicadores y actividad sobre la tabla original |
| Idioma | `invenio.cfg` | `BABEL_DEFAULT_LOCALE = "es"`; español como idioma por defecto |
| Registro cerrado | `invenio.cfg`, `.env.prod` | `SECURITY_REGISTERABLE = False` |
| Perfiles de solo lectura | `invenio.cfg` | `USERPROFILES_READ_ONLY = True` |
| Correo sin DNS | `invenio.cfg` | Validador sin verificación de entregabilidad para redes internas |
| Despliegue automatizado | `setup.sh` | Instalación local y producción idempotente |
| Inicialización | `entrypoint.py`, `entrypoint.sh` | Base de datos, roles, archivos, índices y colas |
| Recursos visuales | `static/images/` | Logo MSPBS, favicon y fotografías institucionales |

### 3.12.1 Detalle del tema visual

La hoja de estilos `unae-theme.css` se carga después de los estilos base de Invenio y
sobrescribe las variables de Semantic UI y de Invenio Theme. El resultado es un
sistema coherente en portada, búsqueda, fichas, formularios, panel de administración,
pantalla de acceso y pie de página.

| Zona | Tratamiento |
|---|---|
| Cabecera | Fondo blanco, marca a la izquierda y acciones a la derecha |
| *Hero* | Degradado rojo profundo con retícula sutil y fotografía institucional |
| Botones | Rojo `#ea2428`; hover `#c81c21`; texto blanco |
| Tarjetas | Bordes suaves, sombra discreta y radios de 12–18 px |
| Formularios | Campos amplios, foco rojo y mensajes de error legibles |
| Tablas | Cabecera tenue, filas alternadas y desplazamiento horizontal contenido |
| Admin | Barra superior marrón `#2a1518`, panel claro y tarjetas de indicadores |
| Acceso | Tarjeta partida con panel de marca y formulario limpio |
| Pie | Fondo oscuro, columnas de enlaces y créditos institucionales |
| Móvil | Navegación compacta, marca visible y ausencia de scroll horizontal |

Los cambios de plantilla o de CSS se aplican reiniciando el contenedor web; los
cambios de variables de entorno requieren recrear los contenedores para que el nuevo
valor sea leído por la aplicación.

## 3.13 Ciclo de vida y eliminación

El sistema distingue entre eliminar un borrador y retirar un registro publicado.
Eliminar un borrador lo quita del sistema sin dejar rastro público. Retirar un
registro publicado conserva la lápida, el identificador y la trazabilidad, y responde
`410 Gone` a las consultas posteriores. Esta distinción es esencial para la
integridad de las citas y para la preservación a largo plazo.
"""

PART3 = r"""
# 4. Arquitectura y tecnología

## 4.1 Principios y estilo arquitectónico

La solución adopta una **arquitectura cliente/servidor web multicapa**, desplegada en
contenedores, con una aplicación monolítica modular (Invenio/Flask) apoyada en
servicios de datos dedicados. Los principios rectores son:

- **Reproducibilidad:** toda la infraestructura se declara como código
  (`compose.yml`, `compose.prod.yml`, `Dockerfile`, variables de entorno).
- **Separación de responsabilidades:** proxy, aplicación, worker, base de datos,
  búsqueda y caché son servicios independientes con ciclos de vida propios.
- **Mínima exposición:** solo el proxy publica puertos al host; los servicios de datos
  permanecen en la red interna de Docker.
- **Persistencia explícita:** los datos y archivos viven en volúmenes nombrados.
- **Actualización sin reconstrucción:** plantillas, configuración y extensión propia se
  montan como volúmenes de solo lectura para agilizar los cambios.
- **Estándares abiertos:** HTTP/HTTPS, JSON, OAI-PMH, Dublin Core, DataCite y SQL.

## 4.2 Arquitectura de despliegue

```
        Navegador (HTTPS 443)
                 │
        ┌────────▼────────┐
        │  Caddy 2.10     │  proxy inverso + TLS
        └────────┬────────┘
                 │ HTTP 5000 (red interna)
        ┌────────▼────────┐        ┌──────────────────┐
        │ Gunicorn / web  │───────▶│ PostgreSQL 17.4  │
        │ Invenio 13.0.8  │        └──────────────────┘
        └───┬────────┬────┘        ┌──────────────────┐
            │        └────────────▶│ OpenSearch 2.18  │
            │                      └──────────────────┘
            │                      ┌──────────────────┐
            ├─────────────────────▶│ Valkey 7.2.5     │
            │                      └──────────────────┘
            │                      ┌──────────────────┐
            └─────────────────────▶│ instance-data    │
                                   └──────────────────┘

        ┌──────────────────┐
        │ Celery worker    │  indexación, estadísticas, limpieza
        └──────────────────┘
```

En producción, Apache sustituye a Caddy como terminador TLS y proxy frontal, y la
aplicación se publica únicamente en `127.0.0.1:5000`. En desarrollo, Caddy publica
80/443 y emite un certificado autofirmado para `localhost`.

## 4.3 Componentes y contenedores

| Servicio | Imagen | Función | Exposición |
|---|---|---|---|
| `proxy` | `caddy:2.10` | Proxy inverso, TLS y enrutamiento | 80/443 (solo desarrollo) |
| `web` | `ghcr.io/front-matter/invenio-rdm-starter:latest` | Aplicación web y API (Gunicorn) | Interna 5000; en producción `127.0.0.1:5000` |
| `worker` | misma imagen | Tareas Celery (indexación, estadísticas, limpieza) | Sin puertos |
| `db` | `postgres:17.4-bookworm` | Base de datos transaccional | Sin puertos |
| `search` | `opensearchproject/opensearch:2.18.0` | Índices de búsqueda y eventos | Sin puertos |
| `cache` | `valkey/valkey:7.2.5-bookworm` | Caché, sesiones y cola de Celery | Sin puertos |

**Volúmenes persistentes:** `db-data` (PostgreSQL), `search-data` (OpenSearch),
`caddy-data` y `caddy-config` (certificados y configuración de Caddy), e
`instance-data` (archivos depositados). Los volúmenes sobreviven a la recreación de
contenedores, pero no a `docker compose down -v`, que debe evitarse en producción.

## 4.4 Stack tecnológico y licencias

| Capa | Tecnología | Versión | Licencia |
|---|---|---|---|
| Plataforma | InvenioRDM / invenio-app-rdm | 13.0.8 | MIT |
| Plantilla de despliegue | InvenioRDM Starter | 14.0.0 | MIT |
| Lenguaje backend | Python | 3.13 | PSF |
| Framework web | Flask / Flask-Security | Según Invenio 13 | BSD |
| Servidor WSGI | Gunicorn | 23 | MIT |
| Tareas asíncronas | Celery | Según Invenio 13 | BSD |
| Base de datos | PostgreSQL | 17.4 | PostgreSQL License |
| Búsqueda | OpenSearch | 2.18.0 | Apache-2.0 |
| Caché / cola | Valkey | 7.2.5 | BSD-3 |
| Proxy (desarrollo) | Caddy | 2.10 | Apache-2.0 |
| Proxy (producción) | Apache HTTP Server | Según servidor | Apache-2.0 |
| Frontend | JavaScript, LESS/CSS, HTML/Jinja2 | — | PSF / MIT |
| Contenedores | Docker Engine + Compose | 29.x / v2 | Apache-2.0 |
| Control de versiones | Git | — | GPL-2.0 |

No existen componentes licenciados de pago. Las dependencias de Python y del frontend
están fijadas en `uv.lock` y `pnpm-lock.yaml`, respectivamente, para garantizar
reproducibilidad.

## 4.5 Modelo de datos y almacenamiento

| Entidad / tabla | Contenido | Persistencia |
|---|---|---|
| `accounts_user` | Cuentas, correo, hash de contraseña, estado y roles | PostgreSQL |
| `rdm_records_metadata` | Metadatos de registros publicados (JSON) | PostgreSQL |
| `rdm_drafts_metadata` | Metadatos de borradores | PostgreSQL |
| `pidstore_pid` | Identificadores persistentes (`recid`, OAI) | PostgreSQL |
| `files_*` | Objetos de archivo, versiones y checksums | PostgreSQL + almacenamiento |
| Comunidades | Comunidades, miembros y roles | PostgreSQL |
| `oaiserver_*` | Registros y conjuntos OAI-PMH | PostgreSQL |
| `jobs_*` | Trabajos asíncronos y su estado | PostgreSQL |
| Índices | Documentos de búsqueda, eventos y estadísticas | OpenSearch |
| Caché / sesiones / cola | Claves temporales y mensajes | Valkey |

Los metadatos se almacenan como documentos JSON validados por esquemas, lo que
permite evolucionar el modelo sin migraciones destructivas. Las relaciones críticas
(propietario, comunidad, PID, versión) se mantienen en tablas relacionales.

## 4.6 Estructura del repositorio

```
Invennio/
├── compose.yml                 # stack de desarrollo
├── compose.prod.yml            # override de producción (sin Caddy)
├── Caddyfile                   # proxy TLS local
├── Dockerfile                  # imagen de la aplicación
├── entrypoint.py / .sh         # inicialización de Invenio
├── setup.sh                    # instalación automatizada local/prod
├── invenio.cfg                 # configuración de la instancia
├── .env.example                # variables de desarrollo
├── .env.prod.example           # variables de producción
├── apache/                     # configuraciones de Apache
├── docker/live/                # extensión viva (unae_admin)
├── static/images/              # tema, logos y fotografías
├── templates/semantic-ui/      # plantillas sobrescritas
├── docs/                       # documentación y matrices MITIC
└── assets/                     # recursos de compilación del frontend
```

La extensión `docker/live` se monta en `/opt/unae_live` y se registra en el entorno
virtual mediante `docker/live.pth`, de modo que el código propio se carga sin
reconstruir la imagen. Esta decisión acelera la iteración, pero exige mantener la
compatibilidad con la versión de Invenio fijada en la imagen.

## 4.7 Configuración de la aplicación

| Variable | Valor actual / predeterminado | Función |
|---|---|---|
| `INVENIO_SITE_UI_URL` | `https://localhost` / `https://lasi.soteweb.com` | URL pública de la interfaz |
| `INVENIO_SITE_API_URL` | `<UI>/api` | URL pública de la API |
| `INVENIO_TRUSTED_HOSTS` | Lista de hosts permitidos | Protección contra *host header injection* |
| `INVENIO_SECRET_KEY` | Secreto por entorno | Firma de sesiones y tokens |
| `INVENIO_SECURITY_PASSWORD_SALT` | Sal por entorno | Hash de contraseñas |
| `POSTGRES_*` | Host, base, usuario y clave | Conexión a PostgreSQL |
| `INVENIO_S3_*` | Opcional | Almacenamiento compatible con S3 |
| `INVENIO_MAIL_*` | Opcional | Correo saliente |
| `INVENIO_ACCOUNTS_LOCAL_LOGIN_ENABLED` | `True` en desarrollo | Habilita el acceso local |
| `INVENIO_SECURITY_REGISTERABLE` | `False` | Cierra el registro público |
| `OPENSEARCH_JAVA_OPTS` | `-Xms1g -Xmx1g` en producción | Memoria del motor de búsqueda |

Las variables se declaran en `.env` (desarrollo) y `.env.prod` (producción). Los
secretos nunca se incluyen en el código; `.env` está excluido del control de versiones.

## 4.8 Sistema de diseño y tema

El tema se implementa en una única hoja `static/images/unae-theme.css` cargada por las
plantillas `page.html` y `page_cover.html` con un parámetro de versión
(`?v=20261026-11`) para invalidar la caché del navegador. La hoja define tokens,
componentes y reglas responsive.

| Grupo | Elementos |
|---|---|
| Tokens | Colores de marca, neutros, tipografías, radios y sombras |
| Layout | Contenedores, rejillas, cabecera, *hero*, secciones y pie |
| Componentes | Botones, tarjetas, formularios, mensajes, tablas y paginación |
| Vistas | Portada, búsqueda, ficha, depósito, acceso, admin y error |
| Responsive | Puntos de corte para tablet y móvil; navegación compacta |
| Accesibilidad | Contraste, foco visible, etiquetas y textos alternativos |

Los cambios de estilo se validaron visualmente en escritorio y móvil, y se corrigieron
los desbordamientos horizontales detectados en la tabla de usuarios y en la navegación
del panel administrativo.

# 5. Seguridad y control de acceso

## 5.1 Modelo de seguridad

La seguridad se aborda en capas: red, transporte, aplicación, datos y operación. El
modelo asume que el sistema es accesible desde Internet en producción y aplica
controles proporcionales al riesgo de un repositorio de información pública con
cuentas institucionales.

| Capa | Control principal |
|---|---|
| Red | Solo 80/443 expuestos; servicios de datos sin puertos publicados |
| Transporte | TLS obligatorio; HSTS; redirección de HTTP a HTTPS |
| Aplicación | CSRF, validación de esquemas, RBAC, sesiones firmadas |
| Datos | Hash de contraseñas, mínimo privilegio, respaldos cifrados |
| Operación | Registros, monitoreo, actualizaciones y gestión de secretos |

## 5.2 Controles implementados

| Criterio | Control | Verificación |
|---|---|---|
| Transporte cifrado | TLS en Caddy (desarrollo) o Apache (producción); único punto expuesto | Acceso exclusivo por HTTPS; puertos internos cerrados |
| Autenticación | Correo y contraseña con Flask-Security; hash y sal | P-02 |
| Autorización | Roles `admin`, `administration`, `administration-moderation` | P-11, P-15 |
| CSRF | Token por sesión y verificación de `Referer`/`Origin` | P-12 |
| Validación de entradas | Esquemas Marshmallow estrictos; descarte de campos desconocidos | Pruebas de API |
| Mínimo privilegio | Proceso `invenio` (uid 1654); datos con dueño correcto | Verificación de permisos |
| Gestión de secretos | Variables de entorno; secretos únicos por entorno | Revisión de configuración |
| Registro y monitoreo | Access logs, logs de aplicación y worker, job logs y eventos | P-16 |
| Integridad de archivos | Checksum MD5 verificado | P-04, P-06 |
| Respaldos | Volúmenes persistentes y procedimiento documentado | Anexo D |
| Actualizaciones | Imágenes versionadas y dependencias fijadas | `uv.lock`, `pnpm-lock.yaml` |
| Correo seguro | TLS y autenticación con el servidor SMTP institucional | Configuración `.env.prod` |
| Protección de cabeceras | CSP, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy` | Respuestas HTTP |

## 5.3 Identidades, sesiones y contraseñas

- Las cuentas se crean exclusivamente desde la administración; el registro público
  está deshabilitado.
- Las contraseñas se almacenan con hash y sal; la sal (`PASSWORD_SALT`) es un secreto
  crítico: cambiarla invalida los hashes existentes y obliga a restablecer las
  contraseñas.
- Las sesiones se almacenan en Valkey y se transportan en cookies firmadas con
  `Secure`, `HttpOnly` y `SameSite=Lax`.
- Los perfiles son de solo lectura para evitar que los usuarios modifiquen campos no
  validados.
- La recuperación de contraseña depende del correo institucional; en entornos sin
  correo se realiza por la administración.

## 5.4 Gestión de secretos

| Secreto | Dónde se define | Recomendación |
|---|---|---|
| `INVENIO_SECRET_KEY` | `.env` / `.env.prod` | Cadena aleatoria de al menos 48 caracteres, única por entorno |
| `INVENIO_SECURITY_PASSWORD_SALT` | `.env` / `.env.prod` | Cadena aleatoria única; no rotar sin plan de reseteo |
| `POSTGRES_PASSWORD` | `.env` / `.env.prod` | Clave larga y única; no reutilizar |
| Credenciales SMTP | `.env` / `.env.prod` | Cuenta de servicio con permisos mínimos |
| Credenciales S3 | `.env` / `.env.prod` | Claves de acceso restringidas al bucket |

`setup.sh` genera secretos automáticamente cuando faltan. En producción se recomienda
generarlos manualmente, almacenarlos en un gestor de secretos y restringir los
permisos del archivo (`chmod 600`).

## 5.5 Registro, auditoría y monitoreo

El sistema produce tres flujos de registro: acceso HTTP (Gunicorn), aplicación y
worker (Celery). Los eventos de uso se indexan en OpenSearch y los trabajos se
consultan desde el panel de administración. Para auditoría se recomienda:

1. Centralizar los logs de los contenedores en un almacén externo.
2. Alertar sobre errores 5xx, fallos de autenticación repetidos y caídas de servicios.
3. Revisar semanalmente el estado de los índices y la capacidad de los volúmenes.
4. Conservar los registros de acceso según la política institucional.

## 5.6 Brechas operativas y plan de cierre

| Brecha | Riesgo | Acción | Responsable | Plazo |
|---|---|---|---|---|
| Credenciales por defecto en documentación | Acceso no autorizado | Rotar claves y no publicarlas en repositorios | Unidad TIC | 30/11/2026 |
| Secretos de ejemplo en `.env.prod` versionado | Compromiso de sesiones | Regenerar secretos y retirar del control de versiones | Unidad TIC | 30/11/2026 |
| Certificado TLS autofirmado en desarrollo | Advertencia del navegador | Importar la CA local o usar certificado confiable | Desarrollo | Continuo |
| Copias de seguridad no programadas | Pérdida de datos | Programar respaldos y probar restauración | Unidad TIC | 30/11/2026 |
| Firewall del host no documentado | Exposición de puertos | Aplicar política de solo 80/443 | Unidad TIC | 30/11/2026 |
| Falta de pruebas de carga | Degradación en picos | Ejecutar prueba con 20 usuarios concurrentes | Tester | Aceptación |

Estas brechas coinciden con los dos ítems en estado parcial de la matriz de
cumplimiento (repositorio MITIC y seguridad operativa) y con las tareas pendientes de
la fase de aceptación.
"""

PART4 = r"""
# 6. Instalación y despliegue

## 6.1 Requisitos previos

| Requisito | Mínimo | Recomendado |
|---|---|---|
| Sistema operativo | Linux con Docker Engine | Linux x86_64 actualizado |
| Docker Engine | 24 | 29.x |
| Docker Compose | v2 | v2.20 o superior |
| Memoria RAM | 8 GB | 16 GB (OpenSearch y PostgreSQL) |
| Disco | 40 GB | 100 GB SSD |
| CPU | 2 vCPU | 4 vCPU |
| Red | Acceso a Internet para la primera descarga de imágenes | Salida HTTPS y SMTP |
| Navegador | Navegador moderno | Chrome, Firefox o Edge actualizados |

No se requiere Python, Node ni Invenio CLI en el equipo anfitrión: la aplicación se
ejecuta dentro de los contenedores.

## 6.2 Obtención del código

```bash
git clone https://github.com/jesusbaez41-rgb/Invennio.git
cd Invennio
chmod +x setup.sh
```

El repositorio incluye los archivos de configuración de ejemplo. Los archivos `.env`
reales no se versionan; `setup.sh` los crea a partir de los ejemplos cuando faltan.

## 6.3 Instalación local automatizada

```bash
./setup.sh local
```

El script ejecuta, en orden:

1. Verifica Docker y Docker Compose.
2. Crea `.env` desde `.env.example` si no existe.
3. Genera secretos y valores por defecto faltantes (clave secreta, sal, correo y
   contraseña del administrador, URL local).
4. Fuerza el acceso local por contraseña en desarrollo.
5. Levanta los servicios y espera a PostgreSQL y a la aplicación.
6. Si la base está vacía, inicializa tablas, almacenamiento, roles, índices, campos
   personalizados y colas.
7. Crea el administrador y le asigna los roles `admin` y `administration`.
8. Verifica que el sitio responda `200` y muestra el estado de los contenedores.

Al finalizar, el sitio queda disponible en `https://localhost`. El certificado es
autofirmado; para evitar la advertencia del navegador se puede importar la CA local de
Caddy (`data/caddy/pki/authorities/local/root.crt`).

**Credenciales de desarrollo por defecto:**

| Campo | Valor |
|---|---|
| Correo | `admin@inveniosoftware.org` |
| Contraseña | `changeme` |

Estas credenciales son exclusivamente locales y deben rotarse en cualquier entorno
expuesto.

## 6.4 Despliegue en producción

El despliegue de producción utiliza el mismo stack, con el override
`compose.prod.yml`:

```bash
cp .env.prod.example .env.prod
# editar dominio, credenciales, secretos y correo
./setup.sh prod
```

El override de producción:

- Desactiva Caddy (`profiles: ["donotstart"]`) para no chocar con Apache.
- Publica la aplicación solo en `127.0.0.1:5000`.
- Activa `restart: unless-stopped` en los servicios.
- Permite ajustar la memoria de OpenSearch mediante `OPENSEARCH_JAVA_OPTS`.

Apache debe actuar como proxy inverso hacia `127.0.0.1:5000`. El repositorio incluye
dos configuraciones de referencia en `apache/`: una para el Apache del sistema y otra
para aaPanel. El proxy debe reenviar `Host`, `X-Forwarded-Proto` y
`X-Forwarded-For`, y mantener TLS en el frontal.

| Elemento | Valor de referencia |
|---|---|
| URL pública | `https://lasi.soteweb.com` |
| API | `https://lasi.soteweb.com/api` |
| Hosts permitidos | `lasi.soteweb.com`, `localhost`, `127.0.0.1` |
| Aplicación interna | `127.0.0.1:5000` |
| Puertos públicos | 80 y 443 (Apache) |

> **Nota.** El archivo `.env.prod.example` conserva la IP histórica
> `169.58.201.84:8478` como ejemplo. En la instalación real debe reemplazarse por el
> dominio o la IP definitivos y por un certificado TLS confiable.

## 6.5 Inicialización manual (referencia)

Si se despliega sin `setup.sh`, la primera puesta en marcha requiere:

```bash
docker compose exec web invenio db init create
docker compose exec web invenio files location create --default default \
  file:///opt/invenio/var/instance/data
docker compose exec web invenio roles create admin
docker compose exec web invenio access allow superuser-access role admin
docker compose exec web invenio roles create administration
docker compose exec web invenio access allow administration-access role administration
docker compose exec web invenio roles create administration-moderation
docker compose exec web invenio access allow administration-moderation role administration-moderation
docker compose exec web invenio index init
docker compose exec web invenio rdm-records custom-fields init
docker compose exec web invenio communities custom-fields init
docker compose exec web invenio rdm rebuild-all-indices
docker compose exec web invenio queues declare
docker compose exec web invenio users create admin@dominio --password 'ClaveSegura' --active --confirm
docker compose exec web invenio roles add admin@dominio admin
docker compose exec web invenio roles add admin@dominio administration
```

En producción, los comandos deben ejecutarse con el archivo de composición y el
entorno correspondientes:

```bash
docker compose -f compose.yml -f compose.prod.yml --env-file .env.prod exec web <comando>
```

## 6.6 Verificación y puesta en marcha

| Verificación | Comando / criterio | Resultado esperado |
|---|---|---|
| Contenedores activos | `docker compose ps` | Seis servicios `Up` (cinco en producción) |
| Base de datos | `pg_isready` o consulta de tablas | Conexión aceptada |
| Aplicación | `curl -k https://localhost/` | `200` |
| Login | `curl -k https://localhost/login/` | `200` con formulario |
| API | `curl -k https://localhost/api/records` | `200` con JSON |
| OAI-PMH | `curl -k https://localhost/oai2d?verb=Identify` | XML válido |
| Almacenamiento | `invenio files location list` | Ubicación por defecto activa |
| Índices | `invenio index list` | Índices creados |
| Administrador | Acceso al panel | `200` y rol correcto |
| Worker | `docker compose logs worker` | Sin errores recurrentes |

`./setup.sh verify` automatiza las comprobaciones principales y muestra el estado de
los contenedores.

## 6.7 Actualización de la aplicación

1. Respaldar la base de datos y el volumen de archivos.
2. Revisar las notas de la nueva versión y los cambios de esquema.
3. Actualizar el código (`git pull`) y, si corresponde, la imagen base.
4. Recrear los contenedores: `docker compose up -d --build`.
5. Ejecutar migraciones y reconstruir índices si la versión lo requiere.
6. Verificar el sitio y los flujos críticos.

Las plantillas y el CSS se actualizan sin reconstruir la imagen, reiniciando el
contenedor web. Los cambios de variables de entorno requieren recrear los contenedores
(`up -d`), porque `restart` no recarga el entorno.

## 6.8 Respaldo y restauración

**Respaldo de base de datos:**

```bash
docker compose exec -T db pg_dump -U postgres -d inveniordm -Fc > respaldo-$(date +%F).dump
```

**Respaldo de archivos:**

```bash
docker run --rm -v invennio_instance-data:/data -v "$PWD":/backup alpine \
  tar czf /backup/instance-data-$(date +%F).tar.gz -C /data .
```

**Restauración:**

```bash
cat respaldo-2026-10-27.dump | docker compose exec -T db pg_restore -U postgres -d inveniordm --clean
```

Se recomienda una copia diaria incremental, una copia semanal completa y una prueba
de restauración mensual en un entorno aislado. Los respaldos deben cifrarse y
almacenarse fuera del servidor de producción.

## 6.9 Operación diaria y comandos de referencia

| Tarea | Comando |
|---|---|
| Ver estado | `docker compose ps` |
| Ver logs web | `docker compose logs -f web` |
| Ver logs worker | `docker compose logs -f worker` |
| Reiniciar web | `docker compose restart web` |
| Recrear con nuevo entorno | `docker compose up -d web worker` |
| Reindexar | `docker compose exec web invenio rdm rebuild-all-indices` |
| Crear usuario | `docker compose exec web invenio users create <email> --password '<clave>' --active --confirm` |
| Asignar rol | `docker compose exec web invenio roles add <email> admin` |
| Listar ubicaciones | `docker compose exec web invenio files location list` |
| Estado de colas | `docker compose exec web invenio queues list` |
| Acceder a PostgreSQL | `docker compose exec db psql -U postgres -d inveniordm` |
| Acceder a OpenSearch | `curl http://localhost:9200` (desde el contenedor) |

## 6.10 Solución de problemas

| Síntoma | Causa probable | Solución |
|---|---|---|
| La web responde 500 tras recrear volúmenes | Dueño incorrecto del directorio de datos | `docker exec -u root <web> chown -R 1654:0 /opt/invenio/var/instance/data` |
| El login no aparece | `INVENIO_ACCOUNTS_LOCAL_LOGIN_ENABLED` desactivado | Activar en `.env` y recrear web y worker |
| Error de contraseña tras cambiar la sal | La sal invalida los hashes existentes | Restaurar la sal o restablecer contraseñas |
| Búsqueda vacía o desactualizada | Índices no creados o desincronizados | `invenio index init` y `rebuild-all-indices` |
| Error de conexión a la base | Contraseña o host incorrectos | Revisar `POSTGRES_*` y recrear los contenedores |
| Apache devuelve 502 | La app no escucha en 5000 o el proxy apunta mal | Verificar `docker compose ps` y la configuración de Apache |
| Redirección a HTTPS inesperada | `SITE_UI_URL` o proxy mal configurado | Ajustar URL y cabeceras `X-Forwarded-Proto` |
| La descarga falla | Ubicación de archivos no creada | `invenio files location create ...` |
| El worker no procesa tareas | Valkey caído o cola no declarada | Verificar `cache`, `invenio queues declare` |

# 7. Calidad, pruebas y evidencias

## 7.1 Estrategia de aseguramiento de calidad

La calidad se aborda con tres niveles: verificación estática (revisión de
configuración y código), pruebas funcionales sobre el sistema desplegado y pruebas
negativas de seguridad. Cada caso se vincula a un requerimiento y a una evidencia
observable, conforme al capítulo 2, sección 1, ítem 7 del estándar MITIC.

| Nivel | Actividad | Evidencia |
|---|---|---|
| Estático | Revisión de configuración, plantillas y scripts | `compose config`, `bash -n`, revisión manual |
| Funcional | Flujos de depósito, publicación, búsqueda y descarga | Matriz P-01 a P-18 |
| Negativo | Acceso sin sesión, CSRF, permisos | P-11, P-12 |
| Integridad | Checksums y consistencia de índices | P-04, P-06, P-17, P-18 |
| Operación | Tareas del worker y logs | P-16 |

## 7.2 Entornos y datos de prueba

Las pruebas se ejecutaron el 26/10/2026 (UTC) sobre el despliegue local real, a través
del proxy `https://localhost`, con el usuario administrador de prueba. Se utilizaron
registros y archivos de prueba creados y eliminados durante la sesión, verificando al
final que la base y los índices quedaran consistentes (0 registros, 0 borradores y 0
PID de prueba).

## 7.3 Resultados de la batería de pruebas

| Grupo | Casos | Resultado |
|---|---|---|
| Disponibilidad de rutas públicas | P-01 | 200/200/200 |
| Autenticación | P-02 | 302 y cookie de sesión |
| Depósito y metadatos | P-03 | 201; metadatos persistidos |
| Archivos | P-04 a P-06, P-10 | 201/200/200; checksum e integridad correctos |
| Publicación y ficha | P-07, P-09 | 202; ficha 200 |
| Búsqueda | P-08 | 1 resultado para la consulta de prueba |
| Seguridad negativa | P-11, P-12 | 403 y 400 respectivamente |
| Ciclo de vida | P-13, P-14 | 204; lápida y 410 |
| Administración | P-15 | 200 solo con rol autorizado |
| Worker y almacenamiento | P-16, P-17 | Tarea ejecutada; ubicación local activa |
| Consistencia final | P-18 | Conteos en cero y índices consistentes |

El detalle completo, con método, resultado y evidencia de cada caso, se reproduce en
la sección 8.6 (matriz de trazabilidad).

## 7.4 Criterios de aceptación

Se consideran criterios de aceptación de la versión:

1. Todos los requerimientos de prioridad alta cuentan con prueba ejecutada o
   verificación estructural documentada.
2. No existen defectos abiertos de severidad crítica o alta.
3. El sistema responde `200` en las rutas públicas y el login funciona.
4. El flujo de depósito, publicación, búsqueda y descarga se completa de extremo a
   extremo.
5. Los controles de seguridad negativos (sin sesión y sin CSRF) bloquean la escritura.
6. La documentación de instalación permite reproducir el entorno desde cero.
7. El paquete de cumplimiento MITIC está completo y con evidencias.

## 7.5 Deuda técnica y pruebas pendientes

| Tema | Estado | Acción prevista |
|---|---|---|
| Prueba de carga con 20 usuarios concurrentes | Pendiente | Ejecutar en la fase de aceptación y registrar latencias p95 |
| Versionado con flujo completo de UI | Pendiente | Caso funcional con dos versiones y verificación de historial |
| Comunidades con flujo completo de UI | Pendiente | Crear comunidad, invitar miembros y publicar registro |
| Manual de usuario con capturas por rol | En curso | Completar capturas y publicar en `/help` |
| Pruebas de accesibilidad | Recomendado | Auditoría WCAG 2.1 AA y corrección de hallazgos |
| Pruebas de restauración de respaldos | Recomendado | Simulacro mensual en entorno aislado |
"""

PART5 = r"""
# 8. Cumplimiento del Estándar de Software (MITIC)

## 8.1 Marco del estándar y modalidad adoptada

El **Estándar de Software — Desarrollo y adquisición** del MITIC (versión 1.0,
26-05-2020), elaborado en el marco de la Ley N.º 6207/2018 y el Decreto N.º 2274/2019,
establece los requisitos mínimos de documentación, calidad, seguridad, soporte y
garantía para el software del Estado paraguayo.

El proyecto se encuadra en el **Título II — Desarrollo de software de titularidad del
Estado**, submodalidad **Desarrollo de software con requerimientos definidos**. La
base tecnológica es software de código abierto de terceros y el trabajo propio
comprende instalación, configuración, personalización, integración, documentación y
pruebas.

El paquete de cumplimiento se organiza en seis artefactos:

| Documento | Contenido | Ítem del estándar |
|---|---|---|
| `00-matriz-cumplimiento.md` | Matriz de revisión de cumplimiento (37 ítems) | Verificación global |
| `01-matriz-requerimientos-funcionales.md` | RF-01 a RF-14 con criterios de calidad | Cap. 2, Sec. 1, §1; Anexo I |
| `02-matriz-requerimientos-no-funcionales.md` | RNF-01 a RNF-10 medibles | Cap. 2, Sec. 1, §2 |
| `03-matriz-trazabilidad-pruebas.md` | 18 casos de prueba con evidencias | Cap. 2, Sec. 1, §7 |
| `04-inventario-software.md` | Inventario del software y licencias | Cap. 1, §1 |
| `05-especificacion-tecnica.md` | Especificación técnica completa (EC-1 a EC-25) | Cap. 2, Sec. 1 |

A continuación se reproducen íntegramente las matrices y la especificación, con su
numeración y redacción originales, para preservar la trazabilidad con las evidencias
del repositorio.

## 8.2 Método de evaluación y evidencia

Cada ítem del estándar se evaluó con uno de tres estados: **Cumplido** (implementado y
verificado con evidencia), **Parcial** (avance real con tarea abierta) y **No aplica**
(excluido con justificación). Las evidencias se codificaron como `EC-##` (secciones de
la especificación), `M1`–`M3` (matrices), `INV` (inventario) y `REPO/…` (archivos del
repositorio).

La evaluación no se limita a declarar cumplimiento: cada afirmación se contrastó con
el sistema desplegado, con la configuración versionada o con una prueba ejecutada. Las
tareas abiertas se registran con responsable y fecha objetivo en el plan de cierre.

<<LANDSCAPE>>
## 8.3 Matriz de revisión de cumplimiento

{{DOC:estandar-mitic/00-matriz-cumplimiento.md}}

## 8.4 Matriz de requerimientos funcionales

{{DOC:estandar-mitic/01-matriz-requerimientos-funcionales.md}}

## 8.5 Matriz de requerimientos no funcionales

{{DOC:estandar-mitic/02-matriz-requerimientos-no-funcionales.md}}

## 8.6 Matriz de trazabilidad y pruebas

{{DOC:estandar-mitic/03-matriz-trazabilidad-pruebas.md}}
<<PORTRAIT>>

## 8.7 Inventario de software

{{DOC:estandar-mitic/04-inventario-software.md}}

## 8.8 Especificación técnica

La especificación se reproduce a continuación con su numeración original (§1 a §25 y
apéndices §A.1 y §A.2). Cada sección lleva el código `EC-##` con el que la matriz de
cumplimiento referencia la evidencia correspondiente.

{{DOC:estandar-mitic/05-especificacion-tecnica.md}}

## 8.9 Síntesis de cumplimiento y plan de cierre

| Estado | Cantidad | Ítems |
|---|---|---|
| Cumplido y verificado | 30 | Mayoría de los ítems de los Títulos I y II |
| Parcial / en curso | 2 | Copia en repositorio MITIC (C1 §2); seguridad operativa (S1 §5) |
| No aplica, justificado | 5 | Hardware separado, SII, Identidad Electrónica, portal único, línea gráfica gubernamental, criterios por monto |

**Lectura del resultado.** El proyecto cumple los requisitos sustantivos del estándar:
documentación de análisis, requerimientos bien formados, arquitectura y tecnología
documentadas, seguridad con controles verificados, plan de trabajo y capacitación,
entregables, soporte y garantía. Los dos ítems parciales no afectan la operación del
sistema, pero deben cerrarse para completar el expediente institucional.

**Plan de cierre.**

| Tarea | Responsable | Fecha objetivo |
|---|---|---|
| Solicitar el alta del código y la documentación en el repositorio del MITIC (`gobiernoelectronico@mitic.gov.py`) | Unidad TIC | 30/11/2026 |
| Rotar credenciales por defecto, definir secretos fuertes y certificado TLS confiable | Unidad TIC | 30/11/2026 |
| Ejecutar prueba de carga y pruebas funcionales pendientes | Tester / Unidad TIC | Fase de aceptación |
| Completar el manual de usuario con capturas por rol | Implementador | Fase de aceptación |

**Correspondencia con los objetivos del proyecto.** Los objetivos específicos 1 a 10
del capítulo 1 se verifican así: despliegue reproducible (capítulo 6), identidad y
español (capítulos 2 y 3), flujo de depósito (3.3 a 3.5), búsqueda (3.6), roles y
administración (2.5 y 3.9), persistencia (3.4 y 4.3), interoperabilidad (3.11),
estadísticas (3.10), documentación y pruebas (capítulos 7 y 8), y soporte, capacitación
y garantía (capítulo 10).

# 9. Manual de usuario

## 9.1 Acceso al sistema

1. Abrir la URL institucional del repositorio.
2. Seleccionar **Entrar** en la cabecera.
3. Ingresar el correo institucional y la contraseña provistos por la administración.
4. Si es el primer acceso, cambiar la contraseña desde el perfil.
5. Si se olvidó la contraseña, solicitarla a la administración (el registro y la
   recuperación automática dependen de la configuración de correo).

No existe auto-registro: las cuentas las crea la administración del repositorio.

## 9.2 Depositar un registro paso a paso

1. Entrar y seleccionar **Depositar** o **Nuevo depósito**.
2. Elegir el tipo de recurso (tesis, artículo, conjunto de datos, documento, etc.).
3. Completar los metadatos obligatorios: título, tipo de recurso, creadores y fecha
   de publicación.
4. Añadir metadatos opcionales: descripción, editor, licencia, idioma, temas y fechas.
5. Guardar el borrador; se puede retomar más tarde desde **Mi panel**.
6. Subir los archivos y esperar la confirmación de integridad.
7. Revisar la vista previa y publicar.
8. Copiar el identificador persistente y la citación sugerida.

**Recomendaciones de calidad:** usar títulos descriptivos, declarar correctamente la
autoría y la afiliación, elegir una licencia adecuada, describir el contenido y
conservar los nombres de archivo originales cuando sean significativos.

## 9.3 Buscar y descargar

- La búsqueda global admite texto libre y filtros por tipo, fecha, creador, idioma y
  comunidad.
- Los resultados se ordenan por relevancia o fecha.
- La ficha del registro muestra metadatos, archivos, licencia, citación y enlaces
  persistentes.
- La descarga de archivos abiertos no requiere sesión.
- Para citar, usar la citación sugerida o el identificador persistente.

## 9.4 Gestionar versiones

1. Abrir el registro publicado y seleccionar **Nueva versión**.
2. Modificar metadatos o archivos según la corrección requerida.
3. Publicar la nueva versión.
4. Verificar que el historial muestra ambas versiones y que la anterior permanece
   accesible.
5. Actualizar la citación si corresponde.

## 9.5 Tareas de administración

| Tarea | Ruta | Rol |
|---|---|---|
| Crear usuario | Administración → Usuarios → Crear usuario | `administration` / `admin` |
| Asignar rol | Administración → Usuarios → Editar | `admin` |
| Crear comunidad | Administración → Comunidades | `administration` |
| Publicar aviso | Administración → Banners | `administration` |
| Crear página | Administración → Páginas | `administration` |
| Revisar moderación | Administración → Moderación | `administration-moderation` |
| Ver trabajos | Administración → Jobs | `admin` |
| Reindexar | CLI o panel de sistema | `admin` |

## 9.6 Preguntas frecuentes

**¿Quién puede depositar?** Los usuarios con cuenta institucional creada por la
administración.

**¿Los archivos son públicos?** Los registros publicados y sus archivos abiertos son
consultables por el público. Los borradores no son visibles.

**¿Puedo eliminar un registro publicado?** No se elimina: se retira y se conserva una
lápida con el identificador persistente.

**¿Cómo obtengo un DOI?** El DOI requiere la configuración de DataCite
(`DATACITE_ENABLED`), que no está activa por defecto. El sistema asigna un `recid`
interno y expone OAI-PMH.

**¿Dónde veo las estadísticas?** En la ficha del registro y en el panel de
administración, según los permisos.

**¿Qué hago si no puedo iniciar sesión?** Verificar el correo y la contraseña; si
persiste, contactar a la administración. En producción, el restablecimiento automático
depende del correo institucional.

# 10. Operación, soporte y garantía

## 10.1 Modelo de soporte

El soporte es **interno**, provisto por el equipo de desarrollo y la Unidad TIC, por
un período de **12 meses** desde la recepción satisfactoria. Incluye mantenimiento
correctivo, preventivo y evolutivo menor.

| Aspecto | Compromiso |
|---|---|
| Duración | 12 meses desde la recepción |
| Canales | Correo institucional, sistema de incidencias del repositorio y asistencia virtual o presencial |
| Horario | Lunes a viernes, 8:00–17:00 |
| Horas de especialista | Hasta 40 horas sin costo adicional |
| Actualizaciones | Parches de seguridad y versiones del stack durante la vigencia |
| Monitoreo | Revisión periódica de logs, índices y capacidad |

## 10.2 Niveles de servicio

| Nivel | Tipo | Respuesta | Resolución |
|---|---|---|---|
| N1 | Consulta de uso | ≤ 2 días hábiles | Orientación y buenas prácticas |
| N2 | Falla funcional | ≤ 2 días hábiles | Corrección ≤ 5 días hábiles |
| N3 | Falla total del servicio | ≤ 4 horas hábiles | Mitigación inmediata y plan de recuperación |

## 10.3 Garantía

El funcionamiento del software queda garantizado por **24 meses** desde la terminación
del proyecto, en las condiciones de recepción y con hardware de características
equivalentes. La garantía cubre vicios ocultos, fallas o defectos originados en el
código fuente u objeto.

El desarrollador asume la defensa e indemnización ante reclamos de propiedad
intelectual atribuibles a las creaciones entregadas, y se compromete a proveer
alternativas de continuidad mientras dure el conflicto. No aplican consorcios.

## 10.4 Capacitación y gestión del cambio

| Capacitación | Participantes | Duración | Modalidad | Material |
|---|---|---|---|---|
| C1 — Administración del repositorio | Administradores (2–5) | 8 h | Virtual | Manual de administración y respaldos |
| C2 — Depósito y gestión | Docentes e investigadores (lotes de ~30) | 4 h | Virtual | Manual de usuario y guía rápida |
| C3 — Operación técnica | Programador y soporte interno | 6 h | Virtual | Arquitectura, contenedores y monitoreo |

Se recomienda registrar la asistencia, entregar constancias y mantener un canal de
consultas durante los primeros tres meses de operación.

## 10.5 Mantenimiento evolutivo y hoja de ruta

| Horizonte | Acción |
|---|---|
| Corto plazo | Cerrar brechas de seguridad, programar respaldos y completar pruebas pendientes |
| Mediano plazo | Integrar correo institucional, DOI (DataCite) y catálogo en datos abiertos |
| Largo plazo | Integración con SII, identidad electrónica y mejoras de accesibilidad |

El mantenimiento evolutivo debe planificarse con la Unidad TIC y presupuestarse de
forma separada del soporte correctivo.

# 11. Conclusiones

El Repositorio HGI constituye una solución madura, reproducible y documentada para la
gestión de la producción académica y científica de la institución. La adopción de
InvenioRDM permite apoyarse en una plataforma probada internacionalmente, mientras que
las personalizaciones del proyecto aportan una identidad institucional coherente, un
acceso cerrado y controlado, y una experiencia de administración adaptada a las
necesidades del hospital.

La arquitectura en contenedores, la automatización del despliegue y la separación de
servicios facilitan la operación y la recuperación ante fallas. La documentación
producida cubre el ciclo completo: contexto, funcionalidad, arquitectura, seguridad,
instalación, operación, calidad y cumplimiento normativo.

El proyecto alcanza un nivel alto de cumplimiento del Estándar de Software del MITIC:
30 ítems cumplidos y verificados, 2 parciales con plan de cierre y 5 no aplicables con
justificación. Las brechas restantes son operativas y acotadas: copia del código en el
repositorio MITIC, rotación de credenciales, certificado TLS confiable y pruebas de
carga. Su cierre oportuno permitirá completar el expediente institucional y sostener
la operación con niveles de servicio adecuados.

**Recomendaciones finales.**

1. Ejecutar el plan de cierre de brechas antes del 30/11/2026.
2. Programar respaldos automáticos y probar la restauración.
3. Completar el manual de usuario con capturas por rol.
4. Ejecutar la prueba de carga y las pruebas funcionales pendientes.
5. Mantener actualizada la documentación y las matrices ante cada cambio relevante.
6. Evaluar la integración con correo institucional, DOI y datos abiertos.

# Referencias

- MITIC. *Estándar de Software — Desarrollo y adquisición*, versión 1.0, 26-05-2020.
- Ley N.º 6207/2018 (creación del MITIC) y Decreto N.º 2274/2019.
- Ley N.º 5282/2014 y Decreto N.º 4064/2015 (acceso a la información pública).
- Ley N.º 1328/1998 (derecho de autor).
- Ley N.º 4017/2010 y N.º 4610/2012 (firma electrónica y digital).
- Resolución MITIC N.º 212/2020 y Decreto N.º 8709/2018 (SII).
- Resolución MITIC N.º 218/2020 (portal único y datos abiertos).
- ISO/IEC/IEEE 29148:2018 — Requirements engineering.
- InvenioRDM Documentation. https://inveniordm.docs.cern.ch
- InvenioRDM Starter. https://github.com/front-matter/invenio-rdm-starter
- OpenSearch Documentation. https://opensearch.org/docs
- PostgreSQL Documentation. https://www.postgresql.org/docs
- Caddy Documentation. https://caddyserver.com/docs
- Docker Compose Documentation. https://docs.docker.com/compose
- OAI-PMH Specification. https://www.openarchives.org/OAI/openarchivesprotocol.html
- DataCite Metadata Schema. https://schema.datacite.org

# Anexo A. Inventario de artefactos del repositorio

| Artefacto | Ruta | Función |
|---|---|---|
| Composición de desarrollo | `compose.yml` | Define los seis servicios, redes y volúmenes |
| Composición de producción | `compose.prod.yml` | Override sin Caddy, loopback y reinicio |
| Proxy local | `Caddyfile` | TLS y enrutamiento a la app |
| Imagen | `Dockerfile` | Construcción de la aplicación |
| Inicialización | `entrypoint.py`, `entrypoint.sh` | Base, roles, archivos, índices y colas |
| Instalador | `setup.sh` | Automatización local, producción y verificación |
| Configuración | `invenio.cfg` | Parámetros de la instancia |
| Entorno local | `.env.example` | Variables de desarrollo |
| Entorno productivo | `.env.prod.example` | Variables de producción |
| Apache | `apache/*.conf` | Proxy inverso del sistema y aaPanel |
| Extensión | `docker/live/unae_admin/` | Indicadores y contexto del panel de usuarios |
| Tema | `static/images/unae-theme.css` | Sistema de diseño institucional |
| Recursos | `static/images/` | Logos, favicon y fotografías |
| Plantillas | `templates/semantic-ui/` | Sobrescrituras de portada, login, admin y footer |
| Documentación | `docs/` | Este documento y el paquete MITIC |
| Licencia | `LICENSE` | Licencia MIT del código propio |

# Anexo B. Referencia de la plantilla base InvenioRDM Starter

El proyecto se apoya en **InvenioRDM Starter**, una plantilla de despliegue que
permite ejecutar InvenioRDM en Docker sin instalar Python ni Invenio CLI en el equipo
anfitrión. Este anexo resume la documentación de la plantilla incluida en
`docs/index.md`, adaptada al contexto del Repositorio HGI.

## B.1 Características de la plantilla

- Imagen preconstruida de Invenio-App-RDM.
- Archivo de composición con valores predeterminados y documentación.
- Sin instalación local de Python, Invenio CLI ni entorno virtual.
- Debian Bookworm como distribución base, Python 3.13 y Node 20.
- Gunicorn como servidor WSGI (en lugar de uWSGI).
- Caddy como proxy inverso (en lugar de Nginx).
- Valkey/Redis como broker de mensajes (en lugar de RabbitMQ).
- Inicialización mediante script al arrancar el contenedor.

## B.2 Configuración de referencia

| Variable | Función | Valor predeterminado |
|---|---|---|
| `INVENIO_APP_ALLOWED_HOSTS` | Hosts permitidos | `['0.0.0.0', 'localhost', '127.0.0.1']` |
| `INVENIO_SQLALCHEMY_DATABASE_URI` | URI de base de datos | PostgreSQL del compose |
| `INVENIO_BABEL_DEFAULT_LOCALE` | Idioma por defecto | `en` (en HGI: `es`) |
| `INVENIO_BABEL_DEFAULT_TIMEZONE` | Zona horaria | `UTC` |
| `INVENIO_CACHE_TYPE` | Tipo de caché | `redis` |
| `INVENIO_CACHE_REDIS_URL` | URL de caché | `redis://cache:6379/0` |
| `INVENIO_ACCOUNTS_SESSION_REDIS_URL` | Sesiones | `redis://cache:6379/1` |
| `INVENIO_CELERY_RESULT_BACKEND` | Backend de Celery | `redis://cache:6379/2` |
| `INVENIO_RATELIMIT_STORAGE_URL` | Límite de peticiones | `redis://cache:6379/3` |
| `INVENIO_COMMUNITIES_IDENTITIES_CACHE_REDIS_URL` | Caché de comunidades | `redis://cache:6379/4` |
| `INVENIO_CELERY_BROKER_URL` | Broker | `redis://cache:6379/5` |
| `INVENIO_WSGI_PROXIES` | Proxies de confianza | `4` |
| `INVENIO_SECRET_KEY` | Clave secreta | `changeme` |
| `INVENIO_THEME_HEADER_LOGO` | Logo de cabecera | `images/starter-white.svg` |
| `INVENIO_THEME_FRONTPAGE_TITLE` | Título de portada | `InvenioRDM Starter` |
| `INVENIO_THEME_SHOW_FRONTPAGE_INTRO_SECTION` | Mostrar introducción | `False` |
| `INVENIO_SITE_UI_URL` | URL de interfaz | `https://localhost` |
| `INVENIO_SITE_API_URL` | URL de API | `https://localhost/api` |
| `INVENIO_DATACITE_ENABLED` | Activar DataCite | `False` |
| `INVENIO_RDM_ALLOW_METADATA_ONLY_RECORDS` | Registros solo de metadatos | `True` |
| `INVENIO_RDM_ALLOW_RESTRICTED_RECORDS` | Registros restringidos | `True` (en HGI: `False`) |
| `INVENIO_RDM_CITATION_STYLES_DEFAULT` | Estilo de citación | `apa` |
| `INVENIO_ACCOUNTS_LOCAL_LOGIN_ENABLED` | Login local | `True` |
| `INVENIO_OAISERVER_ID_PREFIX` | Prefijo OAI | `invenio-rdm` |
| `INVENIO_SEARCH_HOSTS` | Host de búsqueda | `['search:9200']` |
| `INVENIO_SEARCH_INDEX_PREFIX` | Prefijo de índices | `invenio-rdm-` |
| `INVENIO_LOGGING_CONSOLE_LEVEL` | Nivel de log | `WARNING` |
| `INVENIO_MAIL_SUPPRESS_SEND` | Suprimir correo | `True` |
| `INVENIO_S3_ENDPOINT_URL` | Endpoint S3 | — |
| `INVENIO_S3_ACCESS_KEY_ID` | Clave S3 | — |
| `INVENIO_S3_SECRET_ACCESS_KEY` | Secreto S3 | — |
| `INVENIO_S3_REGION_NAME` | Región S3 | `us-east-1` |
| `INVENIO_S3_BUCKET_NAME` | Bucket S3 | — |

## B.3 Diferencias con una instalación generada por invenio-cli

| Aspecto | Plantilla Starter | invenio-cli |
|---|---|---|
| Python/CLI local | No requiere | Requiere |
| Imagen | Preconstruida | Construida localmente |
| Distribución | Debian Bookworm | AlmaLinux |
| Python / Node | 3.13 / 20 | 3.9 / 18 |
| Servidor WSGI | Gunicorn | uWSGI |
| Proxy | Caddy | Nginx |
| Broker | Redis/Valkey | RabbitMQ |
| Inicialización | Script al arrancar | invenio-cli |

## B.4 Preguntas frecuentes de la plantilla

**¿Dónde se consultan dudas?** En la documentación de InvenioRDM y en el canal de
Discord de Invenio.

**¿Cómo obtener un certificado válido en localhost?** Caddy genera un certificado
autofirmado; se puede importar la CA local (`data/caddy/pki/authorities/local/root.crt`)
en el almacén del sistema. Como alternativa, el navegador permite aceptar la excepción
para localhost.

**¿Cómo eliminar la base de datos?** `invenio db drop --yes-i-know` (operación
destructiva; solo en desarrollo).

**¿Cómo eliminar los índices?** `invenio index destroy --force --yes-i-know`
(operación destructiva).

**¿Cómo reindexar?** `invenio rdm rebuild-all-indices`.

**¿Cómo añadir vocabularios?** `invenio rdm-records add-to-fixture <nombre>`.

**¿Por qué Python 3.13?** Es la versión soportada por la imagen; no se usan
características exclusivas de versiones posteriores a 3.9.

**¿Por qué no RabbitMQ?** Celery admite Redis/Valkey como broker y backend, lo que
simplifica el stack.

**¿Por qué Debian?** Las imágenes oficiales de Python usan Debian o Alpine; Debian
ofrece un equilibrio entre compatibilidad, seguridad y familiaridad.

**¿Por qué Gunicorn?** Permite una configuración única para la interfaz y la API, y
simplifica el despliegue.

# Anexo C. Trazabilidad documental

| Documento fuente | Contenido | Sección de este documento |
|---|---|---|
| `docs/index.md` | Documentación de la plantilla base | Anexo B; capítulos 4 y 6 |
| `docs/estandar-mitic/README.md` | Presentación del paquete | 8.1 |
| `00-matriz-cumplimiento.md` | Matriz de 37 ítems | 8.3 y 8.9 |
| `01-matriz-requerimientos-funcionales.md` | RF-01 a RF-14 | 8.4; capítulo 3 |
| `02-matriz-requerimientos-no-funcionales.md` | RNF-01 a RNF-10 | 8.5; capítulo 5 |
| `03-matriz-trazabilidad-pruebas.md` | P-01 a P-18 | 8.6; capítulo 7 |
| `04-inventario-software.md` | Inventario y licencias | 8.7; capítulo 4 |
| `05-especificacion-tecnica.md` | Especificación EC-1 a EC-25 | 8.8 |
| `compose.yml`, `compose.prod.yml` | Infraestructura | Capítulo 6 |
| `setup.sh`, `entrypoint.py` | Despliegue e inicialización | 6.3 a 6.5 |
| `invenio.cfg` | Configuración | 4.7 y 5.4 |
| `unae-theme.css` | Tema visual | 2.6 y 3.12 |
| `docker/live/unae_admin/` | Panel de usuarios | 3.9.1 |

# Anexo D. Lista de verificación para producción

| N.º | Verificación | Estado |
|---|---|---|
| 1 | Dominio y URL pública configurados en `.env.prod` | ☐ |
| 2 | `INVENIO_TRUSTED_HOSTS` incluye el dominio real | ☐ |
| 3 | Certificado TLS confiable emitido y renovación automática | ☐ |
| 4 | Secretos únicos y robustos (`SECRET_KEY`, sal, BD, SMTP) | ☐ |
| 5 | Credenciales administrativas rotadas y custodiadas | ☐ |
| 6 | Registro público deshabilitado | ☐ |
| 7 | Apache configurado como proxy a `127.0.0.1:5000` | ☐ |
| 8 | Puertos 80/443 abiertos; resto cerrado por firewall | ☐ |
| 9 | `restart: unless-stopped` activo | ☐ |
| 10 | Respaldos programados de base y archivos | ☐ |
| 11 | Prueba de restauración ejecutada | ☐ |
| 12 | Monitoreo y alertas configurados | ☐ |
| 13 | Índices reconstruidos y búsqueda verificada | ☐ |
| 14 | Flujo de depósito, publicación y descarga probado | ☐ |
| 15 | Correo institucional probado (si está habilitado) | ☐ |
| 16 | Documentación y matrices actualizadas | ☐ |
| 17 | Copia del código en repositorio MITIC solicitada | ☐ |
| 18 | Capacitación y acta de entrega firmadas | ☐ |
| 19 | Plan de soporte y garantía aceptado | ☐ |
| 20 | Prueba de carga y accesibilidad planificadas | ☐ |
"""

CONTENT = "\n\n".join([PART1, PART2, PART3, PART4, PART5])
