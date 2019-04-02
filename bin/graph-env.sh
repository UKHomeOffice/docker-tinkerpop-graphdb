PVGDPR_DISABLE_HADOOP_CLASSPATH_LOOKUP=true
PVGDPR_CLASSPATH=/opt/graphdb/conf
PVGDPR_OPTS=" \
  -DgremlinServerSandbox=/opt/graphdb/whitelist.yml \
  -Dbulk.elastic.retry_on_conflict=5 \
  -Dindex.elastic.use_params=true "

