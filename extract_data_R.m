function [final_feature_output,sz_parameters] = extract_data_R(animal_info,path_extract,seizure_duration_list,folder_num)

% Uses Seizure Duration to Splice Feature Data into Before, During Stim,
% and Thirds. Exports the Means Along With Spliced Seizure Parameters For
% Processing in R.

% -------------------------------------------------------------------------

% Step 1: Read Seizure Parameters and Features

sz_parameters = readmatrix(strcat(path_extract,'Trials Spreadsheet.csv'));

load(strcat(path_extract,"Normalized Features.mat"))

% Make Adjustments - Adds in Phenytoin & Levetiracetam Columnns

if sz_parameters(1,1) <= 37

    sz_parameters(:,end + 1) = 0;
    sz_parameters(:,end + 1) = 0;

end

% -------------------------------------------------------------------------

% Step 2: Create 4 Cell Arrays (Per Channel) And Populate Animal Information

% Determine Number of Seizures (ROWS)

num_seizures = size(sz_parameters,1);

% Column 1 - Animal Number

col1 = num2cell(sz_parameters(:,1));

% Column 2 - Epileptic Or Not

col2(1:num_seizures,1) = table2cell(animal_info(sz_parameters(1,1),5));

% Column 3 - Gender

col3(1:num_seizures,1) = table2cell(animal_info(sz_parameters(1,1),6));

% Column 4 - Age

col4(1:num_seizures,1) = table2cell(animal_info(sz_parameters(1,1),7));

% Column 5 - Weeks Post KA 

col5(1:num_seizures,1) = table2cell(animal_info(sz_parameters(1,1),10));

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

% Create Tables For Common Data

beginning_data = table(col1,col2,col3,col4,col5,col6,col7,col8,col9,col10,col11,col12,...
    col13,col14,col15,col16,col17,'VariableNames',["Animal","Epileptic","Gender","Age",...
    "Weeks Post KA","Successful Evocation","Laser 1 - Color","Laser 1 - Power","Laser 1 - Duration",...
    "Laser 2 - Color", "Laser 2 - Power", "Laser 2 - Duration","Delay","Laser 2 - Frequency",...
    "Diazepam","Levetiracetam","Phenytoin"]);

% -------------------------------------------------------------------------

% Step 3: Create Indices for Seizure Duration

seizure_duration = seizure_duration_list{sz_parameters(:,1)};

for seizure_idx = 1:num_seizures

    indv_stim_duration = sz_parameters(seizure_idx,12);
    indv_duration = seizure_duration(seizure_idx);

    % Create Indices For Thirds

    sz_start = (t_before + indv_stim_duration)/winDisp;
    sz_end = sz_start + indv_duration/winDisp;
    indices(seizure_idx,1:7) = [1 , t_before/winDisp , sz_start , sz_start+round((sz_end-sz_start)/3), ...
        sz_start+round(2*(sz_end-sz_start)/3) , sz_end , sz_end+30/winDisp];
    
    % Prepare For Case In Which End + 30 Seconds Exceed Bounds

    if sz_end + 30/winDisp >= (t_after + t_before)/winDisp - 1
        indices(seizure_idx,7) = (t_after + t_before)/winDisp - 1;
    end

    % Prepare For Edge Case Where Seizures Doesnt Stop
    
    if sz_end >= (t_after + t_before)/winDisp - 1
        indices(seizure_idx,6) = (t_after + t_before)/winDisp - 1;
        indices(seizure_idx,7) = indices(seizure_idx,6);
    end

end

% -------------------------------------------------------------------------

% Step 4: Calculate Mean Features Per Channel Per Seizure

feature_names = fieldnames(norm_features);

for feature_number = 1:length(feature_names)

    % Special Case for Band Power, Concactenate Increasing BP
    % Filters in Order
    if (isequal(feature_names{feature_number},'Band_Power'))
        for bp_cnt = 1:size(bp_filters,1)

            % Loop Through Seizures
            for seizure_idx = 1:num_seizures

                feature_data = norm_features.(feature_names{feature_number}){bp_cnt}{seizure_idx};

                % Loop Through Channels
                for ch = 1:size(feature_data,2)

                    % Calculate Thirds
                    mean_pre_stim = mean(feature_data(indices(seizure_idx,1):indices(seizure_idx,2),ch),1);
                    mean_during_stim = mean(feature_data(indices(seizure_idx,2):indices(seizure_idx,3),ch),1);
                    mean_first_third = mean(feature_data(indices(seizure_idx,3):indices(seizure_idx,4),ch),1);
                    mean_second_third = mean(feature_data(indices(seizure_idx,4):indices(seizure_idx,5),ch),1);
                    mean_final_third = mean(feature_data(indices(seizure_idx,5):indices(seizure_idx,6),ch),1);
                    if indices(seizure_idx,6) ~= indices (seizure_idx,7)
                    mean_post_ictal = mean(feature_data(indices(seizure_idx,6):indices(seizure_idx,7),ch),1);
                    else
                    mean_post_ictal = mean_pre_stim;
                    end

                    % PROBLEM WITH ASSIGNMENT
                    final_divided{ch}(seizure_idx,:) = [final_divided{ch}(seizure_idx,:), mean_pre_stim, mean_during_stim, mean_first_third, ...
                        mean_second_third, mean_final_third, mean_post_ictal];

                end
            end
        end

    else

    end

end


end