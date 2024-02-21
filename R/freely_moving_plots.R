# Step 1: Import Libraries and Master Spreadsheet

library(readxl)
library(ggplot2)
library(ggbreak)
library(ggpubr)
library(tidyverse)
library(rstatix)

# Change to local folder directory

directory <- "E:/"

# Read Trial Master Spreadsheet

trial_info <- read_xlsx(path = paste(directory, "Trial Info R.xlsx", sep = ""))
trial_info$Diazepam <- as.logical(trial_info$Diazepam)
trial_info$Levetiracetam <- as.logical(trial_info$Levetiracetam)
trial_info$Phenytoin <- as.logical(trial_info$Phenytoin)

# Step 2: Generate Days List For Animals

animal_exp_days <- data.frame(
  Animal = c(100:110),
  Start_Day = c(-9,-9,-6,-5,-5,-9,-9,-9,-5,-5,-5),
  End_Day = c(16,16,6,11,11,15,15,15,12,12,12)
)

# -----------------------------------------------------------------------------

# Step 3: Generate Spontaneous Seizure Points For Day vs Animal

day_vs_an <- data.frame()

# Loop Through Animals

for (animal in unique(trial_info$Animal)) {
  
  if (animal == 105 | animal == 106) {
    experimental_days = c(-42:-32,animal_exp_days$Start_Day[which(animal_exp_days$Animal == animal)] : -1,
       1: animal_exp_days$End_Day[which(animal_exp_days$Animal == animal)])
    
  } else {
    experimental_days = c(animal_exp_days$Start_Day[which(animal_exp_days$Animal == animal)] : -1,
       1: animal_exp_days$End_Day[which(animal_exp_days$Animal == animal)])
  }
  
  # Loop Through Experimental Days For  Each Animal
  for (day in experimental_days) {
    
    # Spontaneous Seizure Count
    
    spont_trial_count <- length(which(trial_info$Animal == animal & 
       trial_info$Day == day & trial_info$`Laser Color 1` == -1))
    
    temp_data <- data.frame(animal,day,spont_trial_count,trial_info$Epileptic[which(trial_info$Animal == animal)][1])
    names(temp_data) <- c("Animal","Day","Spontaneous Seizures","Epileptic")
    day_vs_an <- rbind(day_vs_an,temp_data)
    
    rm(temp_data)
    
  }

}

# Step 4: Organize Spontaneous Seizure Counts Into Plot Form

spon_sz_plots <- data.frame()

# Get Counts For Combinations of Days and Seizures For Spontaneous Seizures

for (day in unique(day_vs_an$Day)){
  
  # Spontaneous Seizures Segregation
  
  unique_counts <- unique(day_vs_an$`Spontaneous Seizures`[which(day_vs_an$Day == day)])
  
  for(sz_num in unique_counts){
    
    counts_ep = length(which(day_vs_an$Day == day & day_vs_an$`Spontaneous Seizures` == sz_num & day_vs_an$Epileptic == 1))
    counts_nv = length(which(day_vs_an$Day == day & day_vs_an$`Spontaneous Seizures` == sz_num & day_vs_an$Epileptic == 0))
    spon_sz_plots <- rbind(spon_sz_plots, data.frame(day,sz_num,counts_ep,counts_nv))
    
  }
  
}

# Clear Workspace

rm(counts_ep, counts_nv, sz_num, animal, day, experimental_days, unique_counts, spont_trial_count)

# -----------------------------------------------------------------------------

# Step 5: Spontaneous Seizure Count Plot

spont_sz_vs_day <- ggplot() 
spont_sz_vs_day + 
  # Points: Epileptic Data With Size Dictating How Many Values @ Each Point
  geom_point(data = spon_sz_plots[which(spon_sz_plots$counts_ep > 0),], aes(x = day, y = sz_num, size = counts_ep, colour = "red1")) +
  # Points: Naive Data With Size Dictating How Many Values @ Each Point
  geom_point(data = spon_sz_plots[which(spon_sz_plots$counts_nv > 0),], aes(x = day, y = sz_num, size = counts_nv, colour = "royalblue1")) +
  # Conditional Mean: Epileptic
  geom_smooth(data = day_vs_an[which(day_vs_an$Epileptic == 1),], aes(x = `Day`, y = `Spontaneous Seizures`), fill = "red2", colour="red1") +
  # Conditional Mean: Naive
  geom_smooth(data = day_vs_an[which(day_vs_an$Epileptic == 0),], aes(x = `Day`, y = `Spontaneous Seizures`), fill = "royalblue2", colour="royalblue1") +
  # X Axis Break
  scale_x_continuous(minor_breaks = seq(-50, 30, 2.5)) + scale_x_break(c(-32, -9)) +
  # Axes Labels
  xlab("Day To Stimulation Start") + ylab("Number Spontaneous Seizures") +
  # Legends
  scale_colour_manual(name="Legend", labels = c("Epileptic", "Naive") , values = c("red1","royalblue1")) +
  scale_size(name = "Counts")

# -----------------------------------------------------------------------------

# Step 6: Evoked Seizures Calculations

evk_sz_data <- data.frame()

for (animal in unique(trial_info$Animal)){
  
  experimental_days <- unique(trial_info$Day[which(trial_info$Animal == animal & trial_info$`Laser Color 1` != -1)])
  
  for (day in experimental_days){

    # Trials Occuring On Specific Experimental Days
    
    specific_trials <- trial_info[which(trial_info$Animal == animal & trial_info$Day == day & trial_info$`Laser Color 1` != -1),]
    
    # Drug Free Evocations
    
    drug_free_total <- length(which(specific_trials$Diazepam == 0 & specific_trials$Levetiracetam == 0 & specific_trials$Phenytoin == 0))
    
    # Evocations After Drug
    
    lev_total <- length(which(specific_trials$Levetiracetam != 0))
    diaz_total <- length(which(specific_trials$Diazepam != 0 ))
    
    # Drug Free Evocations
    
    if (drug_free_total > 0) {
      
       # Electrographic Success Rate 
       
       drug_free_trials <- specific_trials[which(specific_trials$Diazepam == 0 & specific_trials$Levetiracetam == 0 & specific_trials$Phenytoin == 0),]
       electrographic_sz_cnt <- sum(drug_free_trials$`Seizure Or Not`)
       true_behavioral_success <- length(which(drug_free_trials$`Racine` > 0))/drug_free_total * 100
       electrographic_success <- electrographic_sz_cnt/drug_free_total * 100
       
       # Percentage Electrographic Seizures That Are Also Behavioral
       
       if (electrographic_sz_cnt > 0) {
       
       behavioral_success <- length(which(drug_free_trials$`Racine` > 0 & drug_free_trials$`Seizure Or Not` == 1))/
         electrographic_sz_cnt * 100
       
       } else {
         
       behavioral_success <- 0
         
       }

    } else {
      
      electrographic_success <- NaN
      behavioral_success <- NaN
      
    }
    
    # Levetiracetam
    
    if (lev_total > 0) {
      
      lev_trials <- specific_trials[which(specific_trials$Levetiracetam > 0),]
      lev_elec_sz_cnt <- sum(lev_trials$`Seizure Or Not`)
      lev_elec_success <- lev_elec_sz_cnt/lev_total * 100
      
      if (lev_elec_sz_cnt > 0) {
        
      lev_behav_success <- length(which(lev_trials$`Racine` > 0 & lev_trials$`Seizure Or Not` == 1))/
        lev_total * 100
        
      } else {
      
      lev_behav_success <- 0
        
      }
      
    } else {
      
      lev_elec_success <- NaN
      lev_behav_success <- NaN
      
    }
    
    # Diazepam
    
    if (diaz_total > 0) {
      
      diaz_trials <- specific_trials[which(specific_trials$Diazepam > 0),]
      diaz_elec_sz_cnt <- sum(diaz_trials$`Seizure Or Not`)
      diaz_elec_success <- sum(diaz_trials$`Seizure Or Not`)/diaz_total * 100
      
      if (diaz_elec_sz_cnt > 0) {
      
      diaz_behav_success <- sum(diaz_trials$`Racine` > 0 & diaz_trials$`Seizure Or Not` == 1)/
        diaz_total * 100
      
      } else {
        
      diaz_behav_success <- 0
      
      }
      
    } else {
      
      diaz_elec_success <- NaN
      diaz_behav_success <- NaN
      
    }
    
    # Incorporate Into Dataframe
    
    temp_data <- data.frame(animal,day,drug_free_total,electrographic_success,behavioral_success, true_behavioral_success,
            lev_total,lev_elec_success,lev_behav_success,diaz_total, diaz_elec_success, diaz_behav_success,
            trial_info$Epileptic[which(trial_info$Animal == animal)][1])
    names(temp_data) <- c("Animal","Day","Drug Free Evocations","Success Rate (E) - Drug Free","Behavioral Manifestation of Electrographic Seizures - Drug Free", 
                          "Behavioral Manifestation of All Seizures - Drug Free","Levetiracetam Evocations","Success Rate (E) - Levetiracetam",
                          "Behavioral Manifestation of All Seizures - Levetiracetam", "Diazepam Evocations",
                          "Success Rate (E) - Diazepam","Behavioral Manifestation of All Seizures - Diazepam", "Epileptic")        
    
    evk_sz_data <- rbind(evk_sz_data, temp_data)
    
    # Clear Workspace Between Trials
    
    rm(specific_trials, diaz_trials, lev_trials, drug_free_trials, temp_data,diaz_behav_success,diaz_elec_success,
       lev_behav_success,lev_elec_success,diaz_elec_sz_cnt,lev_elec_sz_cnt,electrographic_sz_cnt,behavioral_success,
       drug_free_total, lev_total, diaz_total,true_behavioral_success)
    
    }

}

# Clear Workspace

rm(animal, day, experimental_days)

# -----------------------------------------------------------------------------

# Step 7: Evocation Success Rate Organization For Plot

evk_elec_sz_plots <- data.frame()

for (day in unique(evk_sz_data$Day)){
  
  # Evocation Segregation
  
  unique_elec_counts <- unique(evk_sz_data$`Success Rate (E) - Drug Free`[which(evk_sz_data$Day == day)])
  
  for(success_rate_electrographic in unique_elec_counts){
    
    counts_ep = length(which(evk_sz_data$Day == day & evk_sz_data$`Success Rate (E) - Drug Free` == success_rate_electrographic & evk_sz_data$Epileptic == 1))
    counts_nv = length(which(evk_sz_data$Day == day & evk_sz_data$`Success Rate (E) - Drug Free` == success_rate_electrographic & evk_sz_data$Epileptic == 0))
    evk_elec_sz_plots <- rbind(evk_elec_sz_plots, data.frame(day,success_rate_electrographic,counts_ep,counts_nv))
    
  }
  
}

evk_behav_sz_plots <- data.frame()

for (day in unique(evk_sz_data$Day)){
  
  # Evocation Segregation
  
  unique_elec_counts <- unique(evk_sz_data$`Behavioral Manifestation of Electrographic Seizures - Drug Free`[which(evk_sz_data$Day == day)])
  
  for(success_rate_behavior in unique_elec_counts){
    
    counts_ep = length(which(evk_sz_data$Day == day & evk_sz_data$`Behavioral Manifestation of Electrographic Seizures - Drug Free` == success_rate_behavior & evk_sz_data$Epileptic == 1))
    counts_nv = length(which(evk_sz_data$Day == day & evk_sz_data$`Behavioral Manifestation of Electrographic Seizures - Drug Free` == success_rate_behavior & evk_sz_data$Epileptic == 0))
    evk_behav_sz_plots <- rbind(evk_behav_sz_plots, data.frame(day,success_rate_behavior,counts_ep,counts_nv))
    
  }
  
}

# Pairwise T Test For Behavioral Seizure to Epileptic

print(evk_sz_data[which(evk_sz_data$Day == 1),] %>% pairwise_t_test(`Behavioral Manifestation of All Seizures - Drug Free`~ Epileptic))
print(evk_sz_data[which(evk_sz_data$Day == 2),] %>% pairwise_t_test(`Behavioral Manifestation of All Seizures - Drug Free`~ Epileptic))

# -----------------------------------------------------------------------------

# Step 8: Electrographic Seizure Plot

evoked_sz_rate <- ggplot() 
evoked_sz_rate +
  # Points: Epileptic Data With Size Dictating How Many Values @ Each Point
  geom_point(data = evk_elec_sz_plots[which(evk_elec_sz_plots$counts_ep > 0),], aes(x = day, y = success_rate_electrographic, size = counts_ep, colour = "red1")) +
  # Points: Naive Data With Size Dictating How Many Values @ Each Point
  geom_point(data = evk_elec_sz_plots[which(evk_elec_sz_plots$counts_nv > 0),], aes(x = day, y = success_rate_electrographic, size = counts_nv, colour = "royalblue1")) +
  # Conditional Mean: Epileptic
  geom_smooth(data = evk_sz_data[which(evk_sz_data$Epileptic == 1),], aes(x = `Day`, y = `Success Rate (E) - Drug Free`), fill = "red2", colour="red1") +
  # Conditional Mean: Naive
  geom_smooth(data = evk_sz_data[which(evk_sz_data$Epileptic == 0),], aes(x = `Day`, y = `Success Rate (E) - Drug Free`), fill = "royalblue2", colour="royalblue1") +
  # Axes Labels
  xlab("Day Since Evocation Start") + ylab("Electrographic Evocation Success Rate") +
  # Legends
  scale_colour_manual(name="Legend", labels = c("Epileptic", "Naive") , values = c("red1","royalblue1")) +
  scale_size(name = "Counts")

evoked_sz_rate_beh <- ggplot()
evoked_sz_rate_beh +
  # Points: Epileptic Data With Size Dictating How Many Values @ Each Point
  geom_point(data = evk_behav_sz_plots[which(evk_behav_sz_plots$counts_ep > 0),], aes(x = day, y = success_rate_behavior, size = counts_ep, colour = "red1")) +
  # Points: Naive Data With Size Dictating How Many Values @ Each Point
  geom_point(data = evk_behav_sz_plots[which(evk_behav_sz_plots$counts_nv > 0),], aes(x = day, y = success_rate_behavior, size = counts_nv, colour = "royalblue1")) +
  # Conditional Mean: Epileptic
  geom_smooth(data = evk_sz_data[which(evk_sz_data$Epileptic == 1),], aes(x = `Day`, y = `Behavioral Manifestation of Electrographic Seizures - Drug Free`), fill = "red2", colour="red1") +
  # Conditional Mean: Naive
  geom_smooth(data = evk_sz_data[which(evk_sz_data$Epileptic == 0),], aes(x = `Day`, y = `Behavioral Manifestation of Electrographic Seizures - Drug Free`), fill = "royalblue2", colour="royalblue1") +
  # Axes Labels
  xlab("Day Since Evocation Start") + ylab("Behavioral Evocation Success Rate") +
  # Legends
  scale_colour_manual(name="Legend", labels = c("Epileptic", "Naive") , values = c("red1","royalblue1")) +
  scale_size(name = "Counts")

# -----------------------------------------------------------------------------

# Step 9: Organize Data For Drug
# Note: Behavior For Drug Efficacy is Over TOTAL Stimulations, Not Just Electrographic

# Sets Up Variables

no_drug_elec_d = c()
diaz_elec = c()
no_drug_behav_d = c()
diaz_behav = c()
no_drug_elec_l = c()
lev_elec = c()
no_drug_behav_l = c()
lev_behav = c()

for (animal in unique(evk_sz_data$Animal)) {

  # Extracts Drug Trial Days
  
  diaz_drug_days <- unique(evk_sz_data[which(evk_sz_data$Animal == animal & evk_sz_data$`Diazepam Evocations` > 0),]$Day)
  lev_drug_days <- unique(evk_sz_data[which(evk_sz_data$Animal == animal & evk_sz_data$`Levetiracetam Evocations` > 0),]$Day)
  
  if (length(diaz_drug_days) > 0) {
    
    # Extract Success Rate For Non-Drug and Drug Trials on Drug Day
    
    for (day in unique(diaz_drug_days)) {
      
      # Appends Control Trial Info
      
      if (is.null(no_drug_elec_d)) {
        
        no_drug_elec_d[1] <- evk_sz_data[which(evk_sz_data$Animal == animal & evk_sz_data$Day == day),]$`Success Rate (E) - Drug Free`
        no_drug_behav_d[1] <- evk_sz_data[which(evk_sz_data$Animal == animal & evk_sz_data$Day == day),]$`Behavioral Manifestation of All Seizures - Drug Free`
        
      } else {
      
        no_drug_elec_d <- append(no_drug_elec_d, evk_sz_data[which(evk_sz_data$Animal == animal & evk_sz_data$Day == day),]$`Success Rate (E) - Drug Free`)
        no_drug_behav_d <- append(no_drug_behav_d, evk_sz_data[which(evk_sz_data$Animal == animal & evk_sz_data$Day == day),]$`Behavioral Manifestation of All Seizures - Drug Free`)
        
      }
      
      # Appends Diazepam Trial Info
      
      if (is.null(diaz_elec)) {
        
        diaz_elec[1] <- evk_sz_data[which(evk_sz_data$Animal == animal & evk_sz_data$Day == day),]$`Success Rate (E) - Diazepam`
        diaz_behav[1] <- evk_sz_data[which(evk_sz_data$Animal == animal & evk_sz_data$Day == day),]$`Behavioral Manifestation of All Seizures - Diazepam`
        
      } else {
        
        diaz_elec <- append(diaz_elec, evk_sz_data[which(evk_sz_data$Animal == animal & evk_sz_data$Day == day),]$`Success Rate (E) - Diazepam`)
        diaz_behav <- append(diaz_behav,evk_sz_data[which(evk_sz_data$Animal == animal & evk_sz_data$Day == day),]$`Behavioral Manifestation of All Seizures - Diazepam`)
        
      }
    
      }
    
  }
  
  # Levetiracetam
  
  if (length(lev_drug_days) > 0) {
    
    # Extract Success Rate For Non-Drug and Drug Trials on Drug Day
    
    for (day in unique(lev_drug_days)) {
      
      # Appends Control Trial Info
      
      if (is.null(no_drug_elec_l)) {
        
        no_drug_elec_l[1] <- evk_sz_data[which(evk_sz_data$Animal == animal & evk_sz_data$Day == day),]$`Success Rate (E) - Drug Free`
        no_drug_behav_l[1] <- evk_sz_data[which(evk_sz_data$Animal == animal & evk_sz_data$Day == day),]$`Behavioral Manifestation of All Seizures - Drug Free`
        
      } else {
        
        no_drug_elec_l <- append(no_drug_elec_l, evk_sz_data[which(evk_sz_data$Animal == animal & evk_sz_data$Day == day),]$`Success Rate (E) - Drug Free`)
        no_drug_behav_l <- append(no_drug_behav_l, evk_sz_data[which(evk_sz_data$Animal == animal & evk_sz_data$Day == day),]$`Behavioral Manifestation of All Seizures - Drug Free`)
        
      }
      
      # Appends Levetiracetam Trial Info
      
      if (is.null(lev_elec)) {
        
        lev_elec[1] <- evk_sz_data[which(evk_sz_data$Animal == animal & evk_sz_data$Day == day),]$`Success Rate (E) - Levetiracetam`
        lev_behav[1] <- evk_sz_data[which(evk_sz_data$Animal == animal & evk_sz_data$Day == day),]$`Behavioral Manifestation of All Seizures - Levetiracetam`
        
      } else {
        
        lev_elec <- append(lev_elec, evk_sz_data[which(evk_sz_data$Animal == animal & evk_sz_data$Day == day),]$`Success Rate (E) - Levetiracetam`)
        lev_behav <- append(lev_behav,evk_sz_data[which(evk_sz_data$Animal == animal & evk_sz_data$Day == day),]$`Behavioral Manifestation of All Seizures - Levetiracetam`)
        
      }
      
    }
    
  }
  
}

# Compile Into Dataframe

compiled_success <- c(no_drug_elec_d, diaz_elec, no_drug_behav_d , diaz_behav,
                      no_drug_elec_l, lev_elec, no_drug_behav_l, lev_behav)
compiled_names <- c(rep("WT-D-E",length(no_drug_elec_d)),rep("DZ-E",length(diaz_elec)),
                    rep("WT-D-B",length(no_drug_behav_d)),rep("DZ-B",length(diaz_behav)),
                    rep("WT-L-E",length(no_drug_elec_l)),rep("LV-E",length(lev_elec)),
                    rep("WT-L-B",length(no_drug_behav_l)),rep("LV-B",length(lev_behav)))
conditions <- c(rep("Control",length(no_drug_elec_d)),rep("Diazepam",length(diaz_elec)),
               rep("Control",length(no_drug_behav_d)),rep("Diazepam",length(diaz_behav)),
               rep("Control",length(no_drug_elec_l)),rep("Levetiracetam",length(lev_elec)),
               rep("Control",length(no_drug_behav_l)),rep("Levetiracetam",length(lev_behav)))

drug_test_plot <- data.frame(compiled_names,compiled_success, conditions)
names(drug_test_plot) <- c("Condition","Success Rate","Control Or Not")

drug_comparison <- ggplot()
drug_comparison +
  # Box Plot For Data
  ggboxplot(drug_test_plot,x = "Condition",y = "Success Rate",add = "dotplot",  palette = c("black", "forestgreen", "purple2"),
            color = "Control Or Not")

# Clear Workspace

rm(lev_behav,lev_elec,no_drug_behav_d,no_drug_behav_l,no_drug_elec_d,no_drug_elec_l,diaz_behav,diaz_elec,
   diaz_drug_days,lev_drug_days,success_rate_behavior,success_rate_electrographic,electrographic_success, animal,
   counts_ep, counts_nv, day, unique_elec_counts, compiled_names, compiled_success, conditions)