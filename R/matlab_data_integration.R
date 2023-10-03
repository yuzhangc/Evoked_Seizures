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

# Extracts Sampling Rate, Feature Names, And Band Power Index

fs = matlab_data[["fs"]][1,1]
feature_names <- names(matlab_data[["norm_features"]])
bp_index = match("Band_Power",feature_names)

# Extracts Features And Puts Into Data Frame

ifelse(is.na(match("Band_Power",feature_names)),total_indices <-
         length(feature_names),total_indices <- length(feature_names) + matlab_data[["bp_filters"]]$dims[1] - 1)
temp_dataframe <- data.frame(matrix(ncol = total_indices, nrow = matlab_data[["sz_parameters"]]$dims[1]))

# Data Frame (Each Channel Has Its Own Data Frame) Structure - Use MATLAB to Export Subset of sz_parameter
# Column 1 Animal Number
# Column 2 Seizure Or Not
# Column 3 Laser Color 1 (Evocation)
# Column 4 Laser Power 1
# Column 5 Laser Color 2 (Treatment)
# Column 6 Laser Power 2
# Column 7 Stim Time (Laser 1)
# Column 8 Delay Between Stim
# Column 9 Stim Time (Laser 2)
# Column 10 Frequency (Laser 2)
# Column 11 Diazepam
# Column 12 Levetiracetam	* Need to Add to Early Trials *
# Column 13 Phenytoin * Need to Add to Early Trials *

# Column 14 - Infinity.
# Features Ordered in Windows

for (index in 1:length(feature_names)){

if index != bp_index{
  
matlab_data[["norm_features"]][[feature_names[index]]]

}
  
}