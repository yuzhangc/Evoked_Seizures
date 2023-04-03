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
to_plot = 0;
% Plot Duration for Raw and Filtered Data (not for verifying filtering but
% for visualization)
plot_duration = 55;
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

% K Means
k_means_classes = 4;

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
    load([path_evoked,'Filtered Seizure Data.mat']);

    % Bandpower
    for i = 1:size(filter_set,1)
    temp_bp_calc = [];
    norm_temp_bp_calc = [];
    for j = 1:length(evoked_sz)
        temp_bp_calc{j}=MovingWinFeats(filtered_evoked_sz{i}{j}, fs_Neuronexus, winLen, winDisp, @bandpower);
        norm_temp_bp_calc{j} = (temp_bp_calc{j} - mean(temp_bp_calc{j}))./std(temp_bp_calc{j});
    end
    bp_calc_evoked{i} = temp_bp_calc;
    norm_bp_calc_evoked{i} = norm_temp_bp_calc;
    end

    for j = 1:length(evoked_sz)
        % Line Length
        LLFn_evoked{j} = MovingWinFeats(evoked_sz{j}, fs_Neuronexus, winLen, winDisp, LLFn);
        norm_LLFn_evoked{j} = (LLFn_evoked{j} - mean(LLFn_evoked{j}))./std(LLFn_evoked{j});
        % Area
        Area_evoked{j} = MovingWinFeats(evoked_sz{j}, fs_Neuronexus, winLen, winDisp, Area);
        norm_Area_evoked{j} = (Area_evoked{j} - mean(Area_evoked{j}))./std(Area_evoked{j});
        % Energy
        Energy_evoked{j} = MovingWinFeats(evoked_sz{j}, fs_Neuronexus, winLen, winDisp, Energy);
        norm_Energy_evoked{j} = (Energy_evoked{j} - mean(Energy_evoked{j}))./std(Energy_evoked{j});
        % Zero Crossing
        Zero_Crossing_evoked{j} = MovingWinFeats(evoked_sz{j}, fs_Neuronexus, winLen, winDisp, ZeroCrossing);
        norm_Zero_Crossing_evoked{j} = (Zero_Crossing_evoked{j} - mean(Zero_Crossing_evoked{j}))./std(Zero_Crossing_evoked{j});
        if to_plot
            figure;
            subplot(4,1,1)
            plot(winDisp:winDisp:floor(size(evoked_sz{j},1)/fs_Neuronexus/winDisp - (winLen-winDisp)/winDisp)*winDisp,norm_LLFn_evoked{j})
            xlabel('Seconds')
            ylabel('Line Length')
            title(['Line Length - ',subFolders(folder_num).name, ' Seizure #', num2str(j)]);
            subplot(4,1,2)
            plot(winDisp:winDisp:floor(size(evoked_sz{j},1)/fs_Neuronexus/winDisp - (winLen-winDisp)/winDisp)*winDisp,norm_Area_evoked{j})
            xlabel('Seconds')
            ylabel('Area')
            title(['Area - ',subFolders(folder_num).name, ' Seizure #',num2str(j)]);
            subplot(4,1,3)
            plot(winDisp:winDisp:floor(size(evoked_sz{j},1)/fs_Neuronexus/winDisp - (winLen-winDisp)/winDisp)*winDisp,norm_Energy_evoked{j})
            xlabel('Seconds')
            ylabel('Energy')
            title(['Energy - ',subFolders(folder_num).name, ' Seizure #',num2str(j)]);
            subplot(4,1,4)
            plot(winDisp:winDisp:floor(size(evoked_sz{j},1)/fs_Neuronexus/winDisp - (winLen-winDisp)/winDisp)*winDisp,norm_Zero_Crossing_evoked{j})
            xlabel('Seconds')
            ylabel('Zero Crossing')
            title(['Zero Crossing - ',subFolders(folder_num).name, ' Seizure #',num2str(j)]);
            
            figure
            for i = 1:size(filter_set,1)
            subplot(size(filter_set,1),1,i)
            plot(winDisp:winDisp:floor(size(evoked_sz{j},1)/fs_Neuronexus/winDisp - (winLen-winDisp)/winDisp)*winDisp,norm_bp_calc_evoked{i}{j})
            xlabel('Seconds')
            ylabel([num2str(filter_set(i,1)), ' - ' num2str(filter_set(i,2)), ' Hz'])
            title(['Bandpower - ',subFolders(folder_num).name, ' Seizure #',num2str(j)]);
            end
        end
    end
    save([path_evoked,'Raw Features.mat'],'LLFn_evoked', 'Area_evoked', 'Energy_evoked', 'Zero_Crossing_evoked', 'bp_calc_evoked')
    save([path_evoked,'Normalized Features.mat'],'norm_LLFn_evoked', 'norm_Area_evoked', 'norm_Energy_evoked', ...
        'norm_Zero_Crossing_evoked', 'norm_bp_calc_evoked')

    clear LLFn_evoked Area_evoked Energy_evoked Zero_Crossing_evoked 
    clear norm_LLFn_evoked norm_Area_evoked norm_Energy_evoked norm_Zero_Crossing_evoked norm_bp_calc_evoked
end

clear evoked_sz evoked_stim_length delay_length second_stim_length evoked_sz
clear fs_Neuronexus fs_EEG t_after t_before_Neuronexus filter_set filtered_evoked_sz
clear i j k folder_num temp_bp_calc norm_temp_bp_calc bp_calc_spont bp_calc_evoked

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
        norm_Zero_Crossing_evoked{seizure}];
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
        scatter(xaxis,ones(1,length(xaxis))*k,[],Colorset_plot(k_means_evoked(1:length(xaxis),seizure),:))
        ylim([-1,k+1])
        hold off
        title([subFolders(folder_num).name, ' Seizure ',num2str(seizure)])
    end
    end
    
    clear norm_LLFn_evoked norm_Area_evoked norm_Energy_evoked norm_Zero_Crossing_evoked norm_bp_calc_evoked
    clear evoked_sz evoked_stim_length delay_length second_stim_length evoked_sz norm_factor
    clear fs_Neuronexus fs_EEG t_after t_before_Neuronexus filter_set filtered_evoked_sz i j k
end

%% Specific Predictions

clear paired_output_evoked paired_Kmeans_Mdl k_means_evoked

pairings = [5 8 6 9 7 2; 5 5 6 5 7 1; 1 5 2 4 2 2];

for row = 1:size(pairings,1)
for folder_num = 1:size(pairings,2)/2
        
    path_evoked = strcat(path_EEG,subFolders(pairings(row,2*folder_num-1)+2).name,'\');
    load([path_evoked,'Normalized Features.mat']);
    load([path_evoked,'Filtered Seizure Data.mat']);
    
    Output_Array_evoked = [];
    seizure = pairings(row,2*folder_num);
    Output_Array_evoked = [norm_Area_evoked{seizure}, norm_Energy_evoked{seizure}, norm_LLFn_evoked{seizure},...
        norm_Zero_Crossing_evoked{seizure}];
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
title(subFolders(pairings(row,2)+2).name, ' Seizures')
end

end