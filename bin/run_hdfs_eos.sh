#!/bin/bash
# With this environment, It works in lxplus7, it can requiere modifications to run elsewhere.
source /cvmfs/sft.cern.ch/lcg/views/LCG_94python3/x86_64-centos7-gcc8-opt/setup.sh
source /cvmfs/sft.cern.ch/lcg/etc/hadoop-confext/hadoop-swan-setconf.sh analytix
currentDir=$(
  cd $(dirname "$0")
  pwd
)
#In lxplus, when running with acrontab, we need to set the java home
# to a jvm with avanced encryption enabled. 
# see https://cern.service-now.com/service-portal/view-request.do?n=RQF1380598 

if [ -e "/usr/lib/jvm/java-1.8.0" ]
then
export JAVA_HOME="/usr/lib/jvm/java-1.8.0"
elif ! (java -XX:+PrintFlagsFinal -version 2>/dev/null |grep -E -q 'UseAES\s*=\s*true')
then
    (>&2 echo "This script requires a java version with AES enabled") 
    exit 1
fi
export PYTHONPATH=$PYTHONPATH:"$currentDir/../src/python"
if ! klist -s
then
    echo "There is not valid ticket yet"
    kinit
fi
spark-submit  --master yarn \
--conf spark.driver.extraClassPath='/eos/project/s/swan/public/hadoop-mapreduce-client-core-2.6.0-cdh5.7.6.jar' \
--conf spark.executor.memory=4g --conf spark.executor.instances=60 --conf spark.executor.cores=4 --conf spark.driver.memory=4g \
"$currentDir/../src/python/CMSSpark/dbs_hdfs_eos.py" "$@"
