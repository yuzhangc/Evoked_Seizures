# On-Demand Seizures Facilitate Rapid Screening of Therapeutics for Epilepsy
# Authors: Yuzhang Chen, Brian Litt, Flavia Vitale, Hajime Takano
# DOI: https://doi.org/10.7554/eLife.101859

# Step 0: Epileptic (1) or Naive (0)

ep_or_nv = 1;

# Step 1: Import Libraries and Master Spreadsheet

library(readxl)
library(ggplot2)
library(ggbreak)
library(ggpubr)
library(tidyverse)
library(rstatix)
library(dplyr)
library(RColorBrewer)

# KEY: Change to local folder directory

directory <- "E:/eLife Export/"

# Read Trial Master Spreadsheet

trial_info <- read_xlsx(path = paste(directory, "Trial Info R.xlsx", sep = ""))
trial_info$Diazepam <- as.logical(trial_info$Diazepam)
trial_info$Levetiracetam <- as.logical(trial_info$Levetiracetam)
trial_info$Phenytoin <- as.logical(trial_info$Phenytoin)

# Step 2: Filter to Epileptic or Naive Only

kept_indices <- which(trial_info$Epileptic == ep_or_nv) 
trial_info_filt <- trial_info[kept_indices,]

# Step 3: Generate Dataframe For Duration and Success Rate Plots Per Animal

total_rac_data <- data.frame (Animal = character(), Condition = character(), Condition_Merge = character(), Counts = integer())
volc_dur_data <- data.frame (Animal = character(), Duration = double(), Condition = character())

for (animal in unique(trial_info_filt$Animal)){
  
  # Temporary Output Array
  # Structure: Failed, Racine 0 - 5
  temp_output <- c()
  
  # Segregate Data By Animal, Remove Drugged Indices. Second Stimulations Were Assumed Ineffective.
  kept_indices <- which(trial_info_filt$Animal == animal & trial_info_filt$`Laser Color 1` != -1 &
                        trial_info_filt$Levetiracetam == 0 & trial_info_filt$Phenytoin == 0 & trial_info_filt$Diazepam == 0)
  trial_info_sub <- trial_info_filt[kept_indices,]
  
  # Count Only Stimulus Above Threshold
  
  thresh_pow <- trial_info_sub %>% group_by(`Laser Power 1`) %>% summarize(mean_success = mean(`Seizure Or Not`)) %>% filter(mean_success > 0.66)
  thresh_pow <- min(thresh_pow$`Laser Power 1`)
  if (animal == 109){thresh_pow = 8}
  
  thresh_dur <- trial_info_sub %>% group_by(`Stim Time`) %>% summarize(mean_success = mean(`Seizure Or Not`)) %>% filter(mean_success > 0.66)
  thresh_dur <- min(thresh_dur$`Stim Time`)
  if (animal == 109){thresh_dur = 10}
  
  kept_indices <- which(trial_info_sub$`Laser Power 1` >= thresh_pow & trial_info_sub$`Stim Time` >= thresh_dur)
  trial_info_sub <- trial_info_sub[kept_indices,]
  
  # Information for Duration Plot (Include Failed)
  time_dur <- trial_info_sub$Duration
  animal_dur <- c(rep(as.character(animal),length(time_dur)))
  rac_dur <- as.character(trial_info_sub$Racine)
  
  # Count Failures. Failed Are Removed For Racine Calculations
  
  failed_evoc <- which(trial_info_sub$`Seizure Or Not` == 0)
  temp_output <- c(temp_output, length(failed_evoc))
  
  trial_info_sub <- trial_info_sub[which(trial_info_sub$`Seizure Or Not` == 1),]
  
  # Loop Through Racine Scale 1 to 5
  for (racine in 0:5) {
    temp_output <- c(temp_output,length(which(trial_info_sub$Racine == racine)))
  }
  
  # Information For Racine Scale Plot (Include Failed)
  
  animalnum <- c(rep(as.character(animal),7))
  condition <- c("Failed", "Rac. 0", "Rac. 1", "Rac. 2", "Rac. 3","Rac. 4","Rac. 5")
  condition_merged <- c("Failed", "Rac. 0 - 2", "Rac. 0 - 2", "Rac. 0 - 2", "Rac. 3 - 5","Rac. 3 - 5","Rac. 3 - 5")
  
  # Merge into Dataframe
  
  evoc_anim_data <- data.frame(Animal = animalnum, Condition = condition, Condition_Merge = condition_merged, Counts = temp_output)
  total_rac_data <- rbind(total_rac_data, evoc_anim_data)
  anim_dur_data <- data.frame(Animal = animal_dur, Duration = time_dur, Racine = rac_dur)
  volc_dur_data <- rbind(volc_dur_data, anim_dur_data)
  
}

# Step 4: Do Same Day Proportions for Drug Evocation Per Animal

total_diaz <- data.frame (Animal = character(), Racine = character(), Duration = double(), Condition = character())
total_lev <- data.frame (Animal = character(), Racine = character(), Duration = double(), Condition = character())

for (animal in unique(trial_info_filt$Animal)){

  # Identify Days Where Diazepam Occurred
  diaz_days <- unique(trial_info_filt[which(trial_info_filt$Diazepam == TRUE & trial_info_filt$Animal == animal),]$Day)
  
  for (day in diaz_days){
    kept_indices <- which(trial_info_filt$Animal == animal & trial_info_filt$`Laser Color 1` != -1 & trial_info_filt$Day == day)
    trial_info_sub <- trial_info_filt[kept_indices,]
    diaz_free <- trial_info_sub[which(trial_info_sub$Diazepam == 0),]
    diaz_trials <- trial_info_sub[which(trial_info_sub$Diazepam == 1),]
    diaz_fail <- which(diaz_trials$`Seizure Or Not` == 0)
    free_fail <- which(diaz_free$`Seizure Or Not` == 0)
    
    free_time_dur <- diaz_free$Duration
    free_animal <- c(rep(as.character(animal),length(free_time_dur)))
    free_rac <- as.character(paste("Rac. ", diaz_free$Racine))
    free_rac[free_fail] <- "Failed"
    free_condition <- ifelse(diaz_free$Racine <= 2, "Racine 0 - 2", "Racine 3 - 5")
    free_condition[free_fail] <- "Failed"
    
    dz_time_dur <- diaz_trials$Duration
    dz_animal <- c(rep(paste("DZ",as.character(animal)),length(dz_time_dur)))
    dz_rac <- as.character(paste("Rac. ", diaz_trials$Racine))
    dz_rac[diaz_fail] <- "Failed"
    dz_condition <- ifelse(diaz_trials$Racine <= 2, "Racine 0 - 2", "Racine 3 - 5")
    dz_condition[diaz_fail] <- "Failed"
    
    temp_data <- data.frame(Animal = c(free_animal, dz_animal), Racine = c(free_rac, dz_rac), Duration = c(free_time_dur, dz_time_dur), Condition = c(free_condition, dz_condition))
    total_diaz <- rbind(total_diaz, temp_data)
  }
  
  # Identify Days Where Levetiracetam Occurred
  lev_days <- unique(trial_info_filt[which(trial_info_filt$Levetiracetam == TRUE & trial_info_filt$Animal == animal),]$Day)
  
  for (day in lev_days){
    kept_indices <- which(trial_info_filt$Animal == animal & trial_info_filt$`Laser Color 1` != -1 & trial_info_filt$Day == day)
    trial_info_sub <- trial_info_filt[kept_indices,]
    lev_free <- trial_info_sub[which(trial_info_sub$Levetiracetam == 0),]
    lev_trials <- trial_info_sub[which(trial_info_sub$Levetiracetam == 1),]
    lev_fail <- which(lev_trials$`Seizure Or Not` == 0)
    free_fail <- which(lev_free$`Seizure Or Not` == 0)
    
    free_time_dur <- lev_free$Duration
    free_animal <- c(rep(as.character(animal),length(free_time_dur)))
    free_rac <- as.character(paste("Rac. ", lev_free$Racine))
    free_rac[free_fail] <- "Failed"
    free_condition <- ifelse(lev_free$Racine <= 2, "Racine 0 - 2", "Racine 3 - 5")
    free_condition[free_fail] <- "Failed"
    
    lv_time_dur <- lev_trials$Duration
    lv_animal <- c(rep(paste("LEV",as.character(animal)),length(lv_time_dur)))
    lv_rac <- as.character(paste("Rac. ", lev_trials$Racine))
    lv_rac[lev_fail] <- "Failed"
    lv_condition <- ifelse(lev_trials$Racine <= 2, "Racine 0 - 2", "Racine 3 - 5")
    lv_condition[lev_fail] <- "Failed"
    
    temp_data <- data.frame(Animal = c(free_animal, lv_animal), Racine = c(free_rac, lv_rac), Duration = c(free_time_dur, lv_time_dur), Condition = c(free_condition, lv_condition))
    total_lev <- rbind(total_lev, temp_data)
  }
}

# Step 5: Generate Plots of Evocation Outcomes (Racine & Duration) Per Animal W Drug

count_dz <- total_diaz %>% group_by(Animal, Racine) %>% summarise(Count = n(), .groups = "drop")
count_cond_dz <- total_diaz %>% group_by(Animal, Condition) %>% summarise(Count = n(), .groups = "drop")

# Figure A 9 A
ggplot(count_cond_dz, aes(fill=Condition, y=Count, x=Animal)) + geom_bar(position="fill", stat="identity") + scale_fill_brewer(palette = "YlOrRd")

count_lev <- total_lev %>% group_by(Animal, Racine) %>% summarise(Count = n(), .groups = "drop")
count_cond_lev <- total_lev %>% group_by(Animal, Condition) %>% summarise(Count = n(), .groups = "drop")

# Figure A 9 B
ggplot(count_cond_lev, aes(fill=Condition, y=Count, x=Animal)) + geom_bar(position="fill", stat="identity") + scale_fill_brewer(palette = "YlOrRd")