function [final_feature_output, subdiv_index, merged_sz_duration] = naiv_ep_plot_func_fig4D(merged_output_array,merged_sz_parameters,seizure_duration_list,directory,subFolders,day_st,day_end)

% On-Demand Seizures Facilitate Rapid Screening of Therapeutics for Epilepsy
% Authors: Yuzhang Chen, Brian Litt, Flavia Vitale, Hajime Takano
% DOI: https://doi.org/10.7554/eLife.101859

% Use Integrated Feature Information Across All Channels, Then Separates Them
% According to User Input and Categorization. Makes Plots Too

% Input Variables
% merged_output_array - merged feature list
% merged_sz_parameters - complete seizure information list
% seizure_duration_list - list of seizure duration, organized by folder
% directory - directory to extract feature info from
% day_st and day_end - start and end dates for early/late

% Output Variables
% final_feature_output - features segregated by class, channels, then
% individual features across all divisions
% subdiv_index - divisions
% merged_sz_duration - Merged Seizure Durations

% -------------------------------------------------------------------------

% Loads Animal Information

animal_info = readmatrix(strcat(directory,'Animal Master.csv'));

% Extract Features Information and Names From Last Folder in Directory

path_extract = strcat(directory,subFolders(length(subFolders)).name,'\');
load(strcat(path_extract,'Raw Features.mat'))
norm_features = features;
feature_names = fieldnames(norm_features);

% -------------------------------------------------------------------------

% Step 1: Identify Inclusion/Exclusion Criteria
% Generates 7 variables
% 1) main_division - main plot
% 2) ind_data - plot individual dots or not
% 3) naive_ep - splits naive or epileptic
% 4) excl_addl - exclude any with additional stimulation afterwards
% 5) excl_short - exclude events shorter than short_duration (15 sec)
% 6) excl_diaz - exclude diazepam trials
% 7) excl_naiv - exclude naive animals

main_division = 1;

% Plot Individual Data
ind_data = 1;

% Split Naive and Epileptic Data
naive_ep = 1;

% Exclude those W Additional Stim After Evoke
excl_addl = 1;

% Exclude Shorter Than 15 Sec
excl_short = 1;
short_duration = 15;

% Exclude Drug Trials
excl_diaz = 1;

% Keep Naive Animals
excl_naiv = 0;

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

% -------------------------------------------------------------------------

% Step 4: Refine Based on Spontaneous or Evoked. Remove if not include
% spontaneous

excluded_indices = find(merged_sz_parameters(:,8) == -1);
for cnt = 1:length(subdiv_index)
    subdiv_index{cnt} = setdiff(subdiv_index{cnt}, excluded_indices);
end

% -------------------------------------------------------------------------

% Step 5: Refine Indices Based on Epileptic Or Naive

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

% Step 6: Shorten Indices Based on Seizure Duration

if excl_short 
    
    excluded_indices = find(merged_sz_duration < short_duration);
    for cnt = 1:length(subdiv_index)
        subdiv_index{cnt} = setdiff(subdiv_index{cnt}, excluded_indices);
    end
    clear excluded_indices
    
end

% -------------------------------------------------------------------------

% Step 7: Exclude Indices With Additional Stimulation

if excl_addl
    
    excluded_indices = find(merged_sz_parameters(:,10) ~= -1);
    for cnt = 1:length(subdiv_index)
        subdiv_index{cnt} = setdiff(subdiv_index{cnt}, excluded_indices);
    end
    clear excluded_indices
    
end

% -------------------------------------------------------------------------

% Step 8: Exclude Days Not In Index

excluded_indices = find(merged_sz_parameters(:,20) < day_st | merged_sz_parameters(:,20) > day_end);
for cnt = 1:length(subdiv_index)
    subdiv_index{cnt} = setdiff(subdiv_index{cnt}, excluded_indices);
end
clear excluded_indices

% -------------------------------------------------------------------------

% Step 9: Exclude Diazepam (and Other Drugs)

if excl_diaz
    
    excluded_indices = find(merged_sz_parameters(:,16) > 0 | merged_sz_parameters(:,17) > 0 | merged_sz_parameters(:,18) > 0);
    for cnt = 1:length(subdiv_index)
        subdiv_index{cnt} = setdiff(subdiv_index{cnt}, excluded_indices);
    end
    clear excluded_indices
    
end

% -------------------------------------------------------------------------

% Step 10: Uses Seizure Duration to Calculate Thirds of Merged Features

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
        if indv_stim_duration ~= -1
        sz_start = (t_before + indv_stim_duration)/winDisp;
        else
        sz_start = (t_before)/winDisp;
        end

        sz_end = sz_start + indv_duration/winDisp;
        indices = [1 , floor(t_before/winDisp) , floor(sz_start) , floor(sz_start+round((sz_end-sz_start)/3)), ...
            floor(sz_start+round(2*(sz_end-sz_start)/3)) , floor(sz_end) , floor(sz_end+30/winDisp)];
        
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
    
end

% -------------------------------------------------------------------------

% Step 11: Determine Which Features to Plot

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

% Step 12: Make Divided Plots

% Structure of Final Feature Output is divide by 1) class 2) channel 3)
% feature.

% Each Plot Needs to Split Into Channel, then Plot Both Classes on Each
% Feature, Separated by Color

% First Split Plots by Channel

% Sets Up Standard Deviation Amounts For Errorbar Plot And How Many Rows To
% Divide Features Into

std_or_sem = 0;
std_cnt = 0;

% Plot in 1 Row w/ Offset
rows_subplot = 1;
offset = 1;

lineornot = "";

ch = 3;
    
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

        elseif std_cnt >= 0
            plot_info = strcat(lineornot,positioning(class_split)); % : for dotted line     
        end

        % Plots Group Data

        if std_cnt < 0

        boxplot(indv_data,'Positions',xaxis,'Widths',0.5/(size(final_feature_output,2) + 2),'Colors',Colorset_plot(class_split,:),'Symbol','') % No Outlier Symbols

        % Fixes Y Lim For Box Plots
        if min(indv_data,[],"all") < ylim_min
            ylim_min = min(indv_data,[],"all");
            % ylim_min = -3;
        end
        if max(indv_data,[],"all") > ylim_max
            ylim_max = max(indv_data,[],"all");
            % ylim_max = 6;
        end

        else 

        % Correction For Standard Error of the Mean (SEM)
        if std_or_sem
            correction_val = 1;
        else
            correction_val = sqrt(size(indv_data,1));
        end

        errorbar(xaxis,nanmean(indv_data),std_cnt.*nanstd(indv_data)./correction_val,plot_info,...
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

% -------------------------------------------------------------------------

% Step 13: Outputs Number of Unique Animals Per Class

for class_split = 1:length(subdiv_index)
% Following Line Is Used to Display Animals In Each Class
unique(merged_sz_parameters(subdiv_index{class_split},1))'
num_in_class = length(unique(merged_sz_parameters(subdiv_index{class_split},1)));
disp(strcat("Class ", num2str(class_split), ": ", num2str(length(subdiv_index{class_split})),...
    " Seizures in ", num2str(num_in_class), " Animals"));
end

end