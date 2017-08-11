#!/bin/bash

date_year='2017'
date_month='07'
date_day_list=(09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31)
node_name='ceph1'

cmd='cat '

prefix='iostat'
file_path='./'

output_file="${file_path}iostat_${node_name}_all_date"

# filename example
# iostat_ceph1_2017-07-18

for date_day in ${date_day_list[@]}; do

    file_name="${prefix}_${node_name}_${date_year}-${date_month}-${date_day}"
    cmd="${cmd} ${file_path}${file_name} "

done


echo "Command to execute:"
echo ${cmd}

`${cmd} > ${output_file}`
