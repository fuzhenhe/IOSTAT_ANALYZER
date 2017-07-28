#!/bin/bash
# before start
# you might have to combin all raw output file into one file in order to shift time all together
#


# ===========================================================
# Define Variables
# ===========================================================

file_name=${1}


disk_list=(sdd sde sdf sdg sdh sdi sdj sdk)
count_section=(0 1 2 3 4 5 6 7 8 9 10)


output_dir='./output/'
temp_dir='./tmp/'

date_year='2017'
date_month='07'
date_day_list=(10 11 12 13 14 15 16 17 18 19 20 21 22 23 24)


# ===========================================================
# Prepare Environment
# ===========================================================
mkdir -p ${output_dir}
mkdir -p ${temp_dir}

output_title="date time, sdd, sde, sdf, sdg, sdh, sdi, sdj, sdk"
echo "${output_title}" > ${output_dir}iostat_title


# date time file
timefile=${temp_dir}iostat_time
new_timefile=${temp_dir}new_iostat_time
rm -rf ${timefile}
rm -rf ${new_timefile}


# verify arguments
if [[ -z ${file_name} ]]; then
    echo "Error. Undefined file path." > /dev/stderr
    exit
fi
#if [[ -z ${io_type} ]]; then
#    echo "Error. Undefined IO type." > /dev/stderr
#    exit
#fi





# ===========================================================
# Functions
# ===========================================================

function add_hours() {
    echo -e "\n[ add hours... ]"    
    cat ${file_name} | grep "AM\|PM" | sed 's/_/ /g' > ${timefile}

    while read -r line
    do
        #echo ${line}
        
        timestamp=`date -d "${line}" +%s`
        timestamp=$((timestamp+28800))  # add 8 hours
        add_8_hours=`date -d "@${timestamp}" +"%Y/%m/%d %H:%M:%S"`

        #echo ${add_8_hours}
        echo $add_8_hours >> ${new_timefile}

    done < "${timefile}"
    #echo ${new_timefile}
}


function calc_io_req() {

    # set argument variable
    local file_name=$1
    local disk_name=$2
    local io_type=$3
    local count_range=$4

    r_plus_w=0

    # set column position
    if [[ ${io_type} == "r" ]]; then
        column_position=4
    elif [[ ${io_type} == "w" ]]; then
        column_position=5
    elif [[ ${io_type} == "b" ]]; then
        r_plus_w=${io_type}
    fi
    

    if [[ "${r_plus_w}" == "b" ]]; then
        req_value=`cat ${file_name} | grep ${disk_name} | awk '{printf "%.2f\n", $4+$5}' | grep "${count_range}" | wc -l`
        #echo "cat ${file_name} | grep ${disk_name} | awk '{printf "%.2f\n", $4+$5}' | grep "${count_range}" | wc -l" > ./tmp_cmd

    else
        req_value=`cat ${file_name} | grep ${disk_name} | awk -v pos=${column_position} '{printf "%.2f\n", $pos}' | grep "${count_range}" | wc -l`
        #echo "cat ${file_name} | grep ${disk_name} | awk -v pos=${column_position} '{printf "%.2f\n", $pos}' | grep "${count_range}" | wc -l" > ./tmp_cmd

    fi
    
    echo $req_value
}


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


function calc_disk_req() {
    echo -e "\n[ calculate IO requests... ]"
    
    local io_type=$1
    
    # Todo: add time of first and last record
    
    time_now=`date`
    echo "==========================================================="
    echo "File name =" ${file_name} 
    echo "Date time =" ${time_now} 
    echo "IO   Type =" ${io_type}
    echo "==========================================================="

    for disk_name in ${disk_list[@]}; do

        output_list=""

        for hundred in ${count_section[@]}; do
            range_re=$( count_range ${hundred} )
            
            #echo ${file_name} ${disk_name} ${io_type} "${range_re}"
            output=$( calc_io_req ${file_name} ${disk_name} ${io_type} "${range_re}" )

            output=" ${output}"
            output_list="${output_list}${output}"
        done

        echo ${disk_name} ${output_list}

    done
}


function calc_req_above() {
    echo -e "\n[ calculate IO above 200... ]"

    echo ${file_name}
    echo "==========================================================="

    for disk_name in ${disk_list[@]}; do
        above=`cat ${file_name} | grep ${disk_name} | awk '{printf "%.2f\n", $4+$5}' | grep "^[2-9][0-9][0-9]\." | wc -l`  # above 200
        echo ${disk_name} ${above}
    done
}


function convert_req_to_csv() {
    echo -e "\n[ convert to csv... ]"   

    replace_year=${date_year}

    tmp_r_req_file="${temp_dir}r_req"
    tmp_w_req_file="${temp_dir}w_req"

    cat ${file_name} | sed "s/${replace_year} /${replace_year}_/g" | awk '{print $1,$4}' | grep "${replace_year}\|sd" | grep -v "Linux" > ${tmp_r_req_file}   
    cat ${file_name} | sed "s/${replace_year} /${replace_year}_/g" | awk '{print $1,$5}' | grep "${replace_year}\|sd" | grep -v "Linux" > ${tmp_w_req_file}

    r_disks=""
    w_disks=""
    
    for disk_name in ${disk_list[@]}; do

        tmp_disk="${temp_dir}r_${disk_name}_req"
        r_disks="${r_disks} ${tmp_disk}"
        cat ${tmp_r_req_file} | grep ${disk_name} | awk '{print $2}' > ${tmp_disk}


        tmp_disk="${temp_dir}w_${disk_name}_req"
        cat ${tmp_w_req_file} | grep ${disk_name} | awk '{print $2}' > ${tmp_disk}        
        w_disks="${w_disks} ${tmp_disk}"

    done


    # final raw result in tab format (in temp dir)
    r_req_name="disks_r_req"
    w_req_name="disks_w_req"

    tmp_disks_r="${temp_dir}${r_req_name}"
    paste ${new_timefile} ${r_disks} > ${tmp_disks_r}
    tmp_disks_w="${temp_dir}${w_req_name}"
    paste ${new_timefile} ${w_disks} > ${tmp_disks_w}
    
    
    # final raw result in csv format (in output dir)
    cat ${tmp_disks_r} | sed 's/  / /g' | sed 's/\t/, /g' | sed 's/ , /, /g' > ${output_dir}${r_req_name}.csv
    cat ${tmp_disks_w} | sed 's/  / /g' | sed 's/\t/, /g' | sed 's/ , /, /g' > ${output_dir}${w_req_name}.csv

    echo "==========================================================="
    echo ${output_dir}${r_req_name}.csv
    echo ${output_dir}${w_req_name}.csv
}


# uncompleted...
function calc_req {

    echo "disk, read req sum, write req sum"
    echo "-----------------------------------------------------------------"
    for disk_name in ${disk_list[@]}; do

        r_sum=`cat ${file_name} | grep ${disk_name} | awk '{print $4}' | paste -sd+ | bc`
        w_sum=`cat ${file_name} | grep ${disk_name} | awk '{print $5}' | paste -sd+ | bc`

        t_sum=$(( r_sum + w_sum ))
        echo ${disk_name}, sum = ${t_sum}, $r_sum, $w_sum
        echo "${disk_name}, ${r_sum} = $(( r_sum / t_sum )), ${w_sum} = $(( w_sum / t_sum ))"

    done
}


# uncompleted...
function await {

  #cat ./iostat_ceph${node} | sed 's/2017 /2017_/g' | awk '{print $1,$10,$11,$12}' | grep "2017\|sd" > ./iostat_ceph${node}_await
  cat ./iostat_ceph${node} | sed 's/2017 /2017_/g' | awk '{print $1,$10}' | grep "2017\|sd" > ./iostat_ceph${node}_await

  for i in ${disk[@]}; do
    echo parser await column of $i.
    cat ./iostat_ceph${node}_await | grep ${i} | awk '{print $2}' > ./${i}
  done

  await_file_path="${output_dir}iostat_ceph${node}_await"

  # combine
  paste ./new_iostat_time ./sdd ./sde ./sdf ./sdg ./sdh ./sdi ./sdj ./sdk > ${await_file_path}
  echo ${await_file_path}

  #cat ${await_file_path} | sed 's/  / /g' | sed 's/\t/, /g' | sed 's/, , /, /g' | sed 's/ , /, /g' > ${await_file_path}.csv
  cat ${await_file_path} | sed 's/  / /g' | sed 's/\t/, /g' | sed 's/ , /, /g' > ${await_file_path}.csv

  # split by date
  count=0
  for i in ${date_key[@]}; do
    echo $count, ${i}
    cat ${await_file_path}.csv | grep ${i} > ${await_file_path}.${date_str[${count}]}.csv.tmp
    cat ./iostat_title  ${await_file_path}.${date_str[${count}]}.csv.tmp >  ${await_file_path}.${date_str[${count}]}.csv
    count=$((count+1))
  done
}


# ===========================================================
# Main 
# ===========================================================

# ( 1 ) generate csv file
# --------------------------------------
add_hours       # add 8 hours
convert_req_to_csv



# ( 2 ) calculate IO request
# --------------------------------------
calc_disk_req "r" | tee ${output_dir}calc_disk_r_req
calc_disk_req "w" | tee ${output_dir}calc_disk_w_req
calc_disk_req "b" | tee ${output_dir}calc_disk_b_req



# ( 3 ) calculate IO request above
# --------------------------------------
calc_req_above | tee ${output_dir}calc_req_above200



# ( 4 ) sum up number of record...
# --------------------------------------
total_record=`cat ${file_name} | grep "avg-cpu" | wc -l`
echo "==========================================================="
echo -e "\nTotal: ${total_record} on each disk_list"



