#!/bin/bash

date_year='2017'
date_month='07'
date_day_list=(10 11 12 13 14 15 16 17 18 19 20 21 22 23 24)

date_middle='/'

title_prefix='title_'
sum_prefix='sum_'

echo "time, write, read" > ./tmp_sum_title


for date_day in ${date_day_list[@]}; do

    #echo $date_day

    # Read
    filename="disks_r_req.csv"
    splited_file1="./${date_year}${date_month}${date_day}_${filename}"
    splited_file2="./${title_prefix}${date_year}${date_month}${date_day}_${filename}"
    splited_file3="./${sum_prefix}${date_year}${date_month}${date_day}_${filename}"

    cat ./${filename} | grep "${date_year}${date_middle}${date_month}${date_middle}${date_day}\ " > ${splited_file1}  # retrive by date
    cat ./iostat_title ./${date_year}${date_month}${date_day}_${filename} > ${splited_file2}  # add title

    #sed -i -- "s/${date_year}-${date_month}-${date_day} //" ./${title_prefix}${date_month}${date_day}_${filename}
    #sed -i -- "s/, /,/g" ./${title_prefix}${date_month}${date_day}_${filename}

    cat ./${date_year}${date_month}${date_day}_${filename} |  awk -F ',' -v OFS=',' '{print $1, $2+$3+$4+$5+$6+$7+$8+$9}' > ${splited_file3}
    cat ./${sum_prefix}${date_year}${date_month}${date_day}_${filename} | awk -F ',' '{print $2}' > ./tmp_sum_r     # read temp file to combin with write

    rm -rf ./${date_year}${date_month}${date_day}_${filename}


    # Write
    filename="disks_w_req.csv"
    splited_file1="./${date_year}${date_month}${date_day}_${filename}"
    splited_file2="./${title_prefix}${date_year}${date_month}${date_day}_${filename}"
    splited_file3="./${sum_prefix}${date_year}${date_month}${date_day}_${filename}"

    cat ./${filename} | grep "${date_year}${date_middle}${date_month}${date_middle}${date_day}\ " > ${splited_file1}  # retrive by date
    cat ./iostat_title ./${date_year}${date_month}${date_day}_${filename} > ${splited_file2}  # add title

    #sed -i -- "s/${date_year}-${date_month}-${date_day} //" ./${title_prefix}${date_month}${date_day}_${filename}
    #sed -i -- "s/, /,/g" ./${title_prefix}${date_month}${date_day}_${filename}

    cat ./${date_year}${date_month}${date_day}_${filename} |  awk -F ',' -v OFS=',' '{print $1, $2+$3+$4+$5+$6+$7+$8+$9}' > ${splited_file3}

    rm -rf ./${date_year}${date_month}${date_day}_${filename}


    # combin sum of read and write 
    splited_file4="./${sum_prefix}${date_year}${date_month}${date_day}_disks_rw.csv"

    paste -d ', ' ./${sum_prefix}${date_year}${date_month}${date_day}_${filename} ./tmp_sum_r > ${splited_file4}

    cat ./tmp_sum_title ${splited_file4} > "${splited_file4}.tmp"

    rm -rf ${splited_file4}
    mv "${splited_file4}.tmp" ${splited_file4}
    sed -i 's/\//\-/g' ${splited_file4} 

    rm -rf ./tmp_sum_r

done

rm -rf ./tmp_sum_title
