#!/bin/bash

#===================================================
# Setup Analysis Environment 
#===================================================

date_year='2017'
date_month='07'
#date_day_list=(10 11 12 13 14 15 16 17 18 19 20 21 22 23 24)
#date_day_list=(25 26 27 28 29 30)
#date_day_list=(10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30)
date_day_list=(9 10 11)
#date_day_list=(17 18 19 20 21 22 23 24 25 26 27 28 29 30)

date_middle='/'

title_prefix='title_'
host_prefix='host_'
title_file='disks_output_title'

disks_read_req_dir='./disks_read_req/'
disks_write_req_dir='./disks_write_req/'
disks_read_write_req_dir='./disks_read_write_req/'

host_read_req_dir='./host_read_req/'
host_write_req_dir='./host_write_req'
host_read_write_req_dir='./host_read_write_req/'


file_disks_r_req="disks_r_req.csv"
file_disks_w_req="disks_w_req.csv"
file_disks_rw_req="disks_rw_req.csv"


#===================================================
# Setup Analysis Environment 
#===================================================
echo "time, write, read" > ./tmp_sum_title

mkdir -p ${disks_read_req_dir}
mkdir -p ${disks_write_req_dir}
mkdir -p ${disks_read_write_req_dir}
mkdir -p ${host_read_req_dir}
mkdir -p ${host_write_req_dir}
mkdir -p ${host_read_write_req_dir}


# for calculate IO loading by day
number_of_disk=8
column_name=(time sdd sde sdf sdg sdh sdi sdj sdk)
count_section=(0 1 2 3 4 5 6 7 8 9 10)

declare -A io_stats


#===================================================
# Define Functions
#===================================================
function count_range() {
    local postfix='[0-9][0-9]'
    local range_hundred=$1
    
    if [[ "$range_hundred" -eq "0" ]]; then
        echo "^[1-9][0-9]\.\|^[0-9]\."

    elif [[ "$range_hundred" -eq "10" ]]; then
        echo "^[1-9][0-9][0-9][0-9]\."

    else
        echo "^${range_hundred}${postfix}\."

    fi
}

# analysis IO loading (r/s and w/s)
# this is different in iostat_analysis_io_req.sh
function analysis_disk_io_request() {
    filename=${1}
    day_string=${date_year}${date_middle}${date_month}${date_middle}${2}

    echo "${date_year}-${date_month}-${date_day}"

    last_column=$(( $number_of_disk + 1 ))    
    for column_num in `seq 2 ${last_column}`; do
        
        output_req_list=""
        real_column_pos=$(( ${column_num} - 1 ))
        disk_name=${column_name[${real_column_pos}]}

        for hundred in ${count_section[@]}; do
            range_re=$( count_range ${hundred} )
            
            echo "cat ${filename} | grep \"${day_string}\" | awk -F ', ' -v pos=${column_num} '{print \$pos}' | grep \"${range_re}\" | wc -l" >> ./cmd.log
            req_value=`cat ${filename} | grep "${day_string}" | awk -F ', ' -v pos=${column_num} '{print $pos}' | grep "${range_re}" | wc -l`
 
            output=" ${req_value}"
            output_req_list="${output_req_list}${output}"
            
            io_stats[${disk_name}]=$(( ${io_stats[${disk_name}]} + ${req_value} ))
        done

        echo ${disk_name} ${output_req_list}

    done
}


#===================================================
# Main
#===================================================

for date_day in ${date_day_list[@]}; do

    #------------------------------------------------------
    # Read
    #------------------------------------------------------
    filename=${file_disks_r_req}
    splited_file1="./${date_year}${date_month}${date_day}_${filename}"
    splited_file2="./${title_prefix}${date_year}${date_month}${date_day}_${filename}"
    splited_file3="./${host_prefix}${date_year}${date_month}${date_day}_${filename}"

    cat ./${filename} | grep "${date_year}${date_middle}${date_month}${date_middle}${date_day}\ " > ${splited_file1}  # retrive by date
    cat ./${title_file} ./${date_year}${date_month}${date_day}_${filename} > ${splited_file2}  # add title
    mv ${splited_file2} ${disks_read_req_dir}

    # Remove year month day and comma and space to reduce size of file
    #sed -i -- "s/${date_year}${date_middle}${date_month}${date_middle}${date_day} //" ./${title_prefix}${date_month}${date_day}_${filename}
    #sed -i -- "s/, /,/g" ./${title_prefix}${date_month}${date_day}_${filename}

    cat ./${date_year}${date_month}${date_day}_${filename} |  awk -F ',' -v OFS=',' '{print $1, $2+$3+$4+$5+$6+$7+$8+$9}' > ${splited_file3}
    
    # generate read temp file to combin with write
    #cat ./${host_prefix}${date_year}${date_month}${date_day}_${filename} | awk -F ',' '{print $2}' > ./tmp_sum_r    
    cat ${splited_file3} | awk -F ',' '{print $2}' > ./tmp_sum_r    
    rm -rf ./${date_year}${date_month}${date_day}_${filename}
    mv ${splited_file3} ${host_read_req_dir}


    #------------------------------------------------------
    # Write
    #------------------------------------------------------
    filename=${file_disks_w_req}
    splited_file1="./${date_year}${date_month}${date_day}_${filename}"
    splited_file2="./${title_prefix}${date_year}${date_month}${date_day}_${filename}"
    splited_file3="./${host_prefix}${date_year}${date_month}${date_day}_${filename}"

    cat ./${filename} | grep "${date_year}${date_middle}${date_month}${date_middle}${date_day}\ " > ${splited_file1}  # retrive by date
    cat ./${title_file} ./${date_year}${date_month}${date_day}_${filename} > ${splited_file2}  # add title
    mv ${splited_file2} ${disks_write_req_dir}

    # Remove year month day and comma and space to reduce size of file
    #sed -i -- "s/${date_year}${date_middle}${date_month}${date_middle}${date_day} //" ./${title_prefix}${date_month}${date_day}_${filename}
    #sed -i -- "s/, /,/g" ./${title_prefix}${date_month}${date_day}_${filename}

    cat ./${date_year}${date_month}${date_day}_${filename} |  awk -F ',' -v OFS=',' '{print $1, $2+$3+$4+$5+$6+$7+$8+$9}' > ${splited_file3}
    rm -rf ./${date_year}${date_month}${date_day}_${filename}
    cp ${splited_file3} ./tmp_sum_w
    mv ${splited_file3} ${host_write_req_dir}


    #------------------------------------------------------
    # combin read and write 
    #------------------------------------------------------
    splited_file4="./${host_prefix}${date_year}${date_month}${date_day}_disks_rw_req.csv"

    #paste -d ', ' ./${host_prefix}${date_year}${date_month}${date_day}_${filename} ./tmp_sum_r > ${splited_file4}
    paste -d ', ' ./tmp_sum_w ./tmp_sum_r > ${splited_file4}

    cat ./tmp_sum_title ${splited_file4} > "${splited_file4}.tmp"

    rm -rf ${splited_file4}
    mv "${splited_file4}.tmp" ${splited_file4}
    sed -i 's/\//\-/g' ${splited_file4} 
    mv ${splited_file4} ${host_read_write_req_dir}
    
    rm -rf ./tmp_sum_r
    rm -rf ./tmp_sum_w


    #------------------------------------------------------
    # calculation of disk IO request loading
    #------------------------------------------------------
    #filename=${file_disks_w_req}
    #filename=${file_disks_r_req}
    filename=${file_disks_rw_req}
    analysis_disk_io_request ${filename} ${date_day}
    echo 
    
done

# verify stats
for i in "${!io_stats[@]}"
do
  echo "key  : $i", "value: ${io_stats[$i]}"
done

rm -rf ./tmp_sum_title
