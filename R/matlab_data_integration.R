# Step 1: Import Libraries and Generate List of SubFolders

library(ggplot2)
library(lmerTest)
library(dplyr)

# Change to local folder directory

directory <- "E:/" #"G:/Clone of ORG_YZ 20231006/"

# Generate subfolder list

complete_list <- list.dirs(directory,recursive=FALSE) 
real_folder_st <- match(paste(directory,"00000000 DO NOT PROCESS",sep = ""),complete_list)
real_folder_end <- match(paste(directory,"99999999 END",sep = ""),complete_list)
subFolders <- complete_list[(real_folder_st + 1):(real_folder_end - 1)]

# ---------------------------------------------------------------------------------------------------

# Step 2: Loops Through All Folder To Generate Complete Data Frame

all_data <- data.frame()
  
for (folder_num in seq(1:length(subFolders))) {

# Imports Files
csv_file_list <- list.files(path = subFolders[folder_num], pattern = "Extracted_Features_Channel_V2",
           full.names = FALSE, ignore.case = FALSE)

# Target Channel
target_ch <- 1

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

# Append to All_Data

all_data <- rbind(all_data,feature_data)

}

# ---------------------------------------------------------------------------------------------------

# Step 3: Filters Data Frame

# Remove Short Events - INPUT 15

min_time <- readline(prompt="Do you want to exclude short events?\nIf so, type in the second duration of events to exclude.\nAny events smaller than the duration will be excluded: ")
15
kept_indices <- which(all_data$Evoked.Activity.Duration > as.numeric(min_time))
all_data <- all_data[kept_indices,]

# Remove Early Recordings - INPUT 12

min_anim <- readline(prompt="Do you want to exclude early animals?\nIf so, type in the smallest animal to exclude.\nAny events smaller than or equal to it will be excluded. \nCommon Ones: 12 = 2022/11/07, 22 = 2023/01/16: ")
12
kept_indices <- which(all_data$Animal > as.integer(min_anim))
all_data <- all_data[kept_indices,]

# Responder - Area is Outcome, Multiplied Predictor Terms Have Interactions
# Added Predictor Terms Do Not Have Interactions. So If Epileptic and Time.Point
# are not significantly correlated, we can just do addition. 

# '|' is random. And (1|RandomEffect) means the intercept is changed by the random factor.
# So in this case, we are assuming there is a random effect from the animals (e.g. one of the)
# seizures are more similar within animals than between animals.
summary(lmer(Ch.1.Area ~ Epileptic * Time.Point + (1|Animal), data = all_data))

# Upon evaluation, we find that the summary is presented as follows
# The first few rows indicate what each factor contributes...and whether or not there is a difference
# compared to the base element/level in the Epileptic or Time Point. We see obviously that there is a
# significant difference during seizure. Next, we see the combination. We find that when Epileptic is True
# and at a particular time point (second third and final third), epileptic area is less (since the estimate is negative)
# but during stim, epileptic area is higher (since it's more positive) when compared to the naive.

# Evaluating random effects in first few lines requires an evaluation of the values for the area. So we find that
# since the variance is 0.04, it is big since our entire area value is pretty small.

summary(all_data$Ch.1.Area)
