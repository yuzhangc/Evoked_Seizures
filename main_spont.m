clear all; close all; clc;

% Change to local folder directory
directory = 'G:\Clone of ORG_YZ 20231006\';
% Generate subfolder list
complete_list = dir(directory); dirFlags = [complete_list.isdir]; subFolders = complete_list(dirFlags);
real_folder_st = find(ismember({subFolders.name},'EEG_01_2023_06_26_100_KA_THY_SST_CHR')); real_folder_end = find(ismember({subFolders.name},'EEG_04_2023_07_11_103_KA_THY_PV_ARCH'));
subFolders = subFolders(real_folder_st:real_folder_end);
clear complete_list dirFlags real_folder_st real_folder_end;

%% Spontaneous Seizure Processing

% Cross Correlation Across Seizures Raw Waveform

for folder_num = 1:length(subFolders)
    path_extract = strcat(directory,subFolders(folder_num).name,'\');
    [sz_corr, sz_lag, sz_grp] = calculate_seizure_corr(path_extract, [1:4], to_plot);
end

%% Seizure Duration / EEG Waveform Comparison

% Seizure Model Was 3 Neighbor KNN Model