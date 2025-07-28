clear all;

%subjectIDs = [20 22 23 24 25 26 28 29 30 31 32 33 35 36 37 41];

subjectIDs = [34];
% iterate over each subject ID
for subject = 1:length(subjectIDs)

    filename = sprintf('Data/Sub%d_timing_data.csv', subjectIDs(subject));

    % check if the sourcthe e file exists
    if ~isfile(filename)
        disp(['Source file ' filename ' not found.']);
        continue; % Skip to the next iteration
    end
    
    % read csv
    T = readtable(filename);
    
    % Extract data for each recording
    for i = 1:3
        recordingName = sprintf('Recording %d', i);
        recordingData = T(strcmp(T.Type, recordingName), :);

        % validate
        if isempty(recordingData)
            disp(['No data found for ' recordingName ' in ' filename]);
            continue; % Skip to the next iteration
        end

        
        strength = ones(height(recordingData), 1);
        
        % Convert the table to a matrix for writing
        matrixData = [recordingData.Start, recordingData.Duration, strength];
        
        % output filename
        outFilename = sprintf('Data/Regressors/subject_%d_Recording%d.txt', subjectIDs(subject), i); % Using .txt extension for clarity
        
        % space delimiter
        dlmwrite(outFilename, matrixData, 'delimiter', ' ', 'precision', '%.6f');

        % confirm save
        if isfile(outFilename)
            disp(['Saved: ' outFilename]);
        else
            disp(['Failed to save: ' outFilename]);
        end
    end
end
