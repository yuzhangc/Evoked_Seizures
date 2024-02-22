function [svm_values] = spont_svm_characterization(merged_output_array,merged_sz_parameters,directory)

% Use Support Vector Machine to Separate Successful Evocations From Failed
% (Control or Ahem, Random Baseline). Map Spontaneous Seizures Onto Them

% Input Variables
% merged_output_array - merged feature list
% merged_sz_parameters - complete seizure information list

% Loops Through Animals and Extracts Seizures

animal_list = unique(merged_sz_parameters(:,1));

for animal = 1:length(animal_list)

% Successful Evocations Are Seizures (5), Evoked With Blue Light (8), Has
% No Second Stimulus (14), and Has no Drugs (16, 17, 18)

idx_succ_evok = find(merged_sz_parameters(:,1) == animal_list(animal) & merged_sz_parameters(:,5) == 1 & (merged_sz_parameters(:,8) == 473 | merged_sz_parameters(:,8) == 488) ...
    & merged_sz_parameters(:,14) == -1 & merged_sz_parameters(:,16) == 0 & merged_sz_parameters(:,17) == 0 & merged_sz_parameters(:,18) == 0) ;

% Failed Evocations Are Seizures (5), Evoked With Blue Light (8), Has
% No Second Stimulus (14), and Has no Drugs (16, 17, 18)

idx_failed_evok = find(merged_sz_parameters(:,1) == animal_list(animal) & merged_sz_parameters(:,5) == 0 & (merged_sz_parameters(:,8) == 473 | merged_sz_parameters(:,8) == 488) ...
    & merged_sz_parameters(:,14) == -1 & merged_sz_parameters(:,16) == 0 & merged_sz_parameters(:,17) == 0 & merged_sz_parameters(:,18) == 0) ;

% Spontaneous Indices Are Seizures (5), Not Evoked (8)

idx_spont = find(merged_sz_parameters(:,1) == animal_list(animal) & merged_sz_parameters(:,5) == 1 & merged_sz_parameters(:,8) == -1);

% Identify if Null Spontaneous Seizures

if not(isempty(idx_spont))
    
    training_vector_x = [];
    training_vector_y = [];
    testing_vector_x = [];
    
    % Rows - Trials, Columns = Reshaped Variables
    
    % Training Data - Successful vs Failed Evocations
    
    % Successful Evocations
    for trial = 1:length(idx_succ_evok)
        temp_output_array = merged_output_array{idx_succ_evok(trial)};
        temp_output_array = reshape(temp_output_array,[1,size(temp_output_array,1) *size(temp_output_array,2)]);
        training_vector_x(trial,:) = temp_output_array;
        training_vector_y(trial,:) = 1;
    end
    
    % Failed Evocations
    for trial = 1:length(idx_failed_evok)
        temp_output_array = merged_output_array{idx_failed_evok(trial)};
        temp_output_array = reshape(temp_output_array,[1,size(temp_output_array,1) *size(temp_output_array,2)]);
        training_vector_x(trial + length(idx_succ_evok),:) = temp_output_array;
        training_vector_y(trial + length(idx_succ_evok),:) = 0;
    end
    
    % Testing Data - Spontaneous Seizures
    for trial = 1:length(idx_spont)
        temp_output_array = merged_output_array{idx_spont(trial)};
        temp_output_array = reshape(temp_output_array,[1,size(temp_output_array,1) *size(temp_output_array,2)]);
        testing_vector_x(trial,:) = temp_output_array;
    end
    
    % Train SVM Model and Predict With Spontaneous Seizures
    SVMModel = fitcsvm(training_vector_x,training_vector_y);
    [testing_vector_y,score] = predict(SVMModel,testing_vector_x);
    
    % PCA Calculation
    
    total_vector = [training_vector_x; testing_vector_x];
    [coeff,score,latent] = pca(total_vector);
    
    % PCA Colors
    
    % Increases Value By 1 For Testing Colors For Differentiation
    testing_vector_y = testing_vector_y + 2;
    output_values = [training_vector_y ; testing_vector_y];
        
    colors_for_pca = [];
    % 0 & 2 = Failed to Evoke | 1 & 3 = Evoked
    color_list = [255,51,51;
        51,51,255;
        255,128,0;
        76,0,153];
    color_list = color_list./255;
    
    for trial = 1:length(output_values)
        colors_for_pca(trial,:) = color_list(output_values(trial) + 1,:);
    end
    
    % PCA Plot of Data
    
    figure
    scatter(score(:,1),score(:,2),50,colors_for_pca,'filled');
    xlabel('Component 1')
    ylabel('Component 2')
    title(strcat('Animal ', num2str(animal_list(animal))))
    
    
end

end

end