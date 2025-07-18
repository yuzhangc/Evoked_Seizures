%% Welcome & Introduction ----------------------------------------------------
% On-Demand Seizures Facilitate Rapid Screening of Therapeutics for Epilepsy
% Authors: Yuzhang Chen, Brian Litt, Flavia Vitale, Hajime Takano
% DOI: https://doi.org/10.7554/eLife.101859

% This code is to be used with the pre-processed source data below:
% SOURCE DATA LOCATION

% ----------------------------------------------------------------------------

% Clears All Variables From Workplace & Command Line Output

clear all; close all; clc;

%% KEY: Set directory to Source File Directory -------------------------------

directory = 'E:\eLife Export\';

%% General Parameters & SubFolder List Compilation ---------------------------

% Generate complete subfolder list, identify start and end of EEG data
complete_list = dir(directory); dirFlags = [complete_list.isdir]; subFolders = complete_list(dirFlags);
real_folder_st = find(ismember({subFolders.name},'EEG_000_START')); 
real_folder_end = find(ismember({subFolders.name},'EEG_999_END'));

% Select Folders & Put into List Called SubFolders
subFolders = subFolders(real_folder_st + 1:real_folder_end - 1);
clear complete_list dirFlags real_folder_st real_folder_end;

%% Parameters ----------------------------------------------------------------

% Booleans
% First Run? 0 - No; 1 - Yes
first_run = 0;
% Do Features Need to Be Calculated? 0 - No; 1 - Yes
feat_calc = 1;
% Should Figures Be Plotted? 0 - No; 1 - Yes How Long? plot_duration (s)
to_plot = 0; plot_duration = 95;

% Key Global Variables
% Sampling Rate
fs = 2000;
% Feature window size (s). Window displacement (s).
winLen = 0.5; winDisp = 0.25; overlap_per = winDisp/winLen*100;
% Feature List - 1:12 include all features. Refer to calculate_features for
% more information
feature_list = [1:12];
% Band Power Ranges (Hz)
bp_filters = [1, 30; 30, 300; 300, fs/2];
% Seizure Countdown/Cooldown Period For Automated Seizure Detection (s)
countdown_sec = 5;

%% Filters Extracted Data ----------------------------------------------------

if first_run
    for folder_num = 1:length(subFolders)
        path_extract = strcat(directory,subFolders(folder_num).name,'\');
        filter_downsample(path_extract,fs,plot_duration);
    end
end

%% Feature Calculation -------------------------------------------------------

if feat_calc && first_run
    for folder_num = 1:length(subFolders)
        path_extract = strcat(directory,subFolders(folder_num).name,'\');
        calculate_features(path_extract,1,feature_list,winLen, winDisp, bp_filters);
    end
end

%% Figure 3 A B & 4 A B - Plots of Individual Seizures -----------------------

% Figure 3 A & B - Epileptic Induction Plots

folder_num = find({subFolders.name} == "EEG_100_KA_THY_SST_CHR");
path_extract = strcat(directory,subFolders(folder_num).name,'\');

% Figure 3 A

seizure = 21; time_idx = [6, 16; 18, 28; 42, 52]; filtered = 1; plot_duration = 65;
plot_select_pairs_fig3A3B4A4B(path_extract, seizure, time_idx, plot_duration, filtered);

% Figure 3 B

seizure = 35; time_idx = [12, 22; 24, 34; 46, 56]; filtered = 1; plot_duration = 65;
plot_select_pairs_fig3A3B4A4B(path_extract, seizure, time_idx, plot_duration, filtered);

% Figure 4 A & B Naive Induction Plots

folder_num = find({subFolders.name} == "EEG_110_NA_THY");
path_extract = strcat(directory,subFolders(folder_num).name,'\');

% Figure 4 A

seizure = 1; time_idx = [8, 18; 22, 32; 34, 44]; filtered = 1; plot_duration = 55;
plot_select_pairs_fig3A3B4A4B(path_extract, seizure, time_idx, plot_duration, filtered);

% Figure 4 B

seizure = 22; time_idx = [8, 18; 22, 32; 34, 44]; filtered = 1; plot_duration = 55;
plot_select_pairs_fig3A3B4A4B(path_extract, seizure, time_idx, plot_duration, filtered);

%% Seizure Duration Calculations and Thresholding - Figure A2 B C D E --------

% Loads Seizure Model

% Seizure_model_spont's model was trained on Animal 100 % Seizure 49 
% Training Function - fitcknn(X,Y) where X is merged temp_output_array and
% Y is kmeans(X,3)

load('seizure_model_spont.mat')

max_trial = 200;

% Loads 'To Fix' File For Manual Seizure Duration Fix (~15% of Trials)

to_fix_chart = readmatrix(strcat(directory,"To Fix.csv"));

% -------------------------------------------------------------------------

% Merged sz_parameters and output_array

animal_info = readtable(strcat(directory,'Animal Master.csv'));

merged_output_array = [];
merged_sz_parameters = [];

% Performs seizure calculation

for folder_num = 1:length(subFolders)
    
    path_extract = strcat(directory,subFolders(folder_num).name,'\');
    [seizure_duration,min_thresh,output_array,sz_parameters,to_fix_chart] = predict_seizure_duration(path_extract,sz_model,countdown_sec,to_fix_chart,to_plot,subFolders, max_trial,0);    
    merged_output_array = [merged_output_array, output_array];
    merged_sz_parameters = [merged_sz_parameters; sz_parameters];
    seizure_duration_list(folder_num) = {seizure_duration};
    min_thresh_list(folder_num) = min_thresh;

end

% Threshold Comparisons

pw = [min_thresh_list.power];
pw (pw == -1 ) = NaN;
dur = [min_thresh_list.duration];
dur (dur == -1) = NaN;
ep = table2array(animal_info(:,5));

% Wilcoxon Rank Sum Test

pow_ep_vs_nv = ranksum(pw(ep == 1), pw(ep == 0))
dur_ep_vs_nv = ranksum(dur(ep == 1), dur(ep == 0))

% Epileptic Calculations

ep_pow_mean = mean(pw(ep == 1))
ep_pow_sd = std(pw(ep == 1))

ep_dur_mean = mean(dur(ep == 1))
ep_dur_sd = std(dur(ep == 1))

min_thresh_success = [min_thresh_list.avg_success];
ep_mean_success = mean(min_thresh_success(ep == 1))
ep_sd_success = std(min_thresh_success(ep == 1))

% Wilcoxon Rank Sum Test

succ_ep_vs_nv = ranksum(min_thresh_success(ep == 1), min_thresh_success(ep == 0))

% Naive Calculations

nv_pow_mean = nanmean(pw(ep == 0))
nv_pow_sd = nanstd(pw(ep == 0))

nv_dur_mean = nanmean(dur(ep == 0))
nv_dur_sd = nanstd(dur(ep == 0))

nv_mean_success = mean(min_thresh_success(ep == 0))
nv_sd_success = std(min_thresh_success(ep == 0))

% Figure A2 B C D E

% The number of animals in 'Animal Master.csv' has to equal the number of
% animals that were processed.

threshold_and_success_rate_plot_func_figA2(directory,min_thresh_list,seizure_duration_list,1)

% Overall Accuracy Within 5 Secs. Must Perform With All Animals!

num_within_5sec = sum(to_fix_chart((to_fix_chart(:,1) > 99),6));
animal_in_to_fix = size(to_fix_chart((to_fix_chart(:,1) > 99),6),1);
accuracy_within_5sec = 1 - (animal_in_to_fix - num_within_5sec)/size(merged_sz_parameters,1)

% Epileptic Only Accuracy

total = sum(merged_sz_parameters (:,1) == 111) + sum(merged_sz_parameters (:,1) == 112) + sum(merged_sz_parameters (:,1) <= 107 & merged_sz_parameters (:,1) >= 100);
fixed = sum(to_fix_chart(:,1) == 111 & to_fix_chart(:,6) == 0) + sum(to_fix_chart(:,1) == 112 & to_fix_chart(:,6) == 0) + sum(to_fix_chart(:,1) >= 100 & to_fix_chart(:,1) <= 107 & to_fix_chart(:,6) == 0);
accuracy_within_5sec_ep = 1 - fixed/total

% Naive Only Accuracy

total = sum(merged_sz_parameters (:,1) >= 113 & merged_sz_parameters (:,1) <= 116) + sum(merged_sz_parameters (:,1) <= 110 & merged_sz_parameters (:,1) >= 108);
fixed = sum(to_fix_chart(:,1) >= 113 & to_fix_chart(:,1) <= 116 & to_fix_chart(:,6) == 0) + sum(to_fix_chart(:,1) >= 108 & to_fix_chart(:,1) <= 110 & to_fix_chart(:,6) == 0);
accuracy_within_5sec_nv = 1 - fixed/total

clear min_thresh seizure_duration output_array sz_parameters animal_info

%% Output Data To R ----------------------------------------------------------

animal_info = readtable(strcat(directory,'Animal Master.csv'));

% Special Case For Drug Trials. Only Export Above Threshold Ones W Pairing
drug = 0;
% Removes Second Stim Indices.
second_stim = 1;

for folder_num = 1:length(subFolders)

path_extract = strcat(directory,subFolders(folder_num).name,'\');

if folder_num == 1
[final_divided,sz_parameters,feature_list] = extract_data_R(animal_info,path_extract,seizure_duration_list,[],folder_num,drug,second_stim,1);
else
[final_divided,sz_parameters,feature_list] = extract_data_R(animal_info,path_extract,seizure_duration_list,feature_list,folder_num,drug,second_stim,1);
end

end

clear animal_info

%% Spontaneous Seizure Support Vector Machine Plotting - Figure 3 D ----------

% Appends Baseline Signals

path_extract = strcat(directory,"EEG_END_BASELINE_FOR_SVM_ALL_ANIMALS",'\');
[~,~,output_array_base,sz_param_base] = predict_seizure_duration(path_extract,sz_model,0,to_fix_chart,0,subFolders,2000,0); 

svm_merged_output_array = [merged_output_array, output_array_base];
svm_merged_sz_parameters = [merged_sz_parameters; sz_param_base];

svm_values = spont_svm_characterization_fig3D(svm_merged_output_array,svm_merged_sz_parameters);
    
% Extracts Predictions and Ground Truth

output_values = svm_values(:,1);
true_output_values = svm_values(:,2);

% Find Indices For Truth
idx_evk = find(true_output_values == 3);
idx_failed = find(true_output_values == 2);

% True Positive
evk_accuracy = sum(output_values(idx_evk,:) == true_output_values(idx_evk,:)) / length(idx_evk) * 100

% True Negative
failed_accuracy = sum(output_values(idx_failed,:) == true_output_values(idx_failed,:)) / length(idx_failed) * 100

% Type I and Type II Errors
false_positive = sum(output_values(idx_failed,:) == 3) / length(idx_failed) * 100
false_negative = sum(output_values(idx_evk,:) == 2) / length(idx_evk) * 100

% Note: Above Values were for both epileptic and naive. Extracting only
% values of accuracy from epileptic animals (from the outputted figures)
% gives the values reported in Figure 3 E

%% Evoked Seizures Processing - Figures 3 C and 4 D --------------------------

% Figure 3 C

[final_feature_output, subdiv_index, merged_sz_duration] = spont_evok_plot_func_fig3C(merged_output_array,merged_sz_parameters,seizure_duration_list,directory,subFolders);

set(gcf, 'Position', [469 445 636 521])

% Figure 4 D
[final_feature_output, subdiv_index, merged_sz_duration] = naiv_ep_plot_func_fig4D(merged_output_array,merged_sz_parameters,seizure_duration_list,directory,subFolders,1,4);
set(gcf, 'Position', [207 516 1025 362])

[final_feature_output, subdiv_index, merged_sz_duration] = naiv_ep_plot_func_fig4D(merged_output_array,merged_sz_parameters,seizure_duration_list,directory,subFolders,5,200);
set(gcf, 'Position', [207 516 1025 362])