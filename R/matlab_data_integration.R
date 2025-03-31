# Step 1: Import Libraries and Generate List of SubFolders

library(ggplot2)
library(lmerTest)
library(dplyr)

# Change to local folder directory

directory <- "E:/"

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

# Optional For Use in Bootstrapping

# Remove Recordings Above Certain Hours - INPUT 20 (5 HOURS)

# max_time <- readline(prompt="What is maximum trial number to include?\nIf so, type in the smallest animal to exclude.\nAny events smaller than or equal to it will be excluded. \nCommon Ones: 12 = 2022/11/07, 22 = 2023/01/16: ")
# 20
# kept_indices <- which(all_data$Trial.Number <= as.integer(min_anim))
# all_data <- all_data[kept_indices,]

# Permutations of Animals - This is to test if smaller clusters of animals have same significance as in larger clusters.

# class_1 <- unique(all_data$Animal [which(all_data$Epileptic == TRUE)])
# class_2 <- unique(all_data$Animal [which(all_data$Epileptic == FALSE)])

# if (length(class_1) > 5) class_1 <- class_1[sample(length(class_1),5)]
# if (length(class_2) > 5) class_2 <- class_2[sample(length(class_2),5)]

# kept_indices = which (all_data$Animal %in% c(class_1, class_2));
# all_data <- all_data[kept_indices,]

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
summary(lmer(Ch.3.Skew ~ Epileptic * Time.Point + (1|Animal), data = sing_data))
summary(lmer(Ch.3.Line.Length ~ Epileptic * Time.Point + (1|Animal), data = sing_data))
summary(lmer(Ch.3.Band.Power.1.Hz.to.30Hz ~ Epileptic * Time.Point + (1|Animal), data = sing_data))
summary(lmer(Ch.3.Band.Power.30.Hz.to.300Hz ~ Epileptic * Time.Point + (1|Animal), data = sing_data))
summary(lmer(Ch.3.Band.Power.300.Hz.to.1000Hz ~ Epileptic * Time.Point + (1|Animal), data = sing_data))
summary(lmer(Ch.3.AEntropy ~ Epileptic * Time.Point + (1|Animal), data = sing_data))
summary(lmer(Ch.3.PLHG ~ Epileptic * Time.Point + (1|Animal), data = sing_data))

# ---------------------------------------------------------------------------------------------------

# Step 5: Perform LME Models On Single Vs Double Stim (EPILEPTIC ONLY)

summary(lmer(Ch.3.Band.Power.1.Hz.to.30Hz ~ Sing * Time.Point + (1|Animal), data = sing_vs_db_ep_data))
summary(lmer(Ch.3.Band.Power.30.Hz.to.300Hz ~ Sing * Time.Point + (1|Animal), data = sing_vs_db_ep_data))
summary(lmer(Ch.3.Band.Power.300.Hz.to.1000Hz ~ Sing * Time.Point + (1|Animal), data = sing_vs_db_ep_data))
summary(lmer(Ch.3.Line.Length ~ Sing * Time.Point + (1|Animal), data = sing_vs_db_ep_data))
summary(lmer(Ch.3.Area ~ Sing * Time.Point + (1|Animal), data = sing_vs_db_ep_data))
summary(lmer(Ch.3.Skew ~ Sing * Time.Point + (1|Animal), data = sing_vs_db_ep_data))

# ---------------------------------------------------------------------------------------------------

# Step 6: Perform Comparisons on Spontaneous Vs Evoked (FREELY MOVING & EPILEPTIC ONLY)

summary(lmer(Ch.3.Band.Power.1.Hz.to.30Hz ~ Spont * Time.Point + (1|Animal), data = spont_vs_evoked_data))
summary(lmer(Ch.3.Band.Power.30.Hz.to.300Hz ~ Spont * Time.Point + (1|Animal), data = spont_vs_evoked_data))
summary(lmer(Ch.3.Band.Power.300.Hz.to.1000Hz ~ Spont * Time.Point + (1|Animal), data = spont_vs_evoked_data))
summary(lmer(Ch.3.Line.Length ~ Spont * Time.Point + (1|Animal), data = spont_vs_evoked_data))
summary(lmer(Ch.3.Area ~ Spont * Time.Point + (1|Animal), data = spont_vs_evoked_data))
summary(lmer(Ch.3.Skew ~ Spont * Time.Point + (1|Animal), data = spont_vs_evoked_data))
summary(lmer(Ch.3.AEntropy ~ Spont * Time.Point + (1|Animal), data = spont_vs_evoked_data))
summary(lmer(Ch.3.PLHG ~ Spont * Time.Point + (1|Animal), data = spont_vs_evoked_data))

# ---------------------------------------------------------------------------------------------------

# Step 7: Spontaneous Only Characterization

summary(lmer(Ch.3.Area ~ Time.Point + (1|Animal), data = spont_data))
summary(lmer(Ch.3.Skew ~ Time.Point + (1|Animal), data = spont_data))
summary(lmer(Ch.3.Line.Length ~ Time.Point + (1|Animal), data = spont_data))
summary(lmer(Ch.3.Band.Power.1.Hz.to.30Hz ~ Time.Point + (1|Animal), data = spont_data))
summary(lmer(Ch.3.Band.Power.30.Hz.to.300Hz ~ Time.Point + (1|Animal), data = spont_data))
summary(lmer(Ch.3.Band.Power.300.Hz.to.1000Hz ~ Time.Point + (1|Animal), data = spont_data))
summary(lmer(Ch.3.AEntropy ~ Time.Point + (1|Animal), data = spont_data))
summary(lmer(Ch.3.PLHG ~ Time.Point + (1|Animal), data = spont_data))

# Change Order of Factors so Compare Second Third to First Third

spont_data$Time.Point <- factor(spont_data$Time.Point, levels = c("Seizure - First Third", "Before Stimulation", 
  "During Stimulation", "Seizure - Second Third", "Seizure - Final Third", "Post Seizure"))

# Change Order of Factors so Compare Second Third to Final Third

spont_data$Time.Point <- factor(spont_data$Time.Point, levels = c("Seizure - Second Third", "Before Stimulation", 
  "During Stimulation", "Seizure - First Third", "Seizure - Final Third", "Post Seizure"))

# Change Order of Factors so Compare First Third to Pre Stim

spont_data$Time.Point <- factor(spont_data$Time.Point, levels = c("Before Stimulation", "During Stimulation",
  "Seizure - First Third", "Seizure - Second Third", "Seizure - Final Third", "Post Seizure"))

# ---------------------------------------------------------------------------------------------------

# Step 8: Epileptic Only Characterization

# Specific to Epileptic

kept_indices <- which(sing_data$Weeks.Post.KA > -1)
sing_data_ep <- sing_data[kept_indices,]

summary(lmer(Ch.3.Area ~ Time.Point + (1|Animal), data = sing_data_ep))
summary(lmer(Ch.3.Skew ~ Time.Point + (1|Animal), data = sing_data_ep))
summary(lmer(Ch.3.Line.Length ~ Time.Point + (1|Animal), data = sing_data_ep))
summary(lmer(Ch.3.Band.Power.1.Hz.to.30Hz ~ Time.Point + (1|Animal), data = sing_data_ep))
summary(lmer(Ch.3.Band.Power.30.Hz.to.300Hz ~ Time.Point + (1|Animal), data = sing_data_ep))
summary(lmer(Ch.3.Band.Power.300.Hz.to.1000Hz ~ Time.Point + (1|Animal), data = sing_data_ep))
summary(lmer(Ch.3.AEntropy ~ Time.Point + (1|Animal), data = sing_data_ep))
summary(lmer(Ch.3.PLHG ~ Time.Point + (1|Animal), data = sing_data_ep))

# Change Order of Factors so Compare Second Third to First Third

sing_data_ep$Time.Point <- factor(sing_data_ep$Time.Point, levels = c("Seizure - First Third", "Before Stimulation", 
                                                                  "During Stimulation", "Seizure - Second Third", "Seizure - Final Third", "Post Seizure"))

# Change Order of Factors so Compare Second Third to Final Third

sing_data_ep$Time.Point <- factor(sing_data_ep$Time.Point, levels = c("Seizure - Second Third", "Before Stimulation", 
                                                                  "During Stimulation", "Seizure - First Third", "Seizure - Final Third", "Post Seizure"))

# Change Order of Factors so Compare First Third to Pre Stim

sing_data_ep$Time.Point <- factor(sing_data_ep$Time.Point, levels = c("Before Stimulation", "During Stimulation",
                                                                  "Seizure - First Third", "Seizure - Second Third", "Seizure - Final Third", "Post Seizure"))
