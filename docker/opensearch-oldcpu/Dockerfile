# OpenSearch 2.18 para CPUs sin x86-64-v2.
#
# La imagen oficial usa Amazon Linux 2023, cuyo glibc exige x86-64-v2
# (SSE4.2/POPCNT) y aborta con:
#   Fatal glibc error: CPU does not support x86-64-v2
#
# Esta variante reutiliza los binarios oficiales de OpenSearch pero los
# ejecuta sobre Ubuntu 22.04, que mantiene el baseline x86-64 clásico.
# El JDK incluido por Amazon se reemplaza por Eclipse Temurin 21 (jammy).
#
# Construir:
#   docker build -t invennio/opensearch:2.18.0-oldcpu-v2 \
#     -f docker/opensearch-oldcpu/Dockerfile .
#
# Usar en .env:
#   OPENSEARCH_IMAGE=invennio/opensearch:2.18.0-oldcpu-v2

FROM opensearchproject/opensearch:2.18.0 AS dist

FROM eclipse-temurin:21-jre-jammy

ARG UID=1000
ARG GID=1000

RUN apt-get update \
    && apt-get install -y --no-install-recommends bash ca-certificates curl passwd procps \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g "${GID}" opensearch \
    && useradd -u "${UID}" -g "${GID}" -d /usr/share/opensearch -s /bin/bash opensearch

COPY --from=dist --chown=${UID}:${GID} /usr/share/opensearch /usr/share/opensearch

# El JDK de la imagen oficial viene de Amazon Linux 2023; se usa Temurin.
# Además se quitan los plugins que InvenioRDM no usa (seguridad, ML, k-NN,
# performance-analyzer, alerting, etc.): varios arrancan procesos o cargan
# librerías nativas y consumen RAM de más en servidores pequeños.
RUN rm -rf /usr/share/opensearch/jdk /usr/share/opensearch/plugins/* \
    && mkdir -p /usr/share/opensearch/data /usr/share/opensearch/logs \
    && chown -R "${UID}:${GID}" /usr/share/opensearch

ENV OPENSEARCH_JAVA_HOME=/opt/java/openjdk \
    JAVA_HOME=/opt/java/openjdk \
    OPENSEARCH_HOME=/usr/share/opensearch \
    OPENSEARCH_PATH_CONF=/usr/share/opensearch/config \
    PATH=/usr/share/opensearch/bin:$PATH \
    LD_LIBRARY_PATH=/usr/share/opensearch/plugins/opensearch-knn/lib

USER ${UID}:${GID}
WORKDIR /usr/share/opensearch

EXPOSE 9200 9300 9600 9650

ENTRYPOINT ["./opensearch-docker-entrypoint.sh"]
CMD ["opensearch"]
