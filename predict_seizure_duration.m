function [seizure_duration,min_thresh,output_array,sz_parameters] = predict_seizure_duration(path_extract,sz_model,countdown_sec,to_fix_chart,to_plot,subFolders, max_trial)

% Uses a pre-defined seizure model to identify seizure length.
% Concactenates features

% Input Variables
% path_extract - path for normalized seizure features and seizure
% parameters
% sz_model - input seizure model for detection
% countdown_sec - how many seconds before not counted as seizure
% to_fix_chart - table with seizures durations that should be manually fixed
% to_plot - show plots or not
% 
% Output Variables
% 1) seizure_duration - calculated seizure_duration
%
% 2) min_thresh - has below components
% power - power at which 2/3 of time reliably induce seizures
% duration - duration at which 2/3 of time reliably induce seizures
% seizures - trial #s for evoked events above min power AND duration
%       (excluding diazepam)
% avg_success - success rate for evocation above min power AND duration or
%       for ALL if threshold was not found (excluding diazepam)
% diaz_seizures - trial # for diazepam seizures above threshold
% diaz_success - success rate for evocation with diazepam
%
% 3) output_array - concactenated features, indexed by seizure
%
% 4) sz_parameters - seizure parameters
%
% 5) Subfolders - if size 1 - 1 animal, load raw

% -------------------------------------------------------------------------

% Step 1: Loads Features and Seizure Parameters

disp("Working on: " + path_extract)
load(strcat(path_extract,'Filtered Seizure Data.mat'))
if size(subFolders,1) == 1
load(strcat(path_extract,'Raw Features.mat'))
end
load(strcat(path_extract,'Normalized Features.mat'))
sz_parameters = readmatrix(strcat(path_extract,'Trials Spreadsheet.csv'));

% Adds Levetiracetam and Phenytoin Information For Early Trials
if size(sz_parameters,2) == 16
sz_parameters(1:end,17:18) = 0;
end

% Step 2: Generate Seizure Duration Matrix. Initiate all to Zeros. Extract
% feature names

seizure_duration = zeros(size(sz_parameters,1),1);
feature_names = fieldnames(norm_features);

% -------------------------------------------------------------------------

% Step 3: Determine Length.

for sz_cnt = 1:size(sz_parameters,1)
    
    temp_output_array = [];
    if size(subFolders,1) == 1
        raw_output_array = [];
    end
    
    % Step 3A: Check to determine if channels is equal to 4. Do not perform
    % operation if not
    if (isequal(feature_names{end},'Band_Power'))
    channel_incongruency = rem(size(norm_features.(feature_names{end}){1}{sz_cnt},2),4) ~= 0;
    else
    channel_incongruency = rem(size(norm_features.(feature_names{end}){sz_cnt},2),4) ~= 0;
    end
    
    % Step 3B: Concactenate Features in Order
    for feature_number = 1:length(feature_names)

        % Special Case for Band Power, Concactenate Increasing BP
        % Filters in Order
        if (isequal(feature_names{feature_number},'Band_Power'))
            for bp_cnt = 1:size(bp_filters,1)
                temp_output_array = [temp_output_array,norm_features.(feature_names{feature_number}){bp_cnt}{sz_cnt}];
                if size(subFolders,1) == 1
                raw_output_array = [raw_output_array,features.(feature_names{feature_number}){bp_cnt}{sz_cnt}];
                end
            end
        else
            temp_output_array = [temp_output_array,norm_features.(feature_names{feature_number}){sz_cnt}];
            if size(subFolders,1) == 1
            raw_output_array = [raw_output_array,features.(feature_names{feature_number}){sz_cnt}];
            end
        end

    end
    
    pred_output_array{sz_cnt} = temp_output_array;
    if size(subFolders,1) == 1
        output_array{sz_cnt} = raw_output_array;
    else
        output_array{sz_cnt} = temp_output_array;
    end

    % Skip Seizures If Visual Inspection Shows 0 OR Channel Incongruency
    if channel_incongruency
    else
        
        % Step 3C: Use Model to Classify Seizure or Not
        k_means_pred = predict(sz_model, pred_output_array{sz_cnt});
        
        % Step 3D: Using a Countup/Cooldown Timer to Determine True Seizure
        % Length and Ignore Brief Aberrations ----------------------------
        
        % Sets Initial Countdown to Be Equal to a Few Seconds. Usually a few
        % seconds break is good enough indicator of true termination
        countdown = 0;
        countdown_lim = countdown_sec/winDisp;
        
        % Uses Stimulation Duration to Set Seizure Start As Immediately After
        if sz_parameters(sz_cnt,12) ~= -1
        sz_start = (t_before + sz_parameters(sz_cnt,12))/winDisp;
        else
        sz_start = (t_before)/winDisp;
        end
        sz_pos = sz_start;
        sz_end = sz_start;
        
        % If countdown hasn't reached termination limit OR if seizure is
        % still ongoing (class 2 or 1), continue
        
        if sz_parameters(1,1) < 100
            sz_classes_1 = 2;
            sz_classes_2 = 1;
            non_sz_class = 3;
        else
            sz_classes_1 = 2;
            sz_classes_2 = 3;
            non_sz_class = 1;
        end
        
        final_end = false;
        
        while ((k_means_pred(sz_pos) == sz_classes_2 || k_means_pred(sz_pos) == sz_classes_1) || countdown < countdown_lim) && not(final_end)
            
            % Keeps on Moving Forward if Still Seizing
            if k_means_pred(sz_pos) ~= non_sz_class
                countdown = 0;
                sz_end = sz_pos;
                
            % Increase Cooldown Countdown If Not    
            else
                countdown = countdown + 1;
            end
            
            % Moves Up One Window, Unless at End, then Break
            if sz_pos == size(norm_features.(feature_names{end}){sz_cnt},1)
            countdown = countdown_lim;
            final_end = true;
            else
            sz_pos = sz_pos + 1;
            end
            
        end
        
        % Since Each Increase in sz_pos is by winDisp, Multiply by winDisp to find
        % true duration in seconds
        seizure_duration(sz_cnt) = (sz_end - sz_start).*winDisp;
        
        % End Step 3D ----------------------------------------------------
        
        % Step 3E: Plots Figures With K Means Predictions
        if not(isfolder(strcat(path_extract,'Figures\Seizure Duration')))
        mkdir(path_extract,'Figures\Seizure Duration')
        end
        
        if to_plot
        
        fig1 = figure(1);
        fig1.WindowState = 'maximized';
        hold on
        
        % Plots Raw EEG Data. Channel 1 is the topmost. Uses maximum of
        % first 30 seconds to 'normalize' plot. 
        for channel = 1 : size(output_data{sz_cnt},2)
        plot(1/fs : 1/fs : size(output_data{sz_cnt},1)/fs , output_data{sz_cnt}(:,channel)...
            ./max(output_data{sz_cnt}(1:30*fs,channel))/2+size(output_data{sz_cnt},2)-channel,'k');
        end
        
        % Plots Scatterplot of K Means Predictions on Top of Channel 1
        Colorset_plot = [0 0 0; 0 0 0; 0 0 0];
        Colorset_plot(sz_classes_1,:) = [1 0 0];
        Colorset_plot(sz_classes_2,:) = [1 0 0];
        Colorset_plot(non_sz_class,:) = [0 1 0];
        scatter( winDisp : winDisp : t_after + t_before - winDisp, ones(length(k_means_pred),1) + channel - 1,...
            [], Colorset_plot(k_means_pred,:) , 'filled');
        
        % Draws Line at Computationally Detected Seizure Termination Point and Sets Window Boundaries
        xlim([0, sz_end * winDisp + 15])
        ylim([-1,channel])
        xline(sz_end*winDisp,'-r',{'Termination',strcat(num2str(seizure_duration(sz_cnt))," sec")},'LineWidth',2);
        xlabel('Time (sec)')
        
        % If In To-Fix Chart, Draw To Fix Line & Change Seizure Duration
        if ismember([sz_parameters(sz_cnt,1),sz_parameters(sz_cnt,2)],to_fix_chart(:,1:2),'rows')
            
            % Find the column where the row matches in entirety
            [logical_val, fixed_duration_row] = ismember([sz_parameters(sz_cnt,1),sz_parameters(sz_cnt,2)],to_fix_chart(:,1:2),'rows');
            % Fixes output for seizure duration
            seizure_duration(sz_cnt) = to_fix_chart(fixed_duration_row,3);
            % Moves Seizure End to New Ending, Adjust Window if Necessary
            sz_end_new = sz_start + seizure_duration(sz_cnt)./winDisp;
            if sz_end_new > sz_end
                xlim([0, sz_end_new * winDisp + 15])
            end
            % Draw Fixed Seizure Line
            xline(sz_end_new*winDisp,'-g',{'Manual Fixed',strcat(num2str(seizure_duration(sz_cnt))," sec")},'LineWidth',2);
            
        end
        
        % Titling
        if sz_parameters(sz_cnt,5) == 0
        title('No Seizure')
        else
        title('Seizure')
        end
        
        % Saves Figure
        saveas(fig1,fullfile(strcat(path_extract,"Figures\Seizure Duration\Trial ",num2str(sz_parameters(sz_cnt,2)),".png")),'png');
        
        hold off
        close(fig1)
             
%        % PCA Plot
%         fig1 = figure(1);
%         pca_coef = pca(output_array{sz_cnt}');
%         scatter3(pca_coef(:,1),pca_coef(:,2),pca_coef(:,3),[],Colorset_plot(k_means_pred,:) , 'filled');
%         xlabel('PCA Component 1')
%         ylabel('PCA Component 2')
%         zlabel('PCA Component 3')
%         close(fig1)
        
        else

        if ismember([sz_parameters(sz_cnt,1),sz_parameters(sz_cnt,2)],to_fix_chart(:,1:2),'rows')
            
            % Find the column where the row matches in entirety
            [logical_val, fixed_duration_row] = ismember([sz_parameters(sz_cnt,1),sz_parameters(sz_cnt,2)],to_fix_chart(:,1:2),'rows');
            % Fixes output for seizure duration
            seizure_duration(sz_cnt) = to_fix_chart(fixed_duration_row,3);
           
        end

        end
        
    end
    
end

% -------------------------------------------------------------------------

% Step 4: Determine Threshold Power and Duration (> 50% of trials cause
% events lasting longer than 10 seconds, include all trials in calculation)

% This section only works for later experiments since in early ones there were
% only one/two repeats.

% Unique Counts
number_power = unique(sz_parameters(:,9));
number_power = number_power(find(number_power~=-1));
number_duration = unique(sz_parameters(:,12));
number_duration = number_duration(find(number_duration~=-1));

% Sets Up Output
min_thresh.power = 1000;
min_thresh.duration = 1000;

% -------------------------------------------------------------------------

% Minimum Power Calculation Using Non Diazepam Trials

for cnt = 1:length(number_power)
    
    trials = find(sz_parameters(:,9) == number_power(cnt) & sz_parameters(:,16) == 0 & sz_parameters(:,17) == 0 & sz_parameters(:,18) == 0 & sz_parameters(:,2) <= max_trial);
    
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
    
    trials = find(sz_parameters(:,12) == number_duration(cnt) & sz_parameters(:,16) == 0 & sz_parameters(:,17) == 0 & sz_parameters(:,18) == 0 & sz_parameters(:,2) <= max_trial);
    
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

% As a reminder, in sz_parameters column 12 is stim duration, column 9 is stim power, 
% column 16 is diazepam/not, and column 5 is visually identified seizure or not

if min_thresh.power ~= -1 && min_thresh.duration ~= -1
    
    min_thresh.seizures = find(sz_parameters(:,12) >= min_thresh.duration & ...
        sz_parameters(:,9) >= min_thresh.power & sz_parameters(:,16) == 0 &...
        sz_parameters(:,17) == 0 & sz_parameters(:,18) == 0 & sz_parameters(:,2) <= max_trial);
    min_thresh.avg_success = mean(sz_parameters(min_thresh.seizures,5));
    min_thresh.diaz_seizures = find(sz_parameters(:,12) >= min_thresh.duration & ...
        sz_parameters(:,9) >= min_thresh.power & sz_parameters(:,16) == 1 & sz_parameters(:,2) <= max_trial);
    if isempty(min_thresh.diaz_seizures)
        min_thresh.diaz_success = -1;
    else
        min_thresh.diaz_success = mean(sz_parameters(min_thresh.diaz_seizures,5));
    end
    
else
    
    min_thresh.seizures = [];
    min_thresh.avg_success = mean(sz_parameters(find(sz_parameters(:,16) == 0 & sz_parameters(:,2) <= max_trial),5));
    min_thresh.diaz_seizures = find(sz_parameters(:,16) == 1);
    if isempty(min_thresh.diaz_seizures)
        min_thresh.diaz_success = -1;
    else
        min_thresh.diaz_success = mean(sz_parameters(find(sz_parameters(:,16) == 1 & sz_parameters(:,2) <= max_trial),5));
    end
    
end

% -------------------------------------------------------------------------

end
