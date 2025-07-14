function [output_data] = filter_downsample(path_extract,fs,plot_duration)

% On-Demand Seizures Facilitate Rapid Screening of Therapeutics for Epilepsy
% Authors: Yuzhang Chen, Brian Litt, Flavia Vitale, Hajime Takano
% DOI: https://doi.org/10.7554/eLife.101859

% Function Purpose: Filter Raw EEG Data.

% Input Variables:
% path_extract - path for seizures.
% fs - sampling rate
% plot_duration - duration to plot

% Output Variables:
% output_data = output of function

% -------------------------------------------------------------------------

% Step 1: Import Seizure Parameters & Load Extracted Raw (Standardized)
% Data

disp("Working on: " + path_extract)
mkdir(path_extract,'Figures\Filtered')

load(strcat(path_extract,"Standardized Seizure Data.mat"))
sz_parameters = readmatrix(strcat(path_extract,'Trials Spreadsheet.csv'));

% -------------------------------------------------------------------------

% Step 2: Create 60 Hz notch filters (up to Nyquist frequency). Notch Filter Data

max_filter = 10;
for filter_cnt = 1:max_filter
    wo = filter_cnt * 60/(fs/2); bw = wo/35; [b,a] = iirnotch(wo,bw);
    for sz_cnt = 1:length(output_data)
        output_data{sz_cnt} = filtfilt(b,a,output_data{sz_cnt});
    end
    disp("Progress: Filter #" + num2str(filter_cnt) + " Out Of " + num2str(max_filter) + " Complete")
end

% -------------------------------------------------------------------------

% Step 3: 4 Hz Highpass Filter
   
% Design 6th order Butterworth Highpass Filter To Retain Signals Above 4 Hz
[b,a] = butter(6 ,4/(fs/2) ,'high');
for sz_cnt = 1:length(output_data)
    output_data{sz_cnt} = filtfilt(b,a,output_data{sz_cnt});
    disp("High Pass Progress: Seizure #" + num2str(sz_cnt) + " Out Of " + num2str(length(output_data)) + " Complete")
end
    
disp("High Pass Filtering Complete.")

% -------------------------------------------------------------------------

for sz_cnt = 1:length(output_data)
    
% Step 4: Plots filtered data and saves figures
fig1 = figure(1); hold on;
fig1.WindowState = 'maximized';
% Channel 1 is on TOP. Channel 4 is on Bottom.
for channel = 1:size(output_data{sz_cnt},2)
    plot(1/fs : 1/fs : t_before + t_after , output_data{sz_cnt}(:,channel)./ max(output_data{sz_cnt}(:,channel))...
        * 0.5 + size(output_data{sz_cnt},2) - channel,'k')
end

% Set Axes Limit. Draws Line Around Stimulation.
ylim([-1,size(output_data{sz_cnt},2)+1]); xlim([0,t_before + t_after])
xlabel('Time (sec)')
xlim([0, plot_duration])

% Box For Evocation
if sz_parameters(sz_cnt,8) ~= -1
    if sz_parameters(sz_cnt,8) == 473
        color_first = [0 0 1];
    elseif sz_parameters(sz_cnt,8) == 488
        color_first = [0 1 1];
    end
    rectangle('Position',[t_before size(output_data{sz_cnt},2) sz_parameters(sz_cnt,12) 0.25], 'FaceColor',color_first)
end

% Box For Second Stimulation
if sz_parameters(sz_cnt,10) ~= -1
    if sz_parameters(sz_cnt,10) == 473
        color_second = [0 1 1];
    elseif sz_parameters(sz_cnt,10) == 488
        color_second = [0 0 1];
    elseif sz_parameters(sz_cnt,10) == 660
        color_second = [1 0 0];
    elseif sz_parameters(sz_cnt,10) == 560 || sz_parameters(sz_cnt,10) == 530
        color_second = [0 1 0];
    else
        color_second = [0 0 0];
    end
    rectangle('Position',[sz_parameters(sz_cnt,13) + t_before, size(output_data{sz_cnt},2) + 0.25, sz_parameters(sz_cnt,14), 0.25], 'FaceColor',color_second)
end

% Titling, Saving Figures
figure_title = strcat("Figures\Filtered\M",num2str(sz_parameters(sz_cnt,1)),"_T",num2str(sz_parameters(sz_cnt,2)),...
    "_",num2str(sz_parameters(sz_cnt,8)),"STIM_POW",num2str(sz_parameters(sz_cnt,9)),"mW_",num2str(sz_parameters(sz_cnt,12)),...
    "sec");
plot_title = strcat("Mouse: ",num2str(sz_parameters(sz_cnt,1))," Trial: ",num2str(sz_parameters(sz_cnt,2)),...
    " Vis. Seizure: ",num2str(sz_parameters(sz_cnt,5)));
rational_check = [sz_parameters(sz_cnt,10),sz_parameters(sz_cnt,11),sz_parameters(sz_cnt,13),sz_parameters(sz_cnt,14),sz_parameters(sz_cnt,15)];
if ismember(-1,rational_check) && mean(rational_check == -1) == 1
    if sz_parameters(sz_cnt,1) > 99
        plot_title = strcat(plot_title, " | Day ", num2str(sz_parameters(sz_cnt,20)), " | Seizure Scale ", num2str(sz_parameters(sz_cnt,21)));
    end
elseif ismember(-1,rational_check)
    figure_title = strcat(figure_title,"ERROR");
    plot_title = strcat(plot_title," ERROR");
else
    condition_txt = "";
    if sz_parameters(sz_cnt,13) < -1
        condition_txt = "Before";
    elseif sz_parameters(sz_cnt,13) == 0
        condition_txt = "Concur";
    else
        condition_txt = "After";
    end
    plot_title = strcat(plot_title, " | Second Stim ", num2str(sz_parameters(sz_cnt,15)), " Hz ", num2str(sz_parameters(sz_cnt,10))," nm ", condition_txt);
    
    if sz_parameters(sz_cnt,1) > 99
        plot_title = strcat(plot_title, " | Day ", num2str(sz_parameters(sz_cnt,20)), " | Seizure Scale ", num2str(sz_parameters(sz_cnt,21)));
    end
        
    figure_title = strcat(figure_title,"_AND_",num2str(sz_parameters(sz_cnt,10)),"STIM_POW",num2str(sz_parameters(sz_cnt,11)),"mW_",...
        num2str(sz_parameters(sz_cnt,14)),"sec_",num2str(sz_parameters(sz_cnt,15)),"Hz_STARTING_",num2str(abs(sz_parameters(sz_cnt,13))),...
        "sec_",condition_txt);
end
title(plot_title);
saveas(fig1,fullfile(strcat(path_extract,figure_title,".png")),'png');
hold off; close(fig1);
end

% Step 6: Saves filtered Data
save(strcat(path_extract,'Filtered Seizure Data.mat'),'t_after','t_before','sz_parameters','output_data','fs',"-v7.3");

end