#!/bin/bash

cfg_file=$1
if [ "${cfg_file}" = "" ]; then echo -e "Usage:\n\t./start.sh cfg_file"; exit 1; fi
if [ ! -e ${cfg_file} ]; then echo "can't find configuration file [${cfg_file}]", exit 2; fi
source ${cfg_file}

${mysql_basedir}/bin/mysqld --defaults-file=${mysql_cnf} --user=mysql &
mysql_pid=$!
timed_out=1

for i in {1..100};
do
    ping_result=$(${mysql_basedir}/bin/mysqladmin \
        --socket=${mysql_socket} \
        -u${mysql_user} \
        ping)
        
    if [ $? -eq 0 ];
    then
        echo ${ping_result} | grep -i alive
        if [ $? -eq 0 ]; then timed_out=0; break; fi
    else
        echo -e "mysqld is not ready, wait for 3 seconds and retry";
        sleep 3;
    fi
done

if [ ${timed_out} -ne 0 ]; then echo "starting MySQL timed out"; kill ${mysql_pid}; fi
