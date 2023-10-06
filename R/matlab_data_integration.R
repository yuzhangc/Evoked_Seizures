# Import Libraries

library(ggplot2)
library(nlme)

# Change to local folder directory

directory <- "G:/Clone of ORG_YZ 20230710/"

# Generate subfolder list

complete_list <- list.dirs(directory,recursive=FALSE) 
real_folder_st <- match(paste(directory,"00000000 DO NOT PROCESS",sep = ""),complete_list)
real_folder_end <- match(paste(directory,"99999999 END",sep = ""),complete_list)
subFolders <- complete_list[(real_folder_st + 1):(real_folder_end - 1)]

# Select One Folder

folder_num <- 37

# Imports Files
csv_file_list <- list.files(path = subFolders[folder_num], pattern = "Extracted_Features_Channel_V2",
           full.names = FALSE, ignore.case = FALSE)

# Target Channel
target_ch <- 1

# Reads CSV into Dataframe

feature_data <- read.csv(paste(subFolders[folder_num],csv_file_list[2],sep="/"))

# Make Time Point Factor

feature_data$Time.Point <- factor(feature_data$Time.Point )

# Remove Short Events

min_time <- 15

indices <- which(feature_data$Evoked.Activity.Duration > min_time)

feature_data <- feature_data[indices,]

# Responder - Band Power Predictor - Time Point Random Effect Epileptic?
summary(lme(Ch.2.Band.Power.1.Hz.to.30Hz ~ Time.Point, random = ~ 1|Epileptic, data = feature_data))
