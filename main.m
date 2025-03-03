clear all; close all; clc;

% Change to local folder directory
directory = 'D:\';
% Freely Moving Or Not
freely_moving = 1;
% Manual Seizure Length Determination
seizure_input = 0;
% Generate subfolder list
complete_list = dir(directory); dirFlags = [complete_list.isdir]; subFolders = complete_list(dirFlags);

% Select Folders
if not(freely_moving)
% For Head Fixed
real_folder_st = find(ismember({subFolders.name},'00000000 DO NOT PROCESS')); real_folder_end = find(ismember({subFolders.name},'99999999 END'));
else
% For Freely Moving
real_folder_st = find(ismember({subFolders.name},'99999999 END')); real_folder_end = find(ismember({subFolders.name},'EEG_END'));
end

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

%% Plots Individual Seizures

if freely_moving == 0

% Epileptic Pairs

folder_num = find({subFolders.name} == "20230211_23_KA_THY");

seizure = 35; time_idx = [8, 18; 24, 34; 36, 46]; filtered = 1; plot_duration = 50;
path_extract = strcat(directory,subFolders(folder_num).name,'\');
plot_select_pairs(path_extract, seizure, time_idx, plot_duration, filtered);

seizure = 36;
plot_select_pairs(path_extract, seizure, time_idx, plot_duration, filtered);

seizure = 47;
plot_select_pairs(path_extract, seizure, time_idx, plot_duration, filtered);

else

% Naive Plots

folder_num = find({subFolders.name} == "EEG_14_2024_01_24_110_NA_THY");
path_extract = strcat(directory,subFolders(folder_num).name,'\');

seizure = 1; time_idx = [8, 18; 22, 32; 34, 44]; filtered = 1; plot_duration = 55;
plot_select_pairs(path_extract, seizure, time_idx, plot_duration, filtered);
seizure = 22;
plot_select_pairs(path_extract, seizure, time_idx, plot_duration, filtered);

% Spontaneous Vs Evoked Plots

folder_num = find({subFolders.name} == "EEG_01_2023_06_26_100_KA_THY_SST_CHR");
path_extract = strcat(directory,subFolders(folder_num).name,'\');

seizure = 35; time_idx = [12, 22; 24, 34; 46, 56]; filtered = 1; plot_duration = 65;
plot_select_pairs(path_extract, seizure, time_idx, plot_duration, filtered);
seizure = 21; time_idx = [6, 16; 18, 28; 42, 52]; 
plot_select_pairs(path_extract, seizure, time_idx, plot_duration, filtered);

end

%% Seizure Duration Calculations and Thresholding

% Loads Seizure Model

% Different KNN models must be used since the channels and the output
% classes for seizure are different from each other.

% Seizure_model's model was trained on 2023.06.24 (Animal 37)
% Seizure 16 - 16_473nm_pow7pt2_7pt2mW_7sec_10Hz_230624_211359.rhd
% Training Function - fitcknn(X,Y) where X is merged temp_output_array and
% Y is kmeans(X,3)

% Seizure_model_spont's model was trained on 2023.06.26 (Animal 100)
% Seizure 49 - YZOPTOEEG  2023-07-06 13H53M_Cage1_053116.rhd
% Training Function - fitcknn(X,Y) where X is merged temp_output_array and
% Y is kmeans(X,3)

% subFolders = subFolders([1:8,12,13]) for Epileptic Only

if not(freely_moving)
    load('seizure_model.mat')
else
    load('seizure_model_spont.mat')
end

% Potential For Limiting Trials. Input 200 Always For Future Analysis.

displays_text_12 = ['\nDo you want to limit the analysis to certain trials?', ...
'\nEnter a maximum trial number (e.g. 20). Enter 200 for all: '];

max_trial = input(displays_text_12);

% Loads 'To Fix' File For Manual Seizure Duration Fix (~15% of Trials)

if to_fix & seizure_input ~= 1
to_fix_chart = readmatrix(strcat(directory,"To Fix.csv"));
else
to_fix_chart = [-1 -1 -1 -1 -1 -1];
end

% -------------------------------------------------------------------------

% Merged sz_parameters and output_array

if not(freely_moving)
animal_info = readtable(strcat(directory,'Animal Master Head Fixed.csv'));
else
animal_info = readtable(strcat(directory,'Animal Master.csv'));
end

merged_output_array = [];
merged_sz_parameters = [];

% Performs seizure calculation

for folder_num = 1:length(subFolders)
    
    path_extract = strcat(directory,subFolders(folder_num).name,'\');
    if seizure_input ~= 1
    [seizure_duration,min_thresh,output_array,sz_parameters] = predict_seizure_duration(path_extract,sz_model,countdown_sec,to_fix_chart,to_plot,subFolders, max_trial,seizure_input);
    else
    [seizure_duration,min_thresh,output_array,sz_parameters,to_fix_chart] = predict_seizure_duration(path_extract,sz_model,countdown_sec,to_fix_chart,to_plot,subFolders, max_trial,seizure_input);    
    end
    merged_output_array = [merged_output_array, output_array];
    merged_sz_parameters = [merged_sz_parameters; sz_parameters];
    seizure_duration_list(folder_num) = {seizure_duration};
    min_thresh_list(folder_num) = min_thresh;

    % PCA Calculation
    pca_spont = 1; % Spontaneous Vs Evoked
    pca_day = 1; % Day of Evocation
    tgt_duration = 15; % Minimum Second of Seizure to Be Included in PCA
    min_rac = 3; % Minimum Racine Scale
    t_before = 5; % T Before Used in Extract Seizure

    plot_indiv = 0; % Plot Individuals

    % Main Outputs
    pca_lengths = [];
    pca_output_array = [];

    for sz = 1:length(output_array)

        % Lengths
        if sz_parameters(sz,12) ~= -1
        sz_start = (t_before + sz_parameters(sz,12))/winDisp;
        else
        sz_start = (t_before)/winDisp;
        end
        sz_end = sz_start + seizure_duration(sz)/winDisp;

        if seizure_duration(sz) >= tgt_duration & min_rac <= sz_parameters(sz,21)
        pca_output_array = [pca_output_array,output_array{sz}(sz_start:sz_end,:)']; % Concactenates PCA Arrays
        pca_lengths = [pca_lengths;sz_end-sz_start+1]; % Concactenate Custom Lengths
        else
        pca_lengths = [pca_lengths;0]; % For No Addition
        end
    end

    % Perform PCA (The Inversion Converts it to Obs VS Feature Format)
    [coeff,score] = pca(pca_output_array');

    % CBrewer Colors
    Colorset_plot = cbrewer('qual','Set1',5);
    Colorset_plot(Colorset_plot>1) = 1;
    Colorset_plot(Colorset_plot<0) = 0;
    Colorset_edge = cbrewer('seq','Greens',max(sz_parameters(:,20)));
    Colorset_plot(Colorset_plot>1) = 1;
    Colorset_plot(Colorset_plot<0) = 0;

    % Output Colors
    colors_center = [];
    colors_outline = [];

    % Assign colors
    for sz = 1:length(output_array)

        if pca_spont == 1
            if sz_parameters(sz,8) == -1
                temp_colors = Colorset_plot(4,:);
            else
                temp_colors = Colorset_plot(5,:);
            end
        else
            temp_colors = [0,0,0];
        end

        if pca_day == 1
            if sz_parameters(sz,20) < 0
                temp_edge = [0.5, 0.5, 0.5];
            elseif sz_parameters(sz,20) > 0
                temp_edge = Colorset_edge(sz_parameters(sz,20),:);
            end
        else
            if sz_parameters(sz,20) < 0
                temp_edge = [0.5, 0.5, 0.5];
            elseif sz_parameters(sz,20) > 0
                temp_edge = [1,0,0];
            end
        end
        
        if seizure_duration(sz) >= tgt_duration & min_rac <= sz_parameters(sz,21)
        colors_center = [colors_center;repmat(temp_colors,pca_lengths(sz),1)];
        colors_outline = [colors_outline;repmat(temp_edge,pca_lengths(sz),1)];
        end

    end        

    figure;

    if not(plot_indiv)

    % Plot Combined / All Seizures 
    scatter3(score(:,1),score(:,2),score(:,3),5, colors_center,'filled')
    title(strcat("Animal: ", num2str(sz_parameters(sz,1)), " | Epileptic: ",num2str(animal_info{folder_num,5})))

    else

    % Plot Individual Seizures
    indiv_options = find(pca_lengths > 0);
    randnum = rand(1);
    while round(randnum * length(indiv_options)) == 0
        randnum = rand(1);
    end
    selected = indiv_options(round(randnum * length(indiv_options)));

    colormap(gray)
    pca_indices = sum(pca_lengths(1:selected-1)) + 1:sum(pca_lengths(1:selected-1)) + pca_lengths(selected);
    scatter3(score(pca_indices,1),score(pca_indices,2),score(pca_indices,3),25, linspace(1,10,length(pca_indices)),'filled')
    hold on
    plot3(score(pca_indices,1),score(pca_indices,2),score(pca_indices,3),'-k')
    hold off
    title(strcat("Animal: ", num2str(sz_parameters(selected,1)), " | Epileptic: ",num2str(animal_info{folder_num,5}), " | Seizure: ", num2str(sz_parameters(selected,2))))

    end
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

% Writes To Be Fixed Seizure List

if seizure_input && not(exist(strcat(directory,"To Fix.csv")))
    writematrix(to_fix_chart(2:end,:), strcat(directory,"To Fix.csv"))
elseif seizure_input
    writematrix(to_fix_chart(2:end,:), strcat(directory,"To Fix 2 Be Concactenated.csv"))
end

% Perform Plots

% The number of animals in 'Animal Master.csv' has to equal the number of
% animals that were processed.

threshold_and_success_rate_plot_func(directory,min_thresh_list,seizure_duration_list,freely_moving)

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

%% Output Data To R

if not(freely_moving)
animal_info = readtable(strcat(directory,'Animal Master Head Fixed.csv'));
else
animal_info = readtable(strcat(directory,'Animal Master.csv'));
end

% Special Case For Drug Trials. Only Export Above Threshold Ones W Pairing
drug = 0;
% Removes Second Stim Indices.
second_stim = 1;

for folder_num = 1:length(subFolders)

path_extract = strcat(directory,subFolders(folder_num).name,'\');

if folder_num == 1
[final_divided,sz_parameters,feature_list] = extract_data_R_V2(animal_info,path_extract,seizure_duration_list,[],folder_num,drug,second_stim,1);
else
[final_divided,sz_parameters,feature_list] = extract_data_R_V2(animal_info,path_extract,seizure_duration_list,feature_list,folder_num,drug,second_stim,1);
end

end

clear animal_info

%% Spontaneous Seizure Support Vector Machine Plotting

% Appends Baseline Signals

path_extract = strcat(directory,"EEG_END_BASELINE_FOR_SVM_ALL_ANIMALS",'\');
[~,~,output_array_base,sz_param_base] = predict_seizure_duration(path_extract,sz_model,0,to_fix_chart,0,subFolders,2000,0); 

svm_merged_output_array = [merged_output_array, output_array_base];
svm_merged_sz_parameters = [merged_sz_parameters; sz_param_base];

svm_values = spont_svm_characterization_v2(svm_merged_output_array,svm_merged_sz_parameters);
    
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

%% Evoked Seizures Processing - Plots By Category

[final_feature_output, subdiv_index, merged_sz_duration, coeff,score] = categorization_plot_func(merged_output_array,merged_sz_parameters,seizure_duration_list,directory,subFolders,not(freely_moving));

% Size For Figure 3C Output
set(gcf, 'Position', [469 445 636 521])

% Size For Figure 4C Output
set(gcf, 'Position', [207 516 1025 362])

% Size For Thesis Powerpoint
set(gcf, 'Position',  [501.5 586 1153 292])

% Size of Thresholding 
set(gcf, 'Position',  [680 652.5  263.5  225.5])