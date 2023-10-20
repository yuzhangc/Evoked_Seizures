function calculate_seizure_corr_evoked(min_thresh_list,seizure_duration_list, directory, feature_list)

% Calculates Correlation of Evocations Above Threshold in Feature Space

% Input Variables
% min_thresh_list - Contains item seizures, which is list of evocation above
% threshold, evoked or not.
% seizure_duration_list - list of seizure durations, calculated by model.
% directory - Master directory
% feature_list - List of features

% -------------------------------------------------------------------------

% Step 0: Access Directory, Determine General Parameters

% Reads Animal Information

animal_info = readmatrix(strcat(directory,'Animal Master.csv'));

% Generates Subfolders

complete_list = dir(directory); dirFlags = [complete_list.isdir]; subFolders = complete_list(dirFlags);
real_folder_st = find(ismember({subFolders.name},'00000000 DO NOT PROCESS')); real_folder_end = find(ismember({subFolders.name},'99999999 END'));
subFolders = subFolders(real_folder_st + 1:real_folder_end - 1);

% Identify Exclusion Criteria

displays_text_1 = '\nType in Animal Number Below Which To Exclude (e.g. 12 = 2022/11/07, 22 = 2023/01/16): ';

an_excl = input(displays_text_1);

displays_text_2 = ['\nDo you want to include naive data?', ...
    '\n(1) - Yes', ...
    '\n(0) - No', ...
    '\nEnter a number: '];

naive_ep = input(displays_text_2);

displays_text_3 = '\nHow many seconds is considered a failed/non-evoked event? Type in a number (e.g. 10): ';

short_duration = input(displays_text_3);

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
    
    temp_sz_duration = seizure_duration_list{an};
    temp_thresh_list = min_thresh_list(an).seizures;
    
    for sz = 1:length(temp_thresh_list)
        
        % Exclude If Second Stim. Drugs Should Have Been Excluded Already
        if sz_parameters(temp_thresh_list(sz),10) ~= -1
        else
            
            % Treat As Failed If Under Short Duration
            if seizure_duration_list{an}(temp_thresh_list(sz)) < short_duration
                
                if size(all_failed,1) == 0
                all_failed = [an, temp_thresh_list(sz)];
                else
                all_failed(end+1,:) = [an, temp_thresh_list(sz)];
                end
                
            % Otherwise Include Into Successfully Evoked
            else
                
                if size(all_successful,1) == 0
                all_successful = [an, temp_thresh_list(sz)];
                else
                all_successful(end+1,:) = [an, temp_thresh_list(sz)];
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

for pair1 = 1:length(successful_animals)
    
    % Extracts Successful Seizures
    
    within_successful_seizures = all_successful(all_successful(:,1) == successful_animals(pair1),:);
    
    % Makes Successful Seizures Pairs
    
    temp_within_success = [];
    
    for sz1 = 1:size(within_successful_seizures,1)
        for sz2 = sz1+1:size(within_successful_seizures,1)
            
            temp_within_success = [temp_within_success;within_successful_seizures(sz1,:),within_successful_seizures(sz2,:)];
            
        end
    end
    
    within_success{pair1} = temp_within_success;
    
    % Makes Outside Successful Seizure Pairs
    
    outside_successful_seizures = all_successful(all_successful(:,1) ~= successful_animals(pair1),:);
    
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
            
            temp_with_failed = [temp_with_failed;within_successful_seizures(sz1,:),all_failed(sz2,:)];
            
        end
    end
    
    with_failed{pair1} = temp_with_failed;

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
load(strcat(path_extract,"Normalized Features.mat"))

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

% Extract Features From Seizure Numbers

sz_in_an = [all_successful(all_successful(:,1) == total_unique_an(an),2); all_failed(all_failed(:,1) == total_unique_an(an),2)];

% Loops Through Seizures

temp_sz_array = {};

for sz = 1:size(sz_in_an,1)
    
    temp_ft_array = {};

    for feature_number = 1:length(feature_list)

        temp_ft_array{feature_list(feature_number)} = norm_features.(feature_names{feature_list(feature_number)});

    end

    temp_sz_array {sz_in_an(sz)} = temp_ft_array;

end

master_an_array{total_unique_an(an)} = temp_sz_array;

end

end

% -------------------------------------------------------------------------

% Step 3: Calculate Cross Correlation For Selected Features

end