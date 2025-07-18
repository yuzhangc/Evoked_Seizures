function [features,norm_features] = calculate_features(path_extract,filter_sz,feature_list, winLen, winDisp, bp_filters)

% On-Demand Seizures Facilitate Rapid Screening of Therapeutics for Epilepsy
% Authors: Yuzhang Chen, Brian Litt, Flavia Vitale, Hajime Takano
% DOI: https://doi.org/10.7554/eLife.101859

% Function Purpose: Calculate selected features on data. Note feature 10 is
% specific to 4 channel recordings.

% Input Variables
% path_extract - path for seizures.
% filter_sz - whether to calculate features for filtered or unfiltered data
% filter_sz was set to only filtered data in paper.
% feature_list - list of features below

% 1 - Line Length
% 2 - Area
% 3 - Energy
% 4 - Zero Crossing
% 5 - Root Mean Squared (Amplitude) - https://www.mathworks.com/help/matlab/ref/rms.html
% 6 - Skewness - https://www.mathworks.com/help/stats/skewness.html
% 7 - Approximate Entropy - https://www.mathworks.com/help/predmaint/ref/approximateentropy.html
% 8 - Lyapunov Exponent (Chaos) - https://www.mathworks.com/help/predmaint/ref/lyapunovexponent.html
% 9 - Phase Locked High Gamma
% 10 - Coherence Between Channels - https://www.mathworks.com/help/signal/ref/mscohere.html
% 11 - Mean Absolute Deviation - https://www.mathworks.com/help/stats/mad.html
% 12/end - Band Power by bp_filters pairs

% winLen - Windows Length 
% winDisp - Windows Displacement
% bp_filters - Set of Bandpower Filters

% Output Variables
% features - calculated features
% norm_featured - normalized_features

% -------------------------------------------------------------------------

% Import Seizure Data and Parameters

disp("Working on: " + path_extract)
if filter_sz
load(strcat(path_extract,"Filtered Seizure Data.mat"))
else
load(strcat(path_extract,"Standardized Seizure Data.mat"))
end

sz_parameters = readmatrix(strcat(path_extract,'Trials Spreadsheet.csv'));

% -------------------------------------------------------------------------

% Due to Plotting Requirements. Band Power Goes First
% Case 12: Band Power by bp_filters pairs
if ismember(12, feature_list)
    
    disp("Working on Band Power. May Take a While.")
    
    % Main Output Variable
    clear BP_output norm_BP_output
    
    % Loops Through bp_filter pairs
    for bp_pair = 1:size(bp_filters,1)
    disp("Filter #" + num2str(bp_pair) + " out of " + num2str(size(bp_filters,1)) + ...
        ": " + num2str(bp_filters(bp_pair,1)) + "Hz to " + num2str(bp_filters(bp_pair,2)) + "Hz")
    
    % Loops Through All Seizures. Calculate feature and z score normalization.
    for sz_cnt = 1:length(output_data)
    BP_calc{sz_cnt} = moving_window_feature_calculation(output_data{sz_cnt}, fs, winLen, winDisp, @bandpower,{fs,[bp_filters(bp_pair,:)]});
    norm_BP_calc{sz_cnt} = (BP_calc{sz_cnt} - mean(BP_calc{sz_cnt}))./std(BP_calc{sz_cnt});
    end
    
    % Adds to BP_output
    BP_output{bp_pair} = BP_calc;
    norm_BP_output{bp_pair} = norm_BP_calc;
    
    end
    
    % Adds BP_output to Features.
    features.Band_Power = BP_output;
    norm_features.Band_Power = norm_BP_output;
   
    disp("Band Power Completed")
    
end

% -------------------------------------------------------------------------

% Case 1: Line Length

if ismember(1, feature_list)

% Define Function
LLFn = @(x) sum(abs(diff(x)));

% Loops Through All Seizures. Calculate feature and z score normalization.
for sz_cnt = 1:length(output_data)
    LL_calc{sz_cnt} = moving_window_feature_calculation(output_data{sz_cnt}, fs, winLen, winDisp, LLFn,[]);
    norm_LLFn_calc{sz_cnt} = (LL_calc{sz_cnt} - mean(LL_calc{sz_cnt}))./std(LL_calc{sz_cnt});
end

% Adds to Features
features.Line_Length = LL_calc;
norm_features.Line_Length = norm_LLFn_calc;

disp("Line Length Completed")

end

% -------------------------------------------------------------------------

% Case 2: Area

if ismember(2, feature_list)

% Define Function
Area = @(x) sum(abs(x));

% Loops Through All Seizures. Calculate feature and z score normalization.
for sz_cnt = 1:length(output_data)
    Area_calc{sz_cnt} = moving_window_feature_calculation(output_data{sz_cnt}, fs, winLen, winDisp, Area,[]);
    norm_Area_calc{sz_cnt} = (Area_calc{sz_cnt} - mean(Area_calc{sz_cnt}))./std(Area_calc{sz_cnt});
end

% Adds to Features
features.Area = Area_calc;
norm_features.Area = norm_Area_calc;

disp("Area Completed")

end

% -------------------------------------------------------------------------

% Case 3: Energy

if ismember(3, feature_list)

% Define Function
Energy = @(x)  sum(x.^2);

% Loops Through All Seizures. Calculate feature and z score normalization.
for sz_cnt = 1:length(output_data)
    Energy_calc{sz_cnt} = moving_window_feature_calculation(output_data{sz_cnt}, fs, winLen, winDisp, Energy,[]);
    norm_Energy_calc{sz_cnt} = (Energy_calc{sz_cnt} - mean(Energy_calc{sz_cnt}))./std(Energy_calc{sz_cnt});
end

% Adds to Features
features.Energy = Energy_calc;
norm_features.Energy = norm_Energy_calc;

disp("Energy Completed")

end

% -------------------------------------------------------------------------

% Case 4: Zero Crossing Around Mean
if ismember(4, feature_list)

% Define Function
Zero_Crossing = @(x) sum((x(2:end) - mean(x) > 0 & x(1:end-1) - mean(x) < 0))...
    + sum((x(2:end) - mean(x) < 0 & x(1:end-1) - mean(x) > 0));

% Loops Through All Seizures. Calculate feature and z score normalization.
for sz_cnt = 1:length(output_data)
    Zero_Crossing_calc{sz_cnt} = moving_window_feature_calculation(output_data{sz_cnt}, fs, winLen, winDisp, Zero_Crossing,[]);
    norm_Zero_Crossing_calc{sz_cnt} = (Zero_Crossing_calc{sz_cnt} - mean(Zero_Crossing_calc{sz_cnt}))./std(Zero_Crossing_calc{sz_cnt});
end

% Adds to Features
features.Zero_Crossing = Zero_Crossing_calc;
norm_features.Zero_Crossing = norm_Zero_Crossing_calc;

disp("Zero Crossing Completed")

end

% -------------------------------------------------------------------------

% Case 5: Root Mean Squared (Amplitude) - https://www.mathworks.com/help/matlab/ref/rms.html
if ismember(5, feature_list)
    
% Loops Through All Seizures. Calculate feature and z score normalization.
for sz_cnt = 1:length(output_data)
    RMS_calc{sz_cnt} = moving_window_feature_calculation(output_data{sz_cnt}, fs, winLen, winDisp, @rms,[]);
    norm_RMS_calc{sz_cnt} = (RMS_calc{sz_cnt} - mean(RMS_calc{sz_cnt}))./std(RMS_calc{sz_cnt});
end

% Adds to Features
features.RMS = RMS_calc;
norm_features.RMS = norm_RMS_calc;

disp("Root Mean Squared Amplitude Completed")

end

% -------------------------------------------------------------------------

% Case 6: Skewness - https://www.mathworks.com/help/stats/skewness.html
if ismember(6, feature_list)
    
% Loops Through All Seizures. Calculate feature and z score normalization.
for sz_cnt = 1:length(output_data)
    Skew_calc{sz_cnt} = moving_window_feature_calculation(output_data{sz_cnt}, fs, winLen, winDisp, @skewness,[]);
    norm_Skew_calc{sz_cnt} = (Skew_calc{sz_cnt} - mean(Skew_calc{sz_cnt}))./std(Skew_calc{sz_cnt});
end

% Adds to Features
features.Skew = Skew_calc;
norm_features.Skew = norm_Skew_calc;

disp("Skew Completed")

end

% -------------------------------------------------------------------------

% Case 7: Approximate Entropy - https://www.mathworks.com/help/predmaint/ref/approximateentropy.html
if ismember(7, feature_list)

disp("Working on Approximate Entropy. May Take a While.")
    
% Loops Through All Seizures. Calculate feature and z score normalization.
for sz_cnt = 1:length(output_data)
    AEntropy_calc{sz_cnt} = moving_window_feature_calculation(output_data{sz_cnt}, fs, winLen, winDisp, @approximateEntropy,[]);
    norm_AEntropy_calc{sz_cnt} = (AEntropy_calc{sz_cnt} - mean(AEntropy_calc{sz_cnt}))./std(AEntropy_calc{sz_cnt});
    disp("Progress: " + num2str(sz_cnt) + " out of " + num2str(length(output_data)));
end

% Adds to Features
features.AEntropy = AEntropy_calc;
norm_features.AEntropy = norm_AEntropy_calc;

disp("Approximate Entropy Completed")

end

% -------------------------------------------------------------------------

% Case 8: Lyapunov Exponent (Chaos) - https://www.mathworks.com/help/predmaint/ref/lyapunovexponent.html
if ismember(8, feature_list)
    
disp("Working on Lyapunov Exponent. May Take a While.")
    
% Loops Through All Seizures. Calculate feature and z score normalization.
for sz_cnt = 1:length(output_data)
    LP_Exp_calc{sz_cnt} = moving_window_feature_calculation(output_data{sz_cnt}, fs, winLen, winDisp, @lyapunovExponent,[]);
    norm_LP_Exp_calc{sz_cnt} = (LP_Exp_calc{sz_cnt} - mean(LP_Exp_calc{sz_cnt}))./std(LP_Exp_calc{sz_cnt});
    disp("Progress: " + num2str(sz_cnt) + " out of " + num2str(length(output_data)));
end

% Adds to Features
features.LP_Exp = LP_Exp_calc;
norm_features.LP_Exp = norm_LP_Exp_calc;

disp("Lyapunov Exponent Completed")

end

% -------------------------------------------------------------------------

% Case 9: Phase Locked High Gamma
if ismember(9, feature_list)

% Loops Through All Seizures. Calculate feature and z score normalization.
for sz_cnt = 1:length(output_data)
    PLHG_calc{sz_cnt} = moving_window_feature_calculation(output_data{sz_cnt}, fs, winLen, winDisp, @plhg,{fs});
    norm_PLHG_calc{sz_cnt} = (PLHG_calc{sz_cnt} - mean(PLHG_calc{sz_cnt}))./std(PLHG_calc{sz_cnt});
end

% Adds to Features
features.PLHG = PLHG_calc;
norm_features.PLHG = norm_PLHG_calc;

disp("Phase Locked High Gamma Completed")
    
end

% -------------------------------------------------------------------------

% Case 10: Coherence Between Channels - https://www.mathworks.com/help/signal/ref/mscohere.html
if ismember(10, feature_list)
    
disp("Working on Coherence. May Take a While.")

% Loops Through All Seizures. Calculate feature and z score normalization.
for sz_cnt = 1:length(output_data)
    Coherence_calc{sz_cnt} = windowed_coherence(output_data{sz_cnt}, fs, winLen, winDisp);
    norm_Coherence_calc{sz_cnt} = (Coherence_calc{sz_cnt} - mean(Coherence_calc{sz_cnt}))./std(Coherence_calc{sz_cnt});
    disp("Progress: " + num2str(sz_cnt) + " out of " + num2str(length(output_data)));
end

% Adds to Features
features.Coherence = Coherence_calc;
norm_features.Coherence = norm_Coherence_calc;

disp("Coherence (4 Channel) Completed")

end

% -------------------------------------------------------------------------

% Case 11: Mean Absolute Deviation - https://www.mathworks.com/help/stats/mad.html
if ismember(11, feature_list)
    
% Loops Through All Seizures. Calculate feature and z score normalization.
for sz_cnt = 1:length(output_data)
    Mean_Abs_Dev_calc{sz_cnt} = moving_window_feature_calculation(output_data{sz_cnt}, fs, winLen, winDisp, @mad,[]);
    norm_Mean_Abs_Dev_calc{sz_cnt} = (Mean_Abs_Dev_calc{sz_cnt} - mean(Mean_Abs_Dev_calc{sz_cnt}))./std(Mean_Abs_Dev_calc{sz_cnt});
end

% Adds to Features
features.Mean_Abs_Dev = Mean_Abs_Dev_calc;
norm_features.Mean_Abs_Dev = norm_Mean_Abs_Dev_calc;

disp("Mean Absolute Deviation Completed")

end

% -------------------------------------------------------------------------

% Plots Normalized Features Only

% Creates Directory
mkdir(path_extract,'Figures\Normalized Features')

% Loops Through All Seizures
for sz_cnt = 1:length(output_data)

    fig1 = figure(1);
    fig1.WindowState = 'maximized';
    
    % Chooses colormap for plot
    colormap('winter')
    
    % If exist band power, adjusts start by how many band power plots we
    % have to plot
    
    if ismember(12, feature_list)
        adjustment_val = size(bp_filters,1);
        start_value = 2;
        
        % Generate Subplot For Bandpower (Specifically)
        
        for bp_plot_count = 1:size(bp_filters,1)
            
            % Plots Each Segment Separately
            plot1 = subplot(length(feature_list) + adjustment_val,1,bp_plot_count + 1);
            imagesc(norm_features.Band_Power{bp_plot_count}{sz_cnt}');
            colorbar
            
            % Sets Color Axis. Higher Frequencies Have Lower Increases
            caxis([0,size(bp_filters,1) + 1 - bp_plot_count])
            
            % Sets Title
            title(strcat("Band Power: ", num2str(bp_filters(bp_plot_count,1))," Hz to ", num2str(bp_filters(bp_plot_count,2)), " Hz"));
            
            % This Part Copied From Below ---------------------------------
            
            % Generate Tick Labels For Plots
            xticklabel = winDisp:winDisp:floor(size(output_data{sz_cnt},1)/fs/winDisp - (winLen-winDisp)/winDisp)*winDisp;
            xticks = round(linspace(1, size(norm_features.Band_Power{bp_plot_count}{sz_cnt}, 1), (t_after+t_before)./5));
            xticklabels = xticklabel(xticks);

            % Set X Ticks For Plots
            set(plot1, 'XTick', xticks, 'XTickLabel', xticklabels)
            xlim([0.25 60/winDisp]);
            
            % End Copied Portion ------------------------------------------
            
        end
     
    % Otherwise, no adjustment needed outside of for first plot
    
    else
       
        adjustment_val = 1;
        start_value = 1;
        
    end
    
    % First Plot is Raw Channel. Choose Cortex (Freely Moving)
    plot1 = subplot(length(feature_list) + adjustment_val,1,1); channel = 3;
    plot(1/fs:1/fs:t_before + t_after, output_data{sz_cnt}(:,channel)./ max(output_data{sz_cnt}(:,channel))...
            * 0.5 + size(output_data{sz_cnt},2) - channel,'k');
    xlim([0.25 60]);
    colorbar;
    
    % Generate Subplot For All Other Features
    for plot_count = start_value:length(feature_list)
        
        % Generate Subplot
        plot1 = subplot(length(feature_list) + adjustment_val,1,plot_count + adjustment_val);
        % Extracts Feature Names
        feature_names = fieldnames(norm_features);
        
        % Plots with colorbar
        imagesc(norm_features.(feature_names{plot_count}){sz_cnt}');
        colorbar
        
        % Generate Tick Labels For Plots
        xticklabel = winDisp:winDisp:floor(size(output_data{sz_cnt},1)/fs/winDisp - (winLen-winDisp)/winDisp)*winDisp;
        xticks = round(linspace(1, size(norm_features.(feature_names{plot_count}){sz_cnt}, 1), (t_after+t_before)./5));
        xticklabels = xticklabel(xticks);
        
        % Set X Ticks For Plots
        set(plot1, 'XTick', xticks, 'XTickLabel', xticklabels)
        xlim([0.25 60/winDisp]);
        
        if strcmp(feature_names{plot_count}, "Line_Length") || strcmp(feature_names{plot_count}, "Zero_Crossing") || strcmp(feature_names{plot_count}, "Coherence")
            caxis([-1,1])
        elseif strcmp(feature_names{plot_count}, "Area") || strcmp(feature_names{plot_count}, "RMS")
            caxis([-1,2.5])
        elseif strcmp(feature_names{plot_count}, "Energy")
            caxis([-1,5])
        else
            caxis([-2,2])
        end
        
        % Uses Feature Name as Title, Removing Underscores and Replacing
        % With Spaces
        plot_title = strrep(feature_names{plot_count},"_"," ");
        title(plot_title)
        
    end
    
    % Saves Figures
    saveas(fig1,fullfile(strcat(path_extract,"Figures\Normalized Features\Seizure ",num2str(sz_parameters(sz_cnt,2)),".png")),'png');    
    close(fig1)
    
end

% -------------------------------------------------------------------------

% Saves Features

save(strcat(path_extract,'Raw Features.mat'),'t_after','t_before','sz_parameters','winLen','winDisp','features','filter_sz','bp_filters','fs',"-v7.3");
save(strcat(path_extract,'Normalized Features.mat'),'t_after','t_before','sz_parameters','winLen','winDisp','norm_features','filter_sz','bp_filters','fs',"-v7.3");

end