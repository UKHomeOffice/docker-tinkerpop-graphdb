FROM maven:3.6-jdk-8-alpine as builder


RUN apk upgrade -q --no-cache
RUN apk add -q --no-cache \
      git \
      bash \
      gettext \
      unzip \
      zip 


ARG REPO_GRAPH_WRAPPER=https://github.com/ukhomeoffice/tinkerpop-graphdb-wrapper
ARG GRAPH_WRAPPER_VERSION=v0.3.2
RUN rm -rf /tmp/work/src/graphdb && git clone --single-branch -b $GRAPH_WRAPPER_VERSION $REPO_GRAPH_WRAPPER   /tmp/work/src/graphdb
WORKDIR /tmp/work/src/graphdb
RUN mvn -q install -U package

RUN cd / &&  wget https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.11.0/jmx_prometheus_javaagent-0.11.0.jar

FROM openjdk:8-jre-alpine

ENV LISTEN_HOST="0.0.0.0" \
    LISTEN_PORT="8182"
ARG VERSION="v0.3.2"


EXPOSE 8182

RUN apk upgrade -q --no-cache \
&&  apk add -q --no-cache \
      bash  \
      curl  \
      nss \
&&  mkdir -p /opt/graphdb/lib \
&&  mkdir -p /opt/graphdb/bin \
&&  adduser -S graphdb -u 31337 -h /opt/graphdb/ \
&&  chown -R graphdb /opt/graphdb/

USER 31337

COPY --from=builder /tmp/work/src/graphdb/target/tinkerpop-graphdb-wrapper-*.jar  /opt/graphdb/lib/graphdb-${VERSION}.jar
COPY --from=builder /*.jar  /opt/graphdb/lib/jmx-prometheus-javaagent.jar

COPY bin /opt/graphdb/bin
COPY lib /opt/graphdb/lib

WORKDIR /opt/graphdb
CMD ["/opt/graphdb/bin/run-graph.sh"]

