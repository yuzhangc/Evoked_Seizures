clear all; close all; clc;

% Change to local folder directory
directory = 'G:\Clone of ORG_YZ 20230710\';
% Generate subfolder list
complete_list = dir(directory); dirFlags = [complete_list.isdir]; subFolders = complete_list(dirFlags);
real_folder_st = find(ismember({subFolders.name},'00000000 DO NOT PROCESS')); real_folder_end = find(ismember({subFolders.name},'99999999 END'));
subFolders = subFolders(real_folder_st + 1:real_folder_end - 1);
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
% Spectrogram plot colorbar limits
colorbarlim_evoked = [-30,-0];
% Feature List - 1:12 include all features. Refer to calculate_features for
% more information
feature_list = [1:12];
% Band Power Ranges
bp_filters = [1, 30; 30, 300; 300, target_fs/2];
% Seizure Countdown/Cooldown Period
countdown_sec = 5;

%% Data Extraction and Standardization of Length --------------------------

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

if filter_sz && first_run
    for folder_num = 1:length(subFolders)
        path_extract = strcat(directory,subFolders(folder_num).name,'\');
        filter_downsample(path_extract,downsamp_sz,target_fs,plot_duration);
    end
end

%% Feature Calculation

if feat_calc == 1
    for folder_num = 1:length(subFolders)
        path_extract = strcat(directory,subFolders(folder_num).name,'\');
        calculate_features(path_extract,filter_sz,feature_list,winLen, winDisp, bp_filters);
    end
end

%% Seizure Duration Calculations and Thresholding

% Loads Seizure Model
% This particular seizure model was trained on 2023.06.24 (Animal 37)
% Seizure 16 - 16_473nm_pow7pt2_7pt2mW_7sec_10Hz_230624_211359.rhd
% Training Function - fitcknn(X,Y) where X is merged temp_output_array and
% Y is kmeans(X,3)

% load('seizure_model_net.mat')
% countdown_sec = 1; % See Countdown Sec Vs Accuracy Table 
%   0.0000    0.6433  (within 5 secs abs value)
%   0.2500    0.7737
%   0.5000    0.8190    0.5894 (within 1 sec abs val)
%   0.7500    0.8254    0.5970 !
%   1.0000    0.8373    0.5905
%   1.2500    0.8448 !  0.5754
%   1.5000    0.8308    0.5690
%   1.7500    0.8093
%   2.0000    0.7920
%   2.2500    0.7780
%   2.5000    0.7575
%   2.7500    0.7392
%   3.0000    0.7155
%   3.2500    0.6940
%   3.5000    0.6832
%   3.7500    0.6659
%   4.0000    0.6455
%   4.2500    0.6325
%   4.5000    0.6175

load('seizure_model.mat')
% countdown_sec = 5; % See Countdown Sec Vs Accuracy Table 
%     1.0000    0.7640  (within 5secs abs value)
%     1.2500    0.7920
%     1.5000    0.8103
%     1.7500    0.8287
%     2.0000    0.8405
%     2.2500    0.8491
%     2.5000    0.8427
%     2.7500    0.8427
%     3.0000    0.8470    0.7478 (within 1 sec abs val
%     3.2500    0.8534
%     3.5000    0.8545 !  0.7522
%     3.7500    0.8545 !
%     4.0000    0.8470    0.7543
%     4.2500    0.8394
%     4.5000    0.8384    0.7511
%     4.7500    0.8405
%     5.0000    0.8438    0.7586 !

% Loads 'To Fix' File For Manual Seizure Duration Fix (~15% of Trials)

if to_fix
to_fix_chart = readmatrix(strcat(directory,"To Fix.csv"));
else
to_fix_chart = [-1 -1 -1];
end

% -------------------------------------------------------------------------

% Merged sz_parameters and output_array

merged_output_array = [];
merged_sz_parameters = [];

% Performs seizure calculation

for folder_num = 1:length(subFolders)
    
    path_extract = strcat(directory,subFolders(folder_num).name,'\');
    [seizure_duration,min_thresh,output_array,sz_parameters] = predict_seizure_duration(path_extract,sz_model,countdown_sec,to_fix_chart,to_plot);
    merged_output_array = [merged_output_array, output_array];
    merged_sz_parameters = [merged_sz_parameters; sz_parameters];
    seizure_duration_list(folder_num) = {seizure_duration};
    min_thresh_list(folder_num) = min_thresh;

end

% Perform Plots

% The number of animals in 'Animal Master.csv' has to equal the number of
% animals that were processed.

threshold_and_success_rate_plot_func(directory,min_thresh_list,seizure_duration_list)

clear min_thresh seizure_duration to_fix_chart output_array sz_parameters

%% Evoked Seizures Processing

% Plots By Category

[final_feature_output, subdiv_index, merged_sz_duration] = categorization_plot_func(merged_output_array,merged_sz_parameters,seizure_duration_list,directory);

% Further split into responder and nonresponder

%% Spontaneous Seizure Processing

% Cross Correlation Across Seizures 

[sz_corr, sz_lag, sz_grp] = calculate_seizure_corr(path_extract, [1:4], to_plot);

% Spontaneous Seizure Neural Net Training
