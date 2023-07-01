function [seizure_duration,min_thresh] = predict_seizure_duration(path_extract,sz_model)

% Uses a pre-defined seizure model to identify seizure length.

% Input Variables
% path_extract - path for normalized seizure features and seizure
% parameters
% sz_model - input seizure model for detection
% 
% Output Variables
% seizure_duration - calculated seizure_duration
% min_thresh - has below components
% power - power at which 2/3 of time reliably induce seizures
% duration - duration at which 2/3 of time reliably induce seizures
% seizures - trial #s for evoked events above min power AND duration
%       (excluding diazepam)
% avg_success - success rate for evocation above min power AND duration or
%       for ALL if threshold was not found (excluding diazepam)
% diaz_seizures - trial # for diazepam seizures above threshold
% diaz_success - success rate for evocation with diazepam

% -------------------------------------------------------------------------

% Step 1: Loads Features and Seizure Parameters

disp("Working on: " + path_extract)
sz_parameters = readmatrix(strcat(path_extract,'Trials Spreadsheet.csv'));
load(strcat(path_extract,'Normalized Features.mat'))

% Step 2: Generate Seizure Duration Matrix. Initiate all to Zeros.

seizure_duration = zeros(size(sz_parameters,1),1);

% Step 3: Determine Length.

for sz_cnt = 1:size(sz_parameters,1)
    
    % Skip Seizures If Visual Inspection Shows 0
    if sz_parameters(sz_cnt,5) == 0
    else
        % Use Model to Determine Seizure Length
    end
    
end

% -------------------------------------------------------------------------

% Step 4: Determine Threshold Power and Duration (> 50% of trials cause
% events lasting longer than 10 seconds, include all trials in calculation)

% This section only works for later experiments since in early ones there were
% only one/two repeats.

% Unique Counts
number_power = unique(sz_parameters(:,9));
number_duration = unique(sz_parameters(:,12));

% Sets Up Output
min_thresh.power = 1000;
min_thresh.duration = 1000;

% -------------------------------------------------------------------------

% Minimum Power Calculation Using Non Diazepam Trials

for cnt = 1:length(number_power)
    
    trials = find(sz_parameters(:,9) == number_power(cnt) & sz_parameters(:,16) == 0);
    
    % Ignore One/Two Offs & Higher Powers if Threshold Already Determined
    if length(trials) > 2 && number_power(cnt) < min_thresh.power
        
        % If evoke > 2/3 of time, determine that as threshold
        if mean(sz_parameters(trials,5)) >= 2/3
            min_thresh.power = number_power(cnt);
        end
        
    end
end

% -------------------------------------------------------------------------

% Minimum Duration Calculation Using Non Diazepam Trials

for cnt = 1:length(number_duration)
    
    trials = find(sz_parameters(:,12) == number_duration(cnt) & sz_parameters(:,16) == 0);
    
    % Ignore one/two offs & higher durations if threshold already determined
    if length(trials) > 2 && number_duration(cnt) < min_thresh.duration
        
        % If evoke > 2/3 of time, determine that as threshold
        if mean(sz_parameters(trials,5)) >= 2/3
            min_thresh.duration = number_duration(cnt);
        end
        
    end
end

% -------------------------------------------------------------------------

% In case of failure, notify user

if min_thresh.power == 1000
    min_thresh.power = -1;
    disp("Failed to determine threshold power");
end

if min_thresh.duration == 1000
    min_thresh.duration = -1;
    disp("Failed to determine threshold duration");
end

% -------------------------------------------------------------------------

% Step 5: Compile List of Above Threshold (non Diazepam) Seizures, Success Rate
% When Evoked Above Threshold (without Diazepam), and Above Threshold (Diazepam)
% Seizures and Success Rate of Evocation With Diazepam

if min_thresh.power ~= -1 && min_thresh.duration ~= -1
    
    min_thresh.seizures = find(sz_parameters(:,12) >= min_thresh.duration & sz_parameters(:,9) >= min_thresh.power & sz_parameters(:,16) == 0);
    min_thresh.avg_success = mean(sz_parameters(min_thresh.seizures,5));
    min_thresh.diaz_seizures = find(sz_parameters(:,12) >= min_thresh.duration & sz_parameters(:,9) >= min_thresh.power & sz_parameters(:,16) == 1);
    if isempty(min_thresh.diaz_seizures)
        min_thresh.diaz_success = -1;
    else
        min_thresh.diaz_success = mean(sz_parameters(min_thresh.diaz_seizures,5));
    end
    
else
    
    min_thresh.seizures = [];
    min_thresh.avg_success = mean(sz_parameters(find(sz_parameters(:,16) == 0),5));
    min_thresh.diaz_seizures = find(sz_parameters(:,16) == 1);
    if isempty(min_thresh.diaz_seizures)
        min_thresh.diaz_success = -1;
    else
        min_thresh.diaz_success = mean(sz_parameters(find(sz_parameters(:,16) == 1),5));
    end
    
end

% -------------------------------------------------------------------------

end
