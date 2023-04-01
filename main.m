% Overarching Parameters
clear all

directory = 'D:\';
% Do I need to extract data? If so first_run should equal 1
first_run = 0;
% Is data filtered? If not (0), should filter.
filtered = 1;
% Downsample should be always set to true, otherwise filtering takes eons.
to_downsample = 1;
% Filter Sets
filter_set = [1 30; 30 300];
% Do I want to use normalized data? Only relevant in filtering.
normalized = 1;

% Do I want to plot data?
to_plot = 0;
% Plot Duration for Raw and Filtered Data (not for verifying filtering but
% for visualization)
plot_duration = 55;
% How many plots to plot
num_to_plot = 2;
% Seizures to Plot. If null, randomly chooses
spont_sz_to_plot = [3 4];
evoked_sz_to_plot = [11 2];

% Spectrogram
t_res = 0.5;
freq_limits =[1 300];
overlap_per = 50;
% Colorbar Limits on Spectrogram
colorbarlim_spont = [-100,-20];
colorbarlim_evoked = [-60,-30];

% Spectral Density
% How much after 'seizure start' do I want to move the beginning of the
% window to?
EEG_window_modifier = 15;
Nx_window_modifier = 0;
% Window of Spectral Density (Sec)
t_win = 5;
% Window For Feature Calculation (Sec)
winLen = t_res;
winDisp = t_res*overlap_per/100;

%% Data Extraction and Standardization

if first_run && not(filtered)

% Spontaneous Seizures
path_EEG = strcat(directory,'EEG\');
% Time Before Seizure Start to Extract
t_before_EEG = 50;
% Time After Seizure Start to Extract (same for Neuronexus and EEG)
t_after = 180;
% Frequency of EEG Files
fs_EEG = 2000;

% Visually Identified EEG Seizure Start
% 1. H25M_6_Cage1_0353_0553
% 2. H25M_6_Cage1_1807_2007
% 3. H25M_6_Cage2_1947_2147
% 4. H25M_6_Cage3_0604_0858
% 5. H25M_6_Cage3_1119_end
% 6. H25M_6_Cage2_2132_end
% 7. H25M_6_Cage3_1956_0034
% Note: 5 and 3 has two distinct parts; Seizure 3's start is at the start 
% of higher activity but Seizure 5's start was pushed back beyond the
% initial large single spikes.

t_start_EEG = [7339500, 7290000, 7052000, 7264000, 7285000, 7225000, 7260000];

% Extracts Spontaneous Seizure Data
spont_sz = extract_seizures(path_EEG,t_before_EEG,t_after,fs_EEG,1,t_start_EEG);

% Optional Plots
if to_plot
    for i = 1:length(spont_sz)
        figure
        plot(spont_sz{i});
        title(['Spontaneous Seizure ',num2str(i)]);
    end
end

% Evoked Seizures
path_evoked = strcat(directory,'EEG\Isoflurane Evoked\');
t_before_Neuronexus = 5;
% Frequency of EEG Files
fs_Neuronexus = 20000;

% Stimulation Duration
evoked_stim_length = [5 5 5 7 5 7 5 3 15 7 10 5 7 10 7 5];

% Extracts Evoked Seizure Data
evoked_sz = extract_seizures(path_evoked,t_before_Neuronexus,t_after,fs_Neuronexus,2,evoked_stim_length);

% Clears Excess Variables Transferred to Main Workspace by
% modded_read_Intan_RHD2000
clear amplifier_channels ans aux_input_channels board_adc_channels filename frequency_parameters
clear notes path spike_triggers supply_voltage_channels supply_voltage_data t_amplifier t_aux_input
clear t_board_adc t_supply_voltage aux_input_data amplifier_data board_adc_data

% Optional Plots
if to_plot
    for i = 1:length(evoked_sz)
        figure
        plot(evoked_sz{i});
        title(['Evoked Seizure ',num2str(i)]);
    end
end

save([directory,'EEG\','Standardized Seizure Data.mat'],'evoked_stim_length','evoked_sz','fs_EEG',...
    'fs_Neuronexus','spont_sz','t_after','t_before_EEG', 't_before_Neuronexus', 't_start_EEG');

elseif not(filtered)
    
load([directory,'EEG\','Standardized Seizure Data.mat']);

end

%% Filter Data

if not(filtered)
    
    % If Working With Normalized Data
    
    if normalized
    
    % Normalize Seizures to Max Amplitude (I believe this allows for better
    % comparison across different animals)
    
    % Normalizes Evoked Seizures to Max Amplitude
    evoked_sz = normalize_to_max_amp(evoked_sz,[]);
    
    % Normalizes Spontaneous Seizures to Max Amplitude
    spont_sz = normalize_to_max_amp(spont_sz,[]);
        
    if to_plot
        for i = 1:length(evoked_sz)
            figure
            plot(evoked_sz{i});
            title(['Normalized Evoked Seizure ',num2str(i)]);
        end
        for i = 1:length(spont_sz)
            figure
            plot(spont_sz{i});
            title(['Normalized Spontaneous Seizure ',num2str(i)]);
        end
    end
    
    end
    
    if to_downsample
        % Downsample Normalized Data
        for sz_cnt = 1:length(evoked_sz)
            evoked_sz{sz_cnt} = downsample(evoked_sz{sz_cnt},fs_Neuronexus/fs_EEG);
        end
        fs_Neuronexus = fs_EEG;
    end
    
    % Bandpass Filter Data
    [filtered_spont_sz,spont_sz] = filter_all(spont_sz, filter_set,fs_EEG);
    [filtered_evoked_sz,evoked_sz] = filter_all(evoked_sz, filter_set,fs_EEG);
    
    % Optional Plots
    if to_plot
        for i = 1:size(filter_set,1)
            for j = 1:size(filtered_spont_sz{i},2)
                figure;
                plot(filtered_spont_sz{i}{j})
                title(['Spontaneous Seizure ',num2str(j),': Filters ',...
                    num2str(filter_set(i,1)),'Hz and ',...
                    num2str(filter_set(i,2)),'Hz bands']);
            end
            for j = 1:size(filtered_evoked_sz{i},2)
                figure;
                plot(filtered_evoked_sz{i}{j})
                title(['Evoked Seizure ',num2str(j),': Filters ',...
                    num2str(filter_set(i,1)),'Hz and ',...
                    num2str(filter_set(i,2)),'Hz bands']);
            end
        end
    end
    
    save([directory,'EEG\','Filtered Seizure Data.mat'],'evoked_stim_length','filtered_evoked_sz','fs_EEG',...
    'fs_Neuronexus','filtered_spont_sz','t_after','t_before_EEG', 't_before_Neuronexus', 't_start_EEG', 'filter_set',...
    'evoked_sz', 'spont_sz');

    clear i j sz_cnt

else
    
    load([directory,'EEG\','Filtered Seizure Data.mat']);
    
end

%% Plots All Channels for Selected Seizures

if isempty(spont_sz_to_plot)
    spont_sz_to_plot = randperm(length(filtered_spont_sz{1}),num_to_plot);
end
if isempty(evoked_sz_to_plot) 
    evoked_sz_to_plot = randperm(length(filtered_evoked_sz{1}),num_to_plot);
end

if to_plot
    
    % i is for each filter
    for i = 1:size(filter_set,1)
    % j is for each pair of sponaneous and evoked seizures
    for j = 1:num_to_plot 
    figure;
    subplot(2,1,1)
        % k = Each Channel
        hold on
        for k = 1:size(filtered_spont_sz{i}{spont_sz_to_plot(j)},2)
        plot(1/fs_EEG:1/fs_EEG:plot_duration+t_before_Neuronexus,...
            filtered_spont_sz{i}{spont_sz_to_plot(j)}((t_before_EEG-t_before_Neuronexus)*fs_EEG:...
            (t_before_EEG+plot_duration)*fs_EEG-1,k)+(k-1)*1,'Color','k')
        end
        ylim([-1,k])
        hold off
        title(['Spontaneous Seizure ',num2str(spont_sz_to_plot(j)),': Filtered between ',...
            num2str(filter_set(i,1)),'Hz and ', num2str(filter_set(i,2)),'Hz bands'])
     subplot(2,1,2)   
        % k = Each Channel
        hold on
        for k = 1:size(filtered_evoked_sz{i}{evoked_sz_to_plot(j)},2)
        plot(1/fs_Neuronexus:1/fs_Neuronexus:plot_duration+t_before_Neuronexus,...
            filtered_evoked_sz{i}{evoked_sz_to_plot(j)}(1+(evoked_stim_length(evoked_sz_to_plot(j))-t_before_Neuronexus)*fs_Neuronexus:...
            (evoked_stim_length(evoked_sz_to_plot(j))+plot_duration)*fs_Neuronexus,k)+(k-1)*1,'Color','k')
        end
        hold off
        ylim([-1,k])
        xlabel('Time (sec)')
        title(['Evoked Seizure ',num2str(evoked_sz_to_plot(j)),': Filtered between ',...
            num2str(filter_set(i,1)),'Hz and ', num2str(filter_set(i,2)),'Hz bands'])
    end
    end
    
end

%% Spectrogram for All Channels for Selected Seizures

if to_plot
% j is for each pair of sponaneous and evoked seizures
for j = 1:num_to_plot 
    figure;
    % k is for each channel, so we get spectrogram of all the channels
    for k = 1:size(evoked_sz{evoked_sz_to_plot(j)},2)
        subplot(size(evoked_sz{evoked_sz_to_plot(j)},2),1,k)
        pspectrum(evoked_sz{evoked_sz_to_plot(j)}(1+(evoked_stim_length(evoked_sz_to_plot(j)))*fs_Neuronexus:...
        (evoked_stim_length(evoked_sz_to_plot(j))+t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)...
        ,fs_Neuronexus,'spectrogram', 'FrequencyLimits',freq_limits,'TimeResolution',t_res,'OverlapPercent',overlap_per)
        ylabel(['Ch ',num2str(k),' Hz']);
        if k == 1
            title(['Spectrogram for Evoked Seizure ', num2str(evoked_sz_to_plot(j))])
        else
            title('')
        end
        if k == size(evoked_sz{evoked_sz_to_plot(j)},2)
        else
            xlabel('')
        end
        caxis(colorbarlim_evoked)
        colorbar('hide')
    end

    % Spontaneous Seizures
    figure;
    for k = 1:size(spont_sz{spont_sz_to_plot(j)},2)
        subplot(size(spont_sz{spont_sz_to_plot(j)},2),1,k)
        pspectrum(spont_sz{spont_sz_to_plot(j)}((t_before_EEG-t_before_Neuronexus)*fs_EEG:...
            (t_before_EEG+plot_duration)*fs_EEG-1,k)...
        ,fs_EEG,'spectrogram', 'FrequencyLimits',freq_limits,'TimeResolution',t_res,'OverlapPercent',overlap_per)
        ylabel(['Ch ',num2str(k),' Hz']);
        if k == 1
            title(['Spectrogram for Spontaneous Seizure ', num2str(spont_sz_to_plot(j))])
        else
            title('')
        end
        if k == size(spont_sz{spont_sz_to_plot(j)},2)
        else
            xlabel('')
        end
        caxis(colorbarlim_spont)
        colorbar('hide')
    end
end

end

%% Power Density Plot

if to_plot
figure

% Plots Sponaneous Seizure Power Density Plot on Top Row
for j = 1:num_to_plot 
subplot(2,num_to_plot,j)
hold on
for k = 1:size(spont_sz{spont_sz_to_plot(j)},2)
    [pxx,f] = pwelch(spont_sz{spont_sz_to_plot(j)}((t_before_EEG+EEG_window_modifier)*fs_EEG:...
        (t_before_EEG+EEG_window_modifier+t_win)*fs_EEG-1,k),500,300,500,fs_EEG);
    plot(f,10*log10(pxx),'LineWidth',2)
end
title(['Spontaneous Seizure ',num2str(spont_sz_to_plot(j))])
xlim([0,300])
xlabel('Frequency Hz')
ylabel('Power/Frequency dB/Hz')
hold off
end

% Plots Evoked Seizure Power Density Plot on Bottom Row
for j = 1:num_to_plot 
subplot(2,num_to_plot,j+num_to_plot)
hold on
for k = 1:size(evoked_sz{evoked_sz_to_plot(j)},2)
    [pxx,f] = pwelch(evoked_sz{evoked_sz_to_plot(j)}(1+(Nx_window_modifier+t_before_Neuronexus+evoked_stim_length(evoked_sz_to_plot(j)))*fs_EEG:...
    (evoked_stim_length(evoked_sz_to_plot(j))+Nx_window_modifier+t_before_Neuronexus+t_win)*fs_Neuronexus,k),500,300,500,fs_Neuronexus);
    plot(f,10*log10(pxx),'LineWidth',2)
end
title(['Evoked Seizure ',num2str(evoked_sz_to_plot(j))])
xlim([0,300])
xlabel('Frequency Hz')
ylabel('Power/Frequency dB/Hz')
hold off
end

end

clear pxx f

%% Equation Based Feature Calculation

clear LLFn_evoked norm_LLFn_evoked LLFn_spont norm_LLFn_spont
clear Area_evoked norm_Area_evoked Area_spont norm_Area_spont
clear Energy_evoked norm_Energy_evoked Energy_spont norm_Energy_spont
clear Zero_Crossing_evoked norm_Zero_Crossing_evoked Zero_Crossing_spont norm_Zero_Crossing_spont

% Line Length
LLFn = @(x) sum(abs(diff(x)));
% Area
Area = @(x) sum(abs(x));
% Energy
Energy = @(x)  sum(x.^2);
% Zero Crossing Around Mean
ZeroCrossing = @(x) sum((x(2:end) - mean(x) > 0 & x(1:end-1) - mean(x) < 0))...
    + sum((x(2:end) - mean(x) < 0 & x(1:end-1) - mean(x) > 0));

% Calculates Features One By One
% Then, Normalize Feature by Subtract By Mean And Divide By St Dev.
% Plots Normalized Features since they will be sent into classifier

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
        title(['Line Length - Evoked Seizure ',num2str(j)]);
        subplot(4,1,2)
        plot(winDisp:winDisp:floor(size(evoked_sz{j},1)/fs_Neuronexus/winDisp - (winLen-winDisp)/winDisp)*winDisp,norm_Area_evoked{j})
        xlabel('Seconds')
        ylabel('Area')
        title(['Area - Evoked Seizure ',num2str(j)]);
        subplot(4,1,3)
        plot(winDisp:winDisp:floor(size(evoked_sz{j},1)/fs_Neuronexus/winDisp - (winLen-winDisp)/winDisp)*winDisp,norm_Energy_evoked{j})
        xlabel('Seconds')
        ylabel('Energy')
        title(['Energy - Evoked Seizure ',num2str(j)]);
        subplot(4,1,4)
        plot(winDisp:winDisp:floor(size(evoked_sz{j},1)/fs_Neuronexus/winDisp - (winLen-winDisp)/winDisp)*winDisp,norm_Zero_Crossing_evoked{j})
        xlabel('Seconds')
        ylabel('Zero Crossing')
        title(['Zero Crossing - Evoked Seizure ',num2str(j)]);
    end
end


for j = 1:length(spont_sz)
    % Line Length
    LLFn_spont{j} = MovingWinFeats(spont_sz{j}, fs_EEG, winLen, winDisp, LLFn);
    norm_LLFn_spont{j} = (LLFn_spont{j} - mean(LLFn_spont{j}))./std(LLFn_spont{j});
    % Area
    Area_spont{j} = MovingWinFeats(spont_sz{j}, fs_EEG, winLen, winDisp, Area);
    norm_Area_spont{j} = (Area_spont{j} - mean(Area_spont{j}))./std(Area_spont{j});
    % Energy
    Energy_spont{j} = MovingWinFeats(spont_sz{j}, fs_EEG, winLen, winDisp, Energy);
    norm_Energy_spont{j} = (Energy_spont{j} - mean(Energy_spont{j}))./std(Energy_spont{j});
    % Zero Crossing
    Zero_Crossing_spont{j} = MovingWinFeats(spont_sz{j}, fs_EEG, winLen, winDisp, ZeroCrossing);
    norm_Zero_Crossing_spont{j} = (Zero_Crossing_spont{j} - mean(Zero_Crossing_spont{j}))./std(Zero_Crossing_spont{j});
    if to_plot
        figure;
        subplot(4,1,1)
        plot(winDisp:winDisp:floor(size(spont_sz{j},1)/fs_EEG/winDisp - (winLen-winDisp)/winDisp)*winDisp,norm_LLFn_spont{j})
        xlabel('Seconds')
        ylabel('Line Length')
        title(['Line Length - Spontaneous Seizure ',num2str(j)]);
        subplot(4,1,2)
        plot(winDisp:winDisp:floor(size(spont_sz{j},1)/fs_EEG/winDisp - (winLen-winDisp)/winDisp)*winDisp,norm_Area_spont{j})
        xlabel('Seconds')
        ylabel('Area')
        title(['Area - Spontaneous Seizure ',num2str(j)]);
        subplot(4,1,3)
        plot(winDisp:winDisp:floor(size(spont_sz{j},1)/fs_EEG/winDisp - (winLen-winDisp)/winDisp)*winDisp,norm_Energy_spont{j})
        xlabel('Seconds')
        ylabel('Energy')
        title(['Energy - Spontaneous Seizure ',num2str(j)]);
        subplot(4,1,4)
        plot(winDisp:winDisp:floor(size(spont_sz{j},1)/fs_EEG/winDisp - (winLen-winDisp)/winDisp)*winDisp,norm_Zero_Crossing_spont{j})
        xlabel('Seconds')
        ylabel('Zero Crossing')
        title(['Zero Crossing - Spontaneous Seizure ',num2str(j)]);
    end
end

clear LLFn_evoked LLFn_spont Area_evoked Area_spont 
clear Energy_evoked Energy_spont Zero_Crossing_evoked Zero_Crossing_spont 

%% Additional Feature Calculation

% Band Power According to Filters
for i = 1:size(filter_set,1)
    temp_bp_calc = [];
    norm_temp_bp_calc = [];
    for j = 1:length(evoked_sz)
        temp_bp_calc{j}=MovingWinFeats(filtered_evoked_sz{i}{j}, fs_Neuronexus, winLen, winDisp, @bandpower);
        norm_temp_bp_calc{j} = (temp_bp_calc{j} - mean(temp_bp_calc{j}))./std(temp_bp_calc{j});
    end
    bp_calc_evoked{i} = temp_bp_calc;
    norm_bp_calc_evoked{i} = norm_temp_bp_calc;
    
    temp_bp_calc = [];
    norm_temp_bp_calc = [];
    for j = 1:length(spont_sz)
        temp_bp_calc{j}=MovingWinFeats(filtered_spont_sz{i}{j}, fs_EEG, winLen, winDisp, @bandpower);
        norm_temp_bp_calc{j} = (temp_bp_calc{j} - mean(temp_bp_calc{j}))./std(temp_bp_calc{j});
    end
    bp_calc_spont{i} = temp_bp_calc;
    norm_bp_calc_spont{i} = norm_temp_bp_calc;
end

clear temp_bp_calc norm_temp_bp_calc bp_calc_spont bp_calc_evoked

%% Categorization

% Sets Random Number Generator
rng(1);

% Compile all features per seizure. Features (Columns) By Timepoints(Row)
% Perform K Means Segregation and PCA

% Basic Three State Plot
Colorset_plot = [1 0 0; 0 1 0; 0 0 1];

Output_Array_evoked = [];
for seizure = 1:length(norm_Area_evoked)
    Output_Array_evoked{seizure} = [norm_Area_evoked{seizure}, norm_Energy_evoked{seizure}, norm_LLFn_evoked{seizure},...
        norm_Zero_Crossing_evoked{seizure}];
    for bandpower_set = 1:length(norm_bp_calc_evoked)
        Output_Array_evoked{seizure} = [Output_Array_evoked{seizure},norm_bp_calc_evoked{bandpower_set}{seizure}];
    end
    
    k_means_evoked(:,seizure) = kmeans(Output_Array_evoked{seizure},3);
    [pca_coeff_evoked{seizure},pca_scores_evoked{seizure}] = pca(Output_Array_evoked{seizure}');
    
    if to_plot
        % PCA
        figure
        scatter3(pca_coeff_evoked{seizure}(:,1),pca_coeff_evoked{seizure}(:,2),pca_coeff_evoked{seizure}(:,3),...
            [],Colorset_plot(k_means_evoked(:,seizure),:),'filled')
        xlabel('Principal Component 1')
        ylabel('Principal Component 2')
        zlabel('Principal Component 3')
        title(['Evoked Seizure ', num2str(seizure)]);

        % K Means Over Time
        figure;
        % k = Each Channel
        hold on
        for k = 1:size(evoked_sz{seizure},2)
        plot(1/fs_Neuronexus:1/fs_Neuronexus:plot_duration+t_before_Neuronexus,...
            evoked_sz{seizure}(1:(t_before_Neuronexus+plot_duration)*fs_Neuronexus,k)+(k-1)*1,'Color','k')
        end
        xaxis = winDisp:winDisp:(plot_duration+t_before_Neuronexus);
        scatter(xaxis,ones(1,length(xaxis))*k,[],Colorset_plot(k_means_evoked(1:length(xaxis),seizure),:))
        ylim([-1,k+1])
        hold off
        title(['Evoked Seizure ',num2str(seizure)])
    end
end

Output_Array_spont = [];
for seizure = 1:length(norm_Area_spont)
    Output_Array_spont{seizure} = [norm_Area_spont{seizure},norm_Energy_spont{seizure},norm_LLFn_spont{seizure},...
        norm_Zero_Crossing_spont{seizure}];
    for bandpower_set = 1:length(norm_bp_calc_spont)
        Output_Array_spont{seizure} = [Output_Array_spont{seizure},norm_bp_calc_spont{bandpower_set}{seizure}];
    end
    
    k_means_spont(:,seizure) = kmeans(Output_Array_spont{seizure},3);
    [pca_coeff_spont{seizure},pca_scores_spont{seizure}] = pca(Output_Array_spont{seizure}');
    
    if to_plot
        % PCA
        figure
        scatter3(pca_coeff_spont{seizure}(:,1),pca_coeff_spont{seizure}(:,2),pca_coeff_spont{seizure}(:,3),...
            [],Colorset_plot(k_means_spont(:,seizure),:),'filled')
        xlabel('Principal Component 1')
        ylabel('Principal Component 2')
        zlabel('Principal Component 3')
        title(['Spontaneous Seizure ', num2str(seizure)]);
    
        % K Means Over Time
        figure
        hold on
        for k = 1:size(spont_sz{seizure},2)
        plot(1/fs_EEG:1/fs_EEG:plot_duration+t_before_Neuronexus,...
            spont_sz{seizure}((t_before_EEG-t_before_Neuronexus)*fs_EEG:...
            (t_before_EEG+plot_duration)*fs_EEG-1,k)+(k-1)*1,'Color','k')
        end
        xaxis = winDisp:winDisp:(plot_duration+t_before_Neuronexus);
        scatter(xaxis,ones(1,length(xaxis))*k,[],Colorset_plot(k_means_spont((t_before_EEG-t_before_Neuronexus)/...
            winDisp:(t_before_EEG-t_before_Neuronexus)/winDisp+length(xaxis)-1,seizure),:))
        ylim([-1,k+1])
        hold off
        title(['Spontaneous Seizure ',num2str(seizure)])
    end
end

%% K Means Segregation
% Before Stim is column 1. During stim is column 2. After stim is column 3.

for seizure = 1:length(norm_Area_evoked)
    indexed_k_means(seizure,1) = median(k_means_evoked(1:(t_before_Neuronexus - 0.5)/winDisp,seizure));
    indexed_k_means(seizure,2) = median(k_means_evoked((t_before_Neuronexus + 0.5)/winDisp:...
        (t_before_Neuronexus + evoked_stim_length(seizure) - 0.5)/winDisp,seizure));
    kmeans_tot = 0;
    for i = 1:max(k_means_evoked)
        kmeans_tot = kmeans_tot+i;
    end
    indexed_k_means(seizure,3) = kmeans_tot - indexed_k_means(seizure,1) - indexed_k_means(seizure,2); 
end
indexed_k_means = round(indexed_k_means);

%% Array of Experimental Parameter
load('Experimental_Parameters.mat')

if to_plot

colormap('jet')
% Red Epileptic Blue Non Epileptic
scatter(table2array(ExperimentalParameterList(:,11)),...
    table2array(ExperimentalParameterList(:,12)),[],table2array(ExperimentalParameterList(:,3)),'filled')
xlabel('Laser Power')
ylabel('Minimum Duration')

% Red Ketamine Blue Isoflurane
scatter(table2array(ExperimentalParameterList(:,11)),...
    table2array(ExperimentalParameterList(:,12)),[],table2array(ExperimentalParameterList(:,8)),'filled')
xlabel('Laser Power')
ylabel('Minimum Duration')

clear M_or_F 
for count = 1:size(ExperimentalParameterList,1)
    if table2array(ExperimentalParameterList(count,5))=='M'
        M_or_F(count) = 0;
    else
        M_or_F(count) = 1;
    end
end

% Red Female Blue Male
scatter(table2array(ExperimentalParameterList(:,11)),...
table2array(ExperimentalParameterList(:,12)),[],M_or_F,'filled')
xlabel('Laser Power')
ylabel('Minimum Duration')

% Red Old Blue Young
scatter(table2array(ExperimentalParameterList(:,11)),...
    table2array(ExperimentalParameterList(:,12)),[],...
    table2array(ExperimentalParameterList(:,4))./ max(table2array(ExperimentalParameterList(:,4))),'filled')
xlabel('Laser Power')
ylabel('Minimum Duration')

end