#!/bin/bash
# this script is used to split output file from iostat_analysis_io_req.sh by day
#


#===================================================
# Setup Analysis Environment 
#===================================================

date_year='2017'
date_month='07'
date_day_list=(09 10 11 12 13 14 15)


date_middle='/'

title_prefix='title_'
host_prefix='host_'
title_file='disks_output_title'

ctl_get_small_file='false'
output_dir='./output/'


# default output file name by iostat_analysis_io_req.sh
# modify this to reflect your output filename from iostat_analysis_io_req.sh
file_disks_r_req="disks_r_req.csv"
file_disks_w_req="disks_w_req.csv"
file_disks_rw_req="disks_rw_req.csv"


# detailed output file group folders
# ---------------------------------------
# includes each disks 
disks_read_req_dir='./split_disks_read_req/'
disks_write_req_dir='./split_disks_write_req/'
disks_read_write_req_dir='./split_disks_read_write_req/'  # not used currently


# include sum of disks only
host_read_req_dir='./split_host_read_req/'
host_write_req_dir='./split_host_write_req'
host_read_write_req_dir='./split_host_read_write_req/'


# IO loading analysis output dir
analysis_host_io_req_dir='./split_analysis_host_io_req/'


# IO loading analysis output file
host_read_req_load='./host_read_req_load'
host_write_req_load='./host_write_req_load'
host_read_write_req_load='./host_read_write_req_load'


# for calculate IO loading by day
number_of_disk=8
column_name=(time sdd sde sdf sdg sdh sdi sdj sdk)
count_section=(0 1 2 3 4 5 6 7 8 9 10)


# you may change awk column sum up base on number of disks.
awk_sum_all_disks="awk -F ',' -v OFS=',' '{printf \"%s, %.2f\n\", \$1, \$2+\$3+\$4+\$5+\$6+\$7+\$8+\$9}'"
#echo ${awk_sum_all_disks}


#===================================================
# Setup Analysis Environment 
#===================================================
echo 
echo "==========================================================="
echo "Year  - ${date_year}"
echo "Month - ${date_month}"
echo "Day   - ${date_day_list[@]}"
echo "==========================================================="
echo
echo "[ Processing Environment Setup ]"
echo "-----------------------------------------------------------"

if [[ -d "${output_dir}" ]]; then
    cd ./output/
else
    echo "Error, output directory is not found."
    exit
fi

if [[ ! -f "${file_disks_r_req}" ]]; then
    echo "${file_disks_r_req} is not exist."
    exit
fi

if [[ ! -f "${file_disks_w_req}" ]]; then
    echo "${file_disks_w_req} is not exist."
    exit
fi

if [[ ! -f "${file_disks_rw_req}" ]]; then
    echo "${file_disks_rw_req} is not exist."
    exit
fi

echo "File check pass."
echo "  ${file_disks_r_req}"
echo "  ${file_disks_w_req}"
echo "  ${file_disks_rw_req}"

rm -rf ${disks_read_req_dir} ${disks_write_req_dir} ${disks_read_write_req_dir} ${host_read_req_dir} ${host_write_req_dir} ${host_read_write_req_dir}
mkdir -p ${disks_read_req_dir}
mkdir -p ${disks_write_req_dir}
mkdir -p ${disks_read_write_req_dir}
mkdir -p ${host_read_req_dir}
mkdir -p ${host_write_req_dir}
mkdir -p ${host_read_write_req_dir}

rm -rf ${analysis_host_io_req_dir} 
mkdir -p ${analysis_host_io_req_dir}

echo "Group directory initialized."



echo "time, write, read" > ./host_io_req_title
echo "Set host IO request title file."


echo "Get record count."
echo " " `wc -l ${file_disks_r_req}`
echo " " `wc -l ${file_disks_w_req}`
echo " " `wc -l ${file_disks_rw_req}`


sync

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
    local filename=${1}
    local day_string=${2}
    local io_stasts_file="/tmp/${1}"
    
    declare -A io_stats

    last_column=$(( $number_of_disk + 1 ))    
    for column_num in `seq 2 ${last_column}`; do
        
        output_req_list=""
        real_column_pos=$(( ${column_num} - 1 ))
        disk_name=${column_name[${real_column_pos}]}

        for hundred in ${count_section[@]}; do
            range_re=$( count_range ${hundred} )
            
            #echo "cat ${filename} | grep \"${day_string}\" | awk -F ', ' -v pos=${column_num} '{print \$pos}' | grep \"${range_re}\" | wc -l" >> ./cmd.log
            req_value=`cat ${filename} | grep "${day_string}" | awk -F ', ' -v pos=${column_num} '{print $pos}' | grep "${range_re}" | wc -l`
 
            output=" ${req_value}"
            output_req_list="${output_req_list}${output}"
            
            io_stats[${disk_name}]=$(( ${io_stats[${disk_name}]} + ${req_value} ))
            
        done
        echo ${disk_name} ${output_req_list}
    done    

    disk_stats_line="  ${day_string}: "    
    for i in "${!io_stats[@]}"
    do
        disk_stats_line="${disk_stats_line}${io_stats[$i]} "
        #echo "  disk name: $i", "record count: ${io_stats[$i]}" >> ${io_stasts_file}
    done
    echo "    ${disk_stats_line}" >> ${io_stasts_file}
}


function remove_string_and_space() {
    local file_name=${1}
    local string=${2}
    
    sed -i -- "s/${string}//" ${file_name}
    sed -i -- "s/, /,/g" ${file_name}
}


function core_split_process() {
    local filename=${1}
    local date_string=${2}
    local disk_req_dir=${3}
    local host_req_dir=${4}
    local host_req_tmp=${5}

    splited_file1="./${date_year}${date_month}${date_day}_${filename}"
    splited_file2="./${title_prefix}${date_year}${date_month}${date_day}_${filename}"
    splited_file3="./${host_prefix}${date_year}${date_month}${date_day}_${filename}"

    cat ./${filename} | grep "${date_string}"          > ${splited_file1}  # retrive by date
    cat ./${title_file} ${splited_file1}               > ${splited_file2}  # add csv title
    cat ./${splited_file1} | eval ${awk_sum_all_disks} > ${splited_file3}  # sum up all value of disks

    # Remove year month day and comma and space to reduce size of file
    if [[ "${ctl_get_small_file}" == "true" ]]; then
        cp ${splited_file2} ${splited_file2}.small
        remove_string_and_space "${splited_file2}.small" "${date_string}"
    fi
    
    # dump a temp read file for combine with write (remove date time column)
    #cat ${splited_file3} | awk -F ',' '{print $2}' > ${host_req_tmp}
    cp ${splited_file3} ${host_req_tmp}

    # remove unused file
    rm -rf ${splited_file1}

    # move to group folder
    mv ${splited_file2} ${disk_req_dir}
    mv ${splited_file3} ${host_req_dir}
    
}

#===================================================
# Main Loop
#===================================================
echo
echo "[ Start split by day processing ]"
echo "-----------------------------------------------------------"

for date_day in ${date_day_list[@]}; do

    date_string="${date_year}${date_middle}${date_month}${date_middle}${date_day}"
    echo "  processing ${date_string}"
    #------------------------------------------------------
    # Read
    #------------------------------------------------------
    host_read_tmp="./${date_day}.read.tmp"
    core_split_process "${file_disks_r_req}" "${date_string}" "${disks_read_req_dir}" "${host_read_req_dir}" "${host_read_tmp}"

    #------------------------------------------------------
    # Write
    #------------------------------------------------------
    host_write_tmp="./${date_day}.write.tmp"
    core_split_process "${file_disks_w_req}" "${date_string}" "${disks_write_req_dir}" "${host_write_req_dir}" "${host_write_tmp}"


    #------------------------------------------------------
    # Read+Write
    #------------------------------------------------------
    host_read_write_tmp="./${date_day}.read_write.tmp"
    core_split_process "${file_disks_rw_req}" "${date_string}" "${disks_read_write_req_dir}" "${host_read_write_req_dir}" "${host_read_write_tmp}"


    #------------------------------------------------------
    # combin read and write
    # tmp_sum_r and tmp_sum_w 
    #------------------------------------------------------
    splited_file4="./${host_prefix}${date_year}${date_month}${date_day}_disks_rw_req.csv"

    # get value column in write file
    cat ${host_write_tmp} | awk -F ',' '{print $2}' > ${host_write_tmp}.tmp

    # paste read and write
    paste -d ', ' ${host_read_tmp} ${host_write_tmp}.tmp > ${splited_file4}

    # add title line
    cat ./host_io_req_title ${splited_file4} > "${splited_file4}.tmp"   

    # swap file name 
    rm -rf ${splited_file4}
    mv "${splited_file4}.tmp" ${splited_file4}

    # replace / to - 
    sed -i 's/\//\-/g' ${splited_file4}

    # move to group folder
    mv ${splited_file4} ${host_read_write_req_dir}
    
    # clean up all temp files    
    rm -rf ./*.tmp


    #------------------------------------------------------
    # calculation of disk IO request loading
    #------------------------------------------------------
    analysis_disk_io_request ${file_disks_w_req}  ${date_string} >> ${analysis_host_io_req_dir}${host_read_req_load}
    analysis_disk_io_request ${file_disks_r_req}  ${date_string} >> ${analysis_host_io_req_dir}${host_write_req_load}
    analysis_disk_io_request ${file_disks_rw_req} ${date_string} >> ${analysis_host_io_req_dir}${host_read_write_req_load}
     
done

rm -rf ./host_io_req_title
cd ../


echo 
echo "[ Verify IO loading stastistic ]"
echo "-----------------------------------------------------------"
echo "Read:"
cat /tmp/${file_disks_r_req}
echo "Write:"
cat /tmp/${file_disks_w_req}
echo "Read + Write:"
cat /tmp/${file_disks_rw_req}

echo 
echo "*each count of disk should be the same if calculated correctly"


rm -rf /tmp/${file_disks_r_req} 
rm -rf /tmp/${file_disks_w_req} 
rm -rf /tmp/${file_disks_rw_req} 
