function [seizure_duration,output_array,sz_parameters] = predict_seizure_duration_net(path_extract,sz_model,countdown_sec,to_fix_chart,to_plot)

% Uses a deep learning network to identify seizure length.

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
% 2) output_array - concactenated features, indexed by seizure. NOT THE
% SAME FORMAT AS IN THE K NEAREST NEIGHBORS
%
% 3) sz_parameters - seizure parameters

% For deep learning network, each individual timepoint needs to become its
% own 1 x feature x channel array, where the number of features is the y and t is
% the fourth dimension

% -------------------------------------------------------------------------

% Step 1: Read Features

disp("Working on: " + path_extract)
% Loads Features, Seizure Parameters, and Filtered Seizure Data
load(strcat(path_extract,'Normalized Features.mat'));
load(strcat(path_extract,'Filtered Seizure Data.mat'))
sz_parameters = readmatrix(strcat(path_extract,'Trials Spreadsheet.csv'));

% -------------------------------------------------------------------------

% Step 2: Generate Generate Seizure Duration Matrix. Initiate all to Zeros. Extract
% feature names

seizure_duration = zeros(size(sz_parameters,1),1);
feature_names = fieldnames(norm_features);

% -------------------------------------------------------------------------

% Step 3: Perform Calculations

% Step 3A: Check to determine if channels is equal to 4. Do not perform
% operation if not

if (isequal(feature_names{end},'Band_Power'))
channel_incongruency = rem(size(norm_features.(feature_names{end}){1}{1},2),4) ~= 0;
else
channel_incongruency = rem(size(norm_features.(feature_names{end}){1},2),4) ~= 0;
end

if channel_incongruency
else

% Step 3B: Determine Total Time Segments (fourth dimension) and Channels (third dimension)

if (isequal(feature_names{end},'Band_Power'))
total_timeseg = size(norm_features.(feature_names{end}){1}{1},1);
total_ch = size(norm_features.(feature_names{end}){1}{1},2);
else
total_timeseg = size(norm_features.(feature_names{end}){1},1);
total_ch = size(norm_features.(feature_names{end}){1},2);
end

% Step 3B: Input Size is Number Features

inputSize = length(feature_names);

if sum(ismember(feature_names,'Band_Power'))
    inputSize = inputSize + size(bp_filters,1) - 1;
end

% Step 3C: Loops Through Seizures

for sz_cnt = 1:size(sz_parameters,1)

    % Step 3D: Arrange Data Into Proper Configuration (It's Called
    % Validation Set Because Code Was Borrowed From Below Training and
    % Validation Loops)

    % Clears Validation Set
    validation_set = zeros(1,inputSize,total_ch,total_timeseg);

    % Loops Through Channels
    for current_ch = 1:total_ch
    current_idx = 1;
    
    % Loops Through Features
    for feature = 1:length(feature_names)
    
        % Special Case for Band Power
        if (isequal(feature_names{feature},'Band_Power'))
               for bp_cnt = 1:size(bp_filters,1)
    
                   % Arranges into 1 Row By Timepoint By Channel By Trial
                   % Format
                   for trial = 1:total_timeseg 
                   validation_set(1,current_idx,current_ch,trial) = norm_features.(feature_names{feature})...
                       {bp_cnt}{sz_cnt}(trial,current_ch);
                   end
    
                   current_idx = current_idx + 1;
    
               end
        else
    
        % Otherwise, add features in correct channel array.
    
        for trial = 1:total_timeseg 
        validation_set(1,current_idx,current_ch,trial) = norm_features.(feature_names{feature}){sz_cnt}(trial,current_ch);
        end
    
        current_idx = current_idx + 1;
    
        end
    
    end

    end

    % Step 3E: Rearrange into Arrays
    for trial = 1:total_timeseg 
    
    validation_set_real{trial} = validation_set(1,:,:,trial);
    
    end

    % Step 3F: Assign to Output Array

    output_array{sz_cnt} = validation_set_real;

    % Step 3G: Predicts Using Validation Set

    validation_pred = predict(sz_model, validation_set_real);

    % ---------------------------------------------------------------------

    % Step 4: Determine Seizure Length Using a Countup/Cooldown Timer to 
    % Determine True Seizure Length and Ignore Brief Aberrations
    
    % Sets Initial Countdown to Be Equal to a Few Seconds. Usually a few
    % seconds break is good enough indicator of true termination
    countdown = 0;
    countdown_lim = countdown_sec/winDisp;
    
    % Uses Stimulation Duration to Set Seizure Start As Immediately After
    sz_start = (t_before + sz_parameters(sz_cnt,12))/winDisp;
    sz_pos = sz_start;
    sz_end = sz_start;

    while round(validation_pred(sz_pos,1)) == 0 || countdown < countdown_lim

            % Keeps on Moving Forward if Still Seizing
            if round(validation_pred(sz_pos,1)) ~= 1
                countdown = 0;
                sz_end = sz_pos;
                
            % Increase Cooldown Countdown If Not    
            else
                countdown = countdown + 1;
            end
            
            % Moves Up One Window, Unless at End
            if sz_pos >= size(norm_features.(feature_names{end}){sz_cnt},1)
            countdown = countdown_lim;
            validation_pred(sz_pos,1) = 1;
            else
            sz_pos = sz_pos + 1;
            end
            
    end

    % Since Each Increase in sz_pos is by winDisp, Multiply by winDisp to find
    % true duration in seconds
    seizure_duration(sz_cnt) = (sz_end - sz_start).*winDisp;

    % ---------------------------------------------------------------------

    % Step 5: Plots Figure

    if not(isfolder(strcat(path_extract,'Figures\Seizure Duration Net')))
        mkdir(path_extract,'Figures\Seizure Duration Net')
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
    
    % Plots Scatterplot of Predictions on Top of Channel 1
    Colorset_plot = [1 0 0; 0 1 0];
    
    scatter( winDisp : winDisp : t_after + t_before - winDisp, ones(size(validation_pred,1),1) + channel - 1,...
    [], Colorset_plot(1 + round(validation_pred(:,1)),:) , 'filled');
    
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
    saveas(fig1,fullfile(strcat(path_extract,"Figures\Seizure Duration Net\Trial ",num2str(sz_parameters(sz_cnt,2)),".png")),'png');
    
    hold off
    close(fig1)

    else

        if ismember([sz_parameters(sz_cnt,1),sz_parameters(sz_cnt,2)],to_fix_chart(:,1:2),'rows')
        
        % Find the column where the row matches in entirety
        [logical_val, fixed_duration_row] = ismember([sz_parameters(sz_cnt,1),sz_parameters(sz_cnt,2)],to_fix_chart(:,1:2),'rows');
        % Fixes output for seizure duration
        seizure_duration(sz_cnt) = to_fix_chart(fixed_duration_row,3);
        
        end

    end

end

% % -------------------------------------------------------------------------
% 
% % Step 0: Training Model
% 
% % SPECIFIC: Training Was Done With Animal 37, Trial 10.
% % Validation Was Done With Animal 37 Trial 30
% 
% % Input Size is Number Features
% inputSize = length(feature_names);
% 
% if sum(ismember(feature_names,'Band_Power'))
%     inputSize = inputSize + size(bp_filters,1) - 1;
% end
% 
% % Trial 10 is Location #9 in the Array
% training_segment = 9;
% validation_segment = 28;
% 
% % Input Size is Number Features
% inputSize = length(feature_names);
% 
% if sum(ismember(feature_names,'Band_Power'))
%     inputSize = inputSize + size(bp_filters,1) - 1;
% end
% 
% % Determine Size of Time Space and Channel Count
% 
% if (isequal(feature_names{end},'Band_Power'))
%     total_timeseg = size(norm_features.(feature_names{end}){1}{training_segment},1);
%     total_ch = size(norm_features.(feature_names{end}){1}{training_segment},2);
% else
%     total_timeseg = size(norm_features.(feature_names{end}){training_segment},1);
%     total_ch = size(norm_features.(feature_names{end}){training_segment},2);
% end
% 
% % Parameters Copied From Below Training Guide, Will Modify As Needed
% % https://www.mathworks.com/help/deeplearning/ref/trainnetwork.html
% 
% numHiddenUnits = 100;
% numClasses = 2;
% 
% % Deep Learning Layers
% layers = [ ...
%     sequenceInputLayer([1, inputSize, total_ch])
%     flattenLayer
%     lstmLayer(numHiddenUnits,'OutputMode','last')
%     fullyConnectedLayer(numClasses)
%     softmaxLayer
%     classificationLayer];
% 
% maxEpochs = 70;
% miniBatchSize = 27;
% 
% % Create Zero Array For Population
% 
% training_set = zeros(1,inputSize,total_ch,total_timeseg);
% validation_set = zeros(1,inputSize,total_ch,total_timeseg);
% 
% for current_ch = 1:total_ch
% current_idx = 1;
% 
% for feature = 1:length(feature_names)
% 
%     % Special Case for Band Power
%     if (isequal(feature_names{feature},'Band_Power'))
%            for bp_cnt = 1:size(bp_filters,1)
% 
%                % Arranges into 1 Row By Timepoint By Channel By Trial
%                % Format
%                for trial = 1:total_timeseg 
%                training_set(1,current_idx,current_ch,trial) = norm_features.(feature_names{feature}){bp_cnt}{training_segment}(trial,current_ch);
%                validation_set(1,current_idx,current_ch,trial) = norm_features.(feature_names{feature}){bp_cnt}{validation_segment}(trial,current_ch);
%                end
% 
%                current_idx = current_idx + 1;
% 
%            end
%     else
% 
%     % Otherwise, add features in correct channel array.
% 
%     for trial = 1:total_timeseg 
%     training_set(1,current_idx,current_ch,trial) = norm_features.(feature_names{feature}){training_segment}(trial,current_ch);
%     validation_set(1,current_idx,current_ch,trial) = norm_features.(feature_names{feature}){validation_segment}(trial,current_ch);
%     end
% 
%     current_idx = current_idx + 1;
% 
%     end
% 
% end
% 
% end
% 
% % Reorganizes Training Set Into Arrays
% 
% for trial = 1:total_timeseg 
% 
% training_set_real{trial} = training_set(1,:,:,trial);
% validation_set_real{trial} = validation_set(1,:,:,trial);
% 
% end
% 
% % Training 'Responses'
% 
% manual_length = 60;
% training_outputs = zeros(total_timeseg,1);
% training_outputs(t_before/winDisp:(t_before + sz_parameters(training_segment,12) + manual_length)/winDisp) = 1;
% 
% manual_val_length = 92;
% validation_outputs = zeros(total_timeseg,1);
% validation_outputs(t_before/winDisp:(t_before + sz_parameters(validation_segment,12) + manual_length)/winDisp) = 1;
% 
% % Training Options (Integrating Validation Data)
% 
% options = trainingOptions('adam', ...
%     'ExecutionEnvironment','cpu', ...
%     'MaxEpochs',maxEpochs, ...
%     'MiniBatchSize',miniBatchSize, ...
%     'GradientThreshold',1, ...
%     'Verbose',false, ...
%     'Plots','training-progress', ...
%     'ValidationData',{validation_set_real,categorical(validation_outputs)});
% 
% % Train the LSTM network with the specified training options.
% net = trainNetwork(training_set_real,categorical(training_outputs),layers,options);
% 
% % Predictions
% training_pred = predict(net, training_set_real);
% valid_pred = predict(net, validation_set_real);
% 
% % Graph
% 
% sz_cnt = training_segment;
% 
% load(strcat(path_extract,'Filtered Seizure Data.mat'))
% 
% fig1 = figure(1);
% fig1.WindowState = 'maximized';
% hold on
% 
% % Plots Raw EEG Data. Channel 1 is the topmost. Uses maximum of
% % first 30 seconds to 'normalize' plot. 
% for channel = 1 : size(output_data{sz_cnt},2)
% plot(1/fs : 1/fs : size(output_data{sz_cnt},1)/fs , output_data{sz_cnt}(:,channel)...
%     ./max(output_data{sz_cnt}(1:30*fs,channel))/2+size(output_data{sz_cnt},2)-channel,'k');
% end
% 
% % Plots Scatterplot of Predictions on Top of Channel 1
% Colorset_plot = [1 0 0; 0 1 0];
% 
% scatter( winDisp : winDisp : t_after + t_before - winDisp, ones(size(training_pred,1),1) + channel - 1,...
% [], Colorset_plot(1 + round(training_pred(:,1)),:) , 'filled');
% 
% ylim([-1,channel])
% xlabel('Time (sec)')

end