GRAPHDB_DISABLE_HADOOP_CLASSPATH_LOOKUP=true
GRAPHDB_CLASSPATH=/opt/graphdb/conf
GRAPHDB_OPTS=" \
  -DgremlinServerSandbox=/opt/graphdb/whitelist.yml \
  -Dbulk.elastic.retry_on_conflict=5 \
  -Dindex.elastic.use_params=true \
  $GRAPHDB_OPTS"

