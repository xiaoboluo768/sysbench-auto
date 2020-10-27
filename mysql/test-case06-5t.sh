#!/bin/bash

export dev_name=sfdv0n1
export capacity_gb=8000
export prep_dev=yes     # yes|no
export init_db=yes      # yes|no
export atomic_write=1   # 0|1
export WORKLOADS=sb/percona-mysql-5.7
############################################################
## test configuraion for quick verification
export workload_set="prepare oltp_read_only oltp_read_write oltp_write_only oltp_update_index oltp_update_non_index"
export run_time=600      # in seconds
export thread_count_list="1 16 32 64 128 256"
export table_count=1400
export table_size=20000000


## 600 table x 15 million records for 2T data set
# export workload_set="prepare oltp_read_only oltp_insert oltp_update_index oltp_update_non_index oltp_read_write oltp_write_only"
# export run_time=1200
# export thread_count_list="1 8 32 64 128 256"
# export table_count=600
# export table_size=15000000
############################################################
export innodb_buffer_pool_size=32G
## set iostat_dev_str to collect iostat data for all devices
## interested, like below -
## export iostat_dev_str="md0 sfdv0n1 sfdv1n1 sfdv2n1 sfdv3n1"
export iostat_dev_str=${dev_name}
## set dev_pattern like below to let the script generate 
## iostat csv files for all devices. refult file content 
## will be 
## thrd,tps,qps,%lat,,ts,avg-cpu,%user,%sys,%iowait,%idle,Device:,...
# export dev_pattern="md0 sfdv0n1 sfdv1n1 sfd2n1 sfdv3n1"
export dev_pattern=${iostat_dev_str}
export table_data_src_file=""   # empty|../compress/best.txt 
export run_cmd_script=./run-cases.sh

export WORKSPACE=./

pushd ../

tar xzf bin.tgz
tar xzf compress.tgz

popd

export cfg_list=${WORKLOADS}
export chart_title="percona-server-5.7.29-5t-awon"
${run_cmd_script}
