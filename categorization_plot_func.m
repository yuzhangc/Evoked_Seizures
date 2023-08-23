function [final_feature_output, subdiv_index, anova_results] = categorization_plot_func(merged_output_array,merged_sz_parameters,seizure_duration_list,directory)

% Use Integrated Feature Information Across All Channels, Then Separates Them
% According to User Input and Categorization. Makes Plots Too

% Input Variables
% merged_output_array - merged feature list
% merged_sz_parameters - complete seizure information list
% seizure_duration_list - list of seizure duration, organized by folder
% directory - directory to extract feature info from

% Output Variables
% final_feature_output - features segregated by class, channels, then
% individual features across all divisions
% subdiv_index - divisions
% anova_results - using anova_col_val to guide ANOVA calculations

% -------------------------------------------------------------------------

% Step 0: Set up Variables
anova_excluded_indices = [];

% Loads Animal Information

animal_info = readmatrix(strcat(directory,'Animal Master.csv'));

% Extract Features Information and Names From Last Folder in Directory

complete_list = dir(directory); dirFlags = [complete_list.isdir]; subFolders = complete_list(dirFlags);
real_folder_st = find(ismember({subFolders.name},'00000000 DO NOT PROCESS')); real_folder_end = find(ismember({subFolders.name},'99999999 END')); 
subFolders = subFolders(real_folder_st + 1:real_folder_end - 1);
path_extract = strcat(directory,subFolders(length(subFolders)).name,'\');
load(strcat(path_extract,'Normalized Features.mat'))
feature_names = fieldnames(norm_features);

% -------------------------------------------------------------------------

% Step 1: Receive User Input
% Generates 4 variables
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
    '\n(4) - Comparison of Levetiracetam and Phenytoin with Control',...
    '\n(5) - Additional Stimulation Or Not (INCOMPLETE)',...
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
    short_duration = input('\nHow many seconds is considered a short/non-evoked event? Type in a number (e.g. 15): ');
end

if main_division ~= 4
    
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

displays_text_7 = ['\nDo you want to exclude DIAZEPAM recordings?', ...
    '\n(1) - Yes', ...
    '\n(0) - No', ...
    '\nEnter a number: '];

excl_diaz = input(displays_text_7);

else

excl_diaz = 0;

end

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
        
    case 4 % Levetiracetam vs Phenytoin vs Diazepam

        % Include Short Events and Diazepam
        excl_diaz = 0;

        % Control
        subdiv_index{1} = find(merged_sz_parameters(:,16) == 0 & merged_sz_parameters(:,17) == 0 & merged_sz_parameters(:,18) == 0);
        
        % Levetiracetam Alone
        subdiv_index{2} = find(merged_sz_parameters(:,17) > 0 & merged_sz_parameters(:,18) == 0);

        % Phenytoin Alone
        subdiv_index{3} = find(merged_sz_parameters(:,17) == 0 & merged_sz_parameters(:,18) > 0);

        % Diazepam Alone
        subdiv_index{4} = find(merged_sz_parameters(:,16) > 0);

        % In Combination
        subdiv_index{5} = find(merged_sz_parameters(:,17) > 0 & merged_sz_parameters(:,18) > 0);
        
    case 5 % Additional Stimulation

        % Can Add More To Differentiate Into Unique
        
        excl_addl = 0;
        disp("Colors")
        addl_stim_parameters = unique(merged_sz_parameters(:,[10]))
        
        % INCOMPLETE - ONLY FOR COLOR RN
        
        for cnt = 1:length(addl_stim_parameters)
            subdiv_index{cnt} = find(merged_sz_parameters(:,10) == addl_stim_parameters(cnt));
        end
        
end

% -------------------------------------------------------------------------

% Step 4: Refine Indices Based on Epileptic Or Naive

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

% Step 8: Exclude Diazepam

if excl_diaz
    
    excluded_indices = find(merged_sz_parameters(:,16) == 1);
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
        if indv_stim_duration ~= 0

        sz_start = (t_before + indv_stim_duration)/winDisp;
        sz_end = sz_start + indv_duration/winDisp;
        indices = [1 , t_before/winDisp , sz_start , sz_start+round((sz_end-sz_start)/3), ...
            sz_start+round(2*(sz_end-sz_start)/3) , sz_end , sz_end+30/winDisp];
        
        % Prepare For Edge Case Where Seizures Doesnt Stop
        if sz_end <= (t_after + t_before)/winDisp
            indices(6) = (t_after + t_before)/winDisp - 1;
            indices(7) = indices(6);
        end
        
        % Calculate Means In Indices
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
        
        final_divided = [mean_pre_stim; mean_during_stim; mean_first_third; ...
            mean_second_third; mean_final_third; mean_post_ictal];

        else

        % Calculate Only Pre and Post (and Stim). Otherwise Ignore
        
        indices = [1 , t_before/winDisp , sz_start , sz_start+round((sz_end-sz_start)/3), ...
            sz_start+round(2*(sz_end-sz_start)/3) , sz_end , sz_end+30/winDisp];

        mean_pre_stim = mean(indv_data(indices(1):indices(2),:),1);
        mean_during_stim = mean(indv_data(indices(2):indices(3),:),1);
        mean_post_ictal = mean(indv_data(indices(6):indices(7),:),1);

        final_divided = [mean_pre_stim; mean_during_stim; 0; 0; 0; mean_post_ictal];

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
        
        if naive_ep && main_division ~= 1
            positioning(1:size(final_feature_output,2)/2) = '*';
            positioning(size(final_feature_output,2)/2 + 1:size(final_feature_output,2)) = '^';
            Colorset_plot = Colorset_plot(4:end,:);
            Colorset_plot(size(final_feature_output,2)/2 + 1:size(final_feature_output,2),:) = Colorset_plot(1:size(final_feature_output,2)/2,:);
        elseif main_division == 1
            positioning(1:size(final_feature_output,2)/2) = '*';
            positioning(size(final_feature_output,2)/2 + 1:size(final_feature_output,2)) = '^';
            Colorset_plot = Colorset_plot(1:2,:);
        else
            positioning(1:size(final_feature_output,2)) = 'o';
            Colorset_plot = Colorset_plot(4:end,:);
        end
        
        hold on
        
        % Plots All Classes
        for class_split = 1:size(final_feature_output,2)
            
            % Case For No Items in Class
            if not(isempty(final_feature_output{class_split}))
            % Extracts Relevant Data
            indv_data = final_feature_output{class_split}{ch}{idx_feature};
            
            % Define X Axes and Appropriate Offset
            xaxis = [1:length(mean(indv_data))];
            if offset
                offsetval = - 1/size(final_feature_output,2)*(size(final_feature_output,2)-1) + class_split/size(final_feature_output,2);
            else
                offsetval = 0;
            end
            xaxis = xaxis + offsetval;
            
            % Plots Individual Data
            if ind_data
                plot_info = positioning(class_split);
                
                for row_cnt = 1:size(indv_data,1)
                    scatter(xaxis,indv_data(row_cnt,:),"MarkerEdgeColor",Colorset_plot(class_split,:),"MarkerFaceColor",Colorset_plot(class_split,:));
                end
                
            else
                plot_info = strcat(":",positioning(class_split));     
            end
            
            % Plots Group Data
            
            boxplot(indv_data,'Positions',xaxis,'Widths',0.5/size(final_feature_output,2),'Colors',Colorset_plot(class_split,:))
            
            % errorbar(xaxis,mean(indv_data),std_cnt.*std(indv_data)./sqrt(size(indv_data,1)),plot_info,...
            %     "MarkerEdgeColor",Colorset_plot(class_split,:),"MarkerFaceColor",Colorset_plot(class_split,:),...
            %     'Color',Colorset_plot(class_split,:),'LineWidth',2)
            
            else
                scatter(0,0)
            end
            
            
        end
        
        hold off
        
        % Draws 0 Point and Labels X Axes
        yline(0,'-k','LineWidth',1);
        xticks(1:size(indv_data,2));
        xticklabels({'Pre-Seizure','Stimulation','Sz - Beginning','Sz - Middle','Sz - End','Post Ictal'});
        xtickangle(45);
        
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

% Step 12: Outputs Number of Unique Animals Per Class

for class_split = 1:length(subdiv_index)
% Following Line Is Used to Display Animals In Each Class
unique(merged_sz_parameters(subdiv_index{class_split},1))'
num_in_class = length(unique(merged_sz_parameters(subdiv_index{class_split},1)));
disp(strcat("Class ", num2str(class_split), ": ", num2str(length(subdiv_index{class_split})),...
    " Seizures in ", num2str(num_in_class), " Animals"));
end

end