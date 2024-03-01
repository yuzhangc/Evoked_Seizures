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

%% Plots Individual Seizures

folder_num = find({subFolders.name} == "EEG_01_2023_06_26_100_KA_THY_SST_CHR");

% Diazepam Plots
seizure = 60; time_idx = [8, 18; 25, 35; 55, 65]; filtered = 1; plot_duration = 65;
path_extract = strcat(directory,subFolders(folder_num).name,'\');
plot_select_pairs(path_extract, seizure, time_idx, plot_duration, filtered);
seizure = 62;
plot_select_pairs(path_extract, seizure, time_idx, plot_duration, filtered);

% Spontaneous Vs Evoked Plots
seizure = 35; time_idx = [12, 22; 24, 34; 46, 56]; filtered = 1; plot_duration = 65;
plot_select_pairs(path_extract, seizure, time_idx, plot_duration, filtered);
seizure = 3; time_idx = [6, 16; 18, 28; 42, 52]; 
plot_select_pairs(path_extract, seizure, time_idx, plot_duration, filtered);

%% Seizure Duration Calculations

% This particular seizure model was trained on 2023.06.26 (Animal 100)
% Seizure 49 - YZOPTOEEG  2023-07-06 13H53M_Cage1_053116.rhd
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

    % Removes One Maximum Outlier
    if strcmp(subFolders(folder_num).name, "EEG_02_2023_06_26_101_KA_THY_SST_ARCH")
        good_idx = sz_corr{1} ~= max(sz_corr{1});
        for ch = 1:length(sz_corr)
        sz_corr{ch} = sz_corr{ch}(good_idx);
        sz_lag{ch} = sz_lag{ch}(good_idx);
        sz_grp{ch} = sz_grp{ch}(good_idx,:);
        end
    end

    % Set P Value and Testing Groups - See Below - Refer to calculate_seizure_corr
    % 1 - Spontaneous Success vs Sponaneous Success
    % 2 - Spontaneous Success vs Evoked Success
    % 3 - Spontaneous Success vs Evoked Failed
    % 4 - Evoked Success vs Evoked Success
    % 5 - Evoked Success vs Evoked Failed
    % 6 - Evoked Failed vs Evoked Failed
    p_val = 0.05; grp1 = 1; grp2 = 2;

    for ch = 1:4

    disp(strcat("Channel ", num2str(ch)));
    
    % Identify Indices

    grp1_idx = sz_grp{ch}(:,3) == grp1;
    grp2_idx = sz_grp{ch}(:,3) == grp2;

    % Make Array For Testing

    test_array = nan(max(sum(grp1_idx),sum(grp2_idx)),2);
    test_array(1:sum(grp1_idx),1) = sz_corr{ch}(grp1_idx);
    test_array(1:sum(grp2_idx),2) = sz_corr{ch}(grp2_idx);

    % True Significance Value

    p_sig = p_val/((sum(grp1_idx) + sum(grp2_idx)) * (sum(grp1_idx) + sum(grp2_idx) - 1) / 2);
    
    % Ttest Only if Both Normal
    if kstest(sz_corr{ch}(grp1_idx)) & kstest(sz_corr{ch}(grp2_idx))
    
        [h,p]=ttest(test_array(:,1),test_array(:,2));
        disp(strcat("Bonferroni Correct T Test Decision: ", num2str(p < p_sig), ", Uncorrected P Value: ", num2str(p)));

    % Kruskall Wallis For ANOVA NonParametric (Sample Size Matters)
    % Mann Whitney Otherwise
    else

        p =  kruskalwallis(test_array);
        disp(strcat("Kruskal Wallis Decision: ", num2str(p < p_sig), ", Uncorrected P Value: ", num2str(p)));
        [p, h] = ranksum(test_array(:,1), test_array(:,2));
        disp(strcat("Rank Sum Decision: ", num2str(p < p_sig), ", Uncorrected P Value: ", num2str(p)));

    end

    clear grp1_idx grp2_idx test_array h p p_sig

    end

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

[final_feature_output, subdiv_index, merged_sz_duration, coeff,score] = categorization_plot_func(merged_output_array,merged_sz_parameters,seizure_duration_list,directory,subFolders,0);