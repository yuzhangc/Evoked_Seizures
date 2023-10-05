function [final_divided,sz_parameters,feature_list] = extract_data_R(animal_info,path_extract,seizure_duration_list,feature_list,folder_num)

% Uses Seizure Duration to Splice Feature Data into Before, During Stim,
% and Thirds. Exports the Means Along With Spliced Seizure Parameters For
% Processing in R.

% Input Variables
% animal_info - Animal Information Spreadhseet
% path_extract - Directory to Load Features From
% seizure_duration_list - Calculated Seizure Durations (For Thirds
% Splitting)
% folder_num - Used for Taking Correct Seizure Durations

% Output Variables
% sz_parameters - Seizure Parameters For Animal
% final_divided - Features Divided By Thirds By Animal

% -------------------------------------------------------------------------

disp("Working on: " + path_extract)

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

% Column 18 - Seizure Duration

col18 = num2cell(seizure_duration_list{folder_num});

% Create Tables For Common Data

beginning_data = table(col1,col2,col3,col4,col5,col6,col7,col8,col9,col10,col11,col12,...
    col13,col14,col15,col16,col17,col18,'VariableNames',["Animal","Epileptic","Gender","Age",...
    "Weeks Post KA","Successful Evocation","Laser 1 - Color","Laser 1 - Power","Laser 1 - Duration",...
    "Laser 2 - Color", "Laser 2 - Power", "Laser 2 - Duration","Delay","Laser 2 - Frequency",...
    "Diazepam","Levetiracetam","Phenytoin","Evoked Activity Duration"]);

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

% IO for Features

if isempty(feature_list)

for feature_number = 1:length(feature_names)
    displays_text = strcat("\nDo You Want to Output Feature ",strrep(feature_names(feature_number),"_"," "),"?",...
        "\n(1) Yes (0) No: ");
    yesorno = input(displays_text);

    if yesorno
        feature_list = [feature_list,feature_number];
    else
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

% Loops Through Channels
for ch = 1:total_channels

temp_ch_features = [];
temp_ch_titles = [];

% Loops Through Features
for feature_number = 1:length(feature_list)
    
    % Special Case for Band Power, Concactenate Increasing BP
    % Filters in Order
    if (isequal(feature_names{feature_list(feature_number)},'Band_Power'))
    
        for bp_cnt = 1:size(bp_filters,1)  

        temp_sz_features = [];
    
        % Loop Through Seizures
        for seizure_idx = 1:num_seizures        

            feature_data = norm_features.(feature_names{feature_list(feature_number)}){bp_cnt}{seizure_idx};

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

            % Put Into Output Array

            feature_for_ch = [mean_pre_stim, mean_during_stim, mean_first_third, mean_second_third, ...
                mean_final_third, mean_post_ictal];
            
            temp_sz_features(seizure_idx,:) = feature_for_ch;

            % Assign Variable Titles

            if seizure_idx == 1
            common_title = strcat("Ch ",num2str(ch), " ", strrep(feature_names{feature_list(feature_number)},"_"," "));
            common_title_bp = strcat(common_title," ",num2str(bp_filters(bp_cnt,1))," Hz to ",...
                num2str(bp_filters(bp_cnt,2)),"Hz");
            variable_titles = [strcat(common_title_bp, " Before Stim"), strcat(common_title_bp, " During Stim"), ...
                strcat(common_title_bp, " First Third"), strcat(common_title_bp, " Second Third"),...
                strcat(common_title_bp, " Final Third"), strcat(common_title_bp, " After Seizure")];
            temp_ch_titles = [temp_ch_titles,variable_titles];
            end

        end

        temp_ch_features = [temp_ch_features, temp_sz_features];

        end

    else

        temp_sz_features = [];
    
        % Loop Through Seizures
        for seizure_idx = 1:num_seizures        

            feature_data = norm_features.(feature_names{feature_list(feature_number)}){seizure_idx};

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

            % Put Into Output Array

            feature_for_ch = [mean_pre_stim, mean_during_stim, mean_first_third, mean_second_third, ...
                mean_final_third, mean_post_ictal];
            
            temp_sz_features(seizure_idx,:) = feature_for_ch;

            % Assign Variable Titles

            if seizure_idx == 1
            common_title = strcat("Ch ",num2str(ch), " ", strrep(feature_names{feature_list(feature_number)},"_"," "));
            variable_titles = [strcat(common_title, " Before Stim"), strcat(common_title, " During Stim"), ...
                strcat(common_title, " First Third"), strcat(common_title, " Second Third"),...
                strcat(common_title, " Final Third"), strcat(common_title, " After Seizure")];
            temp_ch_titles = [temp_ch_titles,variable_titles];
            end

        end

        temp_ch_features = [temp_ch_features, temp_sz_features];

    end

end

final_divided{ch} = temp_ch_features;
all_titles{ch} = temp_ch_titles;

end

% -------------------------------------------------------------------------

% Step 5: Create Tables and Save Output

for ch = 1:size(all_titles,2)

    final_table = horzcat(beginning_data,array2table(final_divided{ch},'VariableNames',all_titles{ch}));
    writetable(final_table,strcat(path_extract,"Extracted_Features_Channel_",num2str(ch),".csv"))

end