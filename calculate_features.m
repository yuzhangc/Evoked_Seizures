function [features,norm_features] = calculate_features(path_extract,filter_sz,feature_list, winLen, winDisp, bp_filters)

% Calculate selected features on data. Note feature 10 is specific to 4
% channel recordings.

% Input Variables
% path_extract - path for seizures.
% filter_sz - whether to calculate features for filtered or unfiltered data
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

% Output Variables
% features - calculated features
% norm_featured - normalized_features

% -------------------------------------------------------------------------

% Import Seizure Data.

disp("Working on: " + path_extract)
if filter_sz
load(strcat(path_extract,"Filtered Seizure Data.mat"))
else
load(strcat(path_extract,"Standardized Seizure Data.mat"))
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
norm_features.Line_Length = norm_LLFn_calc{sz_cnt};

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
norm_features.Area = norm_Area_calc{sz_cnt};

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
norm_features.Energy = norm_Energy_calc{sz_cnt};

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
norm_features.Zero_Crossing = norm_Zero_Crossing_calc{sz_cnt};

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
norm_features.RMS = norm_RMS_calc{sz_cnt};

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
norm_features.Skew = norm_Skew_calc{sz_cnt};

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
norm_features.AEntropy = norm_AEntropy_calc{sz_cnt};

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
norm_features.LP_Exp = norm_LP_Exp_calc{sz_cnt};

end

% -------------------------------------------------------------------------

% Case 9: Phase Locked High Gamma
if ismember(9, feature_list)
end

% -------------------------------------------------------------------------

% Case 10: Coherence Between Channels - https://www.mathworks.com/help/signal/ref/mscohere.html
if ismember(10, feature_list)
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
norm_features.Mean_Abs_Dev = norm_Mean_Abs_Dev_calc{sz_cnt};

end

% -------------------------------------------------------------------------

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
    
    % Adds BP_output to Features
    features.Band_Power = BP_output;
    norm_features.Band_Power = norm_BP_output;
    
end

end