# Import Libraries

library(ggplot2)
library(hdf5r)

# Change to local folder directory

directory <- "E:/"

# Generate subfolder list

complete_list <- list.dirs(directory,recursive=FALSE) 
real_folder_st <- match(paste(directory,"00000000 DO NOT PROCESS",sep = ""),complete_list)
real_folder_end <- match(paste(directory,"99999999 END",sep = ""),complete_list)
subFolders <- complete_list[(real_folder_st + 1):(real_folder_end - 1)]

# Select One Folder

folder_num <- 37

# Loads MATLAB Data

matlab_data <- H5File$new(paste(subFolders[folder_num],"/Normalized Features.mat",sep = ""))

fs = matlab_data[["fs"]][1,1]

feature_names <- names(matlab_data[["norm_features"]])

bp_index = match("Band_Power",feature_names)