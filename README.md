# docker-tinkerpop-graphdb
Docker container with a tinkerpop graphdb based on Janusgraph with dynamo db, and lucene as an indexing backend; this is currently only useful to show connectivity between graphdb and dynamodb for dev purposes.  Any realistic solution would use ElasticSearch instead.  

## Intended use
The image produced by this repo is only intended to be used as a base for other images.  One example is [docker-tinkerpop-graphdb-conf](https://github.com/UKHomeOffice/docker-tinkerpop-graphdb-config).  Here is a brief explanation of the files in this package:

* Dockerfile -> multi-stage build that builds the dependencies for the jar file, and creates a small image with the bare essentials to connect Janusgraph to elasticsearch and elastic, plus liveliness/readiness URLs  for use in kubernetes.


* bin/graph-env.sh -> env vars to customize graph
* bin/run-graph.sh -> command line script to start graph
* bin/loadschema-globals.groovy -> utility functions to enable schema creation
* bin/loadschema-bootstrap.groovy -> bootstrap script that loads a json schema file (not present in this image) in the /opt/graphdb/conf/graph-schema.json directory
* lib/log4j.properties -> forces logs to be sent to stdout so they can be picked up by kubernetes.



## Port description

* 8182: graphdb tinkerpop gremlin groovy
* 3001: healthcheck
* 5006: remote java debugging

## Testing
see  [docker-tinkerpop-graphdb-conf](https://github.com/UKHomeOffice/docker-tinkerpop-graphdb-config)
