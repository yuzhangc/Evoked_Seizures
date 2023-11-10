function [final_feature_output, subdiv_index, merged_sz_duration,coeff,score] = categorization_plot_func(merged_output_array,merged_sz_parameters,seizure_duration_list,directory,subFolders,headfixed)

% Use Integrated Feature Information Across All Channels, Then Separates Them
% According to User Input and Categorization. Makes Plots Too

% Input Variables
% merged_output_array - merged feature list
% merged_sz_parameters - complete seizure information list
% seizure_duration_list - list of seizure duration, organized by folder
% directory - directory to extract feature info from
% headfixed - 1 - Evoked Seizures Head Fixed, 0 - Evoked Seizures
% Freely Moving and Spontaneous

% Output Variables
% final_feature_output - features segregated by class, channels, then
% individual features across all divisions
% subdiv_index - divisions
% merged_sz_duration - Merged Seizure Durations
% coeff,score - PCA outputs

% -------------------------------------------------------------------------

% Step 0: Set up Variables
anova_excluded_indices = [];

% Loads Animal Information

if headfixed == 1
animal_info = readmatrix(strcat(directory,'Animal Master.csv'));
else
animal_info = readmatrix(strcat(directory,'Animal Master Freely Moving.csv'));
end

% Extract Features Information and Names From Last Folder in Directory

path_extract = strcat(directory,subFolders(length(subFolders)).name,'\');
if headfixed == 1
load(strcat(path_extract,'Normalized Features.mat'))
else
load(strcat(path_extract,'Raw Features.mat'))
norm_features = features;
end
feature_names = fieldnames(norm_features);

% -------------------------------------------------------------------------

% Step 1: Receive User Input
% Generates 7 variables
% 1) main_division - main plot
% 2) ind_data - plot individual dots or not
% 3) naive_ep - splits naive or epileptic
% 4) excl_short - exclude events shorter than short_duration (conditional input)
% 5) excl_addl - exclude additional stimulation trials
% 6) no_to_early - exclude early recordings (animals smaller than an_excl)
% 7) excl_diaz - exclude diazepam trials

displays_text = ['\nWhich Plot to Plot?:', ...
    '\n(1) - Epileptic Vs Naive Animals', ...
    '\n(2) - Long Vs Short Seizures', ...
    '\n(3) - Successfully Evocations Vs Failed Evocations', ...
    '\n(4) - Comparison of Levetiracetam and Phenytoin with Control (DO IN R)',...
    '\n(5) - Additional Stimulation Or Not (473 nm AFTER Onset ONLY)',...
    '\n(6) - Evoked Vs Spontaneous',...
    '\nEnter a number: '];

main_division = input(displays_text);

displays_text_2 = ['\nDo you want to plot individual data?', ...
    '\n(1) - Yes', ...
    '\n(0) - No', ...
    '\nEnter a number: '];

ind_data = input(displays_text_2);

if main_division ~= 1

displays_text_3 = ['\nDo you want to split naive and epileptic data?', ...
    '\n(1) - Yes', ...
    '\n(0) - No', ...
    '\nEnter a number: '];

naive_ep = input(displays_text_3);

else
    
naive_ep = 1;

end

if main_division ~= 3

displays_text_4 = ['\nDo you want to exclude short events?', ...
    '\n(1) - Yes', ...
    '\n(0) - No', ...
    '\nEnter a number: '];

excl_short = input(displays_text_4);

else
excl_short = 1;
end

if excl_short == 1
    short_duration = input('\nHow many seconds is considered a short/non-evoked event? Type in a number (e.g. 15 for head fixed, 10 for freely moving): ');
else
    short_duration = -1;
end

if main_division ~= 5
    
displays_text_5 = ['\nDo you want to exclude events with additional stimulation?', ...
    '\n(1) - Yes', ...
    '\n(0) - No', ...
    '\nEnter a number: '];

excl_addl = input(displays_text_5);

else
    
excl_addl = 0;

end

displays_text_6 = ['\nDo you want to EXCLUDE early recordings?', ...
    '\n(1) - Yes', ...
    '\n(0) - No', ...
    '\nEnter a number: '];

no_to_early = input(displays_text_6);

if no_to_early == 1
    an_excl = input('\nType in Animal Number Below Which To Exclude (e.g. 12 = 2022/11/07, 22 = 2023/01/16): ');
end

if main_division ~= 4

displays_text_7 = ['\nDo you want to exclude DRUG recordings?', ...
    '\n(1) - Yes', ...
    '\n(0) - No', ...
    '\nEnter a number: '];

excl_diaz = input(displays_text_7);

else

excl_diaz = 0;

end

if main_division ~= 6
    
displays_text_9 = ['\nDo you want to INCLUDE SPONTANEOUS recordings?', ...
'\n(1) - Yes', ...
'\n(0) - No', ...
'\nEnter a number: '];

incl_spont = input(displays_text_9);

else
    
incl_spont = 1;

end

if main_division ~= 1 && naive_ep == 1

displays_text_8 = ['\nDo you want to exclude NAIVE recordings?', ...
    '\n(1) - Yes', ...
    '\n(0) - No', ...
    '\nEnter a number: '];

excl_naiv = input(displays_text_8);

else

excl_naiv = 0;

end

displays_text_11 = ['\nFor PCA Plot, Enter How Many Seconds You Want to Plot (0 is no plot).', ...
'\nEnter a number: '];

pca_dur = input(displays_text_11);

clear displays_text displays_text_2 displays_text_3 displays_text_4 displays_text_5 displays_text_6 displays_text_7

% -------------------------------------------------------------------------

% Step 2: Reorganize Seizure Duration List

merged_sz_duration = [];

for sz_cnt = 1:length(seizure_duration_list)
    
    % No Seizures Detected Case
    
    if sum(seizure_duration_list{sz_cnt}) == 0
        
        merged_sz_duration = [merged_sz_duration ; ones(length(seizure_duration_list{sz_cnt}),1) * -1];
     
    % Otherwise, append seizure durations
    
    else
        
        merged_sz_duration = [merged_sz_duration ; seizure_duration_list{sz_cnt}];
        
    end
    
end

% -------------------------------------------------------------------------

% Step 3: Set Up Indices Based on Main Division Groups

switch main_division
    
    case 1 % Epileptic Vs Naive Animals

        % Prepare Output Variables
        
        ep_trials = [];
        naive_trials = [];
        
        % Uses Animal Info To Identify ID Of Epileptic and Naive Mice
        ep = animal_info(find(animal_info(:,5) == 1),1);
        naive = animal_info(find(animal_info(:,5) == 0),1);
        
        % Sorts Trials into Naive or Epileptic
        for cnt = 1:length(merged_sz_parameters)
            if ismember(merged_sz_parameters(cnt,1),ep)
                ep_trials = [ep_trials;cnt];
            elseif ismember(merged_sz_parameters(cnt,1),naive)
                naive_trials = [naive_trials;cnt];
            end
        end
        
        % Final Output - 1 is Epileptic, 2 is Naive
        subdiv_index{1} = ep_trials;
        subdiv_index{2} = naive_trials;
        anova_col_val(ep_trials) = 1; anova_col_val(naive_trials) = 0;

        duration_labels = {'Epileptic', 'Naive'};
        
    case 2 % Long Vs Short Seizures, Excluding < 5 Sec Events
        
        % Use Short Duration to Redefine Mean
        if excl_short
        mean_sz_dur = mean(merged_sz_duration(merged_sz_duration > short_duration));
        else
        mean_sz_dur = mean(merged_sz_duration(merged_sz_duration > 5));
        end
        
        % Final Output - 1 is Less Than Mean, 2 is Greater Or Equal to Mean
        subdiv_index{1} = find(merged_sz_duration < mean_sz_dur);
        subdiv_index{2} = find(merged_sz_duration >= mean_sz_dur);
        anova_col_val = merged_sz_duration >= mean_sz_dur;
        
        disp(strcat("Mean Event Length: ", num2str(mean_sz_dur), " sec"));
        disp(strcat("Short Event Averagen Length: ", num2str(mean(merged_sz_duration(subdiv_index{1}))), " sec"));
        disp(strcat("Long Event Average Length: ",num2str(mean(merged_sz_duration(subdiv_index{2}))), " sec"));

        duration_labels = {'Short Seizures', 'Long Seizures'};
        
    case 3 % Successfully Evocations Vs Failed Evocations (Shorter than exclusion)
        
        subdiv_index{1} = find(merged_sz_parameters(:,5) == 1 & merged_sz_duration > short_duration);
        subdiv_index{2} = find(merged_sz_parameters(:,5) == 0 | merged_sz_duration <= short_duration);
        anova_col_val = merged_sz_parameters(:,5);
        
        % Manually Exclude Animals With Different Feature Length
        excl_short = 0;
        
        excluded_indices = [];
        
        % Finds Animals With Invalid Feature List
        for animal = 1:length(seizure_duration_list)
            if sum(seizure_duration_list{animal} == 0)
            excluded_indices = [excluded_indices;find(merged_sz_parameters(:,1) == animal)];
            end
        end
        
        % Exclude Animals With Invalid Feature List
        for cnt = 1:length(subdiv_index)
        subdiv_index{cnt} = setdiff(subdiv_index{cnt}, excluded_indices);
        end
        
        clear excluded_indices

        duration_labels = {'Successful Evocations', 'Shorter than Exclusion Criteria'};
        
    case 4 % Levetiracetam vs Phenytoin vs Diazepam

        % Include Short Events and Diazepam
        excl_diaz = 0;

        % Control
        subdiv_index{1} = find(merged_sz_parameters(:,16) == 0 & merged_sz_parameters(:,17) == 0 & merged_sz_parameters(:,18) == 0);
        
        % Levetiracetam Alone
        subdiv_index{2} = find(merged_sz_parameters(:,17) > 0 & merged_sz_parameters(:,18) == 0 & merged_sz_parameters(:,16) == 0);

        % Phenytoin Alone
        subdiv_index{3} = find(merged_sz_parameters(:,17) == 0 & merged_sz_parameters(:,18) > 0 & merged_sz_parameters(:,16) == 0);

        % Diazepam Alone
        subdiv_index{4} = find(merged_sz_parameters(:,16) > 0 & merged_sz_parameters(:,17) == 0 & merged_sz_parameters(:,18) == 0);

        % In Combination
        subdiv_index{5} = find(merged_sz_parameters(:,17) > 0 & merged_sz_parameters(:,18) > 0);

        duration_labels = {'No Drug', 'Levetiracetam', 'Phenytoin', 'Diazepam', 'Levetiracetam & Phenytoin'};
        
    case 5 % Additional Stimulation

        % Can Add More To Differentiate Into Unique
        
        excl_addl = 0;
        excl_diaz = 1;
        
        % Identify Animals With Additional Stimulation
        
        an_w_addl = unique(merged_sz_parameters(merged_sz_parameters(:,10) == 473 & merged_sz_parameters(:,13) > 0,1));

        % Control
        subdiv_index{1} = find(ismember(merged_sz_parameters(:,1), an_w_addl) & merged_sz_parameters(:,10) == -1);
        
        % 10+ Hz Stimulation IMMEDIATELY AFTER
        subdiv_index{2} = find(ismember(merged_sz_parameters(:,1), an_w_addl) & merged_sz_parameters(:,15) >= 10 & ...
            merged_sz_parameters(:,13) == merged_sz_parameters(:,12));
        
        % Constant Light IMMEDIATELY AFTER
        subdiv_index{3} = find(ismember(merged_sz_parameters(:,1), an_w_addl) & merged_sz_parameters(:,15) == 0 & ...
            merged_sz_parameters(:,13) == merged_sz_parameters(:,12));
        
        % 10+ Hz Stimulation ANY DELAY
        subdiv_index{4} = find(ismember(merged_sz_parameters(:,1), an_w_addl) & merged_sz_parameters(:,15) >= 10 & ...
            merged_sz_parameters(:,13) > merged_sz_parameters(:,12));
        
        % Constant Light ANY DELAY
        subdiv_index{5} = find(ismember(merged_sz_parameters(:,1), an_w_addl) & merged_sz_parameters(:,15) == 0 & ...
            merged_sz_parameters(:,13) > merged_sz_parameters(:,12));

        duration_labels = {'Control', 'High Freq No Delay', 'Const No Delay', 'High Freq Any Delay', 'Const Any Delay'};
   
    case 6 % Spontaneous Vs Evoked
        
        % Spontaneous
        subdiv_index{1} = find(merged_sz_parameters(:,8) == -1 & merged_sz_parameters(:,5) == 1);
        
        % Evoked
        subdiv_index{2} = find(merged_sz_parameters(:,8) ~= -1);
        
        duration_labels = {'Spontaneous', 'Evoked'};
        
end

% -------------------------------------------------------------------------

% Step 4A: Refine Based on Spontaneous or Evoked. Remove if not include
% spontaneous

if incl_spont
    
    if main_division == 6
    else
        
        spont_indices = find(merged_sz_parameters(:,8) == -1 & merged_sz_parameters(:,5) == 1);
        length_subdiv = length(subdiv_index);
        for cnt = 1:length_subdiv
            subdiv_index{length_subdiv + cnt} = intersect(subdiv_index{cnt},spont_indices);
            subdiv_index{cnt} = setdiff(subdiv_index{cnt},spont_indices);
        end 

        % Extends Duration Labelling
        for dur_text = 1:length(duration_labels)
        addl_duration_labels{dur_text} = strcat(duration_labels{dur_text}," Spontaneous");
        duration_labels{dur_text} = strcat(duration_labels{dur_text}," Evoked");
        end
        
        duration_labels = [duration_labels,addl_duration_labels];
        
    end
    
else 
   
    excluded_indices = find(merged_sz_parameters(:,8) == -1);
    for cnt = 1:length(subdiv_index)
        subdiv_index{cnt} = setdiff(subdiv_index{cnt}, excluded_indices);
    end
    
end

% -------------------------------------------------------------------------

% Step 4B: Refine Indices Based on Epileptic Or Naive

if naive_ep
    
    if main_division == 1
    else
        
        % Prepare Output Variables
        
        ep_trials = [];
        naive_trials = [];
        
        % Uses Animal Info To Identify ID Of Epileptic and Naive Mice
        
        ep = animal_info(find(animal_info(:,5) == 1),1);
        naive = animal_info(find(animal_info(:,5) == 0),1);
        
        % Sorts Trials into Naive or Epileptic
        for cnt = 1:length(merged_sz_parameters)
            if ismember(merged_sz_parameters(cnt,1),ep)
                ep_trials = [ep_trials;cnt];
            elseif ismember(merged_sz_parameters(cnt,1),naive)
                naive_trials = [naive_trials;cnt];
            end
        end
        
        % Puts Naive into Extended Part of Subdivided Index
        length_subdiv = length(subdiv_index);
        for cnt = 1:length_subdiv
            subdiv_index{length_subdiv + cnt} = intersect(subdiv_index{cnt},naive_trials);
            subdiv_index{cnt} = intersect(subdiv_index{cnt},ep_trials);
        end 

        % Extends Duration Labelling
        for dur_text = 1:length(duration_labels)
        addl_duration_labels{dur_text} = strcat(duration_labels{dur_text}," Naive");
        duration_labels{dur_text} = strcat(duration_labels{dur_text}," Epileptic");
        end

        % If Exclude Naive, Remove Naive Subdiv Index (Second Half)
        if excl_naiv

        subdiv_index = subdiv_index(1:size(subdiv_index,2)/2);
        
        else

        duration_labels = [duration_labels,addl_duration_labels];
        
        end
    
    end
end

% -------------------------------------------------------------------------

% Step 5: Shorten Indices Based on Seizure Duration

if excl_short 
    
    excluded_indices = find(merged_sz_duration < short_duration);
    for cnt = 1:length(subdiv_index)
        subdiv_index{cnt} = setdiff(subdiv_index{cnt}, excluded_indices);
    end
    anova_excluded_indices = union(anova_excluded_indices, excluded_indices);
    clear excluded_indices
    
end

% -------------------------------------------------------------------------

% Step 6: Exclude Indices With Additional Stimulation

if excl_addl
    
    excluded_indices = find(merged_sz_parameters(:,10) ~= -1);
    for cnt = 1:length(subdiv_index)
        subdiv_index{cnt} = setdiff(subdiv_index{cnt}, excluded_indices);
    end
    anova_excluded_indices = union(anova_excluded_indices, excluded_indices);
    clear excluded_indices
    
end

% -------------------------------------------------------------------------

% Step 7: Exclude Early Recordings (All < Animal 22)

if no_to_early
    
    excluded_indices = find(merged_sz_parameters(:,1) < an_excl);
    for cnt = 1:length(subdiv_index)
        subdiv_index{cnt} = setdiff(subdiv_index{cnt}, excluded_indices);
    end
    anova_excluded_indices = union(anova_excluded_indices, excluded_indices);
    clear excluded_indices
    
end

% -------------------------------------------------------------------------

% Step 8: Exclude Diazepam (and Other Drugs)

if excl_diaz
    
    excluded_indices = find(merged_sz_parameters(:,16) > 0 | merged_sz_parameters(:,17) > 0 | merged_sz_parameters(:,18) > 0);
    for cnt = 1:length(subdiv_index)
        subdiv_index{cnt} = setdiff(subdiv_index{cnt}, excluded_indices);
    end
    anova_excluded_indices = union(anova_excluded_indices, excluded_indices);
    clear excluded_indices
    
end

% -------------------------------------------------------------------------

% Step 9: Uses Seizure Duration to Calculate Thirds of Merged Features

% Loop Through Different Divisions
for cnt = 1:length(subdiv_index)
    
    feature_output_for_plot = [];
    pca_for_cnt = [];
    
    % Loops Through Trials
    for seizure_idx = 1:length(subdiv_index{cnt})
        
        if seizure_idx == 1
            first_run = 1;
        else
            first_run = 0;
        end
        
        % Extracts Specific Data For Seizure
        indv_data = merged_output_array{subdiv_index{cnt}(seizure_idx)};
        
        % Extracts Seizure Duration and Stim Duration. Calculate Seizure
        % Start
        indv_duration = merged_sz_duration(subdiv_index{cnt}(seizure_idx));
        indv_stim_duration = merged_sz_parameters(subdiv_index{cnt}(seizure_idx),12);
        
        % Create Indices For Thirds
        if indv_stim_duration ~= -1
        sz_start = (t_before + indv_stim_duration)/winDisp;
        else
        sz_start = (t_before)/winDisp;
        end

        sz_end = sz_start + indv_duration/winDisp;
        indices = [1 , floor(t_before/winDisp) , floor(sz_start) , floor(sz_start+round((sz_end-sz_start)/3)), ...
            floor(sz_start+round(2*(sz_end-sz_start)/3)) , floor(sz_end) , floor(sz_end+30/winDisp)];
        
        % Adds Data to PCA Matrix
        pca_for_cnt = [pca_for_cnt;indv_data(sz_start:sz_start + pca_dur/winDisp,:)];

        % Prepare For Case In Which End + 30 Seconds Exceed Bounds
        if sz_end + 30/winDisp >= (t_after + t_before)/winDisp - 1
            indices(7) = floor((t_after + t_before)/winDisp) - 1;
        end

        % Prepare For Edge Case Where Seizures Doesnt Stop
        if sz_end >= (t_after + t_before)/winDisp - 1
            indices(6) = floor((t_after + t_before)/winDisp) - 1;
            indices(7) = indices(6);
        end
        
        % Calculate Means In Indices. However, EXCLUDE STIM For Second Stim
        % Does Task ONLY If Frequency > 1 Hz
        
        if main_division == 5 && merged_sz_parameters(subdiv_index{cnt}(seizure_idx),15) > 1

        % Determine Duration and Delay of Onset of Second Stim
        indv_delay =  merged_sz_parameters(subdiv_index{cnt}(seizure_idx),13);
        indv_sec_dur =  merged_sz_parameters(subdiv_index{cnt}(seizure_idx),14);

        % Find Indices For Second Stim
        second_stim_st = floor((t_before + indv_delay)/winDisp);
        second_stim_end = floor((t_before + indv_delay + indv_sec_dur)/winDisp);

        % Set Indices For Pre, During, Etc.
        pre_stim_indices = indices(1):indices(2);
        during_stim_indices = indices(2):indices(3);
        first_third_indices = indices(3):indices(4);
        second_third_indices = indices(4):indices(5);
        final_third_indices = indices(5):indices(6);
        if indices(6) ~= indices (7)
        post_ictal_indices = indices(6):indices(7);
        else
        post_ictal_indices = pre_stim_indices;
        end

        % Find Values Not in Stimulation
        pre_stim_indices = pre_stim_indices(~ismember(pre_stim_indices, second_stim_st:second_stim_end));
        during_stim_indices = during_stim_indices(~ismember(during_stim_indices, second_stim_st:second_stim_end));
        first_third_indices = first_third_indices(~ismember(first_third_indices, second_stim_st:second_stim_end));
        second_third_indices = second_third_indices(~ismember(second_third_indices, second_stim_st:second_stim_end));
        final_third_indices = final_third_indices(~ismember(final_third_indices, second_stim_st:second_stim_end));
        post_ictal_indices = post_ictal_indices(~ismember(post_ictal_indices, second_stim_st:second_stim_end));

        % Calculate Mean. May End Up With 'EMPTY' Row Vector if All Removed
        mean_pre_stim = mean(indv_data(pre_stim_indices,:),1);
        mean_during_stim = mean(indv_data(during_stim_indices,:),1);
        mean_first_third = mean(indv_data(first_third_indices,:),1);
        mean_second_third = mean(indv_data(second_third_indices,:),1);
        mean_final_third = mean(indv_data(final_third_indices,:),1);
        mean_post_ictal = mean(indv_data(post_ictal_indices,:),1);

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

        % Otherwise, Calculate With All Indices

        else
        
        mean_pre_stim = mean(indv_data(indices(1):indices(2),:),1);
        mean_during_stim = mean(indv_data(indices(2):indices(3),:),1);
        mean_first_third = mean(indv_data(indices(3):indices(4),:),1);
        mean_second_third = mean(indv_data(indices(4):indices(5),:),1);
        mean_final_third = mean(indv_data(indices(5):indices(6),:),1);
        if indices(6) ~= indices (7)
        mean_post_ictal = mean(indv_data(indices(6):indices(7),:),1);
        else
        mean_post_ictal = mean_pre_stim;
        end

        end

        % No Seizure
        if sz_start == sz_end
            replacement = zeros(size(mean_pre_stim));
            final_divided = [mean_pre_stim; mean_during_stim; replacement; ...
                replacement; replacement; mean_post_ictal];
        % Spontaneous
        elseif merged_sz_parameters(subdiv_index{cnt}(seizure_idx),8) == -1
            final_divided = [mean_pre_stim; nan(size(mean_pre_stim)); mean_first_third; ...
            mean_second_third; mean_final_third; mean_post_ictal];
        % Regular
        else
            final_divided = [mean_pre_stim; mean_during_stim; mean_first_third; ...
            mean_second_third; mean_final_third; mean_post_ictal];
        end
        
        % Segregates According to Channels
        if rem(length(mean_pre_stim),4) ~= 0
            disp('Error!');
        else
            
            % Split by Channels First
            
            for ch = 1:4
                
                feature_per_channel = final_divided(:,ch:4:end);
            
                % Split by Features
                for feature = 1:length(mean_pre_stim)/4
                    
                    % Create Array if Empty
                    if first_run
                    feature_output_for_plot{ch}{feature} = feature_per_channel(:,feature)';
                    % Otherwise Append Feature List
                    else
                    feature_output_for_plot{ch}{feature} = [feature_output_for_plot{ch}{feature};feature_per_channel(:,feature)'];
                    end
                    
                end
                
            end
            
        end
            
    end
    
    final_feature_output{cnt} = feature_output_for_plot;
    final_pca_plot{cnt} = pca_for_cnt;
    
end

% -------------------------------------------------------------------------

% Step 10: Determine Which Features to Plot

features_to_plot = [];

question = input(['\nDo you want to plot all features? '...
    '\n(1) - Yes', ...
    '\n(0) - No', ...
    '\nEnter a number: ']);

if question == 1
    
    if ismember('Band_Power',feature_names)
        features_to_plot = 1:(length(feature_names) + size(bp_filters,1) - 1);
        bp_index = find(strcmp(feature_names,'Band_Power') == 1);
    else
        features_to_plot = 1:length(feature_names);
        bp_index = -1;
    end

else

for feature = 1:length(feature_names)
    
    % Determine Actual Index, Since BP Increases Everything By BP_Filters - 1
    act_feature_index = feature;
    bp_index = find(strcmp(feature_names,'Band_Power') == 1);
    
    if feature > bp_index
        act_feature_index = act_feature_index + size(bp_filters,1) - 1;
    end
    
    question = strcat("\nDo you want to plot feature: ", feature_names{feature},...
        '\n(1) - Yes', ...
        '\n(0) - No', ...
        "\nEnter a number: ");
    yes_or_no = input(question);
    
    if yes_or_no == 1
        if feature == bp_index
        features_to_plot = [features_to_plot, act_feature_index : (act_feature_index+size(bp_filters,1) - 1)];
        else
        features_to_plot = [features_to_plot, act_feature_index];
        end
    end

end

end

% -------------------------------------------------------------------------

% Step 11: Make Divided Plots

% Structure of Final Feature Output is divide by 1) class 2) channel 3)
% feature.

% Each Plot Needs to Split Into Channel, then Plot Both Classes on Each
% Feature, Separated by Color

% First Split Plots by Channel

% Sets Up Standard Deviation Amounts For Errorbar Plot And How Many Rows To
% Divide Features Into

question = strcat("\nHow many standard error of the mean (SEM) to plot for errorbars?",...
    "\nEnter a number: ");
std_cnt = input(question);

question = strcat("\nHow many rows should the information be plotted in?",...
    "\nEnter a number: ");
rows_subplot = input(question);

question = strcat("\nShould different classes be offset for clarity? ",...
    '\n(1) - Yes', ...
    '\n(0) - No', ...
    "\nEnter a number: ");
offset = input(question);

% Line For NOT Boxplots

if std_cnt ~= 0
question = strcat("\nShould there be a line connecting the two points? ",...
    '\n(1) - Yes', ...
    '\n(0) - No', ...
    "\nEnter a number: ");
yesline = input(question);

if yesline
    lineornot = ":";
else
    lineornot = "";
end
end

for ch = 1:4
    
    figure;
    t = tiledlayout(rows_subplot,ceil(length(features_to_plot)/rows_subplot));
    
    % Subplots By Features
    for feature = 1:length(features_to_plot)
        
        % Identifies Features
        nexttile;
        idx_feature = features_to_plot(feature);
        
        % Sets Colors and Shapes. Replicates Colors For Naive/Epileptic
        
        Colorset_plot = cbrewer('qual','Set1',size(final_feature_output,2) + 3);
        Colorset_plot(Colorset_plot>1) = 1;
        Colorset_plot(Colorset_plot<0) = 0;
        
        % Removes Color 3 (Green)
        
        if naive_ep && main_division ~= 1 && excl_naiv == 0
            positioning(1:size(final_feature_output,2)/2) = '*';
            positioning(size(final_feature_output,2)/2 + 1:size(final_feature_output,2)) = '^';
            Colorset_plot = Colorset_plot(4:end,:);
            Colorset_plot(size(final_feature_output,2)/2 + 1:size(final_feature_output,2),:) = Colorset_plot(1:size(final_feature_output,2)/2,:);
        elseif main_division == 1
            positioning(1:size(final_feature_output,2)/2) = '*';
            positioning(size(final_feature_output,2)/2 + 1:size(final_feature_output,2)) = '^';
        else
            positioning(1:size(final_feature_output,2)) = 'o';
            Colorset_plot = Colorset_plot(4:end,:);
        end
        
        hold on
        
        % Plots All Classes
        num_on_x = 0;
        
        % Y Limits
        ylim_min = 0;
        ylim_max = 0;

        for class_split = 1:size(final_feature_output,2)
            
            % Case For No Items in Class
            if not(isempty(final_feature_output{class_split}))
            % Extracts Relevant Data
            indv_data = final_feature_output{class_split}{ch}{idx_feature};

            % Adds to Size
            if size(indv_data,2) > num_on_x
                num_on_x = size(indv_data,2);
            end
            
            % Define X Axes and Appropriate Offset
            xaxis = [1:length(mean(indv_data))];
            if offset
                offsetval = - 0.5/(size(final_feature_output,2) + 2) * (size(final_feature_output,2) + 1) + class_split/(size(final_feature_output,2) + 2);
            else
                offsetval = 0;
            end
            xaxis = xaxis + offsetval;
            
            % Plots Individual Data
            if ind_data
                plot_info = positioning(class_split);
                
                for row_cnt = 1:size(indv_data,1)
                    scatter(xaxis + (rand(size(xaxis)) - 0.5)./(size(final_feature_output,2) + 2),...
                        indv_data(row_cnt,:),0.5,"MarkerEdgeColor",Colorset_plot(class_split,:),"MarkerFaceColor",Colorset_plot(class_split,:));
                end
                
            else
                plot_info = strcat(lineornot,positioning(class_split)); % : for dotted line     
            end
            
            % Plots Group Data
            
            if std_cnt == 0
            
            boxplot(indv_data,'Positions',xaxis,'Widths',0.5/(size(final_feature_output,2) + 2),'Colors',Colorset_plot(class_split,:),'Symbol','') % No Outlier Symbols
            
            % Fixes Y Lim For Box Plots
            if min(indv_data,[],"all") < ylim_min
                ylim_min = min(indv_data,[],"all");
            end
            if max(indv_data,[],"all") > ylim_max
                ylim_max = max(indv_data,[],"all");
            end
            
            else 

            errorbar(xaxis,nanmean(indv_data),std_cnt.*nanstd(indv_data)./sqrt(size(indv_data,1)),plot_info,...
                 "MarkerEdgeColor",Colorset_plot(class_split,:),"MarkerFaceColor",Colorset_plot(class_split,:),...
                 'Color',Colorset_plot(class_split,:),'LineWidth',2)
            end
            
            else
                scatter(0,0)
            end
            
            
        end
        
        hold off
        
        % Draws 0 Point and Labels X Axes
        yline(0,'-k','LineWidth',1);
        xticks(1:num_on_x);
        xticklabels({'Pre-Seizure','Stimulation','Sz - Beginning','Sz - Middle','Sz - End','Post Ictal'});
        xtickangle(45);
        
        % Y Limits on Box Plot Only
        if ylim_max ~= ylim_min
        ylim([ylim_min,ylim_max]);
        end
        xlim([0,num_on_x+1]);
        
        % Titling
        if idx_feature >= bp_index && idx_feature <= bp_index + size(bp_filters,1) - 1
        title(strcat(strrep(feature_names{bp_index},"_"," ")," ",num2str(bp_filters(idx_feature - bp_index + 1,1)),...
            "Hz to ", num2str(bp_filters(idx_feature - bp_index + 1,2)), "Hz"));
        elseif idx_feature > bp_index + size(bp_filters,1) - 1
        title(strrep(feature_names{idx_feature - (size(bp_filters,1) - 1)},"_"," "))
        elseif idx_feature < bp_index
        title(strrep(feature_names{idx_feature},"_"," "));
        end
        
    end
    
end

% -------------------------------------------------------------------------

% Step 12: Plots Seizure Duration Per Class

figure

hold on

% Loop Through Different Divisions
for class_split = 1:length(subdiv_index)
    scatter(ones(length(merged_sz_duration(subdiv_index{class_split})),1) .* class_split , ...
        merged_sz_duration(subdiv_index{class_split}),"MarkerEdgeColor",Colorset_plot(class_split,:),"MarkerFaceColor",Colorset_plot(class_split,:))
end

hold off

% Draws 0 Point and Labels X Axes
yline(0,'-k','LineWidth',1);
xticks(1:length(subdiv_index));
xlim([0,length(subdiv_index) + 1]);
xticklabels(duration_labels);
xtickangle(45);

% -------------------------------------------------------------------------

% Step 13: PCA Plot

if pca_dur > 0

merged_data_for_pca = [];
colors_for_pca = [];

% Black
end_color = [0 0 0];

% Extracts Data
for class_split = 1:length(subdiv_index)
    merged_data_for_pca = [merged_data_for_pca;final_pca_plot{class_split}];

    % Goes From Color to White (For End)
    cmap = interp1([0, 1], [Colorset_plot(class_split,:); end_color], linspace(0, 1, pca_dur/winDisp + 1));
    colors_for_pca = [colors_for_pca;repmat(cmap,size(subdiv_index{class_split},1),1)];
end

colors_for_pca(colors_for_pca>1) = 1;
colors_for_pca(colors_for_pca<0) = 0;

% PCA
[coeff,score] = pca(merged_data_for_pca);

% PLots
figure
scatter3(score(:,1),score(:,2),score(:,3),3,colors_for_pca,'filled');
xlabel('Component 1')
ylabel('Component 2')
zlabel('Component 3')

else

coeff = NaN;
score = NaN;

end

% -------------------------------------------------------------------------

% Step 14: Outputs Number of Unique Animals Per Class

for class_split = 1:length(subdiv_index)
% Following Line Is Used to Display Animals In Each Class
unique(merged_sz_parameters(subdiv_index{class_split},1))'
num_in_class = length(unique(merged_sz_parameters(subdiv_index{class_split},1)));
disp(strcat("Class ", num2str(class_split), ": ", num2str(length(subdiv_index{class_split})),...
    " Seizures in ", num2str(num_in_class), " Animals"));
end

end