function [seizure_yes_no,countdown_inst] = predict_seizure_duration_spont(path_extract,countdown_inst,max_countdown)

% This is a precursor to real-time seizure detection using a neural net.

% Step 0: Train Seizure Model (Using 'Filtered' Spontaneous Seizure Data 
% From Same Animal)

% Step 0A: Load Raw Data (Remember Filtering Happens In The Function For
% Real Time Analysis
load('G:\Clone of ORG_YZ 20230710\EEG_01_2023_06_26_100_KA_THY_SST_CHR\Standardized Seizure Data.mat')

% Step 0B: Input - Select Sponaneous Seizure #1
spont_seizure = output_data{1};
valid_seizure = output_data{37};

% Step 0C: Downsample Seizure

% Start Timer

tic

target_fs = 200;
spont_seizure = downsample(spont_seizure, round(fs/target_fs));
valid_seizure = downsample(valid_seizure, round(fs/target_fs));

% Step 0D: Highpass Filter Seizure
[b,a] = butter(6 ,4/(target_fs/2) ,'high');
spont_seizure =  filtfilt(b,a,spont_seizure);
valid_seizure =  filtfilt(b,a,valid_seizure);

% Step 0E: Discrete Wavelet Transform

% Sets Up Data Space (Wavelet Markers x Wavelet Transform x Channels x Time Segments)
target_sec = 2;
discrete_space = 8;
training_data_base = zeros(discrete_space + 1,target_sec * target_fs,size(spont_seizure,2),...
    floor(size(spont_seizure,1)/target_fs/target_sec));
valid_data_base = zeros(discrete_space + 1,target_sec * target_fs,size(valid_seizure,2),...
    floor(size(valid_seizure,1)/target_fs/target_sec));
timepts = 1:target_sec*target_fs:size(spont_seizure,1) + 1;

for ch = 1:size(spont_seizure,2)

    % Discrete Wavelet Transform
    mra = modwtmra(modwt(spont_seizure(:,ch),discrete_space));
    mra_v = modwtmra(modwt(valid_seizure(:,ch),discrete_space));
    for timeseg = 1:size(timepts,2) - 1
    training_data_base(:,:,ch,timeseg) = mra(:,timepts(timeseg):timepts(timeseg+1) - 1);
    valid_data_base(:,:,ch,timeseg) = mra_v(:,timepts(timeseg):timepts(timeseg+1) - 1);
    end

end

% Step 0F: 2 Seconds Transform Into Ready For CNN Layer Case

clear training_data validation_data

for trial = 1:size(timepts,2) - 1
    
    training_data{trial} = training_data_base(:,:,:,trial);
    validation_data{trial} = valid_data_base(:,:,:,trial);
    
end

% Step 0G: Prepare Training Output/Categories Yes/No Seizure
% Window (8 sec) 5 - 40 (78 sec) - Seizure

training_responses = zeros(1,size(training_data,2));
training_responses(5:40) = 1;
training_responses = num2cell(categorical(training_responses));

% Window (5 sec) 3 - 30 (58 sec) - Seizure
valid_responses = zeros(1,size(validation_data,2));
valid_responses(3:30) = 1;
valid_responses = num2cell(categorical(valid_responses));

% Step 0H: Define CNN Structure

numHiddenUnits = 50;
numClasses = 2;

% Deep Learning Layers and Options
layers = [ ...
    sequenceInputLayer([discrete_space + 1, target_sec * target_fs, size(spont_seizure,2)])
    flattenLayer
    lstmLayer(numHiddenUnits)
    fullyConnectedLayer(numClasses)
    softmaxLayer
    classificationLayer];

maxEpochs = 50;
miniBatchSize = 27;

options = trainingOptions('adam', ...
    'ExecutionEnvironment','cpu', ...
    'MaxEpochs',maxEpochs, ...
    'MiniBatchSize',miniBatchSize, ...
    'GradientThreshold',1, ...
    'Verbose',false, ...
    'Plots','training-progress', ...
    'ValidationData',{validation_data,valid_responses});

% Train Network

net = trainNetwork(training_data,training_responses,layers,options);

training_pred = predict(net, training_data);
valid_pred = predict(net, validation_data);

toc

% Step 1: Downsample Seizure

% Step 2: Filter Seizure

% Step 3: Discrete Wavelet Transform

% Step 4: Predicts and Evaluates Based on Max Countdown

% End timer
toc

end