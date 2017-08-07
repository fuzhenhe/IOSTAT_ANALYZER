#!/bin/bash
# before start
# you might have to combin all raw output file into one file in order to shift time all together
#
# this script used to analysis r/s, w/s in output of "iostat -tx".
#   -t for add datetime; -x for detailed column info which includes r/s and w/s.
#   you might such "iostat -tx <interval> <count> >> /tmp/iostat_output" to collect data.
#   you might use cron table to collect by day in seperate file


# ===========================================================
# Define Global Variables
# ===========================================================

disk_list=(sdd sde sdf sdg sdh sdi sdj sdk)
count_req_section=(0 1 2 3 4 5 6 7 8 9 10)

# true or false
ctl_include_title_in_csv='false'


output_dir='./output/'
temp_dir='./tmp/'

date_year='2017'
date_month='07'
date_day_list=(10 11 12 13 14 15 16 17 18 19 20 21 22 23 24)

time_shift_direction="forward"  # or "backward"
time_shift_hours=8

# you have to modify the grep key base on ouput string of datetime in file
grep_datetime_key="AM\|PM"
#grep_datetime_key="^${date_year}\/"

# for calculating number of request above. 
# to match value greater than value
above200="^[2-9][0-9][0-9]\."
above250="^2[5-9][0-9]\.\|^3[0-9][0-9]\."
above300="^3[0-9][0-9]\."




# ===========================================================
# Prepare Analysis Environment
# ===========================================================

mkdir -p ${output_dir}
mkdir -p ${temp_dir}


# gnerate title file of csv file
disks_output_title="Date Time"
for disk_name in ${disk_list[@]}; do
    disks_output_title="${disks_output_title}, ${disk_name}"
done
echo "${disks_output_title}" > ${output_dir}disks_output_title


# remove date time file if exist
timefile=${temp_dir}iostat_time
new_timefile=${temp_dir}new_iostat_time
rm -rf ${timefile}
rm -rf ${new_timefile}


# verify filename arguments
file_name=${1}
if [[ -z "${file_name}" ]]; then
    echo "Error, please specify a file path as first argument." > /dev/stderr
    exit
fi
if [[ ! -f "${file_name}" ]]; then
    echo "Error, the file path specified not exist or regular file." > /dev/stderr
    exit
fi


# ===========================================================
# Functions
# ===========================================================

# shift hours and convert to 24 hours format
# global variable used
#   timefile 
#   new_timefile
#   grep_datetime_key 
function shift_hours() {
    local file_name=${1}
    local offset_direction=${2}
    local offset_hours=${3}

    echo -e "\n[ Shift hours - ${offset_direction} ${offset_hours} hours. ]"
    echo "-----------------------------------------------------------"
    #cat ${file_name} | grep "${grep_datetime_key}" | sed 's/_/ /g' > ${timefile}
    cat ${file_name} | grep "${grep_datetime_key}" > ${timefile}

    time_count=`wc -l ${timefile} | awk '{print $1}'`
    if [[ "${time_count}" -eq "0" ]]; then
        echo "Error, unable to parser date time in ${file_name}."
        exit
    else
        echo "Total ${time_count} date-time records collected."
    fi

    echo "Original Time: "
    echo "  First Time Record - " `head -n 1 ${timefile}`
    echo "  Last Time Record  - " `tail -n 1 ${timefile}`

    offset_seconds=$(( 3600 * offset_hours ))
    
    while read -r line
    do        
        timestamp=`date -d "${line}" +%s`
        
        if [[ "${offset_direction}" == "forward" ]]; then
            timestamp=$((timestamp+offset_seconds))
        elif [[ "${offset_direction}" == "backward" ]]; then
            timestamp=$((timestamp-offset_seconds))
        fi

        added_hours=`date -d "@${timestamp}" +"%Y/%m/%d %H:%M:%S"`

        echo $added_hours >> ${new_timefile}

    done < "${timefile}"
    
    echo "New Time(24 hour format): "
    echo "  First Time Record - " `head -n 1 ${new_timefile}`
    echo "  Last Time Record  - " `tail -n 1 ${new_timefile}`
    echo 
}


function insert_file_at_begin() {
    local original=${1}
    local insert_file=${2}

    cat ${insert_file} ${original} > ${original}.tmp
    rm -rf ${original}
    mv ${original}.tmp ${original}
}


# generate CSV format analysis output 
# * this function have to modified if the datetime string is not like Ex. "07/09/2017 12:00:01 AM"
# global variable used
#   timefile 
#   new_timefile
#   date_year
#   ctl_include_title_in_csv
function convert_to_csv() {
    local file_name=${1}
    local replace_year=${date_year}
    
    echo -e "\n[ Convert to csv file - include title in csv = ${ctl_include_title_in_csv} ]"
    echo "-----------------------------------------------------------"
    
    # step 1, combin date and time with underscore _
    #   first line of the file might look like below, we need to filter it out
    #       "Linux 3.14.69-2+hlinux1-amd64-hlinux (helion-cp1-ceph0001-mgmt) 	07/09/2017 	_x86_64_	(56 CPU)"
    #   grep date time and disk name line only
    echo "Step 1 ..."
    tmp_r_req_file="${temp_dir}r_req"
    tmp_w_req_file="${temp_dir}w_req"
    tmp_rw_req_file="${temp_dir}rw_req"

    cat ${file_name} | sed "s/${replace_year} /${replace_year}_/g" | awk '{print $1,$4}' | grep "${replace_year}\|sd" | grep -v "Linux" > ${tmp_r_req_file}   
    cat ${file_name} | sed "s/${replace_year} /${replace_year}_/g" | awk '{print $1,$5}' | grep "${replace_year}\|sd" | grep -v "Linux" > ${tmp_w_req_file}
    cat ${file_name} | sed "s/${replace_year} /${replace_year}_/g" | awk '{print $1,$4,$5}' | grep "${replace_year}\|sd" | grep -v "Linux" > ${tmp_rw_req_file}

    # step2, parser read, write, read+write of each disk
    #   
    echo "Step 2 ..."
    disks_read_req=""
    disks_write_req=""
    disks_read_write_req=""
    
    for disk_name in ${disk_list[@]}; do

        tmp_disk="${temp_dir}${disk_name}_read_req"
        disks_read_req="${disks_read_req} ${tmp_disk}"
        cat ${tmp_r_req_file} | grep ${disk_name}  | awk '{printf "%.2f\n", $2}'    > ${tmp_disk}

        tmp_disk="${temp_dir}${disk_name}_write_req"
        disks_write_req="${disks_write_req} ${tmp_disk}"
        cat ${tmp_w_req_file} | grep ${disk_name}  | awk '{printf "%.2f\n", $2}'    > ${tmp_disk}        

        tmp_disk="${temp_dir}${disk_name}_read_write_req"
        disks_read_write_req="${disks_read_write_req} ${tmp_disk}"
        cat ${tmp_rw_req_file} | grep ${disk_name} | awk '{printf "%.2f\n", $2+$3}' > ${tmp_disk}        

    done


    # final raw result in tab format (in temp dir)
    # combine all disks into one file
    echo "Step 3 ..."
    r_req_name="disks_r_req.csv"
    w_req_name="disks_w_req.csv"
    rw_req_name="disks_rw_req.csv"

    tmp_disks_r="${temp_dir}${r_req_name}"
    tmp_disks_w="${temp_dir}${w_req_name}"
    tmp_disks_rw="${temp_dir}${rw_req_name}"
        
    paste ${new_timefile} ${disks_read_req}  > ${tmp_disks_r}
    paste ${new_timefile} ${disks_write_req}  > ${tmp_disks_w}
    paste ${new_timefile} ${disks_read_write_req} > ${tmp_disks_rw}

    
    # final raw result in csv format (in output dir)
    echo "Final step, refining data ..."
    cat ${tmp_disks_r} | sed 's/  / /g' | sed 's/\t/, /g' | sed 's/ , /, /g' > ${output_dir}${r_req_name}
    cat ${tmp_disks_w} | sed 's/  / /g' | sed 's/\t/, /g' | sed 's/ , /, /g' > ${output_dir}${w_req_name}
    cat ${tmp_disks_rw} | sed 's/  / /g' | sed 's/\t/, /g' | sed 's/ , /, /g' > ${output_dir}${rw_req_name}

    # append disks_output_title
    if [[ "${ctl_include_title_in_csv}" == "true" ]]; then
        insert_file_at_begin "${output_dir}${r_req_name}" "${output_dir}disks_output_title"
        insert_file_at_begin "${output_dir}${w_req_name}" "${output_dir}disks_output_title"
        insert_file_at_begin "${output_dir}${rw_req_name}" "${output_dir}disks_output_title"
    fi
    
    echo "CSV output files:"
    echo "  ${output_dir}${r_req_name}"
    echo "  ${output_dir}${w_req_name}"
    echo "  ${output_dir}${rw_req_name}"

    rm -rf ${disks_output_title}
    echo
}





# core function to calculate matched record count
# used by "analysis_disk_io_request" function
function calc_io_req() {
    # set local variable from arguments
    local file_name=$1
    local disk_name=$2
    local io_type=$3
    local count_range=$4

    # 'b' for both of read and write added
    if [[ "${io_type}" == "b" ]]; then
        req_value=`cat ${file_name} | grep ${disk_name} | awk '{printf "%.2f\n", $4+$5}' | grep "${count_range}" | wc -l`
    else
        if [[ ${io_type} == "r" ]]; then
            column_position=4
        elif [[ ${io_type} == "w" ]]; then
            column_position=5
        fi
        req_value=`cat ${file_name} | grep ${disk_name} | awk -v pos=${column_position} '{printf "%.2f\n", $pos}' | grep "${count_range}" | wc -l`
    fi

    echo $req_value
}


# provide regular expression for grep command to get value range
# for 0~99, 100~199, ...etc.
# used by "analysis_disk_io_request" function
function count_range() {
    # predefin matching patten
    local postfix='[0-9][0-9]'
    local range_hundred=$1
    
    if [[ "$range_hundred" -eq "0" ]]; then
        # 0~99
        echo "^[1-9][0-9]\.\|^[0-9]\."
    elif [[ "$range_hundred" -eq "10" ]]; then
        # 1000 ~
        echo "^[1-9][0-9][0-9][0-9]\."
    else
        # 100 ~ 999
        echo "^${range_hundred}${postfix}\."
    fi
}


# analysis IO loading (r/s and w/s)
# global variable used
#   count_req_section
#   disk_list
function analysis_disk_io_request() {
    local file_name=${1}
    local io_type=${2}

    echo -e "\n[ Analysis Disk IO Request - analysis io type = ${io_type} ]"            
    echo "-----------------------------------------------------------"
    #echo "disk 0-99 100-199 200-299 300-399 400-499 500-599 600-699 700-799 800-899 900-999 1000~"
    for disk_name in ${disk_list[@]}; do

        output_list=""

        for hundred in ${count_req_section[@]}; do

            range_re=$( count_range ${hundred} )
            
            output=$( calc_io_req ${file_name} ${disk_name} ${io_type} "${range_re}" )

            output=" ${output}"
            output_list="${output_list}${output}"
        done

        echo ${disk_name} ${output_list}

    done
    echo
}


# count value above
# global variable used
#   disk_list
function calc_req_above() {
    file_name=${1}
    above_value=${2}
    
    echo -e "\n[ Calculate IO (r+w) above - patten = \"${above_value}\"  ]"
    echo "-----------------------------------------------------------"

    for disk_name in ${disk_list[@]}; do
        above=`cat ${file_name} | grep ${disk_name} | awk '{printf "%.2f\n", $4+$5}' | grep "${above_value}" | wc -l`
        echo ${disk_name} ${above}
    done
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
echo
time_now=`date`
total_record=`cat ${file_name} | grep "avg-cpu" | wc -l`

echo "==========================================================="
echo "Date Time    = ${time_now} "
echo "File Path    = ${file_name}"
echo "Record Count = ${total_record} (on each disk)"
echo "==========================================================="



# ( 1 ) generate csv file (shift_hours is required to be called before convert_to_csv)
# --------------------------------------
shift_hours ${file_name} ${time_shift_direction} ${time_shift_hours}
convert_to_csv ${file_name}



# ( 2 ) analysis IO request
# --------------------------------------
analysis_disk_io_request ${file_name} "r" | tee ${output_dir}analysis_disk_read_req
analysis_disk_io_request ${file_name} "w" | tee ${output_dir}analysis_disk_write_req
analysis_disk_io_request ${file_name} "b" | tee ${output_dir}analysis_disk_read_write_req



# ( 3 ) calculate IO request above
# --------------------------------------
calc_req_above ${file_name} ${above200} | tee ${output_dir}analysis_req_above200
