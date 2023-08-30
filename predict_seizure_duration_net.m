function [seizure_duration,min_thresh,output_array,sz_parameters] = predict_seizure_duration_net(path_extract,sz_model,countdown_sec,to_fix_chart,to_plot)

% INCOMPLETE

% Uses a deep learning network to identify seizure length.

% For deep learning network, each individual timepoint needs to become its
% own feature x t array, where the number of features is the row and t is
% the time window (for example, if t is 1, then we predict at each winLen,
% if t is 2, then we use the values at 2 winLen to predict the outcome.

% Deep learning will be performed on concactenated arrays with manual
% categorization of seizure or not.

% -------------------------------------------------------------------------

% Step 1: Read Features

disp("Working on: " + path_extract)
% Loads Features
load(strcat(path_extract,'Normalized Features.mat'));
sz_parameters = readmatrix(strcat(path_extract,'Trials Spreadsheet.csv'));

% Extracts Feature Names
feature_names = fieldnames(norm_features);

% -------------------------------------------------------------------------

% Step 0: Training Model

% Input Size is Number Features
inputSize = length(feature_names);

if sum(ismember(feature_names,'Band_Power'))
    inputSize = inputSize + size(bp_filters,1) - 1;
end

% Determine Size of Time Space and Channel Count

if (isequal(feature_names{end},'Band_Power'))
    total_timeseg = size(norm_features.(feature_names{end}){1}{training_segment},1);
    total_ch = size(norm_features.(feature_names{end}){1}{training_segment},2);
else
    total_timeseg = size(norm_features.(feature_names{end}){training_segment},1);
    total_ch = size(norm_features.(feature_names{end}){training_segment},2);
end

% Parameters Copied From Below Training Guide, Will Modify As Needed
% https://www.mathworks.com/help/deeplearning/ref/trainnetwork.html

numHiddenUnits = 100;
numClasses = 2;

% Deep Learning Layers
layers = [ ...
    sequenceInputLayer([1, inputSize, total_ch])
    lstmLayer(numHiddenUnits,'OutputMode','last')
    fullyConnectedLayer(numClasses)
    softmaxLayer
    classificationLayer];

maxEpochs = 70;
miniBatchSize = 27;

options = trainingOptions('adam', ...
    'ExecutionEnvironment','cpu', ...
    'MaxEpochs',maxEpochs, ...
    'MiniBatchSize',miniBatchSize, ...
    'GradientThreshold',1, ...
    'Verbose',false, ...
    'Plots','training-progress');

% SPECIFIC: Training Was Done With Animal 37, Trial 10.

% Trial 10 is Location #9 in the Array
training_segment = 9;

% Create Zero Array For Population

training_set = zeros(1,inputSize,total_ch,total_timeseg);

for current_ch = 1:total_ch
current_idx = 1;

for feature = 1:length(feature_names)

    % Special Case for Band Power
    if (isequal(feature_names{feature},'Band_Power'))
           for bp_cnt = 1:size(bp_filters,1)
                
               % Arranges into 1 Row By Timepoint By Channel By Trial
               % Format
               for trial = 1:total_timeseg 
               training_set(1,current_idx,current_ch,trial) = norm_features.(feature_names{feature}){bp_cnt}{training_segment}(trial,current_ch);
               end

               current_idx = current_idx + 1;

           end
    else

    % Otherwise, add features in correct channel array.

    for trial = 1:total_timeseg 
    training_set(1,current_idx,current_ch,trial) = norm_features.(feature_names{feature}){training_segment}(trial,current_ch);
    end

    current_idx = current_idx + 1;

    end

end

end

% Training 'Responses'
manual_length = 60;
training_outputs = zeros(total_timeseg,1);
training_outputs(t_before/winDisp:(t_before + sz_parameters(training_segment,12) + manual_length)/winDisp) = 1;

% Train the LSTM network with the specified training options.
net = trainNetwork(training_set,training_outputs,layers,options);

end