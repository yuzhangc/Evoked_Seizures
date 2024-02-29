# Import MATLAB file

import scipy.io
import numpy as np
import pandas as pd

directory = 'C:/Users/chenj/Box Sync/Graphene Project/Lab Meetings/Evoked Seizure Analysis/Evoked_Seizures/'

mat = scipy.io.loadmat(directory + 'Merged_SVM_Parameters.mat')

merged_sz_parameters = mat['svm_merged_sz_parameters']
merged_output_array = mat['svm_merged_output_array']

# Identifies Unique Animals

animal_list = np.unique(merged_sz_parameters[:,0]);

for animal in animal_list:
    
    # Identify Successful Evocations
    
    idx_succ_evok = np.where(np.all([merged_sz_parameters[:,0] == animal, merged_sz_parameters[:,4] == 1, \
                             np.any([merged_sz_parameters[:,7] == 473, merged_sz_parameters[:,7] == 488], axis = 0), \
                             merged_sz_parameters[:,13] == -1, merged_sz_parameters[:,15] == 0, \
                             merged_sz_parameters[:,16] == 0,  merged_sz_parameters[:,17] == 0], \
                             axis = 0))
    
    # Identify Failed Evocations
    
    idx_failed_evok = np.where(np.all([merged_sz_parameters[:,0] == animal, merged_sz_parameters[:,4] == 0, \
                             np.any([merged_sz_parameters[:,7] == 473, merged_sz_parameters[:,7] == 488], axis = 0), \
                             merged_sz_parameters[:,13] == -1, merged_sz_parameters[:,15] == 0, \
                             merged_sz_parameters[:,16] == 0,  merged_sz_parameters[:,17] == 0], \
                                 axis = 0))
    
    print(len(idx_succ_evok[0]))
    print(len(idx_failed_evok[0]))
    
    
    # Identify Spontaneous Seizures

    idx_spont = np.where(np.all([merged_sz_parameters[:,0] == animal, merged_sz_parameters[:,4] == 1, \
                                merged_sz_parameters[:,7] == -1], axis = 0))

    # Identify Baseline Snippets

    idx_base = np.where(np.all([merged_sz_parameters[:,0] == animal, merged_sz_parameters[:,4] == 0, \
                                merged_sz_parameters[:,7] == -1], axis = 0))
        
    print(len(idx_spont[0]))
    print(len(idx_base[0]))
    
    # Identify if Null Spontaneous Seizures

    if len(idx_spont[0]) != 0:
    
        training_vector_x = [];
        training_vector_y = [];
        testing_vector_x = [];
        
        for trial in range(len(idx_spont[0])):
            temp_output_array = merged_output_array[0][idx_spont[0][trial]];
            temp_output_array = reshape(temp_output_array,[1,size(temp_output_array,1) *size(temp_output_array,2)]);
            training_vector_x(trial,:) = temp_output_array;
            training_vector_y(trial,:) = 1;

        