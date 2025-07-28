#!/bin/tcsh


set data_path = /Users/akila/Desktop/OB_Data/fMRI

#  run type
set run = narrative_cleaned_v2

# subs
foreach sub (05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 44 45 48)

    echo "Processing subject: $sub"
    
    
    set feat_dir = ${data_path}/OB_0${sub}/${run}.feat

    
    if (! -d ${feat_dir}) then
        echo "FEAT directory not found for subject ${sub}, skipping..."
        continue
    endif

    # define paths for the relevant files
    set example_func = ${feat_dir}/filtered_func_data.nii.gz  # 4D functional data
    set standard_image = ${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz  # Standard MNI brain
    set warp_matrix = ${feat_dir}/reg/example_func2standard_warp.nii.gz  # Nonlinear warp transformation matrix
    set affine_matrix = ${feat_dir}/reg/example_func2standard.mat  # Affine transformation matrix
    set output_image = ${feat_dir}/func_in_standard.nii.gz  # Output file

    # check if the nonlinear warp matrix exists; otherwise, use the affine matrix
    if (-f ${warp_matrix}) then
        # Applywarp 
        applywarp --ref=${standard_image} \
                  --in=${example_func} \
                  --warp=${warp_matrix} \
                  --out=${output_image} \
                  --interp=spline
    else if (-f ${affine_matrix}) then
        echo "Warp matrix not found, using affine matrix for subject ${sub}."
        flirt -in ${example_func} \
              -ref ${standard_image} \
              -applyxfm -init ${affine_matrix} \
              -out ${output_image}
    else
        echo "neither warp matrix nor affine matrix found for subject ${sub}.."
        continue
    endif

    # Check if the output was created successfully
    if (-f ${output_image}) then
        echo "Generated func_in_standard for subject ${sub}."
    else
        echo "no func_in_standard for subject ${sub}."
    endif

end
