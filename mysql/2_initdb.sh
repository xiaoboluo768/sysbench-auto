#!/bin/bash

function prep_mysql_cnf() {
    template_cnf=$1
    target_cnf=$2
    tokens=("%mysql_basedir%" \
            "%mysql_socket%" \
            "%mysql_pid%" \
            "%mysql_datadir%" \
            "%mysql_redologdir%" \
            "%mysql_tmpdir%" \
            "%mysql_doublewrite%" \
            "%innodb_page_size%" \
            "%innodb_buffer_pool_size%" \
            "%innodb_log_file_size%" \
            "%innodb_buffer_pool_instances%" \
            "%innodb_page_cleaners%" \
            "%innodb_log_write_ahead_size%")
    values=("${mysql_basedir}" \
            "${mysql_socket}" \
            "${mysql_pid}" \
            "${mysql_datadir}" \
            "${mysql_redologdir}" \
            "${mysql_tmpdir}" \
            "${mysql_doublewrite}" \
            "${innodb_page_size}" \
            "${innodb_buffer_pool_size}" \
            "${innodb_log_file_size}" \
            "${innodb_buffer_pool_instances}" \
            "${innodb_page_cleaners}" \
            "${innodb_log_write_ahead_size}")
    if [ ! -e $template_cnf ]; then return 1; fi

    cp ${template_cnf} ${target_cnf}

    for((i=0; i<${#tokens[@]};i++))
    do
        sed "s#${tokens[$i]}#${values[$i]}#g" -i ${target_cnf}
    done
}


cfg_file=$1
if [ "$1" = "" ]; then echo -e "Usage:\n\t2_initdb.sh cfg_file"; exit 1; fi
if [ ! -e ${cfg_file} ]; then echo "can't find configuration file [${cfg_file}]", exit 2; fi
source ${cfg_file}

./stop.sh

if [ "${mysql_datadir}" != "" ] && [ ! -e ${mysql_datadir} ];
then 
        sudo mkdir -p ${mysql_datadir};
fi
sudo chown -R `whoami`:`whoami` ${mysql_datadir};

if [ "${mysql_redologdir}" != "" ]  && [ ! -e ${mysql_redologdir} ];
then 
        sudo mkdir -p ${mysql_redologdir};
fi
sudo chown -R `whoami`:`whoami` ${mysql_redologdir};

if [ "${mysql_tmpdir}" != "" ] && [ ! -e ${mysql_tmpdir} ];
then
        sudo mkdir -p ${mysql_tmpdir};
fi
sudo chown -R `whoami`:`whoami` ${mysql_tmpdir};

if [ "${mysql_datadir}" != "" ] ; then rm -rf ${mysql_datadir}/*; fi
if [ ! -e ${mysql_basedir}/logs ]; then mkdir ${mysql_basedir}/logs; fi
if [ -e ${mysql_basedir}/logs/error.log ];
then
        mv ${mysql_basedir}/logs/error.log ${mysql_basedir}/logs/error-`date +%Y%m%d_%H%M%S`.log
fi

if [ ! -e run ]; then mkdir run; fi

prep_mysql_cnf ${mysql_template_cnf} ${mysql_cnf}
mysql_cnf=`pwd`/${mysql_cnf}
useradd mysql 2> /dev/null                                                                                                                                                  
chown mysql.mysql ${mysql_datadir} -R                                                                                                                                       
chown mysql.mysql ${mysql_datadir}_tmp -R                                                                                                                                   
chown mysql.mysql ${mysql_basedir} -R  

pushd ${mysql_basedir}
${mysql_init_db} \
        --defaults-file=${mysql_cnf} \
        ${mysql_init_db_options}
popd

# after initialization the root password is not set
export MYSQL_PWD=""
./start.sh ${cfg_file}
timed_out=1
for i in {1..120};
do        
        ${mysql_basedir}/bin/mysql \
                --socket=${mysql_socket} \
                -u${mysql_user} \
                -e "${mysql_init_db_set_pwd}"
        if [ $? -eq 0 ];
        then
                timed_out=0
                break
        else
                 echo -e "mysqld is not ready, wait for 5 seconds and retry";
                 sleep 5;
        fi
done

if [ ${timed_out} -ne 0 ]; then echo -e "\nstarting mysqld timed out!\n"; exit 1; fi

# eliminate MySQL warning messages using password in command line

${mysql_basedir}/bin/mysql --socket=${mysql_socket} \
                           -u${mysql_user} \
                           -p${mysql_pwd} \
                           -e "${mysql_init_db_grant_priv}"
${mysql_basedir}/bin/mysql --socket=${mysql_socket} \
                           -u${mysql_user} \
                           -p${mysql_pwd} \
                           -e "create database ${db_name}"
