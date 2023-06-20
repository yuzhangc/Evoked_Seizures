clear all; close all; clc;

% Change to local folder directory
directory = 'D:\';
% Generate subfolder list
complete_list = dir(directory); dirFlags = [complete_list.isdir]; subFolders = complete_list(dirFlags); clear complete_list dirFlags;

%% Parameters -------------------------------------------------------------

% Booleans
% Extracts seizures from raw data
extract_sz = 1;
% Downsamples extracted data
downsamp_sz = 1;
% Filters extracted data
filter_sz = 1;
% Plots figures and data
to_plot = 1; plot_duration = 95;

% Global Variables
% Target sampling rate
fs_EEG = 2000;
% Feature window size (s). Window displacement (s). Spectrogram frequency limit. 
winLen = 0.5; winDisp = 0.25; overlap_per = winDisp/winLen*100; freq_limits = [1 300];
% Spectrogram plot colorbar limits
colorbarlim_evoked = [-30,-0];

%% Data Extraction and Standardization of Length --------------------------

if extract_sz
    % Extraction variables
    t_before = 5; t_after = 180;
    for folder_num = 3:length(subFolders)
        path_extract = strcat(directory,subFolders(folder_num).name,'\');
        extracted_sz = extract_seizures(path_extract,t_before,t_after,2);
        % Notes to Self - Type Determines fs. Type 1 = EEG = 2000; Type 2 =
        % Recent Recordings W Baseline = 20000 (Get From Neuronexus File)
        % Keep in Mind Condition Where Laser 2 == Laser 1 & Laser 2 Delay <
        % - 1. Need to add -fs * Delay to get true start
        % Save Figure Plots of Extracted Data to Subfolder. Meaning During
        % extraction ONLY focus on rhd files.
        % Verify whether the blue channel is on 1 or 2 (it flipped during a
        % trial at some point)
        % Title should Contain All Info From Trials Spreadsheet
    end
end

clear t_before t_after path_extract folder_num evoked_sz

%% Downsamples and Filters Extracted Data ---------------------------------

if downsamp_sz
end

if filter_sz
end