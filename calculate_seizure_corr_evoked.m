function [ch_all_feat] = calculate_seizure_corr_evoked(min_thresh_list,seizure_duration_list, directory, feature_list)

% Calculates Correlation of Evocations Above Threshold in Feature Space

% Input Variables
% min_thresh_list - Contains item seizures, which is list of evocation above
% threshold, evoked or not.
% seizure_duration_list - list of seizure durations, calculated by model.
% directory - Master directory
% feature_list - List of features

% Output Variables
% ch_all_feat - contains groupings of all calculated correlation values by feature

% -------------------------------------------------------------------------

% Step 0: Access Directory, Determine General Parameters

% Reads Animal Information

animal_info = readmatrix(strcat(directory,'Animal Master.csv'));

% Generates Subfolders

complete_list = dir(directory); dirFlags = [complete_list.isdir]; subFolders = complete_list(dirFlags);
real_folder_st = find(ismember({subFolders.name},'00000000 DO NOT PROCESS')); real_folder_end = find(ismember({subFolders.name},'99999999 END'));
subFolders = subFolders(real_folder_st + 1:real_folder_end - 1);

% Identify Main Question

main_division = ['\nWhich analysis to run?',...
    '\n(1) - Between Animal Analysis',...
    '\n(2) - Between Duration Analysis',...
    '\nEnter a number: '];

main_div = input(main_division);

% Identify Exclusion Criteria

displays_text_1 = '\nType in Animal Number Below Which To Exclude (e.g. 12 = 2022/11/07, 22 = 2023/01/16): ';

an_excl = input(displays_text_1);

displays_text_2 = ['\nDo you want to include naive data?', ...
    '\n(1) - Yes', ...
    '\n(0) - No', ...
    '\nEnter a number: '];

naive_ep = input(displays_text_2);

% Identify Threshold for 'Failed' Evocation

displays_text_3 = '\nHow many seconds is considered a failed/non-evoked event? Type in a number (e.g. 10): ';

short_duration = input(displays_text_3);

% Define Boundaries of Seizures Duration if Main Division is #2

if main_div == 2

displays_text_5 = '\nType in minimum duration to include (in secs): ';
min_incl = input(displays_text_5);

displays_text_6 = '\nType in maximum duration to include (in secs): ';
max_incl = input(displays_text_6);

else

min_incl = short_duration;
max_incl = 6000;

end

% Plot Individual Plots For Each Animal

displays_text_4 = ['\nDo You Want to Plot Individual Data?',...
    '\n(1) - Yes', ...
    '\n(0) - No', ...
    '\nEnter a number: '];

indv_plot = input(displays_text_4);

% -------------------------------------------------------------------------

% Step 1: Determine Success/Failure Evocation

% Sets Up Blank Arrays. Column 1 is Animal. Column 2 is Trial.

all_successful = [];
all_failed = [];

% Begin Loop at First Animal to NOT Exclude. Progress to End

for an = an_excl:size(min_thresh_list,2)
    
    % Do Naive Only If Include Naive
    if naive_ep && animal_info(an,5) == 0
        extract_info = 1;
    % Otherwise Do Epileptic Only
    elseif animal_info(an,5) == 1
        extract_info = 1;
    else
        extract_info = 0;
    end
    
    if extract_info
       
    % Extracts Trial Data, Seizure Duration, Above Threshold Seizures
    path_extract = strcat(directory,subFolders(an).name,'\');
    sz_parameters = readmatrix(strcat(path_extract,'Trials Spreadsheet.csv'));
    
    temp_thresh_list = min_thresh_list(an).seizures;
    
    for sz = 1:length(temp_thresh_list)
        
        % Exclude If Second Stim. Drugs Should Have Been Excluded Already
        if sz_parameters(temp_thresh_list(sz),10) ~= -1
        else
            
            % Treat As Failed If Under Short Duration
            if seizure_duration_list{an}(temp_thresh_list(sz)) < short_duration
                
                if size(all_failed,1) == 0
                all_failed = [an, temp_thresh_list(sz),seizure_duration_list{an}(temp_thresh_list(sz))];
                else
                all_failed(end+1,:) = [an, temp_thresh_list(sz),seizure_duration_list{an}(temp_thresh_list(sz))];
                end
                
            % Otherwise Include Into Successfully Evoked
            else
                
                if size(all_successful,1) == 0
                all_successful = [an, temp_thresh_list(sz),seizure_duration_list{an}(temp_thresh_list(sz))];
                else
                all_successful(end+1,:) = [an, temp_thresh_list(sz),seizure_duration_list{an}(temp_thresh_list(sz))];
                end
                
            end
            
        end
    end
        
    end
    
end

% -------------------------------------------------------------------------

% Step 2: Generate Seizure Pairs

% Find Unique Animals in Successful and Failed

successful_animals = unique(all_successful(:,1));
failed_animals = unique(all_failed(:,1));

if main_div == 1

for pair1 = 1:length(successful_animals)
    
    % Extracts Successful Seizures
    
    within_successful_seizures = all_successful(all_successful(:,1) == successful_animals(pair1),1:2);
    
    % Makes Successful Seizures Pairs
    
    temp_within_success = [];
    
    for sz1 = 1:size(within_successful_seizures,1)
        for sz2 = sz1+1:size(within_successful_seizures,1)
            
            temp_within_success = [temp_within_success;within_successful_seizures(sz1,:),within_successful_seizures(sz2,:)];
            
        end
    end
    
    within_success{pair1} = temp_within_success;
    
    % Makes Outside Successful Seizure Pairs
    
    outside_successful_seizures = all_successful(all_successful(:,1) ~= successful_animals(pair1),1:2);
    
    temp_with_outside = [];
    
    for sz1 = 1:size(within_successful_seizures,1)
        for sz2 = 1:size(outside_successful_seizures,1)
            
            temp_with_outside = [temp_with_outside;within_successful_seizures(sz1,:),outside_successful_seizures(sz2,:)];
            
        end
    end
    
    with_outside{pair1} = temp_with_outside;
    
    % Make Pairs With Failed
    
    temp_with_failed = [];

    for sz1 = 1:size(within_successful_seizures,1)
        for sz2 = 1:size(all_failed,1)
            
            temp_with_failed = [temp_with_failed;within_successful_seizures(sz1,:),all_failed(sz2,1:2)];
            
        end
    end
    
    with_failed{pair1} = temp_with_failed;

end

elseif main_div == 2

% Determine Seizures Within Duration

target_duration_seizures = all_successful(all_successful(:,3) >= min_incl & all_successful(:,3) <= max_incl,1:2);
not_target_duration_seizures = all_successful(all_successful(:,3) < min_incl | all_successful(:,3) > max_incl,1:2);

temp_within_success = [];
temp_with_outside = [];
temp_with_failed = [];

for sz1 = 1:size(target_duration_seizures,1)

    % Within Success

    for sz2 = 1:size(target_duration_seizures,1)

        % Eliminates Identical Pairings
        if sz1 ~= sz2
        temp_within_success = [temp_within_success;target_duration_seizures(sz1,:),target_duration_seizures(sz2,:)];
        end

    end

    % With Outside Duration Window

    for sz2 = 1:size(not_target_duration_seizures,1)
        temp_with_outside = [temp_with_outside;target_duration_seizures(sz1,:),not_target_duration_seizures(sz2,:)];
    end

    % With Failed
    for sz2 = 1:size(all_failed,1)
        temp_with_failed = [temp_with_failed;target_duration_seizures(sz1,:),all_failed(sz2,1:2)];
    end


end

% Moves to Animals

for pair1 = 1:length(successful_animals)

    within_success{pair1} = temp_within_success(temp_within_success(:,1) == successful_animals(pair1),:);
    with_outside{pair1} = temp_with_outside(temp_with_outside(:,1) == successful_animals(pair1),:);
    with_failed{pair1} = temp_with_failed(temp_with_failed(:,1) == successful_animals(pair1),:);

end

end

% -------------------------------------------------------------------------

% Step 2: Access Directory And Extract Normalized Features

displays_text_2 = "Do you want to do all animals (0) or a specific animal (input number): ";
all_or_none = input(displays_text_2);

% Determines Animals To Process

if all_or_none == 0
    processed_animals = successful_animals;
    fprintf("All Animals Chosen\n")
elseif ismember(all_or_none, successful_animals)
    processed_animals = all_or_none;
    fprintf(strcat("Animal ", num2str(processed_animals), " Chosen\n"))
else
    processed_animals = [];
    fprintf("Not a Valid Choice\n")
end

% Determine Channels

displays_text_2 = "Do you want to do all channels (0) or specific channels (input number): ";
channels_list = input(displays_text_2);

if channels_list == 0
    channels_list = 1:4;
end

% Loops Through All Animals to Extract Feature Data
% Generates Feature Cell Array That is ANIMAL, SEIZURE, FEATURE
% Has Lot of Blank Cells For Excluded Animals And Other Seizures.

if size(processed_animals,1) > 0

% Determine Total Number of Unique Animals For Failed AND Successful Evocation        
total_unique_an = union(successful_animals,failed_animals);

% Final Output Array
master_an_array = {};

% Loop Through Animals
for an = 1:length(total_unique_an)
    
path_extract = strcat(directory,subFolders(total_unique_an(an)).name,'\');

% Loads Filtered Seizure Data and Features
% load(strcat(path_extract,"Filtered Seizure Data.mat"))
load(strcat(path_extract,"Normalized Features.mat"))

feature_names = fieldnames(norm_features);

% IO for Features

bp_cnter = 1; % Keeps Track of Band Power Pairing

if isempty(feature_list)

for feature_number = 1:length(feature_names)
    displays_text = strcat("\nDo You Want to Output Feature ",strrep(feature_names(feature_number),"_"," "),"?",...
        "\n(1) Yes (0) No: ");
    yesorno = input(displays_text);

    if yesorno && feature_names(feature_number) == "Band_Power"
        for bp = 1:size(bp_filters,1)
        feature_list = [feature_list,feature_number];
        end
        bp_cnter = 1;
    elseif yesorno
        feature_list = [feature_list,feature_number];
    end

end

end

% Extract Features From Seizure Numbers

sz_in_an = [all_successful(all_successful(:,1) == total_unique_an(an),2); all_failed(all_failed(:,1) == total_unique_an(an),2)];

% Loops Through Seizures, Putting Features into Cell Arrays

temp_sz_array = {};

for sz = 1:size(sz_in_an,1)
   
    temp_ft_array = {};

    for feature_number = 1:length(feature_list)

        % Special Case For Band Power
        if (isequal(feature_names{feature_list(feature_number)},'Band_Power'))
            temp_ft_array{feature_number} = norm_features.(feature_names{feature_list(feature_number)}){bp_cnter}{sz_in_an(sz)};
            if bp_cnter == size(bp_filters,1)
            bp_cnter = 1;
            else
            bp_cnter = bp_cnter + 1;
            end
        else
        temp_ft_array{feature_number} = norm_features.(feature_names{feature_list(feature_number)}){sz_in_an(sz)};
        end

    end

    temp_sz_array {sz_in_an(sz)} = temp_ft_array;
    % temp_filtered_array {sz_in_an(sz)} = output_data{sz_in_an(sz)};

end

master_an_array{total_unique_an(an)} = temp_sz_array;
% master_filtered_array{total_unique_an(an)} = temp_filtered_array;

end

end

% -------------------------------------------------------------------------

% Step 3: Calculate Cross Correlation For Selected Features

for ch = 1:length(channels_list)
    
disp(strcat("Working on Channel ", num2str(channels_list(ch))));
    
% Specific to Channel
ch_all_feat = cell(1,length(feature_list));

for an = 1:length(processed_animals)
    
% Specific To Animal
    
an_all_feat = {};
an_all_feat_lag = {};
    
% Calculates Per Feature For Each Animal

within_seizure_list = within_success{find(processed_animals(an) == successful_animals)};
with_other_seizure_list = with_outside{find(processed_animals(an) == successful_animals)};
with_failed_seizure_list = with_failed{find(processed_animals(an) == successful_animals)};

for feature_number = 1:length(feature_list)
    
    % Specific to Feature
    
    within_feat = []; within_feat_lag = [];
    with_other_feat = []; with_other_feat_lag = [];
    with_failed_feat = []; with_failed_feat_lag = [];
    
    % Loops Through Lists
    
    % Within
    
    for sz_pair = 1:size(within_seizure_list,1)
  
    [c,lags] = xcorr(master_an_array{within_seizure_list(sz_pair,1)}{within_seizure_list(sz_pair,2)}{feature_number}(:,channels_list(ch)),...
        master_an_array{within_seizure_list(sz_pair,3)}{within_seizure_list(sz_pair,4)}{feature_number}(:,channels_list(ch)),20);
    within_feat = [within_feat; max(c)];
    within_feat_lag = [within_feat_lag ; lags(find(max(c) == c))];
            
    end
    
    % With Others
    
    for sz_pair = 1:size(with_other_seizure_list,1)
    
    [c,lags] = xcorr(master_an_array{with_other_seizure_list(sz_pair,1)}{with_other_seizure_list(sz_pair,2)}{feature_number}(:,channels_list(ch)),...
        master_an_array{with_other_seizure_list(sz_pair,3)}{with_other_seizure_list(sz_pair,4)}{feature_number}(:,channels_list(ch)),20);
    with_other_feat = [with_other_feat; max(c)];
    with_other_feat_lag = [with_other_feat_lag ; lags(find(max(c) == c))];
        
    end
    
    % With Failed
    
    for sz_pair = 1:size(with_failed_seizure_list,1)
    
    [c,lags] = xcorr(master_an_array{with_failed_seizure_list(sz_pair,1)}{with_failed_seizure_list(sz_pair,2)}{feature_number}(:,channels_list(ch)),...
        master_an_array{with_failed_seizure_list(sz_pair,3)}{with_failed_seizure_list(sz_pair,4)}{feature_number}(:,channels_list(ch)),20);
    with_failed_feat = [with_failed_feat; max(c)];
    with_failed_feat_lag = [with_failed_feat_lag ; lags(find(max(c) == c))];
    
    end
    
    % Collate into Anova Capable Test

    max_size = max([length(within_feat),length(with_other_feat),length(with_failed_feat)]);
    
    an_feat = NaN(max_size,3);
    an_feat(1:length(within_feat),1) = within_feat;
    an_feat(1:length(with_other_feat),2) = with_other_feat;
    an_feat(1:length(with_failed_feat),3) = with_failed_feat;
    
    an_all_feat{feature_number} = an_feat;

    % Individual Plots
    
    if indv_plot
    
    anova1(an_all_feat{feature_number})
    xticks(1:3);
    xtickoptions = {'Vs Same Animal Evoked','Vs Other Animals Evoked','Vs Failed'};
    xticklabels(xtickoptions);
    xtickangle(45);
    if feature_names{feature_list(feature_number)} == "Band_Power"
    title(strcat("Animal ", num2str(processed_animals(an))," ", strrep(feature_names{feature_list(feature_number)},"_"," "),...
        " ", num2str(bp_filters(bp_cnter,1)), " Hz to ", num2str(bp_filters(bp_cnter,2))," Hz"));
    if bp_cnter == size(bp_filters,1)
    bp_cnter = 1;
    else
    bp_cnter = bp_cnter + 1;
    end
    else
    title(strcat("Animal ", num2str(processed_animals(an))," ", strrep(feature_names{feature_list(feature_number)},"_"," ")));
    end
        
    end

    % Collates Lags
    
    an_feat = NaN(max_size,3);
    an_feat(1:length(within_feat),1) = within_feat_lag;
    an_feat(1:length(with_other_feat),2) = with_other_feat_lag;
    an_feat(1:length(with_failed_feat),3) = with_failed_feat_lag;
    
    an_all_feat_lag{feature_number} = an_feat;

end

% -------------------------------------------------------------------------

% Step 4: Output Plots

% Loops To Transfer Features to Channels

for feature_number = 1:length(feature_list)
    
    if isempty(ch_all_feat{feature_number})
    ch_all_feat{feature_number} = [an_all_feat{feature_number}];
    else
    ch_all_feat{feature_number} = [ch_all_feat{feature_number};an_all_feat{feature_number}];
    end
    
end

end

% Compiled Anova of All Animals Per Channel (Only if Individual Plot Not
% Done Yet)

if indv_plot && size(processed_animals,1) == 1
   
else

for feature_number = 1:length(feature_list)
    
    a = anova1(ch_all_feat{feature_number});
    xticks(1:3);
    xtickoptions = {'Vs Same Evoked Category','Vs Other Evoked Seizures','Vs Failed Evocations'};
    xticklabels(xtickoptions);
    xtickangle(45);
    if feature_names{feature_list(feature_number)} == "Band_Power"
    title(strcat("All Animals Channel ", num2str(channels_list(ch))," ",strrep(feature_names{feature_list(feature_number)},"_"," "),...
        " ", num2str(bp_filters(bp_cnter,1)), " Hz to ", num2str(bp_filters(bp_cnter,2))," Hz"));
    if bp_cnter == size(bp_filters,1)
    bp_cnter = 1;
    else
    bp_cnter = bp_cnter + 1;
    end
    else
    title(strcat("All Animals Channel ", num2str(channels_list(ch))," ", strrep(feature_names{feature_list(feature_number)},"_"," ")));
    end
end

end

end

end