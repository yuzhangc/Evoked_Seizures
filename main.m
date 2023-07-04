clear all; close all; clc;

% Change to local folder directory
directory = 'E:\';
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
        extract_seizures(path_extract,t_before,t_after);
    end
end

clear t_before t_after path_extract folder_num

%% Downsamples and Filters Extracted Data ---------------------------------

if filter_sz && first_run
    for folder_num = 1:length(subFolders)
        path_extract = strcat(directory,subFolders(folder_num).name,'\');
        filter_downsample(path_extract,downsamp_sz,target_fs);
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

load('seizure_model.mat')

% Reads Animal Master Spreadsheet
animal_info = readmatrix(strcat(directory,"Animal Master.csv"));

% Loads 'To Fix' File For Manual Seizure Duration Fix (~15% of Trials)

if to_fix
to_fix_chart = readmatrix(strcat(directory,"To Fix.csv"));
else
to_fix_chart = [-1 -1 -1];
end

% -------------------------------------------------------------------------

% Performs seizure calculation

for folder_num = 1:length(subFolders)
    
    path_extract = strcat(directory,subFolders(folder_num).name,'\');
    [seizure_duration,min_thresh,output_array] = predict_seizure_duration(path_extract,sz_model,countdown_sec,to_fix_chart,to_plot);
    seizure_duration_list(folder_num) = {seizure_duration};
    min_thresh_list(folder_num) = min_thresh;

end

clear min_thresh seizure_duration to_fix_chart output_array

% -------------------------------------------------------------------------

% Generate Plots

if to_plot
    
% Generate Output Arrays and Plot Indices
list_of_power = [min_thresh_list.power]; list_of_duration = [min_thresh_list.duration];
invalid_power = find(list_of_power == -1); invalid_duration = find(list_of_duration == -1);
bad_indices = union(invalid_power,invalid_duration); indx_to_plot = not(ismember(1:length(subFolders),bad_indices));

% Plots Threshold Power vs Threshold Duration -----------------------------

% This scatterplot plots threshold power against threshold duration (when
% both exists)

figure;
scatter(list_of_power(indx_to_plot),list_of_duration(indx_to_plot),'filled');
xlabel('Threshold Power (mW)')
ylabel('Threshold Duration (sec)')

% Distribution of Threshold Power -----------------------------------------

% This is a distribution of seizure threshold power, organized into
% epileptic (blue) and naive (yellow) histograms with equal spacing

figure;

hold on
h1 = histogram(list_of_power(list_of_power' ~= -1 & animal_info(:,5) == 1));
h1.BinWidth = 5;
h2 = histogram(list_of_power(list_of_power' ~= -1 & animal_info(:,5) == 0));
h2.BinWidth = 5;
hold off

legend ('Epileptic','Naive')
xlabel('Threshold Power (mW)')
ylabel('Count')

% This limit excludes the 25mW+ threshold, which only happened when I was
% learning to use the fiber.
xlim([5,25])

% Distribution of Threshold Duration --------------------------------------

% This is a distribution of seizure threshold power, organized into
% epileptic (blue) and naive (yellow) histograms with equal spacing

figure;

hold on
h1 = histogram(list_of_duration(list_of_duration' ~= -1 & animal_info(:,5) == 1));
h1.BinWidth = 2;
h2 = histogram(list_of_duration(list_of_duration' ~= -1 & animal_info(:,5) == 0));
h2.BinWidth = 2;
hold off

legend ('Epileptic','Naive')
xlabel('Threshold Duration (sec)')
ylabel('Count')

% Average Success Rate ----------------------------------------------------

% This plot contains epileptic data on the left and naive data on the right,
% using blue for epileptic, red for naive, and yellow for all trials
% where a threshold was not detected. If no threshold is detected, the average 
% evocation success across all trials was used. For trials with threshold, 
% percentage is the percentage success of number of above threshold trials.

% Determine epileptic, naive, and detected threshold (indx_to_plot = 1) or not
indx_to_plot_epileptic = find (indx_to_plot' == 1 & animal_info(:,5) == 1);
indx_to_plot_naive = find (indx_to_plot' == 1 & animal_info(:,5) == 0);
und_thresh_epileptic = find (indx_to_plot' == 0 & animal_info(:,5) == 1);
und_thresh_naive = find (indx_to_plot' == 0 & animal_info(:,5) == 0);

% Extracts Percent Success
avg_success_list = [min_thresh_list.avg_success];

% Scatter Plot
figure;

hold on
scatter(rand(length(indx_to_plot_epileptic),1), avg_success_list(indx_to_plot_epileptic) .* 100,'filled')
scatter(rand(length(indx_to_plot_naive),1) + 2, avg_success_list(indx_to_plot_naive) .* 100,'filled')
scatter(rand(length(und_thresh_epileptic),1), avg_success_list(und_thresh_epileptic) .* 100,'filled',"MarkerFaceColor",[0.9290 0.6940 0.1250])
scatter(rand(length(und_thresh_naive),1) + 2, avg_success_list(und_thresh_naive) .* 100,'filled',"MarkerFaceColor",[0.9290 0.6940 0.1250])
hold off

% Legends and Titles Etc
legend('Epileptic','Naive','Under Threshold','Location','southwest')
xticks([0.5, 2.5])
xticklabels({'Epileptic','Naive'})
xline(1.5,'--k');
ylabel('Success Rate (%)')
title('Stimulation Success Rate %')

clear invalid_power invalid_duration bad_indices indx_to_plot indx_to_plot_epileptic indx_to_plot_naive

end

%%

% Split data according to animal 22+ (this year's data) and epileptic or
% not epileptic
% Plot general trends of features in long seizures vs short seizures
% (further split by epileptic or non epileptic)
% Plot general trends of features in epileptic vs nonepileptic
% Plot summed trends in long vs short seizures and epileptic vs
% nonepileptic
% Further split into responder and nonresponder
% Calculate feature coherence within animals over time