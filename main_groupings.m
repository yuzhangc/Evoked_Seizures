% The purpose of this main file is not to compare between spontaneous and 
% evoked seizures but rather to compare within spontaneous seizures

clear all

directory = 'D:\';
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
to_plot = 1;
% Plot Duration for Raw and Filtered Data (not for verifying filtering but
% for visualization)
plot_duration = 55;
% How many plots to plot
num_to_plot = 2;
% Seizures to Plot. If null, randomly chooses
folders_to_plot = [1,2,5,7];
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
    % First Row is Always Stim Duration, Second Row is Delay, 3rd is 2nd
    % Stim Duration
    
    evoked_stim_length = times_sequence(:,1)';
    if size(times_sequence,2) >= 2
        delay_length = times_sequence(:,2)';
    else
        delay_length = [];
    end
    if size(times_sequence,2) >= 3
        second_stim_length = times_sequence(:,3)';
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

%% Plot Normalized to 1 (Of the Z Score Plots)

if isempty(evoked_sz_to_plot) 
    evoked_sz_to_plot = randperm(length(filtered_evoked_sz{1}),num_to_plot);
end