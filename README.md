# iostat_req_analyzer

*put split_by_date.sh to output folder.
*cd to the output folder and execute the split_by_date.sh

Sample Output 1
root@ycheng:/home/ycheng/Downloads/iostat# ./iostat_analysis_io_req.sh ./iostat_ceph1_2017_07_09to31 

===========================================================
Date Time    = 四  8月  3 16:21:55 CST 2017 
File Path    = ./iostat_ceph1_2017_07_09to31
Record Count = 186413 (on each disk)
===========================================================

[ Shift hours - forward 8 hours. ]
-----------------------------------------------------------
Total 186413 date-time records collected.
Original Time: 
  First Time Record -  07/09/2017 12:00:01 AM
  Last Time Record  -  07/31/2017 07:57:41 AM
New Time(24 hour format): 
  First Time Record -  2017/07/09 08:00:01
  Last Time Record  -  2017/07/31 15:57:41


[ Convert to csv file... ]
-----------------------------------------------------------
step 1 ...
step 2 ...
step 3 ...
final step, refining data...
csv output files...
./output/disks_r_req.csv
./output/disks_w_req.csv
./output/disks_rw_req.csv


[ Analysis Disk IO Request - analysis io type = r ]
-----------------------------------------------------------
sdd 170788 8140 5619 1738 116 6 0 0 0 2 4
sde 172465 5817 5696 2149 245 36 1 0 0 0 4
sdf 170082 7286 6175 2565 265 30 1 2 1 0 6
sdg 171448 7107 6436 1204 196 20 0 1 0 0 1
sdh 173935 4998 5161 2065 224 28 1 1 0 0 0
sdi 170756 7539 6723 1296 81 10 1 0 0 1 6
sdj 170710 6641 6498 2308 235 18 1 0 0 0 2
sdk 170276 7254 6712 2006 150 10 3 0 2 0 0


[ Analysis Disk IO Request - analysis io type = w ]
-----------------------------------------------------------
sdd 126542 56673 3081 108 8 1 0 0 0 0 0
sde 154772 30940 634 62 5 0 0 0 0 0 0
sdf 137183 47815 1287 120 8 0 0 0 0 0 0
sdg 132213 51389 2648 150 12 1 0 0 0 0 0
sdh 148832 36961 542 69 9 0 0 0 0 0 0
sdi 140824 44477 1032 72 8 0 0 0 0 0 0
sdj 137015 47952 1357 80 9 0 0 0 0 0 0
sdk 136872 47742 1728 67 4 0 0 0 0 0 0


[ Analysis Disk IO Request - analysis io type = b ]
-----------------------------------------------------------
sdd 80351 75353 24525 5551 584 39 4 0 0 0 6
sde 112344 58140 10732 4443 699 46 5 0 0 0 4
sdf 88216 74800 16443 5913 984 47 1 2 0 1 6
sdg 95859 64903 20641 4627 342 38 1 0 1 0 1
sdh 107172 63795 10538 4163 695 47 2 0 1 0 0
sdi 94276 71104 16375 4388 230 32 1 0 0 0 7
sdj 95458 66580 18042 5443 851 35 2 0 0 0 2
sdk 93865 68297 18132 5500 588 24 5 0 1 1 0


[ Calculate IO (r+w) above - patten = "^[2-9][0-9][0-9]\."  ]
-----------------------------------------------------------
sdd 30703
sde 15925
sdf 23391
sdg 25650
sdh 15446
sdi 21026
sdj 24373
sdk 24251



Sample output 2
ycheng@ycheng:~/Downloads/iostat/output$ ./split_by_day.sh 
2017-07-9
sdd 0 0 0 0 0 0 0 0 0 0 0
sde 0 0 0 0 0 0 0 0 0 0 0
sdf 0 0 0 0 0 0 0 0 0 0 0
sdg 0 0 0 0 0 0 0 0 0 0 0
sdh 0 0 0 0 0 0 0 0 0 0 0
sdi 0 0 0 0 0 0 0 0 0 0 0
sdj 0 0 0 0 0 0 0 0 0 0 0
sdk 0 0 0 0 0 0 0 0 0 0 0

2017-07-10
sdd 2132 4336 2039 127 6 0 0 0 0 0 0
sde 3562 3870 915 279 13 1 0 0 0 0 0
sdf 2524 4423 1421 260 12 0 0 0 0 0 0
sdg 3387 3827 1347 79 0 0 0 0 0 0 0
sdh 3603 4073 858 105 1 0 0 0 0 0 0
sdi 2978 4165 1238 248 11 0 0 0 0 0 0
sdj 3066 3946 1338 282 8 0 0 0 0 0 0
sdk 3110 3914 1474 141 1 0 0 0 0 0 0

2017-07-11
sdd 2849 4419 1344 28 0 0 0 0 0 0 0
sde 4767 3629 241 2 1 0 0 0 0 0 0
sdf 3236 4704 685 15 0 0 0 0 0 0 0
sdg 3842 3978 806 13 1 0 0 0 0 0 0
sdh 4258 3994 380 7 1 0 0 0 0 0 0
sdi 3602 4423 605 9 1 0 0 0 0 0 0
sdj 3641 4244 745 10 0 0 0 0 0 0 0
sdk 3776 4132 724 7 1 0 0 0 0 0 0

key  : sdg, value: 17280
key  : sdf, value: 17280
key  : sde, value: 17280
key  : sdd, value: 17280
key  : sdk, value: 17280
key  : sdj, value: 17280
key  : sdi, value: 17280
key  : sdh, value: 17280
