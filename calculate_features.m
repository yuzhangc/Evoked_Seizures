function [features,norm_features] = calculate_features(path_extract,filter_sz,feature_list, winLen, winDisp, bp_filters)

% Calculate selected features on data

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
% 11 - 
% 12/end - Band Power by bp_filters pairs

% Output Variables
% features - calculated features
% norm_featured - normalized_features

% -------------------------------------------------------------------------

% Import Seizure Data.

strcat("Working on: ", path_extract)
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

end

% -------------------------------------------------------------------------
% Case 5: Root Mean Squared (Amplitude) - https://www.mathworks.com/help/matlab/ref/rms.html
% 6 - Skewness - https://www.mathworks.com/help/stats/skewness.html
% 7 - Approximate Entropy - https://www.mathworks.com/help/predmaint/ref/approximateentropy.html
% 8 - Lyapunov Exponent (Chaos) - https://www.mathworks.com/help/predmaint/ref/lyapunovexponent.html
% 9 - Phase Locked High Gamma
% 10 - Coherence Between Channels - https://www.mathworks.com/help/signal/ref/mscohere.html
% 11 - 
% 12/end - Band Power by bp_filters pairs