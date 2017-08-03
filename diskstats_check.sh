#!/bin/bash

#check_time=$(date -d '8 hour' +"%Y-%m-%d %H:%M:%S")

check_time=`date -d '8 hour' +"%Y-%m-%d %H:%M:%S"`
echo $check_time >> /tmp/diskstats
cat /proc/diskstats | grep sd >> /tmp/diskstats
