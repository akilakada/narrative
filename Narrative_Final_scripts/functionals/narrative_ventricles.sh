#!/bin/tcsh

set data_path = /Users/akila/Desktop/OB_Data/fMRI
set run = narrative

# Define subject IDs
set PARTICIPANTS = (005 006 007 008 009 010 011 012 013 014 015 016 017 018 019 020 022 023 024 025 026 027 028 029 030 031 032 033 034 035 036 037 038 039 040 041 042 044 045 048)

foreach sub (${PARTICIPANTS})
    echo "subject: ${sub}"
    
    # functional data and anatomical (T1) data
    set func_data = `ls ${data_path}/OB_${sub}/*narrative.nii.gz`
    set t1_data = `ls ${data_path}/OB_${sub}/T1_c.*`

    echo "Functional data: ${func_data}"
    echo "T1 data: ${t1_data}"
    
    # brain extraction 
    echo "Refining brain extraction on T1 image..."
    bet ${t1_data} ${data_path}/OB_${sub}/T1_brain_refined -f 0.4

    # transform to standard space using FNIRT
    echo "Registering T1 image to standard space..."
    flirt -in ${data_path}/OB_${sub}/T1_brain_refined.nii.gz -ref $FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz -out ${data_path}/OB_${sub}/T1_to_MNI -omat ${data_path}/OB_${sub}/T1_to_MNI.mat -bins 256 -cost corratio -dof 12
    fnirt --in=${t1_data} --aff=${data_path}/OB_${sub}/T1_to_MNI.mat --cout=${data_path}/OB_${sub}/T1_to_MNI_warp --config=T1_2_MNI152_2mm
    invwarp --warp=${data_path}/OB_${sub}/T1_to_MNI_warp --ref=${t1_data} --out=${data_path}/OB_${sub}/invwarp_MNI_to_T1
    
    # Create a ventricle mask from Harvard-Oxford atlas
    echo "Creating ventricle mask from Harvard-Oxford Atlas..."
    fslroi $FSLDIR/data/atlases/HarvardOxford/HarvardOxford-sub-prob-2mm.nii.gz ${data_path}/OB_${sub}/LVentricle 2 1
    fslroi $FSLDIR/data/atlases/HarvardOxford/HarvardOxford-sub-prob-2mm.nii.gz ${data_path}/OB_${sub}/RVentricle 13 1
    fslmaths ${data_path}/OB_${sub}/LVentricle.nii.gz -add ${data_path}/OB_${sub}/RVentricle.nii.gz -thr 0.1 -bin ${data_path}/OB_${sub}/VentricleMask

    # ventricle mask to native space
    echo "Transforming ventricle mask to native T1 space..."
    applywarp --in=${data_path}/OB_${sub}/VentricleMask.nii.gz --ref=${t1_data} --warp=${data_path}/OB_${sub}/invwarp_MNI_to_T1 --out=${data_path}/OB_${sub}/VentricleMask_native --interp=nn

    # first volume
    echo "the first volume from functional data..."
    fslroi ${func_data} ${data_path}/OB_${sub}/func_first_vol.nii.gz 0 1

    # resample ventricle mask to match functional data 
    echo "Resampling ventricle mask to match functional data dimensions..."
    flirt -in ${data_path}/OB_${sub}/VentricleMask_native.nii.gz -ref ${data_path}/OB_${sub}/func_first_vol.nii.gz -out ${data_path}/OB_${sub}/VentricleMask_resampled.nii.gz -applyxfm -init ${data_path}/OB_${sub}/T1_to_func.mat -interp nearestneighbour

    # ventricle-specific mask for CSF time series extraction
    echo "Extracting ventricle-specific CSF time series..."
    fslmeants -i ${func_data} -m ${data_path}/OB_${sub}/VentricleMask_resampled.nii.gz -o ${data_path}/OB_${sub}/ventricle_csf_timeseries.txt

    # Nuisance regression
    echo "nuisance regression"
    fsl_regfilt -i ${func_data} -d ${data_path}/OB_${sub}/ventricle_csf_timeseries.txt -f "1" -o ${data_path}/OB_${sub}/${run}_cleaned.nii.gz
    
    # Check params
    set tr = `fslval ${func_data} pixdim4`
    set vols = `fslval ${func_data} dim4`
    echo "TR: ${tr}, Volumes: ${vols}"

    # FSF file for first-level analysis
    echo "Generating FSF file for first-level analysis..."
    sed -e "s|###PATH###|${data_path}|g" \
        -e "s/###RUN###/${run}/g" \
        -e "s/###TR###/${tr}/g" \
        -e "s/###SUB###/${sub}/g" \
        -e "s/###VOLS###/${vols}/g" \
        -e "s|###FUNC_DATA###|${data_path}/OB_${sub}/${run}_cleaned.nii.gz|g" \
        -e "s|###T1_DATA###|${t1_data}|g" \
        ${data_path}/Templates/narrative_1st_lvl.fsf > ${data_path}/OB_${sub}/${run}_1st_lvl.fsf
    
    echo "Processing complete for subject: ${sub}"

end
