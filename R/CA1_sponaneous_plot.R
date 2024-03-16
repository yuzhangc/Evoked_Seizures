library(readxl)
library(ggplot2)

# Change to local folder directory

directory <- "G:/Clone of ORG YZ 20240303/"

# Read Trial Master Spreadsheet

trial_info <- read_xlsx(path = paste(directory, "Trial Info CA1 Sponantaneous Counts.xlsx", sep = ""))

# Organize Spontaneous Seizure Counts Into Plot Form

spon_sz_plots <- data.frame()

for (day in unique(trial_info$Day)){
  
  # Spontaneous Seizures Segregation
  
  unique_counts <- unique(trial_info$`Spontaneous Seizures`[which(trial_info$Day == day)])
  
  for(sz_num in unique_counts){
    
    counts_ep = length(which(trial_info$Day == day & trial_info$`Spontaneous Seizures` == sz_num))
    spon_sz_plots <- rbind(spon_sz_plots, data.frame(day,sz_num,counts_ep))
    
  }
  
}

# Spontaneous Seizure Count Plot

spont_sz_vs_day <- ggplot() 
spont_sz_vs_day + 
  # Points: Epileptic Data With Size Dictating How Many Values @ Each Point
  geom_point(data = spon_sz_plots[which(spon_sz_plots$counts_ep > 0),], aes(x = day, y = sz_num, size = counts_ep, colour = "red1")) +
  # Conditional Mean: Epileptic
  geom_smooth(data = trial_info, aes(x = `Day`, y = `Spontaneous Seizures`), fill = "black", colour="black") +
  # Axes Labels
  xlab("Recording Day") + ylab("Number Spontaneous Seizures") +
  # Legends
  scale_colour_manual(name="Legend", labels = c("Epileptic") , values = c("black")) +
  scale_size(name = "Counts")