# Step 1: Import Libraries and Master Spreadsheet

library(readxl)
library(ggplot2)

# Change to local folder directory

directory <- "G:/Clone of ORG_YZ 20231006/"

# Read Trial Master Spreadsheet

trial_info <- read_xlsx(path = paste(directory, "Trial Info R.xlsx", sep = ""))

# Step 2: Generate Points For Day vs Animal

day_vs_an <- data.frame()

# Loop Through Animals
for (animal in unique(trial_info$Animal)) {
  
  # Loop Through Days Unique to Each Animal
  for (day in unique(trial_info$Day[which(trial_info$Animal == animal)])) {
    
     # Spontaneous Seizure Count
     spont_trial_count <- length(which(trial_info$Animal == animal & 
        trial_info$Day == day & trial_info$`Laser Color 1` == -1))
     
     # Stimulation Days
     if (day > 0) {
     
       # Count Total Evocations
       specific_trials <- trial_info[which(trial_info$Animal ==
          animal & trial_info$Day == day & trial_info$`Laser Color 1` != -1 ),]
       total_evoked = length(specific_trials$`Trial Number`)
       
       if (total_evoked > 0){

       # Electrically Evocation Success
       elec_success_evocation <- sum(specific_trials$`Seizure Or Not`)   
       electrographic_evocation_success <- elec_success_evocation/total_evoked * 100

       # Behavioral Success ONLY For Electrographically Evoked Seizures       
       behavioral_success <- length(which(specific_trials$Racine > 0 & specific_trials$`Seizure Or Not` 
          == 1))/elec_success_evocation* 100
       
       } else {
         
       electrographic_evocation_success <- NaN
       behavioral_success <- NaN
         
       }
       
     } else {
       
       electrographic_evocation_success <- NaN
       behavioral_success <- NaN
       
     }
     
     # Temporary Dataframe For Calculations
     temp_data <- data.frame(animal,day,spont_trial_count,electrographic_evocation_success,
        behavioral_success,trial_info$Epileptic[which(trial_info$Animal == animal)][1])
     names(temp_data) <- c("Animal","Day","Spontaneous Seizures", "Electrographic Evocation Rate",
        "Behavioral Manifestation of Electrographic Seizure", "Epileptic")
     day_vs_an <- rbind(day_vs_an,temp_data)
    
  }
  
}

# Step 3: Plots Evocation Success Rate

spon_sz_plots <- data.frame()

for (day in unique(day_vs_an$Day)){
  
  for(sz_num in unique(day_vs_an$`Spontaneous Seizures`[which(day_vs_an$Day == day)])){
    
    counts_ep = length(which(day_vs_an$Day == day & day_vs_an$`Spontaneous Seizures` == sz_num & day_vs_an$Epileptic == 1))
    counts_nv = length(which(day_vs_an$Day == day & day_vs_an$`Spontaneous Seizures` == sz_num & day_vs_an$Epileptic == 0))
    spon_sz_plots <- rbind(spon_sz_plots, data.frame(day,sz_num,counts_ep,counts_nv))
      
  }
}

spont_sz_vs_day <- ggplot() 
spont_sz_vs_day + geom_point(data = spon_sz_plots[which(spon_sz_plots$counts_ep > 0),], aes(x = day, y = sz_num, size = counts_ep, colour = "red1")) +
  geom_smooth(data = day_vs_an[which(day_vs_an$Epileptic == 1),], aes(x = `Day`, y = `Spontaneous Seizures`), fill="indianred", colour="red1") +
  geom_point(data = spon_sz_plots[which(spon_sz_plots$counts_nv > 0),], aes(x = day, y = sz_num, size = counts_nv, colour = "royalblue1")) +
  geom_smooth(data = day_vs_an[which(day_vs_an$Epileptic == 0),], aes(x = `Day`, y = `Spontaneous Seizures`), fill="royalblue3", colour="royalblue1") +
  xlab("Day To Stimulation Start") + ylab("Number Spontaneous Seizures") + scale_colour_manual(name="Legend", labels = c("Epileptic", "Naive") , values = c("red1","royalblue1"))
