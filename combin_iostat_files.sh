#!/bin/bash

date_year='2017'
date_month='07'
date_day_list=(09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31)
node_name='ceph1'

cmd='cat '


for date_day in ${date_day_list[@]}; do

    file_name="iostat_${node_name}_${date_year}-${date_month}-${date_day}"
    cmd="${cmd} ./${file_name} "
done

echo ${cmd}

`${cmd} > ./iostat_${node_name}_all_date`
