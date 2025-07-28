#!/bin/tcsh
setenv FSLDIR /usr/local/fsl
source ${FSLDIR}/etc/fslconf/fsl.csh
setenv PATH ${FSLDIR}/bin:${PATH}

set data_path = "/Users/akila/Desktop/OB_Data/fMRI"
set ROI_name = rebelong_conj_precuneus
echo $ROI_name
set run = narrative_cleaned_v2
set sphere = 8


#foreach sub(109)
#foreach sub(100)
set participants = (005 006 007 008 009 010 011 012 013 014 015 016 017 018 019 020 022 023 024 025 026 027 028 029 030 031 032 033 034 035 036 037 038 039 040 041 042 044 045 048)
#set participants = (018 019 022 023 024 025 026 027 028 029 031 032 033 034 035 036 037 041)

#set participants = (018 019 022 023 024 025 026 027 028 029 030 031 032 033 034 035 036 037 041)

#set participants = (041)
#set participants = (020)

foreach sub (${participants})

echo $sub
#fslmeants -i ../Sub${sub}/Task_0${task}/Task_0${task}_no_extend.feat/filtered_func_data.nii.gz -o ../Sub${sub}/Connectivity/PPI/Task_0${task}/${ROI_name}_time.txt -m ../ROIS_2021/single_subject/sub${sub}/functional/${ROI_name}_mvpa_test_FINAL.nii.gz

fslmeants -i ${data_path}/OB_${sub}/${run}.feat/filtered_func_data.nii.gz -o ${data_path}/OB_${sub}/Connectivity/PPI/${ROI_name}_${sphere}mm_time.txt -m ${data_path}/ROIs/single_subject/group_level/${ROI_name}_${sphere}mm_ob${sub}.nii.gz

end

