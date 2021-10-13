#!/bin/bash

#Mongodb Production Checklist for Server (RHEL)


dataMount=$1

# Assume mongodb's datafile is on /data or /DATA mount.
if [ -z "$dataMount" ]
then
    dataMount="/data"
fi

RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[;32m'

checker () {
currentValue=$1
targetValue=$2
title=$3
warningText=$4

if [ -z "$warningText" ]
then
    warningText="Check FAILED!"
fi

if  [ "$currentValue" -eq "$targetValue" ]; then
    printf "${GREEN}[PASSED]${NC} $title is set correctly.\n"
else
    printf "${RED}[ERROR]${NC}  $title is not set correctly. $warningText.\n"
fi
}

#var=$(( 1 == 1 ? 1 : 0 ))  

# Turn off transparent hugepages.
var=`cat /sys/kernel/mm/transparent_hugepage/enabled |grep '\[never\]'|wc -l`
checker $var 1 "Transparent hugepages setting"

# Check readahead settings on the devices storing your database files
dev=`df -h |grep -i ${dataMount} |awk '{print $1}'`
devRA=`blockdev --getra $dev`
var=$(( ($devRA >= 8 && $devRA <= 32) ? 1 : 0 ))
checker $var 1 "Readahead setting for data mount" "Current value is ${devRA}, need to be between 8 and 32"

# Check ulimit for mongodb user
var=`su mongodb --shell /bin/bash --command "ulimit -f" |grep unlimited | wc -l`
checker $var 1 "ulimit -f (file size)" "Need to be unlimited"

var=`su mongodb --shell /bin/bash --command "ulimit -t" |grep unlimited | wc -l`
checker $var 1 "ulimit -t (cpu time)" "Need to be unlimited"

var=`su mongodb --shell /bin/bash --command "ulimit -v" |grep unlimited | wc -l`
checker $var 1 "ulimit -v (virtual memory)" "Need to be unlimited"

var=`su mongodb --shell /bin/bash --command "ulimit -l" |grep unlimited | wc -l`
checker $var 1 "ulimit -l (locked-in-memory size)" "Need to be unlimited"

var=`su mongodb --shell /bin/bash --command "ulimit -m" |grep unlimited | wc -l`
checker $var 1 "ulimit -m (memory size)" "Need to be unlimited"

n=`su mongodb --shell /bin/bash --command "ulimit -n"`
var=$(( ($n >= 64000) ? 1 : 0 ))
checker $var 1 "ulimit -n (open files)" "Need to be no less than 64000"

u=`su mongodb --shell /bin/bash --command "ulimit -u"`
var=$(( ($u >= 64000) ? 1 : 0 ))
checker $var 1 "ulimit -u (processes/threads)" "Need to be no less than 64000"

# Use noatime for the dbPath mount point.
var=`cat /etc/fstab |grep $dev | grep noatime |wc -l`
checker $var 1 "noatime for the dbPath mount point" "Use noatime for the dbPath mount point"


# Configure sufficient file handles (fs.file-max), kernel pid limit (kernel.pid_max), maximum threads per process (kernel.threads-max), and maximum number of memory map areas per process (vm.max_map_count) 
output=`cat /proc/sys/fs/file-max`
var=$(( ($output >= 98000) ? 1 : 0 ))
checker $var 1 "fs.file-max" "Current value is ${output}. Need to be no less than 98000"

output=`cat /proc/sys/kernel/pid_max`
var=$(( ($output >= 64000) ? 1 : 0 ))
checker $var 1 "kernel.pid_max" "Current value is ${output}. Need to be no less than 64000"

output=`cat /proc/sys/kernel/threads-max`
var=$(( ($output >= 64000) ? 1 : 0 ))
checker $var 1 "kernel.threads-max" "Current value is ${output}. Need to be no less than 64000"

output=`cat /proc/sys/vm/max_map_count`
var=$(( ($output >= 128000) ? 1 : 0 ))
checker $var 1 "vm.max_map_count" "Current value is ${output}. Need to be no less than 128000"

# Set swappiness to 0 
var=`cat /proc/sys/vm/swappiness`
checker $var 0 "swappiness" "Current value is ${var}. Need to be 0"

# Set  TCP keepalive time to 300
var=`cat /proc/sys/net/ipv4/tcp_keepalive_time`
checker $var 300 "TCP keepalive time" "Current value is ${var}. Need to be 300"
