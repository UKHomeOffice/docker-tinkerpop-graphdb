FROM maven:3.6-jdk-8-alpine as builder

ARG REPO_GRAPH_WRAPPER=https://github.com/pontusvision/pontus-gdpr-graph
ARG REPO_JANUSGRAPH=https://github.com/pontusvision/pontus-janusgraph
ARG REPO_DRIVER_DYNAMODB=https://github.com/pontusvision/pontus-dynamodb-janusgraph-storage-backend
ARG REPO_REDACTION=https://github.com/UKHomeOffice/pontus-redaction
ARG DYNAMODB_VERSION=v0.0.20
ARG JANUSGRAPH_VERSION=v0.0.20
ARG GRAPH_WRAPPER_VERSION=v0.0.20
ARG REDACTION_VERSION=v0.0.20

RUN apk upgrade -q --no-cache
RUN apk add -q --no-cache \
      git \
      bash \
      gettext \
      unzip \
      zip 

RUN mkdir -p /tmp/work/src && \
    git clone --single-branch -b $JANUSGRAPH_VERSION    $REPO_JANUSGRAPH      /tmp/work/src/janusgraph

WORKDIR /tmp/work/src/janusgraph
RUN mvn -DskipTests install  

RUN git clone --single-branch -b $DYNAMODB_VERSION      $REPO_DRIVER_DYNAMODB /tmp/work/src/dynamodb-janusgraph-storage-backend
WORKDIR /tmp/work/src/dynamodb-janusgraph-storage-backend
RUN mvn -DskipTests install 

RUN git clone --single-branch -b $REDACTION_VERSION $REPO_REDACTION   /tmp/work/src/redaction
WORKDIR /tmp/work/src/redaction
RUN mvn -DskipTests install 

RUN git clone --single-branch -b $GRAPH_WRAPPER_VERSION $REPO_GRAPH_WRAPPER   /tmp/work/src/graphdb
WORKDIR /tmp/work/src/graphdb
RUN mvn -DskipTests install -U package 


FROM openjdk:8-jre-alpine

ENV LISTEN_HOST="0.0.0.0" \
    LISTEN_PORT="8182"
ARG VERSION="v0.0.20"


EXPOSE 8182

RUN apk upgrade -q --no-cache \
&&  apk add -q --no-cache \
      bash  \
&&  mkdir -p /opt/graphdb/lib \
&&  mkdir -p /opt/graphdb/bin \
&&  adduser -S graphdb -u 31337 -h /opt/graphdb/ \
&&  chown -R graphdb /opt/graphdb/

USER 31337

COPY --from=builder /tmp/work/src/graphdb/target/pontus-gdpr-graph-*.jar  /opt/graphdb/lib/graphdb-${VERSION}.jar

COPY bin /opt/graphdb/bin

WORKDIR /opt/graphdb
CMD ["/opt/graphdb/bin/run-graph.sh"]

