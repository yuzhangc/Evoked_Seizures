function [seizure_duration,min_thresh,output_array,sz_parameters] = predict_seizure_duration_net(path_extract,sz_model,countdown_sec,to_fix_chart,to_plot)

% INCOMPLETE

% Uses a deep learning network to identify seizure length.

% For deep learning network, each individual timepoint needs to become its
% own feature x t array, where the number of features is the row and t is
% the time window (for example, if t is 1, then we predict at each winLen,
% if t is 2, then we use the values at 2 winLen to predict the outcome.

% Deep learning will be performed on concactenated arrays with manual
% categorization of seizure or not.

% Input Size is Number Features
inputSize = 12;
numHiddenUnits = 100;
numClasses = 2;

layers = [ ...
    sequenceInputLayer(inputSize)
    lstmLayer(numHiddenUnits,'OutputMode','last')
    fullyConnectedLayer(numClasses)
    softmaxLayer
    classificationLayer];

% https://www.mathworks.com/help/deeplearning/ref/trainnetwork.html#mw_36a68d96-8505-4b8d-b338-44e1efa9cc5e

maxEpochs = 70;
miniBatchSize = 27;

options = trainingOptions('adam', ...
    'ExecutionEnvironment','cpu', ...
    'MaxEpochs',maxEpochs, ...
    'MiniBatchSize',miniBatchSize, ...
    'GradientThreshold',1, ...
    'Verbose',false, ...
    'Plots','training-progress');

% Train the LSTM network with the specified training options.
net = trainNetwork(XTrain,YTrain,layers,options);

end