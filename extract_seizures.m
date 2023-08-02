function [output_data] = extract_seizures(path_extract,t_before,t_after,plot_duration)

clear output_data

% Standardizes seizure data into fixed segment with t_before seconds before]
% before the evocation stimulus and t_after seconds after evocation
% stimulus.

% Input Variables
% path_extract - path for seizures.
% t_before - time before seizures to extract in seconds
% t_after - time after seizures to extract in seconds
% plot_duration - duration to plot

% Output Variables
% output_data = output of function

% -------------------------------------------------------------------------

% Import Seizure Parameters and Determine Recording Type.
% Type 3 - Oldest Acutely Evoked Recordings. 1 second baseline. Neuronexus
% Type 2 - New Acutely Evoked Recordings. Neuronexus
% Type 1 - EEG Recordings.

disp("Working on: " + path_extract)

sz_parameters = readmatrix(strcat(path_extract,'Trials Spreadsheet.csv'));
if sz_parameters(1,1) <= 4
    type = 3; stim_channel = 2; t_before = 1; fs = 20000; second_channel = 1;
elseif sz_parameters(1,1) < 100
    type = 2; stim_channel = 1; fs = 20000; second_channel = 2;
else
    type = 1; fs = 2000;
end

% -------------------------------------------------------------------------

% Type 1 - Spontaneous Seizures & Chronic Evoked. Video EEG Data. Sampling Rate 2000 Hz
if type == 1

% Generate Filelist of EEG Files (has Cage in name)
filelist = dir(strcat(path_extract,'*Cage*.mat'));

mkdir(path_extract,'Figures\Raw')

% Step 0: Extracts Visually Identified Stimulation/Seizure Start Time
stim_start_all = sz_parameters(:,17);

for count = 1:length(filelist)
    
    % Step 1: Determine Plot Color For All Optical Stimulus.
    
    % First - Evocation Stimulus
    first_plot_color = '';
    if sz_parameters(count,8) ~= -1
        if sz_parameters(count,8) == 488
            first_plot_color = 'c';
        elseif sz_parameters(count,8) == 473
            first_plot_color = 'b';
        end
    % Otherwise Spontaneous
    elseif sz_parameters(count,8) == -1
        first_plot_color = 'k';
    end
    
    % Second - Treatment Stimulus
    second_plot_color = '';
    if sz_parameters(count,10) ~= -1 && sz_parameters(count,10) ~= sz_parameters(count,8)
        if sz_parameters(count,10) == 560 || sz_parameters(count,10) == 530
            second_plot_color = 'g';
        elseif sz_parameters(count,10) == 660
            second_plot_color = 'r';
        end
    % If equal, then blue
    elseif sz_parameters(count,10) == 473
        second_plot_color = 'b';
    elseif sz_parameters(count,10) == 488
        second_plot_color = 'c';
    end
    
    % Step 2: Reads files
    Cdata = load(strcat(path_extract,filelist(count).name));
    amplifier_data = Cdata.Csave;
    clear Cdata;
    
    % Step 3: Adjusts start time depending on how many seconds before to
    % extract
    stim_start = stim_start_all(count) - t_before * fs;
    
    % Step 4: Extracts relevant sections
    output_data{count} = amplifier_data(stim_start:stim_start + t_before * fs + t_after * fs - 1,:);

    % Step 5: Generates Confirmatory Plot
    fig1 = figure(1); hold on;
    fig1.WindowState = 'maximized';
    % Channel 1 is on TOP. Channel 4 is on Bottom.
    for channel = 1:size(output_data{count},2)
        plot(1/fs : 1/fs : t_before + t_after , output_data{count}(:,channel)./ max(output_data{count}(:,channel))...
            * 0.5 + size(output_data{count},2) - channel)
    end
    
    % Draws line around stimulation and second stimulus. Sets Figure Position
    if sz_parameters(count,8) ~= -1
    xline(t_before,strcat('-',first_plot_color),'Evocation','LineWidth',2); xline(t_before + sz_parameters(count,12),strcat('-',first_plot_color),'LineWidth',2);
    else
    xline(t_before,strcat('-',first_plot_color),'Spontaneous Start','LineWidth',2);
    end
    if sz_parameters(count,10) ~= -1
    xline(t_before + sz_parameters(count,13),strcat('-',second_plot_color),'Treatment','LineWidth',2); xline(t_before + sz_parameters(count,13) + sz_parameters(count,14),strcat('-',second_plot_color),'LineWidth',2);
    end
    
    % Set Axes Limit. Draws Line Around Stimulation.
    ylim([-2,size(output_data{count},2) + 0.5]); xlim([0,t_before + t_after])
    xlim([0, plot_duration]) 
    
    % Titling, Saving Figures
    figure_title = strcat("Figures\Raw\M",num2str(sz_parameters(count,1)),"_T",num2str(sz_parameters(count,2)),...
        "_",num2str(sz_parameters(count,8)),"STIM_POW",num2str(sz_parameters(count,9)),"mW_",num2str(sz_parameters(count,12)),...
        "sec");
    plot_title = strcat("Mouse: ",num2str(sz_parameters(count,1))," Trial: ",num2str(sz_parameters(count,2)),...
        " Vis. Seizure: ",num2str(sz_parameters(count,5)));
    rational_check = [sz_parameters(count,10),sz_parameters(count,11),sz_parameters(count,13),sz_parameters(count,14),sz_parameters(count,15)];
    if ismember(-1,rational_check) && mean(rational_check == -1) == 1
    elseif ismember(-1,rational_check)
        figure_title = strcat(figure_title,"ERROR");
        plot_title = strcat(plot_title," ERROR");
    else
        condition_txt = "";
        if sz_parameters(count,13) < -1
            condition_txt = "Before";
        elseif sz_parameters(count,13) == 0
            condition_txt = "Concur";
        else
            condition_txt = "After";
        end
        plot_title = strcat(plot_title, " | Second Stim ", num2str(sz_parameters(count,15)), " Hz ", num2str(sz_parameters(count,10))," nm ", condition_txt);
        figure_title = strcat(figure_title,"_AND_",num2str(sz_parameters(count,10)),"STIM_POW",num2str(sz_parameters(count,11)),"mW_",...
            num2str(sz_parameters(count,14)),"sec_",num2str(sz_parameters(count,15)),"Hz_STARTING_",num2str(abs(sz_parameters(count,13))),...
            "sec_",condition_txt);
    end
    title(plot_title);
    saveas(fig1,fullfile(strcat(path_extract,figure_title,".png")),'png');
    hold off; close(fig1);
end

% -------------------------------------------------------------------------

% Other Types - Evoked Seizures. Neuronexus Data. Sampling Rate 20000 Hz
else

% Generate Filelist of Neuronexus Files
filelist = dir(strcat(path_extract,'*.rhd'));

mkdir(path_extract,'Figures\Raw')

for count = 1:length(filelist)
    
    % Step 1: Determine how much the stimulus start duration needs to be
    % moved to account for pre-evocation blue light therapies. 
    move_start = 0;
    % Determines if blue light was tested as a therapeutic
    if sz_parameters(count,8) == sz_parameters(count,10) && sz_parameters(count,13) < -1
        move_start = -1 * sz_parameters(count,13);
    end
    % Determine Plot Color For Second Stimulus. Only valid for type 2
    % recordings.
    second_plot_color = '';
    if sz_parameters(count,10) ~= -1 && sz_parameters(count,10) ~= sz_parameters(count,8)
        if sz_parameters(count,10) == 560 || sz_parameters(count,10) == 530
            second_plot_color = 'g';
        elseif sz_parameters(count,10) == 660
            second_plot_color = 'r';
        end
    % If equal, then blue
    elseif sz_parameters(count,10) == 473
        second_plot_color = 'b';
    end

    % Step 2: Reads files
    [board_adc_data,amplifier_data] = modded_read_Intan_RHD2000_file(filelist(count).name,path_extract);
    
    % Step 3: Finds onset of evocation stimulus - blue light, adjusted for
    % move_start duration
    stim_start = find(board_adc_data(stim_channel,:) > 3 , 1) - t_before * fs + move_start * fs;
    
    % Step 4: Extracts relevant sections
    output_data{count} = amplifier_data(:, stim_start:stim_start + t_before * fs + t_after * fs - 1)';
    
    % Step 5: Generates Confirmatory Plot
    fig1 = figure(1); hold on;
    fig1.WindowState = 'maximized';
    % Channel 1 is on TOP. Channel 4 is on Bottom.
    for channel = 1:size(output_data{count},2)
        plot(1/fs : 1/fs : t_before + t_after , output_data{count}(:,channel)./ max(output_data{count}(:,channel))...
            * 0.5 + size(output_data{count},2) - channel)
    end
    % Evocation Laser Plot
    plot(1/fs : 1/fs : t_before + t_after , board_adc_data(stim_channel,stim_start:stim_start + t_before * fs ...
        + t_after * fs - 1)./ max(board_adc_data(stim_channel,stim_start:stim_start + t_before * fs ...
        + t_after * fs - 1)) * 0.5 - 1.5,'b')
    if sz_parameters(count,10) ~= -1 && sz_parameters(count,10) ~= sz_parameters(count,8)
    plot(1/fs : 1/fs : t_before + t_after , board_adc_data(second_channel,stim_start:stim_start + t_before * fs ...
        + t_after * fs - 1)./ max(board_adc_data(second_channel,stim_start:stim_start + t_before * fs ...
        + t_after * fs - 1)) * 0.5 - 2,second_plot_color)
    end
    
    % Draws line around stimulation and second stimulus. Sets Figure Position
    xline(t_before,'-b','Evocation','LineWidth',2); xline(t_before + sz_parameters(count,12),'-b','LineWidth',2);
    if sz_parameters(count,10) ~= -1
    xline(t_before + sz_parameters(count,13),strcat('-',second_plot_color),'Treatment','LineWidth',2); xline(t_before + sz_parameters(count,13) + sz_parameters(count,14),strcat('-',second_plot_color),'LineWidth',2);
    end
    
    % Set Axes Limit. Draws Line Around Stimulation.
    ylim([-2,size(output_data{count},2) + 0.5]); xlim([0,t_before + t_after])
    xlim([0, plot_duration]) 
    
    % Titling, Saving Figures
    figure_title = strcat("Figures\Raw\M",num2str(sz_parameters(count,1)),"_T",num2str(sz_parameters(count,2)),...
        "_",num2str(sz_parameters(count,8)),"STIM_POW",num2str(sz_parameters(count,9)),"mW_",num2str(sz_parameters(count,12)),...
        "sec");
    plot_title = strcat("Mouse: ",num2str(sz_parameters(count,1))," Trial: ",num2str(sz_parameters(count,2)),...
        " Vis. Seizure: ",num2str(sz_parameters(count,5)));
    rational_check = [sz_parameters(count,10),sz_parameters(count,11),sz_parameters(count,13),sz_parameters(count,14),sz_parameters(count,15)];
    if ismember(-1,rational_check) && mean(rational_check == -1) == 1
    elseif ismember(-1,rational_check)
        figure_title = strcat(figure_title,"ERROR");
        plot_title = strcat(plot_title," ERROR");
    else
        condition_txt = "";
        if sz_parameters(count,13) < -1
            condition_txt = "Before";
        elseif sz_parameters(count,13) == 0
            condition_txt = "Concur";
        else
            condition_txt = "After";
        end
        plot_title = strcat(plot_title, " | Second Stim ", num2str(sz_parameters(count,15)), " Hz ", num2str(sz_parameters(count,10))," nm ", condition_txt);
        figure_title = strcat(figure_title,"_AND_",num2str(sz_parameters(count,10)),"STIM_POW",num2str(sz_parameters(count,11)),"mW_",...
            num2str(sz_parameters(count,14)),"sec_",num2str(sz_parameters(count,15)),"Hz_STARTING_",num2str(abs(sz_parameters(count,13))),...
            "sec_",condition_txt);
    end
    title(plot_title);
    saveas(fig1,fullfile(strcat(path_extract,figure_title,".png")),'png');
    hold off; close(fig1);

end

end

% Saves Extracted Data
save(strcat(path_extract,'Standardized Seizure Data.mat'),'t_after','t_before','sz_parameters','output_data','fs',"-v7.3");

end