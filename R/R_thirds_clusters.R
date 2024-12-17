# Step 1: Import Libraries (Copied from Matlab Data Integration)

library(dplyr)
library(tidyverse)

# Change to local folder directory

directory <- "D:/"

# Freely Moving or Head Fixed

freely_moving <- 1

# Critical Variables For Filtering

# Minimum and Maximum Day For Processing, Inclusive. Set - 90 and + 90 to include all - spont vs evoked.
# Set 1 - 4 for Early Naive/Epileptic and 5 and 90 for Late Naive/Epileptic Comparisons

min_day <- -90
max_day <- 90

# Minimum Racine Scale. Enter 0 for All (Naive/Epileptic). Use 3 for Spont vs Evoked.

min_rac <- 3

# Generate subfolder list

complete_list <- list.dirs(directory,recursive=FALSE) 

if (freely_moving) {
  real_folder_st <- match(paste(directory,"99999999 END",sep = ""),complete_list)
  real_folder_end <- match(paste(directory,"EEG_END",sep = ""),complete_list)
} else {
  real_folder_st <- match(paste(directory,"00000000 DO NOT PROCESS",sep = ""),complete_list)
  real_folder_end <- match(paste(directory,"99999999 END",sep = ""),complete_list)
}

subFolders <- complete_list[(real_folder_st + 1):(real_folder_end - 1)]

# ---------------------------------------------------------------------------------------------------

# Step 2: Extract & Concactenate Data From All Channels in Each Folder

all_animal <- data.frame()

for (folder_num in seq(1:length(subFolders))) {
  
  # List of Files
  csv_file_list <- list.files(path = subFolders[folder_num], pattern = "Extracted_Features_Channel_V2_2StimREMOVED",
                              full.names = FALSE, ignore.case = FALSE)
  
  all_channel <- data.frame()
  
  for (channel in seq(1:length(csv_file_list))){
  
  # Reads CSV into Dataframe
  
  feature_data <- read.csv(paste(subFolders[folder_num],csv_file_list[channel],sep="/"))
  
  # Converts Certain Variables Into Right Types
  
  feature_data$Successful.Evocation <- as.logical(feature_data$Successful.Evocation)
  feature_data$Epileptic <- as.logical(feature_data$Epileptic)
  
  # Changes factor order so that FALSE is the first level - and what we compare to.
  
  feature_data$Epileptic <- factor(feature_data$Epileptic, levels = c(FALSE, TRUE))
  
  feature_data$Diazepam <- as.logical(feature_data$Diazepam)
  feature_data$Levetiracetam <- as.logical(feature_data$Levetiracetam)
  feature_data$Phenytoin <- as.logical(feature_data$Phenytoin)
  
  # Make Time Point A Factor. All Other Factorization Will Happen Post-Op
  
  feature_data$Time.Point <- factor(feature_data$Time.Point, levels = c("Before Stimulation", "During Stimulation",
                                                                        "Seizure - First Third", "Seizure - Second Third", "Seizure - Final Third", "Post Seizure"))
  
  # Fixes Gender Imported As 'False'
  
  if (any(feature_data$Gender == 'FALSE')) feature_data$Gender[which(feature_data$Gender == 'FALSE')] <- 'F'
  
  # Replace -1 With NA
  
  feature_data$Laser.2...Color[which(feature_data$Laser.2...Color == -1)] <- NA
  feature_data$Laser.2...Power[which(feature_data$Laser.2...Power == -1)] <- NA
  feature_data$Laser.2...Duration[which(feature_data$Laser.1...Duration == -1)] <- NA
  feature_data$Laser.2...Frequency[which(feature_data$Laser.2...Frequency == -1)] <- NA
  feature_data$Delay[which(feature_data$Delay == -1)] <- NA
  feature_data$Laser.1...Color[which(feature_data$Laser.1...Color == -1)] <- NA
  
  # Remove During Stimulation Segments
  
  feature_data <- feature_data[which(feature_data$Time.Point != "During Stimulation"),]
  
  # Concactenate All Time.Points into 1 Row, Returning Classification to Seizures Instead of "Time.Point"
  
  feature_data_1 <- feature_data[which(feature_data$Time.Point == "Before Stimulation"),]
  feature_data_1 <- feature_data_1[,-which(names(feature_data_1) %in% c("Time.Point"))]
  feature_data_2 <- feature_data[which(feature_data$Time.Point == "Seizure - First Third"),c(19,23:ncol(feature_data))]
  feature_data_3 <- feature_data[which(feature_data$Time.Point == "Seizure - Second Third"),c(19,23:ncol(feature_data))]
  feature_data_4 <- feature_data[which(feature_data$Time.Point == "Seizure - Final Third"),c(19,23:ncol(feature_data))]
  feature_data_5 <- feature_data[which(feature_data$Time.Point == "Post Seizure"),c(19,23:ncol(feature_data))]

  # Merge Dataframes Together
  
  full_list <- list(feature_data_1,feature_data_2,feature_data_3,feature_data_4,feature_data_5)
  full_list <- full_list %>% reduce(full_join, by="Trial.Number")
  
  # In this incidence, the X = Before Stim, Y = First Third, X.X = Second Third, Y.Y = Final Third, NONE = Post Seizure
  
  # Remove Dataframes
  rm(feature_data_1,feature_data_2,feature_data_3,feature_data_4,feature_data_5,feature_data)
  
  if (channel == 1) {
    all_channel <- full_list
    rm(full_list)
  } else {
    full_list <- full_list[,c(19,22:ncol(full_list))]
    new_list_channel <- list(all_channel,full_list)
    new_list_channel <- new_list_channel %>% reduce(full_join, by="Trial.Number")
    all_channel <- new_list_channel
    rm(full_list,new_list_channel)
  }
  
  }
  
  # Adds to Animal Data
  
  if (folder_num == 1) {
    all_animal <- all_channel
  } else {
    all_animal <- rbind(all_animal,all_channel)
  }
  
}

# ---------------------------------------------------------------------------------------------------

# Step 3: Integrate R Data From Baseline