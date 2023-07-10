function [anova_results] = categorization_plot_func(merged_output_array,merged_sz_parameters,seizure_duration_list,animal_info)

% Use Integrated Feature Information Across All Channels, Then Separates Them
% According to User Input and Categorization.

% Input Variables
% merged_output_array - merged feature list
% merged_sz_parameters - complete seizure information list
% seizure_duration_list - list of seizure duration, organized by folder
% animal_info - structure with information about animals

% Output Variables
% anova_results - using anova_col_val to guide ANOVA calculations

% -------------------------------------------------------------------------

% Step 1: Receive User Input
% Generates 4 variables
% 1) main_division - main plot
% 2) ind_data - plot individual dots or not
% 3) naive_ep - splits naive or epileptic
% 4) excl_short - exclude <15 sec events
% 5) excl_addl - exclude additional stimulation trials
% 6) no_to_early - exclude early recordings

displays_text = ['Which Plot to Plot?:', ...
    '\n(1) - Epileptic Vs Naive Animals', ...
    '\n(2) - Long Vs Short Seizures', ...
    '\n(3) - Successfully Evocations Vs Failed Evocations', ...
    '\n(4) - Additional Stimulation or Not'
    '\nEnter a number: '];

main_division = input(displays_text);

displays_text_2 = ['\n Do you want to plot individual data?', ...
    '\n(1) - Yes', ...
    '\n(0) - No', ...
    '\nEnter a number: '];

ind_data = input(displays_text_2);

if main_division ~= 1

displays_text_3 = ['\n Do you want to split naive and epileptic data?', ...
    '\n(1) - Yes', ...
    '\n(0) - No', ...
    '\nEnter a number: '];

naive_ep = input(displays_text_3);

else
    
naive_ep = 1;

end

displays_text_4 = ['\n Do you want to exclude short events (less than 15 seconds)?', ...
    '\n(1) - Yes', ...
    '\n(0) - No', ...
    '\nEnter a number: '];

excl_short = input(displays_text_4);

displays_text_5 = ['\n Do you want to exclude events with additional stimulation?', ...
    '\n(1) - Yes', ...
    '\n(0) - No', ...
    '\nEnter a number: '];

excl_addl = input(displays_text_5);

displays_text_6 = ['\n Do you want to include early (before 01/2023) recordings?', ...
    '\n(1) - Yes', ...
    '\n(0) - No', ...
    '\nEnter a number: '];

no_to_early = input(displays_text_6);

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
        
        mean_sz_dur = mean(merged_sz_duration(merged_sz_duration > 5));
        
        % Final Output - 1 is Less Than Mean, 2 is Greater Or Equal to Mean
        subdiv_index{1} = find(merged_sz_duration < mean_sz_dur);
        subdiv_index{2} = find(merged_sz_duration >= mean_sz_dur);
        anova_col_val = merged_sz_duration >= mean_sz_dur;
        
    case 3 % Successfully Evocations Vs Failed Evocations
        
        subdiv_index{1} = find(merged_sz_parameters(:,5) == 1);
        subdiv_index{2} = find(merged_sz_parameters(:,5) == 0);
        anova_col_val = merged_sz_parameters(:,5);
        
    case 4 % Additional Stimulation or Not
        
        excl_addl = 0;
        
    % INCOMPLETE
        
end

% -------------------------------------------------------------------------

% Step 4: Refine Indices Based on Epileptic Or Naive

if naive_ep
    
    if main_division == 1
    else
        
        ep = animal_info(find(animal_info(:,5) == 1),1);
        naive = animal_info(find(animal_info(:,5) == 0),1);
        
    end
end

% -------------------------------------------------------------------------

% Step 5: Shorten Indices Based on Seizure Duration

if excl_short 
end

% -------------------------------------------------------------------------

% Step 6: Exclude Indices With Additional Stimulation

if excl_addl
end

% -------------------------------------------------------------------------

% Step 7: Exclude Early Recordings (All < Animal 20)

if no_to_early
end

end