% Manual Correction For Files With Fewer than 4 Channels Due to Open Wires
% Generally, we replace the open wire with the data from the same screw.

clear all

path_extract = 'G:\Clone of ORG_YZ 20230710\20230812_42_KA_THY_PV_CHR\';

% Loads Files
load (strcat(path_extract,'Normalized Features_ACT.mat'))

% Sets Missing and Replacement Channels
ch_1_replacement = 1;
ch_2_replacement = 2;
ch_3_replacement = 1;
ch_4_replacement = 3;

% Get Feature Names
 
feature_names = fieldnames(norm_features);

% Loops Through Features
for feature_number = 1:length(feature_names)
    if (isequal(feature_names{feature_number},'Band_Power'))

        % Loops Through Bandpower Segments
        for bp_cnt = 1:size(bp_filters,1)
            for sz_cnt = 1:size(norm_features.(feature_names{feature_number}){bp_cnt},2)

            temp_sz = [];

            temp_sz(:,1) = norm_features.(feature_names{feature_number}){bp_cnt}{sz_cnt}(:,ch_1_replacement);
            temp_sz(:,2) = norm_features.(feature_names{feature_number}){bp_cnt}{sz_cnt}(:,ch_2_replacement);
            temp_sz(:,3) = norm_features.(feature_names{feature_number}){bp_cnt}{sz_cnt}(:,ch_3_replacement);
            temp_sz(:,4) = norm_features.(feature_names{feature_number}){bp_cnt}{sz_cnt}(:,ch_4_replacement);
            
            norm_features.(feature_names{feature_number}){bp_cnt}{sz_cnt} = temp_sz;

            end
        end

    else
        
            for sz_cnt = 1:size(norm_features.(feature_names{feature_number}),2)

            temp_sz = [];

            temp_sz(:,1) = norm_features.(feature_names{feature_number}){sz_cnt}(:,ch_1_replacement);
            temp_sz(:,2) = norm_features.(feature_names{feature_number}){sz_cnt}(:,ch_2_replacement);
            temp_sz(:,3) = norm_features.(feature_names{feature_number}){sz_cnt}(:,ch_3_replacement);
            temp_sz(:,4) = norm_features.(feature_names{feature_number}){sz_cnt}(:,ch_4_replacement);
            
            norm_features.(feature_names{feature_number}){sz_cnt} = temp_sz;

            end

    end
end

save(strcat(path_extract,'Normalized Features.mat'),'t_after','t_before','sz_parameters','winLen','winDisp','norm_features','filter_sz','bp_filters','fs',"-v7.3");
