#!/bin/tcsh

set data_path = /Users/akila/Desktop/OB_Data/fMRI
set data_path_t =  /Users/akila/Desktop/OB_Data


set run = narrative_cleaned_v2
set dummy = 0
set sphere = 8
set ROI_name = rebelong_conj_precuneus

set ROI = ${ROI_name}_${sphere}mm

set participants = (005 006 007 008 009 010 011 012 013 014 015 016 017 018 019 020 022 023 024 025 026 027 028 029 030 031 032 033 034 035 036 037 038 039 040 041 042 044 045 048)

#set participants = (018 019 022 023 024 025 026 027 028 029 031 032 033 034 035 036 037 041)

#set participants = (020 022 023 024 025 026 027 028 029 030 031 032 033 034 035 036 037 041)

#set participants = (018 019 022 023 024 025 026 027 028 029 030 031 032 033 034 035 036 037 041)
#set participants = (041)
foreach sub (${participants})

@ sub_num = $sub # This converts sub to a numeric value, removing leading zeros
    set sub_str = "$sub_num"
#foreach sub(48)
#foreach sub(20 22 23 24 25 26 27 28 29 30 31 32 33 35 36 37 41)
	echo $data_path
	echo $sub
	echo $run
	echo $dummy 


#set data_path_out = $data_path/Sub${sub}/${run}/sts_uncorrected_.05.feat
	
set func_data = `ls ${data_path}/OB_${sub}/*${run}.feat/filtered_func_data.nii.gz`



#	${data_path_t}/Templates/rehum_gPPI_dimensions.fsf > ${data_path}/OB_${sub}/Connectivity/PPI/${run}_dim_gPPI_1st_lvl.fsf


# echo "$reg_1" $reg_1_name


set t1_data = `ls ${data_path}/OB_${sub}/T1_c.*`
echo $func_data
echo $t1_data

set tr = `fslval ${func_data} pixdim4`
set vols = `fslval ${func_data} dim4` 

echo $tr $vols
echo ${data_path}/OB_${sub}/Connectivity/PPI/${run}_gPPI_1st_lvl.fsf

sed -e "s|###PATH###|${data_path}|g" \
	-e "s/###RUN###/${run}/g" \
	-e "s/###TR###/${tr}/g" \
	-e "s/###SUB###/${sub}/g" \
	-e "s/###SUBN###/${sub_num}/g" \
	-e "s/###ROI###/${ROI}/g" \
	-e "s/###VOLS###/${vols}/g" \
	-e "s/###DUMMY###/${dummy}/g" \
	-e "s|###FUNC_DATA###|${func_data}|g" \
	-e "s|###T1_DATA###|${t1_data}|g" \
	${data_path}/Templates/narrative_gPPI.fsf > ${data_path}/OB_${sub}/Connectivity/PPI/${run}_gPPI_1st_lvl.fsf
	end