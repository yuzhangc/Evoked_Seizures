% % Naive Evocation
% 
% folder_num = find({subFolders.name} == "20230221_25_NA_PV_ENP");
% 
% seizure = 21; time_idx = [9, 19; 26, 36; 46, 56]; filtered = 1; plot_duration = 55;
% path_extract = strcat(directory,subFolders(folder_num).name,'\');
% plot_select_pairs(path_extract, seizure, time_idx, plot_duration, filtered);


% load('seizure_model_net.mat')
% countdown_sec = 1; % See Countdown Sec Vs Accuracy Table FOR ALL
%   0.0000    0.6433  (within 5 secs abs value)
%   0.2500    0.7737
%   0.5000    0.8190    0.5894 (within 1 sec abs val)
%   0.7500    0.8254    0.5970 !
%   1.0000    0.8373    0.5905
%   1.2500    0.8448 !  0.5754
%   1.5000    0.8308    0.5690
%   1.7500    0.8093
%   2.0000    0.7920
%   2.2500    0.7780
%   2.5000    0.7575
%   2.7500    0.7392
%   3.0000    0.7155
%   3.2500    0.6940
%   3.5000    0.6832
%   3.7500    0.6659
%   4.0000    0.6455
%   4.2500    0.6325
%   4.5000    0.6175

% FOR 658 SZ IN ANIMAL 22 - 45 EXCL 24 25 (5 sec)

%      0    0.5805
% 0.2500    0.7432
% 0.5000    0.8040
% 0.7500    0.8176
% 1.0000    0.8313
% 1.2500    0.8283
% 1.5000    0.8146
% 1.7500    0.7948
% 2.0000    0.7842
% 2.2500    0.7523
% 2.5000    0.7340
% 2.7500    0.7204
% 3.0000    0.6915
% 3.2500    0.6657
% 3.5000    0.6550
% 3.7500    0.6429
% 4.0000    0.6170
% 4.2500    0.6049
% 4.5000    0.5881
% 4.7500    0.5775
% 5.0000    0.5608

% FOR 658 SZ IN ANIMAL 22 - 45 EXCL 24 25 (1 sec)
%      0    0.3526
% 0.5000    0.5152
% 1.0000    0.5258
% 1.5000    0.5106
% 2.0000    0.5015
% 2.5000    0.4726
% 3.0000    0.4453
% 3.5000    0.4271
% 4.0000    0.4027
% 4.5000    0.3845
% 5.0000    0.3723

% countdown_sec = 5; % See Countdown Sec Vs Accuracy Table FOR ALL
%     1.0000    0.7640  (within 5secs abs value)
%     1.2500    0.7920
%     1.5000    0.8103
%     1.7500    0.8287
%     2.0000    0.8405
%     2.2500    0.8491
%     2.5000    0.8427
%     2.7500    0.8427
%     3.0000    0.8470    0.7478 (within 1 sec abs val
%     3.2500    0.8534
%     3.5000    0.8545 !  0.7522
%     3.7500    0.8545 !
%     4.0000    0.8470    0.7543
%     4.2500    0.8394
%     4.5000    0.8384    0.7511
%     4.7500    0.8405
%     5.0000    0.8438    0.7586 !

% 1 SEC FOR 658 Evocations IN ANIMAL 22 - 45 EXCL 24 25
% 0         0.1839
% 0.2500    0.2933
% 0.5000    0.3997
% 0.7500    0.5015
% 1.0000    0.5699
% 1.2500    0.6140
% 1.5000    0.6520
% 1.7500    0.6839
% 2.0000    0.7249
% 2.2500    0.7432
% 2.5000    0.7416
% 2.7500    0.7523
% 3.0000    0.7644
% 3.2500    0.7660
% 3.5000    0.7690
% 3.7500    0.7736
% 4.0000    0.7690
% 4.2500    0.7599
% 4.5000    0.7599
% 4.7500    0.7599
% 5.0000    0.7614

% 5 sec For Same Group of 658 Evocations
%      0    0.3116
% 0.2500    0.4453
% 0.5000    0.5547
% 0.7500    0.6474
% 1.0000    0.6976
% 1.2500    0.7432
% 1.5000    0.7720
% 1.7500    0.7979
% 2.0000    0.8283
% 2.2500    0.8404
% 2.5000    0.8435
% 2.7500    0.8526
% 3.0000    0.8632
% 3.2500    0.8617
% 3.5000    0.8647
% 3.7500    0.8663
% 4.0000    0.8602
% 4.2500    0.8526
% 4.5000    0.8511
% 4.7500    0.8495
% 5.0000    0.8495

%% Wavelet Feature Calculation

if feat_calc == 1
    for folder_num = 1:length(subFolders)
        path_extract = strcat(directory,subFolders(folder_num).name,'\');
        calculate_wavelet_features(path_extract,filter_sz,wavelets,feature_list,winLen, winDisp);
    end
end

% Within Animal Example

% animal = 39;
% targeted_sz_parameters = merged_sz_parameters(merged_sz_parameters(:,1) == 39,:);
% targeted_output_array = {merged_output_array{find(merged_sz_parameters(:,1) == 39)}};
% targeted_seizure_duration_list{1} = seizure_duration_list{animal};
% categorization_plot_func(targeted_output_array,targeted_sz_parameters,targeted_seizure_duration_list,directory);

%% Evoked Seizures Processing - Cross Correlation

[all_ch_feat, ch_all_lag, feature_list] = calculate_seizure_corr_evoked(min_thresh_list,seizure_duration_list,directory,[]);
