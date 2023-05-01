% The purpose of this main file is not to compare between spontaneous and 
% evoked seizures but rather to compare within spontaneous seizures

clear all

directory = 'E:\';
% Do I need to extract data? If so first_run should equal 1
first_run = 0;
% Is data filtered? If not (0), should filter.
filtered = 1;
% Downsample should be always set to true, otherwise filtering takes eons.
to_downsample = 1;
% Filter Sets
filter_set = [1 30; 30 300;300 2000];
% Do I want to use normalized data? Only relevant in filtering.
normalized = 1;

% Do I want to plot data?
to_plot = 0;
% Plot Duration for Raw and Filtered Data (not for verifying filtering but
% for visualization)
plot_duration = 95;
% How many plots to plot
num_to_plot = 2;
% Folders to Plot. Write Normal (Visually Seeable Folder, Not 3 for First
% Folder)
folders_to_plot = [1,2,5,7];
% Seizures to Plot. If null, randomly chooses
% Row (Folders to Plot by Num to Plot)
evoked_sz_to_plot = [];

% Subfolder Lists
path_EEG = strcat(directory,'EEG\To Filter\');
% Get a List of Subfolders. Filter Every Subfolder
complete_list = dir(path_EEG);
% Get a logical vector that tells which is a directory.
dirFlags = [complete_list.isdir];
% Extract only those that are directories.
subFolders = complete_list(dirFlags);

% Frequency of EEG Files
fs_EEG = 2000;

% Coherence Channels
ch_coher = [3 4];

% Spectrogram
t_res = 0.5;
freq_limits =[1 300];
overlap_per = 50;
% Colorbar Limits on Spectrogram
colorbarlim_evoked = [-30,-0];

% Spectral Density
% How much after 'seizure start' do I want to move the beginning of the
% window to?
Nx_window_modifier = 0;
% Window of Spectral Density (Sec)
t_win = 5;
% Window For Feature Calculation (Sec)
winLen = t_res;
winDisp = t_res*overlap_per/100;

% Fixes Specific Seizures
to_fix = 1;
fix_folder = [8, 3; 7, 11; 7, 9; 7, 8; 5, 14; 5, 12; 4, 6; 3, 8; 3, 7; 3, 5; 3, 4];
fix_length = [17; 45.75; 39.25; 23; 88.25; 63; 63; 70.75; 70.75; 87.25; 90];

% Minor Fixes
fix_folder = [fix_folder; 10 9; 10 3; 9 5; 8 13; 8 6; 8 5; 7 14; 7 13; 7 12; 4 4; 4 1; 2 5; 1 8; 1 7; 8 11; 8 8];
fix_length = [fix_length; 16.5; 8.5; 23; 34; 19.75; 29.25; 22.25; 22; 35; 77; 60.25; 35; 42; 39; 43.75; 35.25];

% K Means
k_means_classes = 3;

% Pairings for Predictions
pairings = [5 8 6 9 7 2; 5 5 6 5 7 1; 1 5 2 4 2 2];

% Which Channel to Use For Subsections
channel_for_feature_split = 2;

%% Data Extraction and Standardization

if first_run

% Time Before Seizure Start
t_before_Neuronexus = 5;
% Frequency of EEG Files
fs_Neuronexus = 20000;
% Time After Seizure Start to Extract (same for Neuronexus and EEG)
t_after = 180;

for folder_num = 3:length(subFolders)
    path_evoked = strcat(path_EEG,subFolders(folder_num).name,'\');
    times_sequence = readmatrix(strcat(path_evoked,'00_Times.csv'));
    % First Column is Always Animal ID, Second Column is Early/Middle/End
    % of Experiment.
    % Third Column is Stim Duration, Fourth Column is Delay, Fifth Column is 2nd
    % Stim Duration
    
    evoked_stim_length = times_sequence(:,3)';
    if size(times_sequence,2) >= 4
        delay_length = times_sequence(:,4)';
    else
        delay_length = [];
    end
    if size(times_sequence,2) >= 5
        second_stim_length = times_sequence(:,5)';
    else
        second_stim_length = [];
    end
    
    % Extracts Seizures Given Parameter Above
    evoked_sz = extract_seizures(path_evoked,t_before_Neuronexus,t_after,fs_Neuronexus,2,evoked_stim_length);
    
    % Optional Plots
    if to_plot
        for i = 1:length(evoked_sz)
            figure
            hold on
            for k = 1:size(evoked_sz{i},2)
            plot(1/fs_Neuronexus:1/fs_Neuronexus:+t_before_Neuronexus+t_after,evoked_sz{i}(:,k) + (k-1)*500);
            end
            xlim([0,t_after])
            title([subFolders(folder_num).name,' Seizure # ', num2str(i)]);
            hold off
        end
    end
    
    clear amplifier_channels ans aux_input_channels board_adc_channels filename frequency_parameters
    clear notes path spike_triggers supply_voltage_channels supply_voltage_data t_amplifier t_aux_input
    clear t_board_adc t_supply_voltage aux_input_data amplifier_data board_adc_data

    save([path_evoked,'Standardized Seizure Data.mat'],'evoked_stim_length','delay_length','second_stim_length',...
        'evoked_sz','fs_Neuronexus','t_after','t_before_Neuronexus');
end

clear evoked_sz evoked_stim_length delay_length fs_Neuronexus i k t_before_Neuronexus times_sequence
clear second_stim_length path_evoked folder_num

end

%% Filters Data
if not(filtered)
    
    % Loops Through Folders and Loads Data
    for folder_num = 3:length(subFolders)
        
    path_evoked = strcat(path_EEG,subFolders(folder_num).name,'\');
    load([path_evoked,'Standardized Seizure Data.mat']);
        
    % Z Score Normalize to Baseline
    if normalized
        evoked_sz = normalize_to_max_amp(evoked_sz,t_before_Neuronexus,fs_Neuronexus);        
    end
    
    if to_plot
        for i = 1:length(evoked_sz)
            figure
            hold on
            for k = 1:size(evoked_sz{i},2)
            plot(1/fs_Neuronexus:1/fs_Neuronexus:+t_before_Neuronexus+t_after,evoked_sz{i}(:,k) + (k-1)*10);
            end
            xlim([0,t_after])
            title(['Normalized ', subFolders(folder_num).name,' Seizure # ', num2str(i)]);
            hold off
        end
    end
    
    if to_downsample
        % Downsample Normalized Data
        for sz_cnt = 1:length(evoked_sz)
            evoked_sz{sz_cnt} = downsample(evoked_sz{sz_cnt},fs_Neuronexus/fs_EEG);
        end
        fs_Neuronexus = fs_EEG;
    end
    
    % Actual Filtering
    [filtered_evoked_sz,evoked_sz] = filter_all(evoked_sz, filter_set,fs_EEG);
    
    if to_plot
        for i = 1:size(filter_set,1)
            for j = 1:size(filtered_evoked_sz{i},2)
                figure
                hold on
                for k = 1:size(evoked_sz{i},2)
                plot(1/fs_Neuronexus:1/fs_Neuronexus:+t_before_Neuronexus+t_after,filtered_evoked_sz{i}{j}(:,k) + (k-1)*10)
                end
                xlim([0,t_after])
                title([subFolders(folder_num).name,' Seizure # ',num2str(j),': Filters ',...
                    num2str(filter_set(i,1)),'Hz and ',...
                    num2str(filter_set(i,2)),'Hz bands']);
                hold off
            end
        end
    end
    
    save([path_evoked,'Filtered Seizure Data.mat'],'evoked_stim_length','delay_length','second_stim_length',...
        'evoked_sz','fs_Neuronexus','fs_EEG','t_after','t_before_Neuronexus', 'filter_set','filtered_evoked_sz')
    
    end
end

clear evoked_sz evoked_stim_length delay_length second_stim_length evoked_sz
clear fs_Neuronexus fs_EEG t_after t_before_Neuronexus filter_set filtered_evoked_sz
clear i j k folder_num

%% Plot Raw Epileptic Data

if to_plot
    
evoked_sz_to_plot = [7,1];

path_evoked = strcat(path_EEG,subFolders(evoked_sz_to_plot(1,1)+2).name,'\');
load([path_evoked,'Standardized Seizure Data.mat']);

plot_duration = 80;

figure
subplot(2,3,1:3)
norm_factor = max(abs(evoked_sz{(evoked_sz_to_plot(1,2))}));
for k = 1:size(evoked_sz{evoked_sz_to_plot(1,2)},2)
    hold on
    plot(1/fs_Neuronexus:1/fs_Neuronexus:plot_duration+t_before_Neuronexus,...
        evoked_sz{evoked_sz_to_plot(1,2)}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)...
        ./norm_factor(k)+(k-1)*1,'Color','k')
    hold off
    ylim([-1,k])
    xlim([0,t_before_Neuronexus+plot_duration])
    xlabel('Time (sec)')
end

subplot(2,3,4)
for k = 1:size(evoked_sz{evoked_sz_to_plot(1,2)},2)
    hold on
    plot(1/fs_Neuronexus:1/fs_Neuronexus:plot_duration+t_before_Neuronexus,...
        evoked_sz{evoked_sz_to_plot(1,2)}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)...
        ./norm_factor(k)+(k-1)*1,'Color','k')
    hold off
    ylim([-1,k])
    xlim([9,19])
    xlabel('Time (sec)')
end

subplot(2,3,5)
for k = 1:size(evoked_sz{evoked_sz_to_plot(1,2)},2)
    hold on
    plot(1/fs_Neuronexus:1/fs_Neuronexus:plot_duration+t_before_Neuronexus,...
        evoked_sz{evoked_sz_to_plot(1,2)}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)...
        ./norm_factor(k)+(k-1)*1,'Color','k')
    hold off
    ylim([-1,k])
    xlim([31,41])
    xlabel('Time (sec)')
end

subplot(2,3,6)
for k = 1:size(evoked_sz{evoked_sz_to_plot(1,2)},2)
    hold on
    plot(1/fs_Neuronexus:1/fs_Neuronexus:plot_duration+t_before_Neuronexus,...
        evoked_sz{evoked_sz_to_plot(1,2)}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)...
        ./norm_factor(k)+(k-1)*1,'Color','k')
    hold off
    ylim([-1,k])
    xlim([63,73])
    xlabel('Time (sec)')
end

set(gcf,'Position', [294 671.5000 1583 307.5000])

end

%% Plot Raw Naive Data

if to_plot
    
evoked_sz_to_plot = [1,6];

path_evoked = strcat(path_EEG,subFolders(evoked_sz_to_plot(1,1)+2).name,'\');
load([path_evoked,'Standardized Seizure Data.mat']);

plot_duration = 80;

figure
subplot(2,3,1:3)
norm_factor = max(abs(evoked_sz{(evoked_sz_to_plot(1,2))}));
for k = 1:size(evoked_sz{evoked_sz_to_plot(1,2)},2)
    hold on
    plot(1/fs_Neuronexus:1/fs_Neuronexus:plot_duration+t_before_Neuronexus,...
        evoked_sz{evoked_sz_to_plot(1,2)}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)...
        ./norm_factor(k)+(k-1)*1,'Color','k')
    hold off
    ylim([-1,k])
    xlim([0,t_before_Neuronexus+plot_duration])
    xlabel('Time (sec)')
end

subplot(2,3,4)
for k = 1:size(evoked_sz{evoked_sz_to_plot(1,2)},2)
    hold on
    plot(1/fs_Neuronexus:1/fs_Neuronexus:plot_duration+t_before_Neuronexus,...
        evoked_sz{evoked_sz_to_plot(1,2)}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)...
        ./norm_factor(k)+(k-1)*1,'Color','k')
    hold off
    ylim([-1,k])
    xlim([9,19])
    xlabel('Time (sec)')
end

subplot(2,3,5)
for k = 1:size(evoked_sz{evoked_sz_to_plot(1,2)},2)
    hold on
    plot(1/fs_Neuronexus:1/fs_Neuronexus:plot_duration+t_before_Neuronexus,...
        evoked_sz{evoked_sz_to_plot(1,2)}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)...
        ./norm_factor(k)+(k-1)*1,'Color','k')
    hold off
    ylim([-1,k])
    xlim([26,36])
    xlabel('Time (sec)')
end

subplot(2,3,6)
for k = 1:size(evoked_sz{evoked_sz_to_plot(1,2)},2)
    hold on
    plot(1/fs_Neuronexus:1/fs_Neuronexus:plot_duration+t_before_Neuronexus,...
        evoked_sz{evoked_sz_to_plot(1,2)}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)...
        ./norm_factor(k)+(k-1)*1,'Color','k')
    hold off
    ylim([-1,k])
    xlim([39,49])
    xlabel('Time (sec)')
end

set(gcf,'Position', [294 671.5000 1583 307.5000])

end

%% Plot Spectrogram to Show Consistency

if to_plot

evoked_sz_to_plot = [8,8;8,15];

path_evoked = strcat(path_EEG,subFolders(evoked_sz_to_plot(1,1)+2).name,'\');
load([path_evoked,'Standardized Seizure Data.mat']);

plot_duration = 55;

figure
subplot(4,1,1)
norm_factor = max(abs(evoked_sz{(evoked_sz_to_plot(1,2))}));
for k = 3
    hold on
    plot(1/fs_Neuronexus:1/fs_Neuronexus:plot_duration+t_before_Neuronexus,...
        evoked_sz{evoked_sz_to_plot(1,2)}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)...
        ./norm_factor(k),'Color','k')
    hold off
    ylim([-1,1])
    xlim([0,t_before_Neuronexus+plot_duration])
    % xlabel('Time (sec)')
    title('Evoked Seizure @ 3:30 PM')
end

subplot(4,1,3)
norm_factor = max(abs(evoked_sz{(evoked_sz_to_plot(2,2))}));
for k = 3
    hold on
    plot(1/fs_Neuronexus:1/fs_Neuronexus:plot_duration+t_before_Neuronexus,...
        evoked_sz{evoked_sz_to_plot(2,2)}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)...
        ./norm_factor(k),'Color','k')
    hold off
    ylim([-1,1])
    xlim([0,t_before_Neuronexus+plot_duration])
    % xlabel('Time (sec)')
    title('9 Evoked Seizures Later @ 5:00 PM')
end

subplot(4,1,2)
pspectrum(evoked_sz{evoked_sz_to_plot(1,2)}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)...
        ,fs_Neuronexus,'spectrogram', 'FrequencyLimits',freq_limits,'TimeResolution',t_res,'OverlapPercent',overlap_per)
        
colormap('winter')
caxis([0,40])
colorbar off
title('')
xlabel('')
ylabel('')

subplot(4,1,4)
pspectrum(evoked_sz{evoked_sz_to_plot(2,2)}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)...
        ,fs_Neuronexus,'spectrogram', 'FrequencyLimits',freq_limits,'TimeResolution',t_res,'OverlapPercent',overlap_per)
        
colormap('winter')
caxis([0,40])
colorbar off
title('')
xlabel('Time (sec)')
ylabel('')

set(gcf,'Position', [81 434.5000 845.5000 544.5000])
end

%% Diazepam Plots

if to_plot
    
evoked_sz_to_plot = [3,3];

path_evoked = strcat(path_EEG,subFolders(evoked_sz_to_plot(1,1)+2).name,'\');
load([path_evoked,'Standardized Seizure Data.mat']);

plot_duration = 55;

figure
subplot(4,1,1)
norm_factor = max(abs(evoked_sz{(evoked_sz_to_plot(1,2))}));
for k = 3
    hold on
    plot(1/fs_Neuronexus:1/fs_Neuronexus:plot_duration+t_before_Neuronexus,...
        evoked_sz{evoked_sz_to_plot(1,2)}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)...
        ./norm_factor(k),'Color','k')
    hold off
    ylim([-1,1])
    xlim([0,t_before_Neuronexus+plot_duration])
    % xlabel('Time (sec)')
end

subplot(4,1,2)
pspectrum(evoked_sz{evoked_sz_to_plot(1,2)}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)...
        ,fs_Neuronexus,'spectrogram', 'FrequencyLimits',freq_limits,'TimeResolution',t_res,'OverlapPercent',overlap_per)
        
colormap('winter')
caxis([0,40])
colorbar off
title('')
xlabel('')
ylabel('')

subplot(4,1,3)
modded_read_Intan_RHD2000_file('26_DIAZ_25mins_230327_194615.rhd','E:\20230327 isofluor KA Thy1-ChR2\');
x_temp = find(board_adc_data(1,:) > 3,1) - t_before_Neuronexus * fs_Neuronexus
plot(0:1/fs_Neuronexus:t_before_Neuronexus+plot_duration,amplifier_data(3,x_temp:x_temp+fs_Neuronexus*(t_before_Neuronexus+plot_duration))./max(amplifier_data(3,x_temp:x_temp+fs_Neuronexus*(t_before_Neuronexus+plot_duration))),'Color',[0 0 0]);

subplot(4,1,4)
pspectrum(amplifier_data(3,x_temp:x_temp+fs_Neuronexus*(t_before_Neuronexus+plot_duration))...
        ,fs_Neuronexus,'spectrogram', 'FrequencyLimits',freq_limits,'TimeResolution',t_res,'OverlapPercent',overlap_per)
        
colormap('winter')
caxis([0,40])
colorbar off
title('')
xlabel('Time (sec)')
ylabel('')

set(gcf,'Position', [81 655 1.0295e+03 324])
end

%% Some Working Ones

if to_plot

evoked_sz_to_plot = [1,2;2,2];

path_evoked = strcat(path_EEG,subFolders(evoked_sz_to_plot(1,1)+2).name,'\');
load([path_evoked,'Standardized Seizure Data.mat']);

plot_duration = 55;

figure
subplot(4,1,1)
norm_factor = max(abs(evoked_sz{(evoked_sz_to_plot(1,2))}));
for k = 1
    hold on
    plot(1/fs_Neuronexus:1/fs_Neuronexus:plot_duration+t_before_Neuronexus,...
        evoked_sz{evoked_sz_to_plot(1,2)}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)...
        ./norm_factor(k),'Color','k')
    hold off
    ylim([-1,1])
    xlim([0,t_before_Neuronexus+plot_duration])
    % xlabel('Time (sec)')
end

subplot(4,1,2)
pspectrum(evoked_sz{evoked_sz_to_plot(1,2)}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)...
        ,fs_Neuronexus,'spectrogram', 'FrequencyLimits',freq_limits,'TimeResolution',t_res,'OverlapPercent',overlap_per)
        
colormap('winter')
caxis([0,40])
colorbar off
title('')
xlabel('')
ylabel('')

path_evoked = strcat(path_EEG,subFolders(evoked_sz_to_plot(2,1)+2).name,'\');
load([path_evoked,'Standardized Seizure Data.mat']);

subplot(4,1,3)
norm_factor = max(abs(evoked_sz{(evoked_sz_to_plot(2,2))}));
for k = 1
    hold on
    plot(1/fs_Neuronexus:1/fs_Neuronexus:plot_duration+t_before_Neuronexus,...
        evoked_sz{evoked_sz_to_plot(2,2)}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)...
        ./norm_factor(k),'Color','k')
    hold off
    ylim([-1,1])
    xlim([0,t_before_Neuronexus+plot_duration])
    % xlabel('Time (sec)')
end

subplot(4,1,4)
pspectrum(evoked_sz{evoked_sz_to_plot(2,2)}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)...
        ,fs_Neuronexus,'spectrogram', 'FrequencyLimits',freq_limits,'TimeResolution',t_res,'OverlapPercent',overlap_per)
        
colormap('winter')
caxis([0,40])
colorbar off
title('')
xlabel('Time (sec)')
ylabel('')

set(gcf,'Position', [81 655 1.0295e+03 324])
end

%% Some Worseners

if to_plot

evoked_sz_to_plot = [5,8;6,9];

path_evoked = strcat(path_EEG,subFolders(evoked_sz_to_plot(1,1)+2).name,'\');
load([path_evoked,'Standardized Seizure Data.mat']);

plot_duration = 55;

figure
subplot(4,1,1)
norm_factor = max(abs(evoked_sz{(evoked_sz_to_plot(1,2))}));
for k = 1
    hold on
    plot(1/fs_Neuronexus:1/fs_Neuronexus:plot_duration+t_before_Neuronexus,...
        evoked_sz{evoked_sz_to_plot(1,2)}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)...
        ./norm_factor(k),'Color','k')
    hold off
    ylim([-1,1])
    xlim([0,t_before_Neuronexus+plot_duration])
    % xlabel('Time (sec)')
end

subplot(4,1,2)
pspectrum(evoked_sz{evoked_sz_to_plot(1,2)}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)...
        ,fs_Neuronexus,'spectrogram', 'FrequencyLimits',freq_limits,'TimeResolution',t_res,'OverlapPercent',overlap_per)
        
colormap('winter')
caxis([0,40])
colorbar off
title('')
xlabel('')
ylabel('')

path_evoked = strcat(path_EEG,subFolders(evoked_sz_to_plot(2,1)+2).name,'\');
load([path_evoked,'Standardized Seizure Data.mat']);

subplot(4,1,3)
norm_factor = max(abs(evoked_sz{(evoked_sz_to_plot(2,2))}));
for k = 1
    hold on
    plot(1/fs_Neuronexus:1/fs_Neuronexus:plot_duration+t_before_Neuronexus,...
        evoked_sz{evoked_sz_to_plot(2,2)}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)...
        ./norm_factor(k),'Color','k')
    hold off
    ylim([-1,1])
    xlim([0,t_before_Neuronexus+plot_duration])
    % xlabel('Time (sec)')
end

subplot(4,1,4)
pspectrum(evoked_sz{evoked_sz_to_plot(2,2)}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)...
        ,fs_Neuronexus,'spectrogram', 'FrequencyLimits',freq_limits,'TimeResolution',t_res,'OverlapPercent',overlap_per)
        
colormap('winter')
caxis([0,40])
colorbar off
title('')
xlabel('Time (sec)')
ylabel('')

set(gcf,'Position', [81 655 1.0295e+03 324])
end

%% Plot Normalized to 1 (Of the Z Score Plots)

if isempty(evoked_sz_to_plot) 
    generate_random = 1;
else
    generate_random = 0;
end

for folder_num = 1:length(folders_to_plot)
    
% Loads Files
path_evoked = strcat(path_EEG,subFolders(folders_to_plot(folder_num)+2).name,'\');
load([path_evoked,'Filtered Seizure Data.mat']);

% Determine Which Seizures To Plot. If Null, Random
if generate_random 
    sz_to_plot = randperm(length(filtered_evoked_sz{1}),num_to_plot);
    evoked_sz_to_plot(folder_num,:) = sz_to_plot;
% Assume Plot Same Seizures For All
elseif size(evoked_sz_to_plot,1) == 1
    sz_to_plot = evoked_sz_to_plot;
% Specific Seizures Per Plot
else
    sz_to_plot = evoked_sz_to_plot(folder_num,:);
end

if to_plot
% Normalizes
for j = 1:num_to_plot 
    figure;
    for i = 1:size(filter_set,1)
        norm_factor = max(abs(evoked_sz{sz_to_plot(j)}));
        for k = 1:size(filtered_evoked_sz{i}{sz_to_plot(j)},2)
        subplot(size(filter_set,1),1,i)
        hold on
        plot(1/fs_Neuronexus:1/fs_Neuronexus:plot_duration+t_before_Neuronexus,...
            filtered_evoked_sz{i}{sz_to_plot(j)}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)...
            ./norm_factor(k)+(k-1)*1,'Color','k')
        title([subFolders(folders_to_plot(folder_num)+2).name,' Seizure # ',num2str(sz_to_plot(j)),...
            ' (', num2str(filter_set(i,1)),'Hz and ', num2str(filter_set(i,2)),'Hz bands)'])
        end
        hold off
        ylim([-1,k])
        xlabel('Time (sec)')
    end
end
end

end

clear evoked_sz evoked_stim_length delay_length second_stim_length evoked_sz
clear fs_Neuronexus fs_EEG t_after t_before_Neuronexus filter_set filtered_evoked_sz
clear i j k folder_num norm_factor

%% Spectrogram for All Channels for Selected Seizures

if to_plot
    
    if isempty(evoked_sz_to_plot) 
        generate_random = 1;
    else
        generate_random = 0;
    end

    for folder_num = 1:length(folders_to_plot)
        % Loads Files
        path_evoked = strcat(path_EEG,subFolders(folders_to_plot(folder_num)+2).name,'\');
        load([path_evoked,'Filtered Seizure Data.mat']);

        % Determine Which Seizures To Plot. If Null, Random
        if generate_random 
            sz_to_plot = randperm(length(filtered_evoked_sz{1}),num_to_plot);
            evoked_sz_to_plot(folder_num,:) = sz_to_plot;
        % Assume Plot Same Seizures For All
        elseif size(evoked_sz_to_plot,1) == 1
            sz_to_plot = evoked_sz_to_plot;
        % Specific Seizures Per Plot
        else
            sz_to_plot = evoked_sz_to_plot(folder_num,:);
        end
        
        for j = 1:num_to_plot
        figure
        hold on
        for k = 1:size(evoked_sz{sz_to_plot(j)},2)
        subplot(size(evoked_sz{sz_to_plot(j)},2),1,k)
        pspectrum(evoked_sz{sz_to_plot(j)}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)...
        ,fs_Neuronexus,'spectrogram', 'FrequencyLimits',freq_limits,'TimeResolution',t_res,'OverlapPercent',overlap_per)
        ylabel(['Ch ',num2str(k),' Hz']);
        if k == 1
            title([subFolders(folders_to_plot(folder_num)+2).name, ' Seizure #',num2str(sz_to_plot(j))])
        else
            title('')
        end
        if k == size(evoked_sz{sz_to_plot(j)},2)
        else
            xlabel('')
        end
        caxis(colorbarlim_evoked)
        colorbar('hide')
        end
        end
    end
end

clear evoked_sz evoked_stim_length delay_length second_stim_length evoked_sz
clear fs_Neuronexus fs_EEG t_after t_before_Neuronexus filter_set filtered_evoked_sz
clear i j k folder_num

%% Welch Frequency Distribution for All Channels for Selected Seizures

if to_plot
    
    if isempty(evoked_sz_to_plot) 
        generate_random = 1;
    else
        generate_random = 0;
    end

    for folder_num = 1:length(folders_to_plot)
        % Loads Files
        path_evoked = strcat(path_EEG,subFolders(folders_to_plot(folder_num)+2).name,'\');
        load([path_evoked,'Filtered Seizure Data.mat']);

        % Determine Which Seizures To Plot. If Null, Random
        if generate_random 
            sz_to_plot = randperm(length(filtered_evoked_sz{1}),num_to_plot);
            evoked_sz_to_plot(folder_num,:) = sz_to_plot;
        % Assume Plot Same Seizures For All
        elseif size(evoked_sz_to_plot,1) == 1
            sz_to_plot = evoked_sz_to_plot;
        % Specific Seizures Per Plot
        else
            sz_to_plot = evoked_sz_to_plot(folder_num,:);
        end
        
        for j = 1:num_to_plot
        figure
        hold on
        for k = 1:size(evoked_sz{sz_to_plot(j)},2)
        [pxx,f] = pwelch(evoked_sz{sz_to_plot(j)}(1+(Nx_window_modifier+t_before_Neuronexus+evoked_stim_length(sz_to_plot(j)))*fs_Neuronexus:...
        (evoked_stim_length(sz_to_plot(j))+Nx_window_modifier+t_before_Neuronexus+t_win)*fs_Neuronexus,k),500,300,500,fs_Neuronexus);
        plot(f,10*log10(pxx),'LineWidth',2)
        end
        title([subFolders(folders_to_plot(folder_num)+2).name, ' Seizure #',num2str(sz_to_plot(j))])
        xlim([0,300])
        xlabel('Frequency Hz')
        ylabel('Power/Frequency dB/Hz')
        end
     
    end
end

clear evoked_sz evoked_stim_length delay_length second_stim_length evoked_sz
clear fs_Neuronexus fs_EEG t_after t_before_Neuronexus filter_set filtered_evoked_sz
clear i j k folder_num

%% Equation Based Feature Calculation

% Line Length
LLFn = @(x) sum(abs(diff(x)));
% Area
Area = @(x) sum(abs(x));
% Energy
Energy = @(x)  sum(x.^2);
% Zero Crossing Around Mean
ZeroCrossing = @(x) sum((x(2:end) - mean(x) > 0 & x(1:end-1) - mean(x) < 0))...
    + sum((x(2:end) - mean(x) < 0 & x(1:end-1) - mean(x) > 0));

for folder_num = 3:length(subFolders)
        
    path_evoked = strcat(path_EEG,subFolders(folder_num).name,'\');
    ['Working on ',path_evoked]
    load([path_evoked,'Filtered Seizure Data.mat']);

    % Bandpower
    for i = 1:size(filter_set,1)
    temp_bp_calc = [];
    norm_temp_bp_calc = [];
    for j = 1:length(evoked_sz)
        temp_bp_calc{j}=MovingWinFeats(filtered_evoked_sz{i}{j}, fs_Neuronexus, winLen, winDisp, @bandpower,[]);
        norm_temp_bp_calc{j} = (temp_bp_calc{j} - mean(temp_bp_calc{j}))./std(temp_bp_calc{j});
    end
    bp_calc_evoked{i} = temp_bp_calc;
    norm_bp_calc_evoked{i} = norm_temp_bp_calc;
    end

    for j = 1:length(evoked_sz)
        ['Working on Seizure ', num2str(j)]
        % RMS Mean
        RMS_evoked{j} = MovingWinFeats(evoked_sz{j}, fs_Neuronexus, winLen, winDisp, @rms,[]);
        norm_RMS_evoked{j} = (RMS_evoked{j} - mean(RMS_evoked{j}))./std(RMS_evoked{j});
        % Skewness
        Skew_evoked{j} = MovingWinFeats(evoked_sz{j}, fs_Neuronexus, winLen, winDisp, @skewness,[]);
        norm_Skew_evoked{j} = (Skew_evoked{j} - mean(Skew_evoked{j}))./std(Skew_evoked{j});
        % Approximate Entropy
        ['Entropy']
        AEntropy_evoked{j} = MovingWinFeats(evoked_sz{j}, fs_Neuronexus, winLen, winDisp, @approximateEntropy,[]);
        norm_AEntropy_evoked{j} = (AEntropy_evoked{j} - mean(AEntropy_evoked{j}))./std(AEntropy_evoked{j});
        ['Done']
        % Line Length
        LLFn_evoked{j} = MovingWinFeats(evoked_sz{j}, fs_Neuronexus, winLen, winDisp, LLFn,[]);
        norm_LLFn_evoked{j} = (LLFn_evoked{j} - mean(LLFn_evoked{j}))./std(LLFn_evoked{j});
        % Area
        Area_evoked{j} = MovingWinFeats(evoked_sz{j}, fs_Neuronexus, winLen, winDisp, Area,[]);
        norm_Area_evoked{j} = (Area_evoked{j} - mean(Area_evoked{j}))./std(Area_evoked{j});
        % Energy
        Energy_evoked{j} = MovingWinFeats(evoked_sz{j}, fs_Neuronexus, winLen, winDisp, Energy,[]);
        norm_Energy_evoked{j} = (Energy_evoked{j} - mean(Energy_evoked{j}))./std(Energy_evoked{j});
        % Zero Crossing
        Zero_Crossing_evoked{j} = MovingWinFeats(evoked_sz{j}, fs_Neuronexus, winLen, winDisp, ZeroCrossing,[]);
        norm_Zero_Crossing_evoked{j} = (Zero_Crossing_evoked{j} - mean(Zero_Crossing_evoked{j}))./std(Zero_Crossing_evoked{j});
        ['LP']
        % Lyapunov Exponent
        LP_exp_evoked{j} = MovingWinFeats(evoked_sz{j}, fs_Neuronexus, winLen, winDisp, @lyapunovExponent,fs_Neuronexus);
        norm_LP_exp_evoked{j} = (LP_exp_evoked{j} - mean(LP_exp_evoked{j}))./std(LP_exp_evoked{j});
        if to_plot
            figure;
            % X Axes Labels
            xticklabel = winDisp:winDisp:floor(size(evoked_sz{j},1)/fs_Neuronexus/winDisp - (winLen-winDisp)/winDisp)*winDisp;
            xticks = round(linspace(1, size(norm_LLFn_evoked{1}, 1), (t_after+t_before_Neuronexus)./5));
            xticklabels = xticklabel(xticks);
            
            % Colormap
            colormap('winter')
            
            plot1 = subplot(8,1,1);
            imagesc(norm_LLFn_evoked{j}')
            caxis([-1,1])
            set(plot1, 'XTick', xticks, 'XTickLabel', xticklabels)
            xlabel('Seconds')
            ylabel('Line Length')
            title(['Line Length - ',subFolders(folder_num).name, ' Seizure #', num2str(j)]);
            colorbar
            
            plot2 = subplot(8,1,2);
            % plot(winDisp:winDisp:floor(size(evoked_sz{j},1)/fs_Neuronexus/winDisp - (winLen-winDisp)/winDisp)*winDisp,norm_Area_evoked{j})
            imagesc(norm_Area_evoked{j}')
            set(plot2, 'XTick', xticks, 'XTickLabel', xticklabels)
            caxis([-1,2.5])
            xlabel('Seconds')
            ylabel('Area')
            title(['Area - ',subFolders(folder_num).name, 'Seizure #',num2str(j)]);
            colorbar
            
            plot3 = subplot(8,1,3);
            imagesc(norm_Energy_evoked{j}')
            set(plot3, 'XTick', xticks, 'XTickLabel', xticklabels)
            caxis([-1,5])
            xlabel('Seconds')
            ylabel('Energy')
            title(['Energy - ',subFolders(folder_num).name, ' Seizure #',num2str(j)]);
            colorbar
            
            plot4 = subplot(8,1,4);
            imagesc(norm_Zero_Crossing_evoked{j}')
            set(plot4, 'XTick', xticks, 'XTickLabel', xticklabels)
            caxis([-1,1])
            xlabel('Seconds')
            ylabel('Zero Crossing')
            title(['Zero Crossing - ',subFolders(folder_num).name, ' Seizure #',num2str(j)]);
            colorbar
            
            plot5 = subplot(8,1,5);
            imagesc(norm_RMS_evoked{j}')
            set(plot5, 'XTick', xticks, 'XTickLabel', xticklabels)
            caxis([-1,3])
            xlabel('Seconds')
            ylabel('RMS Amplitude')
            title(['RMS Amplitude - ',subFolders(folder_num).name, ' Seizure #',num2str(j)]);
            colorbar 
            
            plot6 = subplot(8,1,6);
            imagesc(norm_Skew_evoked{j}')
            set(plot6, 'XTick', xticks, 'XTickLabel', xticklabels)
            caxis([-2,2])
            xlabel('Seconds')
            ylabel('Skew')
            title(['Skew - ',subFolders(folder_num).name, ' Seizure #', num2str(j)]);
            colorbar
            
            plot7 = subplot(8,1,7);
            imagesc(norm_AEntropy_evoked{j}')
            set(plot7, 'XTick', xticks, 'XTickLabel', xticklabels)
            caxis([-2,2])
            xlabel('Seconds')
            ylabel('Entropy')
            title(['Entropy - ',subFolders(folder_num).name, ' Seizure #', num2str(j)]);
            colorbar
            
            plot8 = subplot(8,1,8);
            imagesc(norm_LP_exp_evoked{j}')
            set(plot8, 'XTick', xticks, 'XTickLabel', xticklabels)
            caxis([-2,2])
            xlabel('Seconds')
            ylabel('Lyapunov Exponent')
            title(['Lyapunov Exponent - ',subFolders(folder_num).name, ' Seizure #', num2str(j)]);
            colorbar
            
            figure
            % Colormap
            colormap('winter')
            for i = 1:size(filter_set,1)
            plots = subplot(size(filter_set,1),1,i);
            imagesc(norm_bp_calc_evoked{i}{j}')
            set(plots, 'XTick', xticks, 'XTickLabel', xticklabels)
            caxis([0,4-i])
            colorbar
            xlabel('Seconds')
            ylabel([num2str(filter_set(i,1)), ' - ' num2str(filter_set(i,2)), ' Hz'])
            title(['Bandpower - ',subFolders(folder_num).name, ' Seizure #',num2str(j)]);
            end
        end
    end
    save([path_evoked,'Raw Features.mat'],'LLFn_evoked', 'Area_evoked', 'Energy_evoked', 'Zero_Crossing_evoked', 'bp_calc_evoked',...
        'RMS_evoked', 'Skew_evoked', 'AEntropy_evoked', 'LP_exp_evoked')
    save([path_evoked,'Normalized Features.mat'],'norm_LLFn_evoked', 'norm_Area_evoked', 'norm_Energy_evoked', ...
        'norm_Zero_Crossing_evoked', 'norm_bp_calc_evoked','norm_RMS_evoked','norm_Skew_evoked','norm_LP_exp_evoked',...
        'norm_AEntropy_evoked')

    clear LLFn_evoked Area_evoked Energy_evoked Zero_Crossing_evoked norm_LP_exp_evoked LP_exp_evoked
    clear norm_AEntropy_evoked AEntropy_evoked RMS_evoked Skew_evoked norm_RMS_evoked norm_Skew_evoked
    clear norm_LLFn_evoked norm_Area_evoked norm_Energy_evoked norm_Zero_Crossing_evoked norm_bp_calc_evoked
end

clear evoked_sz evoked_stim_length delay_length second_stim_length evoked_sz
clear fs_Neuronexus fs_EEG t_after t_before_Neuronexus filter_set filtered_evoked_sz
clear i j k folder_num temp_bp_calc norm_temp_bp_calc bp_calc_spont bp_calc_evoked

%% Adds Phase Locked High Gamma and Coherence to Features

if first_run
    
    % EEG
    fs_EEG = 2000;
    
    % Filter to generate low (4-30 Hz) and high gamma (80-150 Hz) signals
    % create LFP and HG filters
    [low_num,low_denom] = butter(2,[4 30]/(2000/2),'bandpass');
    [hg_num,hg_denom] = butter(2,[80 150]/(2000/2),'bandpass');
    
    % Loops Through Folders and Loads Data
    for folder_num = 3:length(subFolders)
        
    if to_plot
        figure(folder_num)
        figure(folder_num+length(subFolders))
    end
        
    path_evoked = strcat(path_EEG,subFolders(folder_num).name,'\');
    load([path_evoked,'Standardized Seizure Data.mat']);
    
    ['Working on Folder ', path_evoked]
    
    % Normalize and Downsample
    if normalized
        evoked_sz = normalize_to_max_amp(evoked_sz,t_before_Neuronexus,fs_Neuronexus);        
    end
    
    if to_downsample
        % Downsample Normalized Data
        for sz_cnt = 1:length(evoked_sz)
            evoked_sz{sz_cnt} = downsample(evoked_sz{sz_cnt},fs_Neuronexus/fs_EEG);
        end
        fs_Neuronexus = fs_EEG;
    end
    
    % filter all channels
    for seizure = 1:length(evoked_sz) 
        lowfreq{seizure} = filtfilt(low_num,low_denom,evoked_sz{seizure});
        highfreq{seizure} = filtfilt(hg_num,hg_denom,evoked_sz{seizure});
    end
    
    % Calculate the LFP phase and the HG amplitude
    for seizure = 1:length(evoked_sz) 
    ['Seizure # ', num2str(seizure)]
    tophase_low = hilbert(lowfreq{seizure});
    IMAGS = imag(tophase_low);
    REALS = real(tophase_low);
    lowphase = atan2(IMAGS,REALS);
    clear IMAGS REALS
    
    tophase_high = hilbert(highfreq{seizure});
    IMAGS = imag(tophase_high);
    REALS = real(tophase_high);
    % highphase = atan2(IMAGS,REALS);
    highamp = sqrt(IMAGS.^2 + REALS.^2);    
    clear IMAGS REALS
    
    % Windows
    NumWins = floor(size(evoked_sz{seizure},1)/fs_Neuronexus/winDisp - (winLen-winDisp)/winDisp);
    plhg_temp = [];
    
    % Defining Lengths
    winst = 1;
    winend = winLen * fs_Neuronexus;
    
    for winnum = 1:NumWins
        plhg_temp(winnum,:) = abs(mean(abs(tophase_high(winst:winend,:)).*exp(i*(lowphase(winst:winend,:) ...
            - highamp(winst:winend,:)))));
        % Coherence Between Screws
        coher_temp(winnum,1) = mean(mscohere(evoked_sz{seizure}(winst:winend,1),evoked_sz{seizure}(winst:winend,2),100,2,[],fs_Neuronexus));
        % Coherence Between Wires
        coher_temp(winnum,2) = mean(mscohere(evoked_sz{seizure}(winst:winend,3),evoked_sz{seizure}(winst:winend,4),100,2,[],fs_Neuronexus));
        % Coherence Between Ipsilateral (Screw + Wire)
        coher_temp(winnum,3) = mean(mscohere(evoked_sz{seizure}(winst:winend,1),evoked_sz{seizure}(winst:winend,3),100,2,[],fs_Neuronexus));
        % Coherence Between Contralateral (Screw + Wire)
        coher_temp(winnum,4) = mean(mscohere(evoked_sz{seizure}(winst:winend,1),evoked_sz{seizure}(winst:winend,4),100,2,[],fs_Neuronexus));
        winst = winst + winDisp * fs_Neuronexus;
        winend = winst - 1 + winLen * fs_Neuronexus;
    end
    
    plhg_evoked{seizure} = plhg_temp;
    coher_evoked{seizure} = coher_temp;
    norm_plhg_evoked{seizure} = (plhg_evoked{seizure} - mean(plhg_evoked{seizure}))./std(plhg_evoked{seizure});
    norm_coher_evoked{seizure} = (coher_evoked{seizure} - mean(coher_evoked{seizure}))./std(coher_evoked{seizure});
    clear tophase_high tophase_low lowphase highamp highphase plhg_temp NumWins coher_temp
    
    if to_plot
        % X Axes Labels
        xticklabel = winDisp:winDisp:floor(size(evoked_sz{seizure},1)/fs_Neuronexus/winDisp - (winLen-winDisp)/winDisp)*winDisp;
        xticks = round(linspace(1, size(norm_plhg_evoked{1}, 1), (t_after+t_before_Neuronexus)./5));
        xticklabels = xticklabel(xticks);

        % Colormap
        colormap('winter')
        
        figure(folder_num)
        plot_temp = subplot(length(evoked_sz),1,seizure);
        imagesc(norm_plhg_evoked{seizure}')
        caxis([-1,1])
        set(plot_temp, 'XTick', xticks, 'XTickLabel', xticklabels)
        xlabel('Seconds')
        ylabel('PLHG')
        title(['Phase Locked High Gamma - ',subFolders(folder_num).name, ' Seizure #', num2str(seizure)]);
        colorbar
        
        figure(folder_num+length(subFolders))
        plot_temp = subplot(length(evoked_sz),1,seizure);
        imagesc(norm_coher_evoked{seizure}')
        caxis([-1,1])
        set(plot_temp, 'XTick', xticks, 'XTickLabel', xticklabels)
        xlabel('Seconds')
        ylabel('Coherence')
        title(['Coherence - ',subFolders(folder_num).name, ' Seizure #', num2str(seizure)]);
        colorbar
    end
    
    end
    
    load([path_evoked,'Raw Features.mat'],'LLFn_evoked', 'Area_evoked', 'Energy_evoked', 'Zero_Crossing_evoked', 'bp_calc_evoked',...
        'RMS_evoked', 'Skew_evoked', 'AEntropy_evoked', 'LP_exp_evoked')
    load([path_evoked,'Normalized Features.mat'],'norm_LLFn_evoked', 'norm_Area_evoked', 'norm_Energy_evoked', ...
        'norm_Zero_Crossing_evoked', 'norm_bp_calc_evoked','norm_RMS_evoked','norm_Skew_evoked','norm_LP_exp_evoked',...
        'norm_AEntropy_evoked')
    save([path_evoked,'Raw Features.mat'],'LLFn_evoked', 'Area_evoked', 'Energy_evoked', 'Zero_Crossing_evoked', 'bp_calc_evoked',...
        'RMS_evoked', 'Skew_evoked', 'AEntropy_evoked', 'LP_exp_evoked','plhg_evoked','coher_evoked')
    save([path_evoked,'Normalized Features.mat'],'norm_LLFn_evoked', 'norm_Area_evoked', 'norm_Energy_evoked', ...
        'norm_Zero_Crossing_evoked', 'norm_bp_calc_evoked','norm_RMS_evoked','norm_Skew_evoked','norm_LP_exp_evoked',...
        'norm_AEntropy_evoked','norm_plhg_evoked','norm_coher_evoked')
    
    clear LLFn_evoked Area_evoked Energy_evoked Zero_Crossing_evoked norm_LP_exp_evoked LP_exp_evoked
    clear norm_AEntropy_evoked AEntropy_evoked RMS_evoked Skew_evoked norm_RMS_evoked norm_Skew_evoked
    clear norm_LLFn_evoked norm_Area_evoked norm_Energy_evoked norm_Zero_Crossing_evoked norm_bp_calc_evoked
    clear norm_coher_evoked norm_plhg_evoked
    end
end

%% Feature Plot

if to_plot
    
filter_set = [1 30; 30 300;300 2000];
    
evoked_sz_to_plot = [8,15];
j = 15;

path_evoked = strcat(path_EEG,subFolders(evoked_sz_to_plot(1,1)+2).name,'\');
load([path_evoked,'Normalized Features.mat']);
load([path_evoked,'Filtered Seizure Data.mat']);

plot_duration = 55;

figure;
% X Axes Labels
xticklabel = winDisp:winDisp:floor(size(evoked_sz{j},1)/fs_Neuronexus/winDisp - (winLen-winDisp)/winDisp)*winDisp;
xticks = round(linspace(1, size(norm_LLFn_evoked{1}, 1), (t_after+t_before_Neuronexus)./5));
xticklabels = xticklabel(xticks);

% Colormap
colormap('winter')

plot1 = subplot(13,1,1);
imagesc(norm_LLFn_evoked{j}')
caxis([-1,1])
set(plot1, 'XTick', xticks, 'XTickLabel', xticklabels)
xlim([0.25 60/winDisp])
% title(['Line Length']);
colorbar

plot2 = subplot(13,1,2);
imagesc(norm_Area_evoked{j}')
set(plot2, 'XTick', xticks, 'XTickLabel', xticklabels)
caxis([-1,2.5])
% title(['Area']);
xlim([0.25 60/winDisp])
colorbar

plot3 = subplot(13,1,3);
imagesc(norm_Energy_evoked{j}')
set(plot3, 'XTick', xticks, 'XTickLabel', xticklabels)
caxis([-1,5])
% title(['Energy']);
xlim([0.25 60/winDisp])
colorbar

plot4 = subplot(13,1,4);
imagesc(norm_Zero_Crossing_evoked{j}')
set(plot4, 'XTick', xticks, 'XTickLabel', xticklabels)
caxis([-1,1])
% title(['Zero Crossing']);
xlim([0.25 60/winDisp])
colorbar

plot5 = subplot(13,1,5);
imagesc(norm_RMS_evoked{j}')
set(plot5, 'XTick', xticks, 'XTickLabel', xticklabels)
caxis([-1,3])
% title(['RMS Amplitude']);
xlim([0.25 60/winDisp])
colorbar 

plot6 = subplot(13,1,6);
imagesc(norm_Skew_evoked{j}')
set(plot6, 'XTick', xticks, 'XTickLabel', xticklabels)
caxis([-2,2])
% title(['Skew ']);
xlim([0.25 60/winDisp])
colorbar

plot7 = subplot(13,1,7);
imagesc(norm_AEntropy_evoked{j}')
set(plot7, 'XTick', xticks, 'XTickLabel', xticklabels)
caxis([-2,2])
% title(['Entropy']);
xlim([0.25 60/winDisp])
colorbar

plot8 = subplot(13,1,8);
imagesc(norm_LP_exp_evoked{j}')
set(plot8, 'XTick', xticks, 'XTickLabel', xticklabels)
caxis([-2,2])
% title(['Lyapunov Exponent']);
xlim([0.25 60/winDisp])
colorbar

plot8 = subplot(13,1,9);
imagesc(norm_plhg_evoked{j}')
set(plot8, 'XTick', xticks, 'XTickLabel', xticklabels)
caxis([-2,2])
% title(['Phase Locked High Gamma']);
xlim([0.25 60/winDisp])
colorbar

plot8 = subplot(13,1,10);
imagesc(norm_coher_evoked{j}')
set(plot8, 'XTick', xticks, 'XTickLabel', xticklabels)
caxis([-1,1])
% title(['Coherence']);
xlim([0.25 60/winDisp])
colorbar

for i = 1:3
plots = subplot(13,1,10+i);
imagesc(norm_bp_calc_evoked{i}{j}')
set(plots, 'XTick', xticks, 'XTickLabel', xticklabels)
caxis([0,4-i])
xlim([0.25 60/winDisp])
colorbar
% title(['Bandpower - ', num2str(filter_set(i,1)), ' - ',num2str(filter_set(i,2)), ' Hz']);
end
xlabel('Seconds')
end

%% K Means Separation

clear total_output_evoked k_means_classes_optimal Kmeans_Mdl k_means_evoked

% Standardization
rng(1)
Colorset_plot = cbrewer('qual','Set1',k_means_classes);
Colorset_plot(Colorset_plot>1) = 1;
Colorset_plot(Colorset_plot<0) = 0;

for folder_num = 3:length(subFolders)
        
    path_evoked = strcat(path_EEG,subFolders(folder_num).name,'\');
    load([path_evoked,'Normalized Features.mat']);
    load([path_evoked,'Filtered Seizure Data.mat']);
    
    Output_Array_evoked = [];
    for seizure = 1:length(norm_Area_evoked)
    Output_Array_evoked{seizure} = [norm_Area_evoked{seizure}, norm_Energy_evoked{seizure}, norm_LLFn_evoked{seizure},...
        norm_Zero_Crossing_evoked{seizure}, norm_AEntropy_evoked{seizure}, norm_RMS_evoked{seizure}, norm_Skew_evoked{seizure},...
        norm_LP_exp_evoked{seizure},norm_plhg_evoked{seizure},norm_coher_evoked{seizure}];
    for bandpower_set = 1:length(norm_bp_calc_evoked)
        Output_Array_evoked{seizure} = [Output_Array_evoked{seizure},norm_bp_calc_evoked{bandpower_set}{seizure}];
    end
    
    total_output_evoked{folder_num-2} = Output_Array_evoked;
    
    % K Means Model
    k_means_evoked(:,seizure) = kmeans(Output_Array_evoked{seizure},k_means_classes);
    Kmeans_Mdl{folder_num-2}{seizure} = fitcknn(Output_Array_evoked{seizure},k_means_evoked(:,seizure));
    [pca_coeff_evoked{seizure},pca_scores_evoked{seizure}] = pca(Output_Array_evoked{seizure}');
    
    % GMM Models
    AIC = zeros(1,k_means_classes);
    GMModels = cell(1,4);

    for k = 1:k_means_classes
        GMModels{k} = fitgmdist(Output_Array_evoked{seizure},k,'CovarianceType','diagonal',...
            'MaxIter',100,'RegularizationValue',0.1);
        AIC(k)= GMModels{k}.AIC;
    end

    [minAIC,numComponents] = min(AIC);
    k_means_classes_optimal(folder_num-2,seizure) = numComponents;
    
    if to_plot
        % PCA
        figure
        scatter3(pca_coeff_evoked{seizure}(:,1),pca_coeff_evoked{seizure}(:,2),pca_coeff_evoked{seizure}(:,3),...
            [],Colorset_plot(k_means_evoked(:,seizure),:),'filled')
        xlabel('Principal Component 1')
        ylabel('Principal Component 2')
        zlabel('Principal Component 3')
        title([subFolders(folder_num).name, ' Seizure ', num2str(seizure)]);

        % K Means Over Time
        figure;
        % k = Each Channel
        hold on
        for k = 1:size(evoked_sz{seizure},2)
        norm_factor = max(abs(evoked_sz{seizure}));
        plot(1/fs_Neuronexus:1/fs_Neuronexus:plot_duration+t_before_Neuronexus,...
            evoked_sz{seizure}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)./norm_factor(k)+(k-1)*1,'Color','k')
        end
        xaxis = winDisp:winDisp:(plot_duration+t_before_Neuronexus);
        scatter(xaxis,ones(1,length(xaxis))*k,[],Colorset_plot(k_means_evoked(1:length(xaxis),seizure),:),'filled')
        ylim([-1,k+1])
        hold off
        title([subFolders(folder_num).name, ' Seizure ',num2str(seizure)])
    end
    end
 
    clear LLFn_evoked Area_evoked Energy_evoked Zero_Crossing_evoked norm_LP_exp_evoked LP_exp_evoked
    clear norm_AEntropy_evoked AEntropy_evoked RMS_evoked Skew_evoked norm_RMS_evoked norm_Skew_evoked
    clear norm_LLFn_evoked norm_Area_evoked norm_Energy_evoked norm_Zero_Crossing_evoked norm_bp_calc_evoked
    clear evoked_sz evoked_stim_length delay_length second_stim_length evoked_sz norm_factor
    clear fs_Neuronexus fs_EEG t_after t_before_Neuronexus filter_set filtered_evoked_sz i j k
    clear norm_coher_evoked norm_plhg_evoked
end

%% Specific Predictions

clear paired_output_evoked paired_Kmeans_Mdl k_means_evoked

for row = 1:size(pairings,1)
for folder_num = 1:size(pairings,2)/2
        
    path_evoked = strcat(path_EEG,subFolders(pairings(row,2*folder_num-1)+2).name,'\');
    load([path_evoked,'Normalized Features.mat']);
    load([path_evoked,'Filtered Seizure Data.mat']);
    
    Output_Array_evoked = [];
    seizure = pairings(row,2*folder_num);
    Output_Array_evoked = [norm_Area_evoked{seizure}, norm_Energy_evoked{seizure}, norm_LLFn_evoked{seizure},...
        norm_Zero_Crossing_evoked{seizure}, norm_AEntropy_evoked{seizure}, norm_RMS_evoked{seizure}, norm_Skew_evoked{seizure},...
        norm_LP_exp_evoked{seizure},norm_plhg_evoked{seizure},norm_coher_evoked{seizure}];
    for bandpower_set = 1:length(norm_bp_calc_evoked)
        Output_Array_evoked = [Output_Array_evoked,norm_bp_calc_evoked{bandpower_set}{seizure}];
    end
    
    paired_output_evoked{row,folder_num} = Output_Array_evoked;
    k_means_evoked{row,folder_num} = kmeans(Output_Array_evoked,k_means_classes);
    paired_Kmeans_Mdl{row,folder_num} = fitcknn(Output_Array_evoked,k_means_evoked{row,folder_num});
    plot_sz{row,folder_num} = evoked_sz{seizure};
end
end

for row = 1:size(pairings,1)

k_means_sanity_check = predict(paired_Kmeans_Mdl{row,1},paired_output_evoked{row,1});
sum(k_means_sanity_check == k_means_evoked{row,1})==length(k_means_sanity_check)
k_means_pred_1 = predict(paired_Kmeans_Mdl{row,1},paired_output_evoked{row,2});
k_means_pred_3 = predict(paired_Kmeans_Mdl{row,1},paired_output_evoked{row,3});

if to_plot
    
figure
hold on
for k = 1:size(pairings,2)/2
norm_factor = max(abs(plot_sz{row,k}));
plot(1/fs_Neuronexus:1/fs_Neuronexus:plot_duration+t_before_Neuronexus,...
plot_sz{row,k}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)./norm_factor(k)+6-2*k,'Color','k')
end
xaxis = winDisp:winDisp:(plot_duration+t_before_Neuronexus);
scatter(xaxis,ones(1,length(xaxis))*5,[],Colorset_plot(k_means_sanity_check(1:length(xaxis)),:),'filled')
scatter(xaxis,ones(1,length(xaxis))*3,[],Colorset_plot(k_means_pred_1(1:length(xaxis)),:),'filled')
scatter(xaxis,ones(1,length(xaxis))*1,[],Colorset_plot(k_means_pred_3(1:length(xaxis)),:),'filled')
xlabel('Time (sec)')
hold off
title(subFolders(pairings(row,1)+2).name, ' Seizures')
end

end

clear LLFn_evoked Area_evoked Energy_evoked Zero_Crossing_evoked norm_LP_exp_evoked LP_exp_evoked
clear norm_AEntropy_evoked AEntropy_evoked RMS_evoked Skew_evoked norm_RMS_evoked norm_Skew_evoked
clear norm_LLFn_evoked norm_Area_evoked norm_Energy_evoked norm_Zero_Crossing_evoked norm_bp_calc_evoked
clear evoked_sz evoked_stim_length delay_length second_stim_length evoked_sz norm_factor
clear fs_Neuronexus fs_EEG t_after t_before_Neuronexus filter_set filtered_evoked_sz i j k
clear k_means_pred_1 k_means_pred_3 k_means_sanity_check

%% Seizure Duration and Split into Three Subsectiosn

% Automated Seizure Detector Standardization
rng(1)
Colorset_plot = cbrewer('qual','Set1',k_means_classes);
Colorset_plot(Colorset_plot>1) = 1;
Colorset_plot(Colorset_plot<0) = 0;

% Which Seizure To Get Model From
folder_num = 3;
seizure = 1;

% Loads Seizure and Features
path_evoked = strcat(path_EEG,subFolders(folder_num).name,'\');
load([path_evoked,'Normalized Features.mat']);
load([path_evoked,'Filtered Seizure Data.mat']);

% Concactenate Arrays
Output_Array_evoked = [];
Output_Array_evoked = [norm_Area_evoked{seizure}, norm_Energy_evoked{seizure}, norm_LLFn_evoked{seizure},...
    norm_Zero_Crossing_evoked{seizure}, norm_AEntropy_evoked{seizure}, norm_RMS_evoked{seizure}, norm_Skew_evoked{seizure},...
    norm_LP_exp_evoked{seizure},norm_plhg_evoked{seizure},norm_coher_evoked{seizure}];
for bandpower_set = 1:length(norm_bp_calc_evoked)
    Output_Array_evoked = [Output_Array_evoked,norm_bp_calc_evoked{bandpower_set}{seizure}];
end

% Fits Model
k_means_evoked_out = kmeans(Output_Array_evoked,2);  
Kmeans_Mdl = fitcknn(Output_Array_evoked,k_means_evoked_out);

% Plots All
for folder_num = 3:length(subFolders)

    clear k_means_pred k_means_sz_duration thirds_loc final_output
    % Loads Features and Seizure
    path_evoked = strcat(path_EEG,subFolders(folder_num).name,'\');
    load([path_evoked,'Normalized Features.mat']);
    load([path_evoked,'Filtered Seizure Data.mat']);
    
    % Concactenate Arrays
    Output_Array_evoked = [];
    for seizure = 1:length(norm_Area_evoked)
    Output_Array_evoked{seizure} = [norm_Area_evoked{seizure}, norm_Energy_evoked{seizure}, norm_LLFn_evoked{seizure},...
        norm_Zero_Crossing_evoked{seizure}, norm_AEntropy_evoked{seizure}, norm_RMS_evoked{seizure}, norm_Skew_evoked{seizure},...
        norm_LP_exp_evoked{seizure},norm_plhg_evoked{seizure},norm_coher_evoked{seizure}];
    for bandpower_set = 1:length(norm_bp_calc_evoked)
        Output_Array_evoked{seizure} = [Output_Array_evoked{seizure},norm_bp_calc_evoked{bandpower_set}{seizure}];
    end
    
    % Predicts
    k_means_pred{seizure} = predict(Kmeans_Mdl,Output_Array_evoked{seizure});
    
    % Use Stim Length and an Adjustment To Determine Seizure Duration
    countdown = 0;
    countdown_lim = 7/winDisp;
    sz_start = (t_before_Neuronexus + evoked_stim_length(seizure))/winDisp;
    sz_pos = sz_start;
    sz_end = sz_start;
    while k_means_pred{seizure}(sz_pos) == 2 || countdown < countdown_lim
        if k_means_pred{seizure}(sz_pos) == 2
            countdown = 0;
            sz_end = sz_pos;
        else
            countdown = countdown + 1;
        end
        sz_pos = sz_pos + 1;
    end
    
    % Fixes Specific Seizures
    if to_fix
        if isempty(find(fix_folder(:,1) == folder_num - 2 & fix_folder(:,2) == seizure))
        else
            idx = find(fix_folder(:,1) == folder_num - 2 & fix_folder(:,2) == seizure);
            sz_end = fix_length(idx)./winDisp + sz_start;
        end
    end
    
    % Split Into Thirds & Takes Data From Contralateral Screw
    thirds_loc(seizure,:) = [1,t_before_Neuronexus/winDisp,sz_start,sz_start+round((sz_end - sz_start)/3),sz_start+round(2*(sz_end - sz_start)/3),sz_end,sz_end+30/winDisp];
    k_means_sz_duration(seizure) = (sz_end - sz_start).*winDisp;
    % Before
    output_measures{1} = Output_Array_evoked{seizure}(thirds_loc(seizure,1):thirds_loc(seizure,2),channel_for_feature_split:4:size(Output_Array_evoked{seizure},2));
    % Stim
    output_measures{2} = Output_Array_evoked{seizure}(thirds_loc(seizure,2):thirds_loc(seizure,3),channel_for_feature_split:4:size(Output_Array_evoked{seizure},2));
    % Beginning
    output_measures{3} = Output_Array_evoked{seizure}(thirds_loc(seizure,3):thirds_loc(seizure,4),channel_for_feature_split:4:size(Output_Array_evoked{seizure},2));
    % Middle
    output_measures{4} = Output_Array_evoked{seizure}(thirds_loc(seizure,4):thirds_loc(seizure,5),channel_for_feature_split:4:size(Output_Array_evoked{seizure},2));
    % End
    output_measures{5} = Output_Array_evoked{seizure}(thirds_loc(seizure,5):thirds_loc(seizure,6),channel_for_feature_split:4:size(Output_Array_evoked{seizure},2));
    % After
    output_measures{6} = Output_Array_evoked{seizure}(thirds_loc(seizure,6):thirds_loc(seizure,7),channel_for_feature_split:4:size(Output_Array_evoked{seizure},2));
    
    final_output{seizure} = output_measures;
    
    % Plots Predictions
    if to_plot    
        figure
        hold on
        for k = 1:size(evoked_sz{seizure},2)
        norm_factor = max(abs(evoked_sz{seizure}));
        plot(1/fs_Neuronexus:1/fs_Neuronexus:plot_duration+t_before_Neuronexus,...
        evoked_sz{seizure}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)./norm_factor(k)+6-2*k,'Color','k')
        end
        xaxis = winDisp:winDisp:(plot_duration+t_before_Neuronexus);
        scatter(xaxis,ones(1,length(xaxis))*7,[],Colorset_plot(k_means_pred{seizure}(1:length(xaxis)),:),'filled')
        xlabel('Time (sec)')
        hold off
        title([subFolders(folder_num).name, ' Seizure: ',num2str(seizure)])
        xline(k_means_sz_duration(seizure) + t_before_Neuronexus + evoked_stim_length(seizure))        
    end    
    end
    
    % Saves    
    save([path_evoked,'Split_Features.mat'],'final_output', 'k_means_sz_duration', 'Output_Array_evoked', 'k_means_pred',...
        'Kmeans_Mdl', 'thirds_loc', 'k_means_pred')
    
    clear output_measures
    clear LLFn_evoked Area_evoked Energy_evoked Zero_Crossing_evoked norm_LP_exp_evoked LP_exp_evoked
    clear norm_AEntropy_evoked AEntropy_evoked RMS_evoked Skew_evoked norm_RMS_evoked norm_Skew_evoked
    clear norm_LLFn_evoked norm_Area_evoked norm_Energy_evoked norm_Zero_Crossing_evoked norm_bp_calc_evoked
    clear evoked_sz evoked_stim_length delay_length second_stim_length evoked_sz norm_factor
    clear fs_Neuronexus fs_EEG t_after t_before_Neuronexus filter_set filtered_evoked_sz i j k
    clear bandpower_set countdown countdown_lim sz_start sz_end sz_pos
    
end

%% Plots Subsection Data

% Compiles Means For All Features

clear to_visualize comparison_plot

for folder_num = 3:length(subFolders)
    % Loads Features and Seizure
    path_evoked = strcat(path_EEG,subFolders(folder_num).name,'\');
    load([path_evoked,'Split_Features.mat']);
    
    for i = 1:length(final_output)
        if folder_num == 3 & i == 1
            % Sets Up First One
            for j = 1:size(final_output{i},2)
            if size(final_output{i}{j},1) > 1
            to_visualize{j} = [mean(final_output{i}{j})];
            else
            to_visualize{j} = [(final_output{i}{j})];
            end
            end
        else
            % Continues Filling It In
            for j = 1:size(final_output{i},2)
                if size(final_output{i}{j},1) > 1
                to_visualize{j} = [to_visualize{j};mean(final_output{i}{j})];
                else
                to_visualize{j} = [to_visualize{j};final_output{i}{j}];
                end
            end
        end
    end
end

% Rearranges to Visualization
for i = 1:size(to_visualize{1},2)
    temp_visualization = [];
    for j = 1:length(to_visualize)
        temp_visualization(:,j) = to_visualize{j}(:,i);
    end
    comparison_plot{i} = temp_visualization;
end

% 95% Confidence Interval With SEM
if to_plot
    figure
    for i = 1:length(comparison_plot)
    subplot(1,length(comparison_plot),i)
    hold on
    errorbar(mean(comparison_plot{i}),1.96*std(comparison_plot{i})./sqrt(size(comparison_plot{i},1)),'ko','LineWidth',2)
    for j = 1:length(to_visualize)
    scatter(j - 0.5 + rand(1,length(comparison_plot{i}(:,j))),comparison_plot{i}(:,j),2,'filled')
    end
    yline(0,'-k','LineWidth',1)
    xticks(1:length(to_visualize))
    xticklabels({'Pre-Seizure','Stimulation','Sz - Beginning','Sz - Middle','Sz - End','Post Ictal'})
    xtickangle(45)
    
    if i == 1
        title('Area')
    elseif i == 2
        title('Energy')
    elseif i == 3
        title('LineLen')
    elseif i == 4
        title('ZeroX')
    elseif i == 5
        title('Entropy')
    elseif i == 6
        title('RMSAmp')
    elseif i == 7
        title('Skew')
    elseif i == 8
        title('LP Exp')
    elseif i == 9
        title('PLHG')
    elseif i == 10
        title('Coherence')
    elseif i == 11
        title('BP sub30Hz')
    elseif i == 12
        title('BP 30-300Hz')
    else
        title('BP 300Hz+')
    end
    end
    
end

%% Segregation of Types

% Seizure ID | Folder Number | Seizure Duration | Animal ID | Position in Experiment | Delay to Second Stim | Second Stim Duration

if first_run

sz_id = [];
seizure_identifier = 1;

for folder_num = 3:length(subFolders)
    path_evoked = strcat(path_EEG,subFolders(folder_num).name,'\');
    filelist = dir(strcat(path_evoked,'*.rhd'));
    load(strcat(path_evoked,'Split_Features.mat'), 'k_means_sz_duration');
    
    times_sequence = readmatrix(strcat(path_evoked,'00_Times.csv'));
    sz_id(seizure_identifier:seizure_identifier+length(filelist)-1,2) = folder_num;
    sz_id(seizure_identifier:seizure_identifier+length(filelist)-1,3) = k_means_sz_duration';
    sz_id(seizure_identifier:seizure_identifier+length(filelist)-1,4) = times_sequence(:,1);
    sz_id(seizure_identifier:seizure_identifier+length(filelist)-1,5) = times_sequence(:,2);
    sz_id(seizure_identifier:seizure_identifier+length(filelist)-1,6) = times_sequence(:,3);
    
    if size(times_sequence,2) >= 4
        sz_id(seizure_identifier:seizure_identifier+length(filelist)-1,7) = times_sequence(:,4);
    else
        sz_id(seizure_identifier:seizure_identifier+length(filelist)-1,7) = NaN(length(filelist),1);
    end
    
    if size(times_sequence,2) >= 5
        sz_id(seizure_identifier:seizure_identifier+length(filelist)-1,8) = times_sequence(:,5);
    else
        sz_id(seizure_identifier:seizure_identifier+length(filelist)-1,8) = NaN(length(filelist),1);
    end
    
    for j = 1:length(filelist)
    % Seizure Number
    sz_id(seizure_identifier,1) = seizure_identifier; 
    % Increment Seizure Number at End
    seizure_identifier = seizure_identifier + 1;
    end
    
end

save([path_EEG,'Seizure_Metadata.mat'],'sz_id')

end

%% Plot Segregated Data

load([path_EEG,'Seizure_Metadata.mat']);

clear subdiv_index to_visualize comparison_plot legend_text anova_col_ID temp_fit

displays_text = ['Which Plot to Plot?: \n(1) - Additional Stimulation or Not \n',...
    '(2) - Individual Animals \n(3) - Epileptic vs Naive', ...
    '\n(4) - Early/Middle/End of Experiment \n(5) - Long or Short Seizures'...
    '\n(6) Human Classification by Folder\n(7) Evoked or Not\nEnter a number: '];
n = input(displays_text);
displays_text_2 = ['\nDo you want to plot individual data? \n(1) - Yes \n(0) - No', ...
    '\nEnter a number: '];
ind_data = input(displays_text_2);
legend_text = [];

if n == 7 || n == 6
max_val = length(subFolders);
else
max_val = length(subFolders) - 1;
sz_id = sz_id(1:109,:);
end

for folder_num = 3:max_val
    % Loads Features and Seizure
    path_evoked = strcat(path_EEG,subFolders(folder_num).name,'\');
    load([path_evoked,'Split_Features.mat']);
    
    for i = 1:length(final_output)
        if folder_num == 3 & i == 1
            % Sets Up First One
            for j = 1:size(final_output{i},2)
            if size(final_output{i}{j},1) > 1
            to_visualize{j} = [mean(final_output{i}{j})];
            else
            to_visualize{j} = [(final_output{i}{j})];
            end
            end
        else
            % Continues Filling It In
            for j = 1:size(final_output{i},2)
                if size(final_output{i}{j},1) > 1
                to_visualize{j} = [to_visualize{j};mean(final_output{i}{j})];
                else
                to_visualize{j} = [to_visualize{j};final_output{i}{j}];
                end
            end
        end
    end
end

% Rearranges to Visualization
for i = 1:size(to_visualize{1},2)
    temp_visualization = [];
    for j = 1:length(to_visualize)
        temp_visualization(:,j) = to_visualize{j}(:,i);
    end
    comparison_plot{i} = temp_visualization;
end

switch n
        
    % Splits By Additional Stimulus Or Not
    case 1
    % 1: No Stim 2: Stim
    anova_col_ID = 7;
    to_plot = 1;
    subdiv_index{1} = find(isnan(sz_id(:,anova_col_ID)));
    subdiv_index{2} = find(~isnan(sz_id(:,anova_col_ID)));
    legend_text = {'Control','Second Stim'};
    temp_fit(subdiv_index{1}) = 0;
    temp_fit(subdiv_index{2}) = 1;

    % Split By Individual Animals
    case 2
    % Early - Epileptic Later - Non-Epileptic
    anova_col_ID = 4;
    to_plot = 1;
    num_unique = unique(sz_id(:,anova_col_ID));
    for unique_id = 1 :length(num_unique)
        subdiv_index{unique_id} = find(sz_id(:,anova_col_ID) == num_unique(unique_id));
        legend_text{unique_id} = num2str(num_unique(unique_id));
    end
    temp_fit = sz_id(:,anova_col_ID);
    
    % Epileptic Or Not
    case 3
    % 1: Epileptic 2: Naive
    anova_col_ID = 4;
    to_plot = 1;
    subdiv_index{1} = find(sz_id(:,anova_col_ID)<100);
    subdiv_index{2} = find(sz_id(:,anova_col_ID)>=100);
    legend_text = {'Epileptic','Naive'};
    temp_fit(subdiv_index{1}) = 1;
    temp_fit(subdiv_index{2}) = 0;

    % Split By Early/Late/End of Experiment
    case 4
    % 1: Early 2: Middle 3: Late
    anova_col_ID = 5;
    to_plot = 1;
    num_unique = unique(sz_id(:,anova_col_ID));
    for unique_id = 1 :length(num_unique)
        subdiv_index{unique_id} = find(sz_id(:,anova_col_ID) == num_unique(unique_id)); % If Epileptic Only: & sz_id(:,2)<100);
    end
    legend_text = {'Early','Middle','End'};
    temp_fit = sz_id(:,anova_col_ID);
    
    case 5
    % Longer or Shorter than Mean
    anova_col_ID = 3;
    to_plot = 1;
    subdiv_index{1} = find(sz_id(:,anova_col_ID)< mean(sz_id(:,anova_col_ID)));
    subdiv_index{2} = find(sz_id(:,anova_col_ID)>= mean(sz_id(:,anova_col_ID)));
    legend_text = {'Less than Average','More than Average'};
    temp_fit(subdiv_index{1}) = 0;
    temp_fit(subdiv_index{2}) = 1;
    
    case 6
    % Which Folder
    anova_col_ID = 2;
    to_plot = 1;
    num_unique = unique(sz_id(:,anova_col_ID));
    for unique_id = 1 :length(num_unique)
        subdiv_index{unique_id} = find(sz_id(:,anova_col_ID) == num_unique(unique_id)); % If Epileptic Only: & sz_id(:,2)<100);
        legend_text{unique_id} = num2str(num_unique(unique_id));
    end
    temp_fit = sz_id(:,anova_col_ID);
    
    case 7
    % Evoked Or Not
    anova_col_ID = 2;
    to_plot = 1;
    subdiv_index{1} = find(sz_id(:,anova_col_ID) == max(sz_id(:,anova_col_ID)));
    subdiv_index{2} = find(sz_id(:,anova_col_ID) ~= max(sz_id(:,anova_col_ID)));
    legend_text = {'Not Evoked','Evoked'};
    temp_fit(subdiv_index{1}) = 0;
    temp_fit(subdiv_index{2}) = 1;
    
    otherwise
    disp ('Invalid Choice')
    to_plot = 0;
    return
end

% 95% Confidence Interval With SEM
if to_plot
    
    figure
    for i = 1:length(comparison_plot)
    subplot(1,length(comparison_plot),i)
    
    % Generate Unique Colors
    Colorset_plot = cbrewer('qual','Set1',length(subdiv_index));
    Colorset_plot(Colorset_plot>1) = 1;
    Colorset_plot(Colorset_plot<0) = 0;
    
    % Evenly Plots Across One Position
    hold on
    for k = 1:length(subdiv_index)
    if ind_data
    errorbar(1/(length(subdiv_index)+2) + (1/(length(subdiv_index))*(k-1)):1:size(comparison_plot{i},2),mean(comparison_plot{i}(subdiv_index{k},:)),...
        1.96*std(comparison_plot{i}(subdiv_index{k},:))./sqrt(length(subdiv_index{k})),'o',...
        'Color',Colorset_plot(k,:),'LineWidth',2)
    else
    errorbar(1:1:size(comparison_plot{i},2),mean(comparison_plot{i}(subdiv_index{k},:)),...
        1.96*std(comparison_plot{i}(subdiv_index{k},:))./sqrt(length(subdiv_index{k})),':o',...
        'Color',Colorset_plot(k,:),'LineWidth',2)
    end
    if ind_data
    for j = 1:length(to_visualize)
    scatter(j - 1 + 1/(length(subdiv_index)+2) + (1/(length(subdiv_index))*(k-1)) + 1/length(subdiv_index)*rand(1,length(comparison_plot{i}(subdiv_index{k},j))),...
        comparison_plot{i}(subdiv_index{k},j),6,'filled','MarkerFaceColor',Colorset_plot(k,:),...
        'MarkerEdgeColor',Colorset_plot(k,:))
    end
    end
    yline(0,'-k','LineWidth',1)
    xticks(1:length(to_visualize))
    xticklabels({'Pre-Seizure','Stimulation','Sz - Beginning','Sz - Middle','Sz - End','Post Ictal'})
    xtickangle(45)
    end
    
    if i == 1
        title('Area')
    elseif i == 2
        title('Energy')
    elseif i == 3
        title('LineLen')
    elseif i == 4
        title('ZeroX')
    elseif i == 5
        title('Entropy')
    elseif i == 6
        title('RMSAmp')
    elseif i == 7
        title('Skew')
    elseif i == 8
        title('LP Exp')
    elseif i == 9
        title('PLHG')
    elseif i == 10
        title('Coherence')
    elseif i == 11
        title('BP sub30Hz')
    elseif i == 12
        title('BP 30-300Hz')
    else
        % Adds Legend
        h = zeros(length(legend_text), 1);
        for counter_num = 1:length(legend_text)
            h(counter_num) = scatter(0,0,'visible', 'off','MarkerFaceColor',Colorset_plot(counter_num,:),'MarkerEdgeColor',Colorset_plot(counter_num,:));
        end
        title('BP 300Hz+')
        legend(h,legend_text)
    end
    end
    
    disp('Influence of Features (X) on Animal Categorization (Y)');
    fitglm([to_visualize{1},to_visualize{2},to_visualize{3},to_visualize{4},to_visualize{5},to_visualize{6}],temp_fit)
    
    disp('Influence of Animal Traits (X) on Seizure EEG Features - Area (Y)');
    fitglm(sz_id,to_visualize{1}(:,1))
    
    disp('Influence of Animal Traits (X) on Seizure EEG Features - Line Length (Y)');
    fitglm(sz_id,to_visualize{1}(:,3))
end

%% Outputs Sz_Id For HAJI

load([path_EEG,'Seizure_Metadata.mat']);

sz_id = sz_id(1:109,:);
k_means_final_duration = [];

clear subdiv_index to_visualize comparison_plot legend_text anova_col_ID

for folder_num = 3:length(subFolders)-1
    % Loads Features and Seizure
    path_evoked = strcat(path_EEG,subFolders(folder_num).name,'\');
    load([path_evoked,'Split_Features.mat']);
    k_means_final_duration = [k_means_final_duration, k_means_sz_duration];
    
    for i = 1:length(final_output)
        if folder_num == 3 & i == 1
            % Sets Up First One
            for j = 1:size(final_output{i},2)
            if size(final_output{i}{j},1) > 1
            to_visualize{j} = [mean(final_output{i}{j})];
            else
            to_visualize{j} = [(final_output{i}{j})];
            end
            end
        else
            % Continues Filling It In
            for j = 1:size(final_output{i},2)
                if size(final_output{i}{j},1) > 1
                to_visualize{j} = [to_visualize{j};mean(final_output{i}{j})];
                else
                to_visualize{j} = [to_visualize{j};final_output{i}{j}];
                end
            end
        end
    end
end

for i = 1:size(to_visualize{1},2)
for j = 1:length(to_visualize)
sz_id = [sz_id to_visualize{j}(:,i)];
end
end

% writematrix(sz_id)

% Seizure Initiation Spike Inversion During Optical Stimulation

% Type of Seizure/Intensity Within a Day

% Signature End of Seizure State - Pure Spiky Thing Vs Complex Spikes