FROM maven:3.6-jdk-8-alpine as builder


RUN apk upgrade -q --no-cache
RUN apk add -q --no-cache \
      git \
      bash \
      gettext \
      unzip \
      zip 


#ARG REPO_JANUSGRAPH=https://github.com/pontusvision/pontus-janusgraph
#ARG JANUSGRAPH_VERSION=v0.0.20
#RUN mkdir -p /tmp/work/src && \
#    git clone --single-branch -b $JANUSGRAPH_VERSION    $REPO_JANUSGRAPH      /tmp/work/src/janusgraph
#WORKDIR /tmp/work/src/janusgraph
#RUN mvn -DskipTests install

ARG REPO_DRIVER_DYNAMODB=https://github.com/pontusvision/pontus-dynamodb-janusgraph-storage-backend
ARG DYNAMODB_VERSION=v0.1.0
RUN git clone --single-branch -b $DYNAMODB_VERSION      $REPO_DRIVER_DYNAMODB /tmp/work/src/dynamodb-janusgraph-storage-backend
WORKDIR /tmp/work/src/dynamodb-janusgraph-storage-backend
RUN mvn -q -DskipTests install

#ARG REPO_REDACTION=https://github.com/UKHomeOffice/pontus-redaction
#ARG REDACTION_VERSION=v0.0.20
#RUN git clone --single-branch -b $REDACTION_VERSION $REPO_REDACTION   /tmp/work/src/redaction
#WORKDIR /tmp/work/src/redaction
#RUN mvn -DskipTests install 

ARG REPO_GRAPH_WRAPPER=https://github.com/ukhomeoffice/tinkerpop-graphdb-wrapper
ARG GRAPH_WRAPPER_VERSION=v0.1.1
RUN rm -rf /tmp/work/src/graphdb && git clone --single-branch -b $GRAPH_WRAPPER_VERSION $REPO_GRAPH_WRAPPER   /tmp/work/src/graphdb
WORKDIR /tmp/work/src/graphdb
RUN mvn -q install -U package

FROM openjdk:8-jre-alpine

ENV LISTEN_HOST="0.0.0.0" \
    LISTEN_PORT="8182"
ARG VERSION="v0.1.1"


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

COPY lib /opt/graphdb/lib
COPY bin /opt/graphdb/bin

WORKDIR /opt/graphdb
CMD ["/opt/graphdb/bin/run-graph.sh"]

