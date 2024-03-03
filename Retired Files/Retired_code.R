
# What Does It All Mean?

# The function is Outcome Measure ~ Predictor + Random Effect.

# In the first example, 'Area' is the Outcome and our predictors - fixed effects - are 'Epileptic' and 'Time.Point'
# We multiply these predictors because the summary of the model shows that there is a significant
# difference when 'Epileptic' and 'Time.Point' are varied together. (See the EpilepticTRUE:Time.Point Terms)
# Otherwise, if they are not significantly correlated, we would add the predictors.

# '|' is random. And (1|RandomEffect) means the intercept is changed by the random factor. In this case,
# we are assuming there is a random effect from the animals (e.g. seizures are more similar within animals
# than between animals.

# To see if there is a random effect, we look at the Random Effects. The variance needs to be tiny for there
# to be no effect.

# Everything is compared to the baseline case (Epileptic - False and Time.Point - Pre Stim)

# ALL DATA CASE: NOT VALID FOR SING DATA. Upon evaluation, we find that the summary is presented as follows
# The first few rows indicate what each factor contributes...and whether or not there is a difference
# compared to the base element/level in the Epileptic or Time Point. We see obviously that there is a
# significant difference during seizure. Next, we see the combination. We find that when Epileptic is True
# and at a particular time point (second third and final third), epileptic area is less (since the estimate is negative)
# but during stim, epileptic area is higher (since it's more positive) when compared to the naive.

# Evaluating random effects in first few lines requires an evaluation of the values for the area. So we find that
# since the variance is 0.04, it is big since our entire area value is pretty small.

# summary(sing_data$Ch.1.Area)

# ---------------------------------------------------------------------------------------------------

# Step 6: Drug Analysis

all_data <- data.frame()

for (folder_num in seq(1:length(subFolders))) {
  
  # Imports Files
  csv_file_list <- list.files(path = subFolders[folder_num], pattern = "Extracted_Features_Channel_V2_DRUG",
                              full.names = FALSE, ignore.case = FALSE)
  
  # Target Channel
  target_ch <- 1
  
  # Reads CSV into Dataframe IF File Exists
  
  if (file.exists(paste(subFolders[folder_num],csv_file_list[target_ch],sep="/"))){
    
    feature_data <- read.csv(paste(subFolders[folder_num],csv_file_list[target_ch],sep="/"))
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
  
}

# Remove Naive Animals and Second Trials

kept_indices <- which(all_data$Epileptic == TRUE)
all_data <- all_data[kept_indices,]

kept_indices <- which(is.na(all_data$Laser.2...Color))
all_data <- all_data[kept_indices,]

# Split into Diazepam, Levetiracetam, and Phenytoin

# Identify Unique Animals

diaz_an <- unique(all_data$Animal[all_data$Diazepam == TRUE & all_data$Levetiracetam == FALSE & all_data$Phenytoin == FALSE])

# Remove Specific Animals
diaz_an[c(1,7,9)] = NA
diaz_an = na.omit(diaz_an)

leve_an <- unique(all_data$Animal[all_data$Diazepam == FALSE & all_data$Levetiracetam == TRUE & all_data$Phenytoin == FALSE])
leve_an[c(4,5)] = NA
leve_an = na.omit(leve_an)

phe_an <- unique(all_data$Animal[all_data$Diazepam == FALSE & all_data$Levetiracetam == FALSE & all_data$Phenytoin == TRUE])

leve_phe_an <- unique(all_data$Animal[all_data$Diazepam == FALSE & all_data$Levetiracetam == TRUE & all_data$Phenytoin == TRUE])
leve_phe_an[c(4,5)] = NA
leve_phe_an = na.omit(leve_phe_an)

# Control Trials

diaz_cont <- which(all_data$Animal %in% diaz_an & all_data$Diazepam == FALSE & all_data$Levetiracetam == FALSE & all_data$Phenytoin == FALSE & all_data$Time.Point == "Before Stimulation")
leve_cont <- which(all_data$Animal %in% leve_an & all_data$Diazepam == FALSE & all_data$Levetiracetam == FALSE & all_data$Phenytoin == FALSE & all_data$Time.Point == "Before Stimulation")
phe_cont <- which(all_data$Animal %in% phe_an & all_data$Diazepam == FALSE & all_data$Levetiracetam == FALSE & all_data$Phenytoin == FALSE & all_data$Time.Point == "Before Stimulation")
leve_phe_cont <- which(all_data$Animal %in% leve_phe_an & all_data$Diazepam == FALSE & all_data$Levetiracetam == FALSE & all_data$Phenytoin == FALSE & all_data$Time.Point == "Before Stimulation")

# Drug Trials

diaz_trials <- which(all_data$Animal %in% diaz_an & all_data$Diazepam == TRUE & all_data$Levetiracetam == FALSE & all_data$Phenytoin == FALSE & all_data$Time.Point == "Before Stimulation")
leve_trials <- which(all_data$Animal %in% leve_an & all_data$Diazepam == FALSE & all_data$Levetiracetam == TRUE & all_data$Phenytoin == FALSE & all_data$Time.Point == "Before Stimulation")
phe_trials <- which(all_data$Animal %in% phe_an & all_data$Diazepam == FALSE & all_data$Levetiracetam == FALSE & all_data$Phenytoin == TRUE & all_data$Time.Point == "Before Stimulation")
leve_phe_trials <- which(all_data$Animal %in% leve_phe_an & all_data$Diazepam == FALSE & all_data$Levetiracetam == TRUE & all_data$Phenytoin == TRUE & all_data$Time.Point == "Before Stimulation")

# Split Data Frame

diaz_data <- all_data[c(diaz_cont,diaz_trials),]
leve_data <- all_data[c(leve_cont,leve_trials),]
phe_data <- all_data[c(phe_cont,phe_trials),]
leve_phe_data <- all_data[c(leve_phe_cont,leve_phe_trials),]

# Perform LME Models On Drug Vs Duration

summary(lmer(Evoked.Activity.Duration ~ Diazepam + (1|Animal), data = diaz_data))
summary(lmer(Evoked.Activity.Duration ~ Levetiracetam + (1|Animal), data = leve_data))
summary(lmer(Evoked.Activity.Duration ~ Phenytoin + (1|Animal), data = phe_data))
summary(lmer(Evoked.Activity.Duration ~ Levetiracetam + (1|Animal), data = leve_phe_data))

# Calculate Animal Means

# Diazepam
diaz_mean = matrix(nrow = 0, ncol = 2)
for (an in diaz_an) {
  an_cont <- mean(diaz_data$Evoked.Activity.Duration[diaz_data$Animal == an & diaz_data$Diazepam == FALSE])
  an_diaz <- mean(diaz_data$Evoked.Activity.Duration[diaz_data$Animal == an & diaz_data$Diazepam == TRUE])
  diaz_mean <- rbind(diaz_mean,c(an_cont,an_diaz))
}

# Levetiracetam
leve_mean = matrix(nrow = 0, ncol = 2)
for (an in leve_an) {
  an_cont <- mean(leve_data$Evoked.Activity.Duration[leve_data$Animal == an & leve_data$Levetiracetam == FALSE])
  an_leve <- mean(leve_data$Evoked.Activity.Duration[leve_data$Animal == an & leve_data$Levetiracetam == TRUE])
  leve_mean <- rbind(leve_mean,c(an_cont,an_leve))
}

phe_mean = matrix(nrow = 0, ncol = 2)
for (an in phe_an) {
  an_cont <- mean(phe_data$Evoked.Activity.Duration[phe_data$Animal == an & phe_data$Phenytoin == FALSE])
  an_phe <- mean(phe_data$Evoked.Activity.Duration[phe_data$Animal == an & phe_data$Phenytoin == TRUE])
  phe_mean <- rbind(phe_mean,c(an_cont,an_phe))
}

# Levetiracetam and Phenytoin
leve_phe_mean = matrix(nrow = 0, ncol = 2)
for (an in leve_phe_an) {
  an_cont <- mean(leve_phe_data$Evoked.Activity.Duration[leve_phe_data$Animal == an & leve_phe_data$Levetiracetam == FALSE])
  an_leve_phe <- mean(leve_phe_data$Evoked.Activity.Duration[leve_phe_data$Animal == an & leve_phe_data$Levetiracetam == TRUE])
  leve_phe_mean <- rbind(leve_phe_mean,c(an_cont,an_leve_phe))
}