#!/bin/tcsh
setenv FSLDIR /usr/local/fsl
source ${FSLDIR}/etc/fslconf/fsl.csh
setenv PATH ${FSLDIR}/bin:${PATH}

# Set paths
set data_path = "/Users/akila/Desktop/OB_Data/fMRI"
set run = "narrative_contrasts"  
set output_dir = "/Users/akila/Desktop/OB_Data/fMRI/fslstats_parameter_estimates"  # Directory to save fslstats results

# masks
set masks = ("l_precuneus_bn_153" "r_precuneus_bn_154") 
set mask_output_names = ("l_precuneus_bn_153" "r_precuneus_bn_154")  

# output
mkdir -p $output_dir

set participants = (005 006 007 008 009 010 011 012 013 015 016 017 018 019 020 022 023 024 025 026 027 028 029 030 031 032 033 034 035 036 037 038 039 040 041 042 044 045 048)

# loop over each participant
foreach subj ($participants)
    # define paths for rejection and rebelonging zstat files
    set zstat_rejection = "${data_path}/OB_${subj}/${run}.feat/stats/cope7.nii.gz"
    set zstat_rebelonging = "${data_path}/OB_${subj}/${run}.feat/stats/cope7.nii.gz"

    # inverse transformation matrix from standard space to functional space
    set inverse_mat = "${data_path}/OB_${subj}/${run}.feat/reg/standard2example_func.mat"
    
    # chceck exists inverse mat
    if (! -e $inverse_mat) then
        echo "Inverse matrix not found for subject OB_${subj}, skipping..."
        continue
    endif

    # loop over each mask 
    @ mask_idx = 1
    foreach mask ($masks)
        set mask_file = "/Users/akila/Desktop/OB_Data/fMRI/ROIs/${mask}.nii.gz"
        set mask_output_name = $mask_output_names[$mask_idx]

        # Define output CSV files for each ROI (separate for rejection and rebelonging)
        set rejection_output_csv = "${output_dir}/rejection_v_rebelong_${mask_output_name}_estimates.csv"
        set rebelonging_output_csv = "${output_dir}/rebelonging_v_belong_${mask_output_name}_estimates.csv"

        if (! -e $rejection_output_csv) then
            echo "Subject_ID,${mask_output_name}" > $rejection_output_csv
        endif
        if (! -e $rebelonging_output_csv) then
            echo "Subject_ID,${mask_output_name}" > $rebelonging_output_csv
        endif

        # apply the inverse transformation to the mask
        set transformed_mask = "${output_dir}/OB_${subj}_${mask_output_name}_func_space.nii.gz"
        flirt -in $mask_file -ref "${data_path}/OB_${subj}/${run}.feat/example_func.nii.gz" -applyxfm -init $inverse_mat -out $transformed_mask

        # Extract the mean parameter estimates for the rejection condition
        set rejection_mean = `fslstats $zstat_rejection -k $transformed_mask -M`

        # extract the mean parameter estimates for the rebelonging condition
        set rebelonging_mean = `fslstats $zstat_rebelonging -k $transformed_mask -M`

        # save data
        echo "${subj},${rejection_mean}" >> $rejection_output_csv
        echo "${subj},${rebelonging_mean}" >> $rebelonging_output_csv

        
        echo "Subject OB_${subj} ${mask_output_name} rejection estimate: ${rejection_mean}"
        echo "Subject OB_${subj} ${mask_output_name} rebelonging estimate: ${rebelonging_mean}"

        @ mask_idx++
    end
end
