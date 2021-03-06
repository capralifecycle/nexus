# inspiration:
# - https://github.com/sonatype/docker-nexus/blob/master/oss/Dockerfile
FROM azul/zulu-openjdk-alpine:8-jre@sha256:94ce3d6a3af100954e14904b18dc7ee06060d794819b554203373567f45e982c

ARG NEXUS_VERSION=2.14.15-01
ARG NEXUS_DOWNLOAD_URL=https://download.sonatype.com/nexus/oss/nexus-${NEXUS_VERSION}-bundle.tar.gz

ENV SONATYPE_DATA /nexus-data
ENV SONATYPE_APP /nexus-app

RUN set -eux; \
    apk add --no-cache \
      ca-certificates \
      curl \
    ; \
    mkdir -p $SONATYPE_DATA; \
    mkdir -p $SONATYPE_APP; \
    curl -fSL "$NEXUS_DOWNLOAD_URL" \
      | tar zxf - -C $SONATYPE_APP --strip-components=1 nexus-$NEXUS_VERSION; \
    \
    addgroup -g 1000 nexus; \
    adduser -D -u 1000 -h $SONATYPE_DATA -G nexus nexus; \
    chown -R nexus:nexus $SONATYPE_DATA $SONATYPE_APP

VOLUME $SONATYPE_DATA
EXPOSE 8081

USER nexus
WORKDIR $SONATYPE_APP

ENV CONTEXT_PATH /
ENV MAX_HEAP 768m
ENV MIN_HEAP 256m
ENV JAVA_OPTS -server -Djava.net.preferIPv4Stack=true
ENV LAUNCHER_CONF ./conf/jetty.xml ./conf/jetty-requestlog.xml

CMD java \
  -Dnexus-work=${SONATYPE_DATA} \
  -Dnexus-webapp-context-path=${CONTEXT_PATH} \
  -Xms${MIN_HEAP} \
  -Xmx${MAX_HEAP} \
  -cp 'conf/:lib/*' \
  ${JAVA_OPTS} \
  org.sonatype.nexus.bootstrap.Launcher ${LAUNCHER_CONF}
