# Import Libraries

library(R.matlab)
library(ggplot2)
library(hdf5r)

# Change to local folder directory

directory <- "E:/"

# Generate subfolder list

complete_list <- list.dirs(directory,recursive=FALSE) 
real_folder_st <- match(paste(directory,"00000000 DO NOT PROCESS",sep = ""),complete_list)
real_folder_end <- match(paste(directory,"99999999 END",sep = ""),complete_list)
subFolders <- complete_list[real_folder_st + 4:real_folder_end - 3] # But WHY?

# Select One Folder

folder_num <- 37

# Loads MATLAB Data

matlab_data <- H5File$new(paste(subFolders[folder_num],"/Normalized Features.mat",sep = ""))

