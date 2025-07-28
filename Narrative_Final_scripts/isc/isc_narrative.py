import numpy as np
import nibabel as nib
from brainiak.isc import isc
import pandas as pd
import os
from nilearn import plotting, image
from brainiak.io import load_images


participant_ids = [5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 16, 17, 18, 19, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 44, 45, 48]

#participant_ids = [5, 8, 12, 13, 15, 18, 20, 23, 25, 26, 28, 30, 31, 33, 34, 35, 44, 45]

# mask
mask_name_simple = "combined_precuneus_153_154"

#brain_mask_path = f'/usr/local/fsl/data/standard/{mask_name_simple}.nii.gz'

brain_mask_path = f'/Users/akila/Desktop/OB_Data/fMRI/ROIs/{mask_name_simple}.nii.gz'

# preprocessed data
subject_files = [
    f'/Users/akila/Desktop/OB_Data/fMRI/OB_{"00" if id < 10 else "0"}{id}/narrative_cleaned_v2.feat/func_in_standard.nii.gz'
    for id in participant_ids
]


brain_mask = nib.load(brain_mask_path).get_fdata().astype(bool)

# read regressor files and block onsets/offsets
def get_block_boundaries(subject_id, num_timepoints, TR):
    blocks = {}
    reg_subject_id = int(subject_id)
    base_path = f'/Users/akila/Desktop/OB_Data/fMRI/Regressors/OB_{"00" if subject_id < 10 else "0"}{subject_id}'
    
    for i, block_name in enumerate(["belonging", "rejection", "rebelonging"], start=1):
        regressor_file = f'{base_path}/subject_{reg_subject_id}_Recording{i}.txt'
        
        if os.path.exists(regressor_file):
            reg_data = np.loadtxt(regressor_file)  # Load the regressor data
            print(f"Subject {subject_id} - Block {block_name} - Regressor Data:\n", reg_data)
            
            # start time and duration
            start_time_sec = reg_data[0]
            duration_sec = reg_data[1]
            
            # convert from secs to time pointts
            start_time = int(round(start_time_sec / TR))  # rounding
            duration = int(round(duration_sec / TR))
            stop_time = start_time + duration  # stop time
            
            # debugging
            print(f"DEBUG: Before check: Subject {subject_id}, Block {block_name}: start_time_sec={start_time_sec}, "
                  f"duration_sec={duration_sec}, start_time={start_time}, duration={duration}, stop_time={stop_time}, "
                  f"num_timepoints={num_timepoints}")

            # check stop time doesn't exceed the number of available timepoints
            if stop_time > num_timepoints:
                print(f"Warning: Stop time {stop_time} exceeds available time points ({num_timepoints}), adjusting to {num_timepoints}")
                stop_time = num_timepoints  # Adjust stop time to the maximum number of timepoints

            # check stop time is greater than start time
            if stop_time <= start_time:
                print(f"Warning: Invalid stop time {stop_time} (less than or equal to start {start_time}). Skipping this block.")
                continue

            blocks[block_name] = (start_time, stop_time)
        else:
            print(f"Regressor file not found for subject {subject_id}: {regressor_file}")
    
    return blocks

# load
all_block_boundaries = {}
all_subjects_data = []

for subject_id, func_file in zip(participant_ids, subject_files):
    print(f"Processing subject {subject_id}")
    
    func_data = next(load_images([func_file]))  # Load functional data
    func_data_array = func_data.get_fdata()  # Extract data array
    num_timepoints = func_data_array.shape[-1]  # Get the number of time points
    
    # num time points for debugging
    print(f"Subject {subject_id} - Number of timepoints: {num_timepoints}")
    
    # block boudnaries
    block_boundaries = get_block_boundaries(subject_id, num_timepoints, TR=1)  # Assuming TR = 1 as stated
    all_block_boundaries[subject_id] = block_boundaries
    
    brain_mask_img = nib.load(brain_mask_path)
    resampled_mask_img = image.resample_to_img(brain_mask_img, func_data, interpolation="nearest")
    resampled_mask = resampled_mask_img.get_fdata().astype(bool)
    
    print(f"Resampled brain mask shape: {resampled_mask.shape}")
    
    if func_data_array.ndim == 4:  # 4D data: time × x × y × z
        masked_data = func_data_array[resampled_mask, :].T  # (time, voxels)
    else:
        print(f"Error: Expected 4D functional data but got {func_data_array.ndim}D for subject {subject_id}")
        continue
    
    print(f"Masked data shape for subject {subject_id}: {masked_data.shape}")
    
    all_subjects_data.append(masked_data)

# ISC for each block
for block_name in ["belonging", "rejection", "rebelonging"]:
    block_data = []
    min_block_length = float('inf')  # minimum block length
    
    for i, sub in enumerate(participant_ids):
        subject_data = all_subjects_data[i]
        if block_name not in all_block_boundaries[sub]:
            print(f"Warning: Block {block_name} missing for subject {sub}. Skipping this block for this subject.")
            continue

        start, stop = all_block_boundaries[sub][block_name]
        
        # valid block timings
        if stop > subject_data.shape[0]:
            print(f"Warning: Stop time exceeds available time points for subject {sub}. Skipping this subject.")
            continue
        
        if start >= stop or start < 0:
            print(f"Warning: Invalid start/stop range for subject {sub} in block {block_name}.")
            continue
        
        block_slice = subject_data[start:stop]
        min_block_length = min(min_block_length, block_slice.shape[0])  # Find the minimum length
        block_data.append(block_slice)
    
    # trimmed to the same length (min_block_length)
    block_data_trimmed = [b[:min_block_length] for b in block_data]
    
    # compute ISC directly
    if len(block_data_trimmed) > 0:
        print(f"DEBUG: Block data shape for {block_name}: {[d.shape for d in block_data_trimmed]}")
        aligned_data = np.stack(block_data_trimmed, axis=-1)  # Stack along the last axis (subjects)
        print(f"DEBUG: Aligned data shape for block {block_name}: {aligned_data.shape}")
        
        # isc
        isc_result = isc(aligned_data, pairwise=False)
        isc_result = np.nan_to_num(isc_result)  # Handle NaNs
        
        isc_scores_per_subject = isc_result.mean(axis=1)
        isc_scores_df = pd.DataFrame({'Subject_ID': participant_ids, 'ISC_Score': isc_scores_per_subject})
        
        csv_file_path = f'/Users/akila/Desktop/OB_Data/fMRI/isc_scores_per_subject_{block_name}_{mask_name_simple}.csv'
        isc_scores_df.to_csv(csv_file_path, index=False)
        print(f"Saved ISC scores for block '{block_name}' to {csv_file_path}")
    else:
        print(f"Skipping ISC computation for block {block_name} due to alignment issues.")
