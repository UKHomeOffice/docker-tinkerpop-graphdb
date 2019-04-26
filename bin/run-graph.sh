#!/bin/bash  -x

#
#/**
# * Licensed to the Apache Software Foundation (ASF) under one
# * or more contributor license agreements.  See the NOTICE file
# * distributed with this work for additional information
# * regarding copyright ownership.  The ASF licenses this file
# * to you under the Apache License, Version 2.0 (the
# * "License"); you may not use this file except in compliance
# * with the License.  You may obtain a copy of the License at
# *
# *     http://www.apache.org/licenses/LICENSE-2.0
# *
# * Unless required by applicable law or agreed to in writing, software
# * distributed under the License is distributed on an "AS IS" BASIS,
# * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# * See the License for the specific language governing permissions and
# * limitations under the License.
# */
#
#
# Environment Variables:
#
#   JAVA_HOME        The java implementation to use.  Overrides JAVA_HOME.
#
#   GRAPHDB_CLASSPATH  Extra Java CLASSPATH entries.
#
#   GRAPHDB_CLASSPATH_PREFIX Extra Java CLASSPATH entries that should be
#                    prefixed to the system classpath.
#
#   GRAPHDB_HEAPSIZE   The maximum amount of heap to use.
#                    Default is unset and uses the JVMs default setting
#                    (usually 1/4th of the available memory).
#
#   GRAPHDB_LIBRARY_PATH  HBase additions to JAVA_LIBRARY_PATH for adding
#                    native libraries.
#
#   GRAPHDB_OPTS       Extra Java runtime options.
#
#   GRAPHDB_CONF_DIR   Alternate conf dir. Default is ${GRAPHDB_HOME}/conf.
#
#
bin=`dirname "$0"`
bin=`cd "$bin">/dev/null; pwd`

# This will set GRAPHDB_HOME, etc.
. "$bin"/graph-env.sh

if [[ -z "$GRAPHDB_HOME" ]]; then
  GRAPHDB_HOME="$bin/.."
fi

if [[ -z "$CLASS" ]]; then
  CLASS=uk.gov.homeoffice.cdp.App
fi

if [[ -z "$GRAPHDB_CONF_DIR" ]]; then
   GRAPHDB_CONF_DIR=${GRAPHDB_HOME}/conf
fi

cygwin=false
case "`uname`" in
CYGWIN*) cygwin=true;;
esac

# Detect if we are in hbase sources dir
in_dev_env=false
if [ -d "${GRAPHDB_HOME}/target" ]; then
  in_dev_env=true
fi

read -d '' options_string << EOF
Options:
  --config DIR     Configuration direction to use. Default: ./conf
EOF

# get arguments
COMMAND=graph

JAVA=$JAVA_HOME/bin/java

add_size_suffix() {
    # add an 'm' suffix if the argument is missing one, otherwise use whats there
    local val="$1"
    local lastchar=${val: -1}
    if [[ "mMgG" == *$lastchar* ]]; then
        echo $val
    else
        echo ${val}m
    fi
}

if [[ -n "$GRAPHDB_HEAPSIZE" ]]; then
    JAVA_HEAP_MAX="-Xmx$(add_size_suffix $GRAPHDB_HEAPSIZE)"
fi

if [[ -n "$GRAPHDB_OFFHEAPSIZE" ]]; then
    JAVA_OFFHEAP_MAX="-XX:MaxDirectMemorySize=$(add_size_suffix $GRAPHDB_OFFHEAPSIZE)"
fi

# so that filenames w/ spaces are handled correctly in loops below
ORIG_IFS=$IFS
IFS=

# CLASSPATH initially contains $GRAPHDB_CONF_DIR
CLASSPATH="${GRAPHDB_CONF_DIR}"
#CLASSPATH=${CLASSPATH}:$JAVA_HOME/lib/tools.jar

add_to_cp_if_exists() {
  if [ -d "$@" ]; then
    CLASSPATH=${CLASSPATH}:"$@"
  fi
}
add_maven_deps_to_classpath() {
  f="${GRAPHDB_HOME}/target/cached_classpath.txt"
  if [ ! -f "${f}" ]
  then
      echo "As this is a development environment, we need ${f} to be generated from maven (command: mvn install -DskipTests)"
      exit 1
  fi
  CLASSPATH=${CLASSPATH}:`cat "${f}"`
}


#Add the development env class path stuff
#if $in_dev_env; then
  #add_maven_deps_to_classpath
#fi

# Add libs to CLASSPATH
for f in $GRAPHDB_HOME/lib/*.jar; do
  CLASSPATH=${CLASSPATH}:$f;
done

for f in $GRAPHDB_HOME/lib/*.properties; do
  CLASSPATH=${CLASSPATH}:$f;
done

# default log directory & file
if [ "$GRAPHDB_LOG_DIR" = "" ]; then
  GRAPHDB_LOG_DIR="$GRAPHDB_HOME/logs"
fi
if [ "$GRAPHDB_LOGFILE" = "" ]; then
  GRAPHDB_LOGFILE='graphdb.log'
fi

function append_path() {
  if [ -z "$1" ]; then
    echo $2
  else
    echo $1:$2
  fi
}

JAVA_PLATFORM=""

# if GRAPHDB_LIBRARY_PATH is defined lets use it as first or second option
if [ "$GRAPHDB_LIBRARY_PATH" != "" ]; then
  JAVA_LIBRARY_PATH=$(append_path "$JAVA_LIBRARY_PATH" "$GRAPHDB_LIBRARY_PATH")
fi

#If avail, add Hadoop to the CLASSPATH and to the JAVA_LIBRARY_PATH
# Allow this functionality to be disabled
if [ "$GRAPHDB_DISABLE_HADOOP_CLASSPATH_LOOKUP" != "true" ] ; then
  HADOOP_IN_PATH=$(PATH="${HADOOP_HOME:-${HADOOP_PREFIX}}/bin:$PATH" which hadoop 2>/dev/null)
  if [ -f ${HADOOP_IN_PATH} ]; then
    HADOOP_JAVA_LIBRARY_PATH=$(HADOOP_CLASSPATH="$CLASSPATH" ${HADOOP_IN_PATH} \
                               org.apache.hadoop.hbase.util.GetJavaProperty java.library.path 2>/dev/null)
    if [ -n "$HADOOP_JAVA_LIBRARY_PATH" ]; then
      JAVA_LIBRARY_PATH=$(append_path "${JAVA_LIBRARY_PATH}" "$HADOOP_JAVA_LIBRARY_PATH")
    fi
    CLASSPATH=$(append_path "${CLASSPATH}" `${HADOOP_IN_PATH} classpath 2>/dev/null`)
  fi
fi

# Add user-specified CLASSPATH last
if [ "$GRAPHDB_CLASSPATH" != "" ]; then
  CLASSPATH=${CLASSPATH}:${GRAPHDB_CLASSPATH}
fi

# Add user-specified CLASSPATH prefix first
if [ "$GRAPHDB_CLASSPATH_PREFIX" != "" ]; then
  CLASSPATH=${GRAPHDB_CLASSPATH_PREFIX}:${CLASSPATH}
fi

# cygwin path translation
if $cygwin; then
  CLASSPATH=`cygpath -p -w "$CLASSPATH"`
  GRAPHDB_HOME=`cygpath -d "$GRAPHDB_HOME"`
  GRAPHDB_LOG_DIR=`cygpath -d "$GRAPHDB_LOG_DIR"`
fi

if [ -d "${GRAPHDB_HOME}/build/native" -o -d "${GRAPHDB_HOME}/lib/native" ]; then
  if [ -z $JAVA_PLATFORM ]; then
    JAVA_PLATFORM=`CLASSPATH=${CLASSPATH} ${JAVA} org.apache.hadoop.util.PlatformName | sed -e "s/ /_/g"`
  fi
  if [ -d "$GRAPHDB_HOME/build/native" ]; then
    JAVA_LIBRARY_PATH=$(append_path "$JAVA_LIBRARY_PATH" ${GRAPHDB_HOME}/build/native/${JAVA_PLATFORM}/lib)
  fi

  if [ -d "${GRAPHDB_HOME}/lib/native" ]; then
    JAVA_LIBRARY_PATH=$(append_path "$JAVA_LIBRARY_PATH" ${GRAPHDB_HOME}/lib/native/${JAVA_PLATFORM})
  fi
fi

# cygwin path translation
if $cygwin; then
  JAVA_LIBRARY_PATH=`cygpath -p "$JAVA_LIBRARY_PATH"`
fi

# restore ordinary behaviour
unset IFS

GRAPHDB_OPTS="$GRAPHDB_OPTS $SERVER_GC_OPTS"

if [ "$AUTH_AS_SERVER" == "true" ] || [ "$COMMAND" = "hbck" ]; then
   if [ -n "$GRAPHDB_SERVER_JAAS_OPTS" ]; then
     GRAPHDB_OPTS="$GRAPHDB_OPTS $GRAPHDB_SERVER_JAAS_OPTS"
   else
     GRAPHDB_OPTS="$GRAPHDB_OPTS $GRAPHDB_REGIONSERVER_OPTS"
   fi
fi

if [ "x$JAVA_LIBRARY_PATH" != "x" ]; then
  GRAPHDB_OPTS="$GRAPHDB_OPTS -Djava.library.path=$JAVA_LIBRARY_PATH"
  export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$JAVA_LIBRARY_PATH"
fi
HEAP_SETTINGS="$JAVA_HEAP_MAX $JAVA_OFFHEAP_MAX"
# Exec unless GRAPHDB_NOEXEC is set.
export CLASSPATH
cd ${GRAPHDB_HOME}
if [ "${GRAPHDB_NOEXEC}" != "" ]; then
  "$JAVA" -Dproc_$COMMAND -cp $CLASSPATH $HEAP_SETTINGS $GRAPHDB_OPTS $CLASS "$@"
else
  exec "$JAVA" \
    -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=${GRAPHDB_DEBUG_PORT:-5006} \
    -Dcom.sun.management.jmxremote \
    -Duk.gov.homeoffice.cdp.log.class=org.eclipse.jetty.util.log.StrErrLog \
    -Dorg.eclipse.jetty.LEVEL=INFO \
    -Dorg.eclipse.jetty.util.log.class=org.eclipse.jetty.util.log.StrErrLog \
    -Dorg.eclipse.jetty.websocket.LEVEL=INFO \
    -Dlog4j.debug \
    -Dlog4j.configuration=file://${GRAPHDB_HOME}/lib/log4j.properties \
    -Dproc_$COMMAND \
    -cp $CLASSPATH $HEAP_SETTINGS $GRAPHDB_OPTS $CLASS "$@"
fi

