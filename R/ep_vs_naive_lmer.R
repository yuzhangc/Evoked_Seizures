# On-Demand Seizures Facilitate Rapid Screening of Therapeutics for Epilepsy
# Authors: Yuzhang Chen, Brian Litt, Flavia Vitale, Hajime Takano
# DOI: https://doi.org/10.7554/eLife.101859

# Step 1: Import Libraries and Generate List of SubFolders

library(ggplot2)
library(lmerTest)
library(dplyr)

# KEY: Change to local folder directory

directory <- "E:/eLife Export/"

# Critical Variables For Filtering

# Minimum and Maximum Day For Processing, Inclusive. Set - 90 and + 90 to include all - spont vs evoked.
# Set 1 - 4 for Early Naive/Epileptic and 5 and 90 for Late Naive/Epileptic Comparisons

min_day <- 1
max_day <- 4

# Minimum Racine Scale. Enter 0 for All (Naive/Epileptic). Use 3 for Spont vs Evoked.

min_rac <- 0

# Generate subfolder list

complete_list <- list.dirs(directory,recursive=FALSE) 

real_folder_st <- match(paste(directory,"EEG_000_START",sep = ""),complete_list)
real_folder_end <- match(paste(directory,"EEG_999_END",sep = ""),complete_list)

subFolders <- complete_list[(real_folder_st + 1):(real_folder_end - 1)]

# ---------------------------------------------------------------------------------------------------

# Step 2: Loops Through All Folder To Generate Complete Data Frame

all_data <- data.frame()
  
for (folder_num in seq(1:length(subFolders))) {

# Imports Files
csv_file_list <- list.files(path = subFolders[folder_num], pattern = "Extracted_Features_Channel_V2_2StimREMOVED",
           full.names = FALSE, ignore.case = FALSE)

# Target Channel
target_ch <- 3

# Reads CSV into Dataframe

feature_data <- read.csv(paste(subFolders[folder_num],csv_file_list[target_ch],sep="/"))

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

# Append to All_Data

all_data <- rbind(all_data,feature_data)

}

# ---------------------------------------------------------------------------------------------------

# Step 3: Filters Data Frame

# Evocation Day Filtering

kept_indices <- which(all_data$Evocation.Day >= min_day & all_data$Evocation.Day <= max_day)
all_data <- all_data[kept_indices,]

# Racine Scale Filtering

kept_indices <- which(all_data$Seizure.Scale >= min_rac)
all_data <- all_data[kept_indices,]

# Remove Short Events - INPUT 15 SEC

min_time <- readline(prompt="Do you want to exclude short events?\nIf so, type in the second duration of events to exclude.\nAny events smaller than the duration will be excluded: ")
15
kept_indices <- which(all_data$Evoked.Activity.Duration >= as.numeric(min_time))
all_data <- all_data[kept_indices,]

# Remove Early Recordings Due to Signal Issues - INPUT 12 (ANIMAL #). Does Not Affect Freely Moving Data

min_anim <- readline(prompt="Do you want to exclude early animals?\nIf so, type in the smallest animal to exclude.\nAny events smaller than or equal to it will be excluded. \nCommon Ones: 12 = 2022/11/07, 22 = 2023/01/16: ")
12
kept_indices <- which(all_data$Animal >= as.integer(min_anim))
all_data <- all_data[kept_indices,]

# Removes Diazepam Levetiracetam and Phenytoin Recordings. No Phenytoin in Freely Moving Animals

drugged_indices <- which(all_data$Levetiracetam == 1 | all_data$Phenytoin == 1 | all_data$Diazepam == 1)
kept_indices <- which(all_data$Levetiracetam == 0 & all_data$Phenytoin == 0 & all_data$Diazepam == 0)
all_data <- all_data[kept_indices,]

# ------------------------------------------------------------

# Separates Second Blue Stimulation Trials From Single Stimulation (Evocation Only) Trials

single_stim_indices <- which(is.na(all_data$Laser.2...Color) & (all_data$Laser.1...Color == 473 | all_data$Laser.1...Color == 488))
double_blue_stim_indices <- which(all_data$Laser.2...Color == 473 & all_data$Delay > 0 & all_data$Laser.2...Frequency > 0)

# Spontaneous Only (Epileptic)

spont_indices <-  which(is.na(all_data$Laser.1...Color) & all_data$Epileptic == TRUE)
spont_data <- all_data[spont_indices,]

# Spontaneous vs Evoked Only Contains Epileptic Animals

spont_vs_evoked_data = all_data[c(single_stim_indices,spont_indices),]
kept_indices <- which(spont_vs_evoked_data$Epileptic == TRUE)
spont_vs_evoked_data = spont_vs_evoked_data[kept_indices,]
spont_vs_evoked_data$Spont <- is.na(spont_vs_evoked_data$Laser.1...Color)
spont_vs_evoked_data$Spont <- factor(spont_vs_evoked_data$Spont, levels = c(FALSE, TRUE))

# Single Vs Additional High Freq Stim Only Contains Epileptic Animals

sing_vs_db_data = all_data[c(single_stim_indices,double_blue_stim_indices),]
sing_vs_db_data$Sing <- is.na(sing_vs_db_data$Delay)
sing_vs_db_data$Sing <- factor(sing_vs_db_data$Sing, levels = c(TRUE, FALSE))

kept_indices <- which(sing_vs_db_data$Epileptic == TRUE)
sing_vs_db_ep_data = sing_vs_db_data[kept_indices,]

# Single Stimulation (Evocation Only) Trials Contains Both Naive and Epileptic Animals

sing_data = all_data[single_stim_indices,]

# ---------------------------------------------------------------------------------------------------

# Step 4: Perform LME Models On Epileptic Vs Naive

summary(lmer(Ch.3.Area ~ Epileptic * Time.Point + (1|Animal), data = sing_data))
summary(lmer(Ch.3.Line.Length ~ Epileptic * Time.Point + (1|Animal), data = sing_data))
summary(lmer(Ch.3.Band.Power.1.Hz.to.30Hz ~ Epileptic * Time.Point + (1|Animal), data = sing_data))
summary(lmer(Ch.3.Band.Power.30.Hz.to.300Hz ~ Epileptic * Time.Point + (1|Animal), data = sing_data))
summary(lmer(Ch.3.Band.Power.300.Hz.to.1000Hz ~ Epileptic * Time.Point + (1|Animal), data = sing_data))