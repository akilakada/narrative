#!/bin/tcsh

set data_path = /Users/akila/Desktop/OB_Data/fMRI


set run = narrative

#foreach sub(34)
foreach sub (05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 44 45 48)
echo $data_path
echo $sub
echo $run
#set data_path_out = $data_path/Sub${sub}/${run}/sts_uncorrected_.05.feat
if ( ${run} == narrative ) then
	set reg_1 = subject_${sub}_Recording1.csv
	set reg_1_name = belonging
	set reg_2_name = rejection
	echo $run
	set reg_2 = subject_${sub}_Recording2.csv
	set reg_3 = subject_${sub}_Recording3.csv
	set reg_3_name = rebelonging

	set func_data = `ls ${data_path}/OB_0${sub}/*narrative_cleaned.nii.gz`
	

    # subN by removing leading zero
    set subN = `echo $sub | sed 's/^0*//'`

    echo "Original sub: $sub, New subN: $subN"


else if ( ${run} == rehum_post) then
	set reg_1 = Sub${sub}_reHum_home_base_2.csv
	set reg_1_name = home
	set reg_2 = Sub${sub}_reHum_pride_base_2.csv
	set reg_2_name = pride
	set func_data = `ls ${data_path}/OB_0${sub}/*_post.nii.gz`
endif

echo "$reg_1" $reg_1_name

set t1_data = `ls ${data_path}/OB_0${sub}/T1_c.*`
echo $func_data
echo $t1_data

set tr = `fslval ${func_data} pixdim4`
set vols = `fslval ${func_data} dim4` 

echo $tr $vols

sed -e "s|###PATH###|${data_path}|g" \
	-e "s/###RUN###/${run}/g" \
	-e "s/###TR###/${tr}/g" \
	-e "s/###SUB###/${sub}/g" \
	-e "s/###SUBN###/${subN}/g" \
	-e "s/###REG_1###/${reg_1}/g" \
	-e "s/###REG_1_NAME###/${reg_1_name}/g" \
	-e "s/###REG_2###/${reg_2}/g" \
	-e "s/###REG_2_NAME###/${reg_2_name}/g" \
	-e "s/###REG_3###/${reg_3}/g" \
	-e "s/###REG_3_NAME###/${reg_3_name}/g" \
	-e "s/###VOLS###/${vols}/g" \
	-e "s|###FUNC_DATA###|${func_data}|g" \
	-e "s|###T1_DATA###|${t1_data}|g" \
	${data_path}/Templates/narrative_1st_lvl.fsf > ${data_path}/OB_0${sub}/${run}_1st_lvl_cleaned_new.fsf
	end