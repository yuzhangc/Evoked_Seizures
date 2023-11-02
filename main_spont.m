clear all; close all; clc;

% Change to local folder directory
directory = 'G:\Clone of ORG_YZ 20231006\';
% Generate subfolder list
complete_list = dir(directory); dirFlags = [complete_list.isdir]; subFolders = complete_list(dirFlags);
real_folder_st = find(ismember({subFolders.name},'EEG_01_2023_06_26_100_KA_THY_SST_CHR')); real_folder_end = find(ismember({subFolders.name},'EEG_04_2023_07_11_103_KA_THY_PV_ARCH'));
subFolders = subFolders(real_folder_st:real_folder_end);
clear complete_list dirFlags real_folder_st real_folder_end;

%% Parameters -------------------------------------------------------------

% Booleans
% First Run? If so, extract and filter from raw data
first_run = 0;
% Extracts seizures from raw data
extract_sz = 1;
% Downsamples extracted data
downsamp_sz = 1;
% Filters extracted data
filter_sz = 1;
% Calculate Features
feat_calc = 1;
% Plots figures and data
to_plot = 0; plot_duration = 95;
% Fixes Certain Duration Calculations
to_fix = 1;

% Global Variables
% Target sampling rate
target_fs = 2000;
% Feature window size (s). Window displacement (s). Spectrogram frequency limit. 
winLen = 0.5; winDisp = 0.25; overlap_per = winDisp/winLen*100; freq_limits = [1 300];
% Feature List - 1:12 include all features. Refer to calculate_features for
% more information
feature_list = [1:12];
% Band Power Ranges
bp_filters = [1, 30; 30, 300; 300, target_fs/2];
% Seizure Countdown/Cooldown Period
countdown_sec = 5;

%% Data Extraction and Standardization of Length --------------------------

% [COPY PASTED]

if extract_sz && first_run
    % Extraction variables
    t_before = 5; t_after = 180;
    for folder_num = 1:length(subFolders)
        path_extract = strcat(directory,subFolders(folder_num).name,'\');
        extract_seizures(path_extract,t_before,t_after,plot_duration);
    end
end

clear t_before t_after folder_num

%% Downsamples and Filters Extracted Data ---------------------------------

% [COPY PASTED]

if filter_sz && first_run
    for folder_num = 1:length(subFolders)
        path_extract = strcat(directory,subFolders(folder_num).name,'\');
        filter_downsample(path_extract,downsamp_sz,target_fs,plot_duration);
    end
end

%% Feature Calculation

% [COPY PASTED]

if feat_calc == 1
    for folder_num = 1:length(subFolders)
        path_extract = strcat(directory,subFolders(folder_num).name,'\');
        calculate_features(path_extract,filter_sz,feature_list,winLen, winDisp, bp_filters);
    end
end

%% Seizure Duration Calculations

% This particular seizure model was trained on 2023.06.26 (Animal 100)
% Seizure 16 - YZOPTOEEG  2023-07-06 13H53M_Cage1_053116.rhd
% Training Function - fitcknn(X,Y) where X is merged temp_output_array and
% Y is kmeans(X,3)

load('seizure_model_spont.mat')

if to_fix
to_fix_chart = readmatrix(strcat(directory,"To Fix Spont.csv"));
else
to_fix_chart = [-1 -1 -1];
end

merged_output_array = [];
merged_sz_parameters = [];

% Performs seizure calculation

for folder_num = 1:length(subFolders)
    
    path_extract = strcat(directory,subFolders(folder_num).name,'\');
    [seizure_duration,min_thresh,output_array,sz_parameters] = predict_seizure_duration(path_extract,sz_model,countdown_sec,to_fix_chart,to_plot,subFolders);
    merged_output_array = [merged_output_array, output_array];
    merged_sz_parameters = [merged_sz_parameters; sz_parameters];
    seizure_duration_list(folder_num) = {seizure_duration};
    min_thresh_list(folder_num) = min_thresh;

end

%% Spontaneous Seizure Processing

% Cross Correlation Across Seizures Raw Waveform

for folder_num = 1:length(subFolders)
    path_extract = strcat(directory,subFolders(folder_num).name,'\');
    [sz_corr, sz_lag, sz_grp] = calculate_seizure_corr(path_extract, [1:4], to_plot);
end

%% Output Data To R

animal_info = readtable(strcat(directory,'Animal Master Freely Moving.csv'));

% Special Case For Drug Trials. Only Export Above Threshold Ones W Pairing
drug = 0;
% Removes Second Stim Indices.
second_stim = 1;

for folder_num = 1:length(subFolders)

path_extract = strcat(directory,subFolders(folder_num).name,'\');

if folder_num == 1
[final_divided,sz_parameters,feature_list] = extract_data_R_V2(animal_info,path_extract,seizure_duration_list,[],folder_num,drug,second_stim,0);
else
[final_divided,sz_parameters,feature_list] = extract_data_R_V2(animal_info,path_extract,seizure_duration_list,feature_list,folder_num,drug,second_stim,0);
end

end

clear animal_info

%% Seizure Duration / EEG Waveform Comparison

[final_feature_output, subdiv_index, merged_sz_duration] = categorization_plot_func(merged_output_array,merged_sz_parameters,seizure_duration_list,directory,subFolders,0);