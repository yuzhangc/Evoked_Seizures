function [output_data] = extract_seizures(path_full,t_before,t_after,fs,type,t_start)

% Extracts Seizures From Raw Data
% Input Variables
% path - directory, e.g. 'D:\EEG\Extracted_Raw_Data.mat' for Raw EEG or
%   folder for Evoked Seizures
% t_before - time before seizure start to include in output file
% t_after - time after seizure start to include in output file
% fs - frequency of signal, e.g. 2000 for EEG and 20k for Neuronexus
% type - Type of Data. 1 - Video EEG. 2 - Neuronexus (Blue on ADC Channel
%   1) 3 - Neuronexus (Blue on ADC Channel 2)
% t_start = time of seizure start, for EEG, or length of optic stimulation, 
%   for Neuronexus. Used to adjust windows for extracting seizures
% Output Variables
% output_data - extracted seizure data

% Spontaneous EEG
if type == 1
    load(strcat(path_full,'Extracted_Raw_Data.mat'));
    
    % Use Visually Identified EEG Seizure Start
    % 1. H25M_6_Cage1_0353_0553
    output_data{1} = H25M_6_Cage1_0353_0553(t_start(1) - t_before* fs:t_start(1) + t_after*fs,:);
    % 2. H25M_6_Cage1_1807_2007
    output_data{2} = H25M_6_Cage1_1807_2007(t_start(2) - t_before* fs:t_start(2) + t_after*fs,:);
    % 3. H25M_6_Cage2_1947_2147
    output_data{3} = H25M_6_Cage2_1947_2147(t_start(3) - t_before* fs:t_start(3) + t_after*fs,:);
    % 4. H25M_6_Cage3_0604_0858
    output_data{4} = H25M_6_Cage3_0604_0858(t_start(4) - t_before* fs:t_start(4) + t_after*fs,:);
    % 5. H25M_6_Cage3_1119_end
    output_data{5} = H25M_6_Cage3_1119_end(t_start(5) - t_before* fs:t_start(5) + t_after*fs,:);
    % 6. H25M_6_Cage2_2132_end
    output_data{6} = H25M_6_Cage2_2132_end(t_start(6) - t_before* fs:t_start(6) + t_after*fs,:);
    % 7. H25M_6_Cage3_1956_0034
    output_data{7} = H25M_6_Cage3_1956_0034(t_start(7) - t_before* fs:t_start(7) + t_after*fs,:);
    
% All Newly Collected Data
elseif type == 2
    
    filelist = dir(path_full);
    for count = 3:length(filelist)
        [board_adc_data,amplifier_data] = modded_read_Intan_RHD2000_file(filelist(count).name,path_full);
        clear amplifier_channels ans aux_input_channels board_adc_channels filename frequency_parameters
        clear notes path spike_triggers supply_voltage_channels supply_voltage_data t_amplifier t_aux_input
        clear t_board_adc t_supply_voltage aux_input_data 

        % Finds Onset of Blue Light
        stim_start = find(board_adc_data(1,:) > 3,1) - t_before * fs;
        output_data{count - 2} = amplifier_data(:,stim_start:stim_start+t_after*fs)';
    end
    
% Data Collected From Early Trials
elseif type == 3
    
        filelist = dir(path_full);
        for count = 3:length(filelist)
            [board_adc_data,amplifier_data] = modded_read_Intan_RHD2000_file(filelist(count).name,path_full);
            clear amplifier_channels ans aux_input_channels board_adc_channels filename frequency_parameters
            clear notes path spike_triggers supply_voltage_channels supply_voltage_data t_amplifier t_aux_input
            clear t_board_adc t_supply_voltage aux_input_data 

            % Finds Onset of Blue Light
            stim_start = find(board_adc_data(2,:) > 3,1) - t_before * fs;
            output_data{count - 2} = amplifier_data(:,stim_start:stim_start+t_after*fs)';
        end
    
end

end