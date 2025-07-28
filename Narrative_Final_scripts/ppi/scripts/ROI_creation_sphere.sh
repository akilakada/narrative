#!/bin/tcsh

setenv FSLDIR /usr/local/fsl
source ${FSLDIR}/etc/fslconf/fsl.csh
setenv PATH ${FSLDIR}/bin:${PATH}

set data_path = "/Users/akila/Desktop/OB_Data/fMRI"


set ROI_name = ang_mtg_conj
set sphere = 8
set run = narrative_cleaned_v2

# coords
set co1 = 75
set co2 = 36
set co3 = 41

# Define location for storing the ROIs
set loc = "ROIs/single_subject"
set loc2 = "group_level"

# Participants list
#set participants = (005 006 007 008 009 010 011 012 013 014 015 016 017 018 019 020 022 023 024 025 026 027 028 029 030 031 032 033 034 035 036 037 038 039 040 041 042 044 045 048)

set participants = (005 006 007 008 009 010 011 012 013 014 015 016 017 018 019 020 022 023 024 025 026 027 028 029 030 031 032 033 034 035 036 037 038 039 040 041 042 044 045 048)

#set participants = (041)


foreach sub (${participants})
    echo "Processing subject: OB_${sub}"

    # transform from standard to functional space
    set inverse_mat = "${data_path}/OB_${sub}/${run}.feat/reg/standard2example_func.mat"
    if (! -e $inverse_mat) then
        echo "Inverse matrix not found for subject OB_${sub}, skipping..."
        continue
    endif

    # single voxel point 
    fslmaths "${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz" -mul 0 -add 1 -roi ${co1} 1 ${co2} 1 ${co3} 1 0 1 ${data_path}/${loc}/${loc2}/${ROI_name}_point_${sub}.nii.gz -odt float

    # spherical ROI around the point
    fslmaths ${data_path}/${loc}/${loc2}/${ROI_name}_point_${sub}.nii.gz -kernel sphere ${sphere} -fmean ${data_path}/${loc}/${loc2}/${ROI_name}_sphere_${sphere}_${sub}.nii.gz -odt float

    # Binarize 
    fslmaths ${data_path}/${loc}/${loc2}/${ROI_name}_sphere_${sphere}_${sub}.nii.gz -bin ${data_path}/${loc}/${loc2}/${ROI_name}_sphere_${sphere}_bin_${sub}.nii.gz

    #  binary spherical ROI to subject's functional space
    flirt -in ${data_path}/${loc}/${loc2}/${ROI_name}_sphere_${sphere}_bin_${sub}.nii.gz -ref ${data_path}/OB_${sub}/${run}.feat/reg/example_func.nii.gz -applyxfm -init $inverse_mat -out ${data_path}/${loc}/${loc2}/${ROI_name}_${sphere}mm_ob${sub}.nii.gz -interp nearestneighbour

end

echo "ROI creation complete."
