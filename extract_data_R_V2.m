function [final_divided,sz_parameters,feature_list] = extract_data_R_V2(animal_info,path_extract,seizure_duration_list,feature_list,folder_num,drug,second_stim,raw_or_normalized)

% Uses Seizure Duration to Splice Feature Data into Before, During Stim,
% and Thirds. Exports the Means Along With Spliced Seizure Parameters For
% Processing in R.

% V2 Makes New Column With Categorical Value 'Position'

% Input Variables
% animal_info - Animal Information Spreadhseet
% path_extract - Directory to Load Features From
% seizure_duration_list - Calculated Seizure Durations (For Thirds
% Splitting)
% folder_num - Used for Taking Correct Seizure Durations
% raw_or_normalized - 1 for normalized, 0 for raw

% drug - Special Case For Drug Trials
% second_stim - Remove Second Stimulation Artifacts

% Output Variables
% sz_parameters - Seizure Parameters For Animal
% final_divided - Features Divided By Thirds By Animal

% -------------------------------------------------------------------------

disp("Working on: " + path_extract)

% Step 1: Read Seizure Parameters and Features

if raw_or_normalized

load(strcat(path_extract,"Normalized Features.mat"))

else
    
load(strcat(path_extract,"Raw Features.mat"))
norm_features = features;

end

sz_parameters = readmatrix(strcat(path_extract,'Trials Spreadsheet.csv'));

% Make Adjustments - Adds in Phenytoin & Levetiracetam Columnns

if sz_parameters(1,1) <= 37 && size(sz_parameters,2) == 16

    sz_parameters(:,end + 1) = 0;
    sz_parameters(:,end + 1) = 0;

end

% -------------------------------------------------------------------------

% Step 2: Create 4 Cell Arrays (Per Channel) And Populate Animal Information

% Determine Number of Seizures (ROWS)

num_seizures = size(sz_parameters,1);

% Column 1 - Animal Number

col1 = num2cell(sz_parameters(:,1));

if sz_parameters(1,1) >= 100
    act_number = sz_parameters(1,1) - 99;
else
    act_number = sz_parameters(1,1);
end

% Column 2 - Epileptic Or Not

col2(1:num_seizures,1) = table2cell(animal_info(act_number,5));

% Column 3 - Gender

col3(1:num_seizures,1) = table2cell(animal_info(act_number,6));

% Column 4 - Age

col4(1:num_seizures,1) = table2cell(animal_info(act_number,7));

% Column 5 - Weeks Post KA 

col5(1:num_seizures,1) = table2cell(animal_info(act_number,10));

% Column 6 - Seizure Or Not

col6 = num2cell(sz_parameters(:,5));

% Column 7 - Laser 1 - Color

col7 = num2cell(sz_parameters(:,8));

% Column 8 - Laser 1 - Power

col8 = num2cell(sz_parameters(:,9));

% Column 9 - Laser 1 - Duration

col9 = num2cell(sz_parameters(:,12));

% Column 10 - Laser 2 - Color

col10 = num2cell(sz_parameters(:,10));

% Column 11 - Laser 2 - Power

col11 = num2cell(sz_parameters(:,11));

% Column 12 - Laser 2 - Duration

col12 = num2cell(sz_parameters(:,14));

% Column 13 - Delay Between Lasers

col13 = num2cell(sz_parameters(:,13));

% Column 14 - Laser 2 - Frequency

col14 = num2cell(sz_parameters(:,15));

% Column 15 - Diazepam

col15 = num2cell(sz_parameters(:,16));

% Column 16 - Levetiracetam

col16 = num2cell(sz_parameters(:,17));

% Column 17 - Phenytoin

col17 = num2cell(sz_parameters(:,18));

% Column 18 - Seizure Duration

col18 = num2cell(seizure_duration_list{folder_num});

% Colum 19 - Seizure Number

col19 = num2cell(sz_parameters(:,2));

% Create Tables For Common Data

beginning_data = table(col1,col2,col3,col4,col5,col6,col7,col8,col9,col10,col11,col12,...
    col13,col14,col15,col16,col17,col18,col19,'VariableNames',["Animal","Epileptic","Gender","Age",...
    "Weeks Post KA","Successful Evocation","Laser 1 - Color","Laser 1 - Power","Laser 1 - Duration",...
    "Laser 2 - Color", "Laser 2 - Power", "Laser 2 - Duration","Delay","Laser 2 - Frequency",...
    "Diazepam","Levetiracetam","Phenytoin","Evoked Activity Duration","Trial Number"]);

% -------------------------------------------------------------------------

% Step 3: Create Indices for Seizure Duration

seizure_duration = seizure_duration_list{act_number};

clear pre_stim_indices during_stim_indices first_third_indices
clear second_third_indices final_third_indices post_ictal_indices

for seizure_idx = 1:num_seizures

    indices = [];

    indv_stim_duration = sz_parameters(seizure_idx,12);
    indv_duration = seizure_duration(seizure_idx);

    % Second Stim Variables
    second_stim_freq = sz_parameters(seizure_idx,15);
    second_stim_delay = sz_parameters(seizure_idx,13);
    second_stim_dur = sz_parameters(seizure_idx,14);
    second_stim_color = sz_parameters(seizure_idx,10);

    % Create Indices For Thirds

    sz_start = (t_before + indv_stim_duration)/winDisp;
    sz_end = sz_start + indv_duration/winDisp;
    indices(seizure_idx,1:7) = [1 , floor(t_before/winDisp) , floor(sz_start) , floor(sz_start+round((sz_end-sz_start)/3)), ...
        floor(sz_start+round(2*(sz_end-sz_start)/3)) , floor(sz_end) , floor(sz_end+30/winDisp)];
    
    % Prepare For Case In Which End + 30 Seconds Exceed Bounds

    if sz_end + 30/winDisp >= (t_after + t_before)/winDisp - 1
        indices(seizure_idx,7) = floor((t_after + t_before)/winDisp) - 1;
    end

    % Prepare For Edge Case Where Seizures Doesnt Stop
    
    if sz_end >= (t_after + t_before)/winDisp - 1
        indices(seizure_idx,6) = floor((t_after + t_before)/winDisp) - 1;
        indices(seizure_idx,7) = indices(seizure_idx,6);
    end

    % Generate Second Stim Indices
    if second_stim && second_stim_color == 473 && second_stim_freq > 1

        % Generate Indices

        pre_stim_indices{seizure_idx} = indices(seizure_idx,1):indices(seizure_idx,2);
        during_stim_indices{seizure_idx} = indices(seizure_idx,2):indices(seizure_idx,3);
        first_third_indices{seizure_idx} = indices(seizure_idx,3):indices(seizure_idx,4);
        second_third_indices{seizure_idx} = indices(seizure_idx,4):indices(seizure_idx,5);
        final_third_indices{seizure_idx} = indices(seizure_idx,5):indices(seizure_idx,6);

        if indices(seizure_idx,6) ~= indices (seizure_idx,7)
        post_ictal_indices{seizure_idx} = indices(seizure_idx,6):indices(seizure_idx,7);
        else
        post_ictal_indices{seizure_idx} = pre_stim_indices{seizure_idx};
        end

        % Remove Second Stimulation
        second_stim_st = floor((t_before + second_stim_delay)/winDisp);
        second_stim_end = floor((t_before + second_stim_delay + second_stim_dur)/winDisp);

        pre_stim_indices{seizure_idx} = pre_stim_indices{seizure_idx}(~ismember(pre_stim_indices{seizure_idx}, second_stim_st:second_stim_end));
        during_stim_indices{seizure_idx} = during_stim_indices{seizure_idx}(~ismember(during_stim_indices{seizure_idx}, second_stim_st:second_stim_end));
        first_third_indices{seizure_idx} = first_third_indices{seizure_idx}(~ismember(first_third_indices{seizure_idx}, second_stim_st:second_stim_end));
        second_third_indices{seizure_idx} = second_third_indices{seizure_idx}(~ismember(second_third_indices{seizure_idx}, second_stim_st:second_stim_end));
        final_third_indices{seizure_idx} = final_third_indices{seizure_idx}(~ismember(final_third_indices{seizure_idx}, second_stim_st:second_stim_end));
        post_ictal_indices{seizure_idx} = post_ictal_indices{seizure_idx}(~ismember(post_ictal_indices{seizure_idx}, second_stim_st:second_stim_end));

    else

        pre_stim_indices{seizure_idx} = indices(seizure_idx,1):indices(seizure_idx,2);
        during_stim_indices{seizure_idx} = indices(seizure_idx,2):indices(seizure_idx,3);
        first_third_indices{seizure_idx} = indices(seizure_idx,3):indices(seizure_idx,4);
        second_third_indices{seizure_idx} = indices(seizure_idx,4):indices(seizure_idx,5);
        final_third_indices{seizure_idx} = indices(seizure_idx,5):indices(seizure_idx,6);

        if indices(seizure_idx,6) ~= indices (seizure_idx,7)
        post_ictal_indices{seizure_idx} = indices(seizure_idx,6):indices(seizure_idx,7);
        else
        post_ictal_indices{seizure_idx} = pre_stim_indices{seizure_idx};
        end

    end

end

% -------------------------------------------------------------------------

% Step 4: Calculate Mean Features Per Channel Per Seizure

feature_names = fieldnames(norm_features);

% IO for Features

if isempty(feature_list)

for feature_number = 1:length(feature_names)
    displays_text = strcat("\nDo You Want to Output Feature ",strrep(feature_names(feature_number),"_"," "),"?",...
        "\n(1) Yes (0) No: ");
    yesorno = input(displays_text);

    if yesorno
        feature_list = [feature_list,feature_number];
    end

end

end

% Determine Number of Channels
if (isequal(feature_names{end},'Band_Power'))
    total_channels = size(norm_features.(feature_names{end}){1}{1},2);
else
    total_channels = size(norm_features.(feature_names{end}){1},2);
end

clear final_divided all_titles

% Expand Beginning Table
true_beginning_data = table();

% Loops Through Channels
for ch = 1:total_channels

temp_ch_features = [];
temp_ch_titles = [];

% Loop Through Seizures
for seizure_idx = 1:num_seizures     

temp_sz_features = [];
real_feat_idx = 1;

if ch == 1
order_table = cell2table({"Before Stimulation";"During Stimulation";"Seizure - First Third";"Seizure - Second Third";...
    "Seizure - Final Third";"Post Seizure"},"VariableNames","Time Point");
true_beginning_data = vertcat(true_beginning_data, ...
    horzcat(repmat(beginning_data(seizure_idx,:),6,1), order_table));
end

% Loops Through Features
for feature_number = 1:length(feature_list)
    
    % Special Case for Band Power, Concactenate Increasing BP
    % Filters in Order
    if (isequal(feature_names{feature_list(feature_number)},'Band_Power'))
    
        for bp_cnt = 1:size(bp_filters,1)  
        
            feature_data = norm_features.(feature_names{feature_list(feature_number)}){bp_cnt}{seizure_idx};

            % Calculate Thirds

            mean_pre_stim = mean(feature_data(pre_stim_indices{seizure_idx},ch),1);
            mean_during_stim = mean(feature_data(during_stim_indices{seizure_idx},ch),1);
            mean_first_third = mean(feature_data(first_third_indices{seizure_idx},ch),1);
            mean_second_third = mean(feature_data(second_third_indices{seizure_idx},ch),1);
            mean_final_third = mean(feature_data(final_third_indices{seizure_idx},ch),1);
            mean_post_ictal = mean(feature_data(post_ictal_indices{seizure_idx},ch),1);

            % Convert 'EMPTY' Mean Values to NaN
            if isempty(mean_pre_stim)
                mean_pre_stim = NaN
            end
    
            if isempty(mean_during_stim)
                mean_during_stim  = NaN
            end
    
            if isempty(mean_first_third)
                mean_first_third = NaN
            end
    
            if isempty(mean_second_third)
                mean_second_third = NaN
            end
    
            if isempty(mean_final_third)
                mean_final_third = NaN
            end
    
            if isempty(mean_post_ictal )
                mean_post_ictal  = NaN
            end

            % Put Into Output Array

            feature_for_ch = [mean_pre_stim, mean_during_stim, mean_first_third, mean_second_third, ...
                mean_final_third, mean_post_ictal]';
            
            temp_sz_features(:,real_feat_idx) = feature_for_ch;

            % Increases Feature Index

            real_feat_idx = real_feat_idx + 1;

            % Assign Variable Titles

            if seizure_idx == 1
            common_title = strcat("Ch ",num2str(ch), " ", strrep(feature_names{feature_list(feature_number)},"_"," "));
            common_title_bp = strcat(common_title," ",num2str(bp_filters(bp_cnt,1))," Hz to ",...
                num2str(bp_filters(bp_cnt,2)),"Hz");
            temp_ch_titles = [temp_ch_titles,common_title_bp];
            end

        end

    else

        feature_data = norm_features.(feature_names{feature_list(feature_number)}){seizure_idx};

        % Calculate Thirds

        mean_pre_stim = mean(feature_data(pre_stim_indices{seizure_idx},ch),1);
        mean_during_stim = mean(feature_data(during_stim_indices{seizure_idx},ch),1);
        mean_first_third = mean(feature_data(first_third_indices{seizure_idx},ch),1);
        mean_second_third = mean(feature_data(second_third_indices{seizure_idx},ch),1);
        mean_final_third = mean(feature_data(final_third_indices{seizure_idx},ch),1);
        mean_post_ictal = mean(feature_data(post_ictal_indices{seizure_idx},ch),1);

        % Convert 'EMPTY' Mean Values to NaN
        if isempty(mean_pre_stim)
            mean_pre_stim = NaN
        end

        if isempty(mean_during_stim)
            mean_during_stim  = NaN
        end

        if isempty(mean_first_third)
            mean_first_third = NaN
        end

        if isempty(mean_second_third)
            mean_second_third = NaN
        end

        if isempty(mean_final_third)
            mean_final_third = NaN
        end

        if isempty(mean_post_ictal )
            mean_post_ictal  = NaN
        end

        % Put Into Output Array

        feature_for_ch = [mean_pre_stim, mean_during_stim, mean_first_third, mean_second_third, ...
            mean_final_third, mean_post_ictal]';
        
        temp_sz_features(:,real_feat_idx) = feature_for_ch;

        % Increases Feature Index

        real_feat_idx = real_feat_idx + 1;

        % Assign Variable Titles

        if seizure_idx == 1
        common_title = strcat("Ch ",num2str(ch), " ", strrep(feature_names{feature_list(feature_number)},"_"," "));
        temp_ch_titles = [temp_ch_titles,common_title];
        end

    end

    end

    temp_ch_features = [temp_ch_features;temp_sz_features];

end

final_divided{ch} = temp_ch_features;
all_titles{ch} = temp_ch_titles;

end

% -------------------------------------------------------------------------

% Step 5: Create Tables and Save Output

for ch = 1:size(all_titles,2)

    final_table = horzcat(true_beginning_data,array2table(final_divided{ch},'VariableNames',all_titles{ch}));

    % Special Case For Drug Tests
    if drug

    % Do Not Write File If No Drug Tests
    drug_test_indices = cell2mat(table2array(final_table(:,15:17))) > 0;

    if any(any(drug_test_indices))
    % Find 'Threshold Stimulus' Trials Only

    threshold_power = min(cell2mat(table2array(final_table(any(drug_test_indices')',"Laser 1 - Power"))));
    threshold_duration = min(cell2mat(table2array(final_table(any(drug_test_indices')',"Laser 1 - Duration"))));

    trials_to_keep = cell2mat(final_table.("Laser 1 - Power")) >= threshold_power & cell2mat(final_table.("Laser 1 - Duration")) >= threshold_duration;

    final_table = final_table(trials_to_keep,:);

    if second_stim
    file_name = "Extracted_Features_Channel_V2_DRUG_2StimREMOVED_";
    else
    file_name = "Extracted_Features_Channel_V2_DRUG_";
    end
    
    writetable(final_table,strcat(path_extract,file_name,num2str(ch),".csv"))

    end

    elseif second_stim

    file_name = "Extracted_Features_Channel_V2_2StimREMOVED_";
    writetable(final_table,strcat(path_extract,file_name,num2str(ch),".csv"))

    else
    
    file_name = "Extracted_Features_Channel_V2_";
    writetable(final_table,strcat(path_extract,file_name,num2str(ch),".csv"))

    end

end