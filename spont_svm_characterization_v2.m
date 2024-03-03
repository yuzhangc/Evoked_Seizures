function [svm_values] = spont_svm_characterization_v2(merged_output_array,merged_sz_parameters)

% Use Support Vector Machine to Separate Successful Evocations From Failed
% (Control or Ahem, Random Baseline). Map Spontaneous Seizures Onto Them

% Input Variables
% merged_output_array - merged feature list
% merged_sz_parameters - complete seizure information list

% Output Variables
% svm_values - Col 1: SVM Prediction, Col 2: Ground Truth for all files

displays_text = ['\nDo you want to do electrographic or behavioral segregation of seizures?', ...
    '\n(1) - Electrographical', ...
    '\n(0) - Behavioral', ...
    '\nEnter a number: '];

electrographic = input(displays_text);

% Loops Through Animals and Extracts Seizures

animal_list = unique(merged_sz_parameters(:,1));
% Epileptic Only animal_list = [100:107,111,112]

% Col 1 - Output , Col 2 - Truth

svm_values = [];

for animal = 1:length(animal_list)

% ------------------------- -----------------------------------------------

% Step 1: Categorize Events
    
if electrographic == 1

% Successful Evocations Are Seizures (5), Evoked With Blue Light (8), Has
% No Second Stimulus (14), and Has no Drugs (16, 17, 18)

idx_succ_evok = find(merged_sz_parameters(:,1) == animal_list(animal) & merged_sz_parameters(:,5) == 1 & (merged_sz_parameters(:,8) == 473 | merged_sz_parameters(:,8) == 488) ...
    & merged_sz_parameters(:,14) == -1 & merged_sz_parameters(:,16) == 0 & merged_sz_parameters(:,17) == 0 & merged_sz_parameters(:,18) == 0) ;

% Failed Evocations Are Seizures (5), Evoked With Blue Light (8), Has
% No Second Stimulus (14), and Has no Drugs (16, 17, 18)

idx_failed_evok = find(merged_sz_parameters(:,1) == animal_list(animal) & merged_sz_parameters(:,5) == 0 & (merged_sz_parameters(:,8) == 473 | merged_sz_parameters(:,8) == 488) ...
    & merged_sz_parameters(:,14) == -1 & merged_sz_parameters(:,16) == 0 & merged_sz_parameters(:,17) == 0 & merged_sz_parameters(:,18) == 0) ;

else

% Change 5 to 21 for Behavioral

idx_succ_evok = find(merged_sz_parameters(:,1) == animal_list(animal) & merged_sz_parameters(:,21) >= 1 & (merged_sz_parameters(:,8) == 473 | merged_sz_parameters(:,8) == 488) ...
    & merged_sz_parameters(:,14) == -1 & merged_sz_parameters(:,16) == 0 & merged_sz_parameters(:,17) == 0 & merged_sz_parameters(:,18) == 0) ;

idx_failed_evok = find(merged_sz_parameters(:,1) == animal_list(animal) & merged_sz_parameters(:,21) == 0 & (merged_sz_parameters(:,8) == 473 | merged_sz_parameters(:,8) == 488) ...
    & merged_sz_parameters(:,14) == -1 & merged_sz_parameters(:,16) == 0 & merged_sz_parameters(:,17) == 0 & merged_sz_parameters(:,18) == 0) ;

end

% Spontaneous Indices Are Seizures (5), Not Evoked (8)

idx_spont = find(merged_sz_parameters(:,1) == animal_list(animal) & merged_sz_parameters(:,5) == 1 & merged_sz_parameters(:,8) == -1);

% Baseline Indices Are Not Seizures (5) Not Evoked (8)

idx_base = find(merged_sz_parameters(:,1) == animal_list(animal) & merged_sz_parameters(:,5) == 0 & merged_sz_parameters(:,8) == -1);

% -------------------------------------------------------------------------

% Step 2: Train Support Vector Machine Between Spontaneous and Baseline

% Identify if Null Spontaneous Seizures

if not(isempty(idx_spont))
    
    training_vector_x = [];
    training_vector_y = [];
    testing_vector_x = [];
    
    % Rows - Trials, Columns = Reshaped Variables
    
    % Training Data - Spontaneous Vs Baseline
    
    % Spontaneous Seizures
    
    for trial = 1:length(idx_spont)
        temp_output_array = merged_output_array{idx_spont(trial)};
        temp_output_array = reshape(temp_output_array,[1,size(temp_output_array,1) *size(temp_output_array,2)]);
        training_vector_x(trial,:) = temp_output_array;
        training_vector_y(trial,:) = 1;
    end
    
    % Baseline
    
    for trial = 1:length(idx_base)
        temp_output_array = merged_output_array{idx_base(trial)};
        temp_output_array = reshape(temp_output_array,[1,size(temp_output_array,1) *size(temp_output_array,2)]);
        training_vector_x(trial + length(idx_spont),:) = temp_output_array;
        training_vector_y(trial + length(idx_spont),:) = 0;
    end
    
    % Testing Data Part 1 - Evoked Seizures
    
    for trial = 1:length(idx_succ_evok)
        temp_output_array = merged_output_array{idx_succ_evok(trial)};
        temp_output_array = reshape(temp_output_array,[1,size(temp_output_array,1) *size(temp_output_array,2)]);
        testing_vector_x(trial,:) = temp_output_array;
    end
    
    % Testing Data Part 2 - Failed Seizures
    
    for trial = 1:length(idx_failed_evok)
        temp_output_array = merged_output_array{idx_failed_evok(trial)};
        temp_output_array = reshape(temp_output_array,[1,size(temp_output_array,1) *size(temp_output_array,2)]);
        testing_vector_x(trial + length(idx_succ_evok),:) = temp_output_array;
    end
    
    % Train SVM Model and Predict With Evoked Seizures
    
    SVMModel = fitcsvm(training_vector_x,training_vector_y);
    
    % ---------------------------------------------------------------------
    
    % Step 3: Test With Evoked Seizures and PCA Plot
    
    [testing_vector_y,score] = predict(SVMModel,testing_vector_x);
    
    % PCA Calculation
    
    total_vector = [training_vector_x; testing_vector_x];
    [coeff,score,latent] = pca(total_vector);
    
    % Increases Value By 1 For Testing Colors For Differentiation
    
    testing_vector_y = testing_vector_y + 2;
    output_values = [training_vector_y ; testing_vector_y];
    true_output_values = [training_vector_y; 3 * ones(length(idx_succ_evok),1);...
        2 * ones(length(idx_failed_evok),1);];

    svm_values = [svm_values;output_values, true_output_values];
    
    % PCA Colors
    
    % 0 - Baseline - Dark Green
    % 1 - Spontaneous - Purple
    % 2 - Failed to Evoke - Gray
    % 3 - Successfully Evoked - Dark Orange
    
    colors_for_pca = [];
    true_colors_for_pca = [];
    
    color_list = [0, 102, 51;
        102, 0, 102;
        96, 96, 96;
        255, 128, 0];
    color_list = color_list./255;
    
    % Assigns Colors Based on Predicted and True Values
    
    for trial = 1:length(output_values)
        colors_for_pca(trial,:) = color_list(output_values(trial) + 1,:);
        true_colors_for_pca(trial,:) = color_list(true_output_values(trial) + 1,:);
    end
    
    % PCA Plot of Data
    
    figure
    hold on
    
    % Plots Each Dot
    for cnt = 1:size(score,1)
    scatter(score(cnt,1), score(cnt,2), 25, 'MarkerFaceColor', colors_for_pca(cnt,:),...
        'MarkerEdgeColor', true_colors_for_pca(cnt,:), 'LineWidth', 1);
    end

    idx_evk = find(true_output_values == 3);
    idx_failed = find(true_output_values == 2);

    % True Positive
    evk_accuracy = sum(output_values(idx_evk,:) == true_output_values(idx_evk,:)) / length(idx_evk) * 100;
    
    % True Negative
    failed_accuracy = sum(output_values(idx_failed,:) == true_output_values(idx_failed,:)) / length(idx_failed) * 100;
    
    % Type I and Type II Errors
    false_positive = sum(output_values(idx_failed,:) == 3) / length(idx_failed) * 100;
    false_negative = sum(output_values(idx_evk,:) == 2) / length(idx_evk) * 100; 
    
    hold off
    xlabel('Principal Component 1')
    ylabel('Principal Component 2')
    title(strcat("Animal ", num2str(animal_list(animal)), " | True Positive: " , ...
        num2str(evk_accuracy), " | True Negative: " , num2str(failed_accuracy) , ...
        " | False Positive: ", num2str(false_positive), " | False Negative: ",...
        num2str(false_negative)));  
    
end

end

end