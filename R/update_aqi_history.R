# Update annual AQI history charts

# Load fonts
extrafont::loadfonts(device="win")
#extrafont::font_import() 
#import_roboto_condensed()
library(tidyverse)
library(hrbrthemes)
library(magick)

# AQI color functions
setwd("X://Agency_Files//Outcomes//Risk_Eval_Air_Mod//_Air_Risk_Evaluation//Staff Folders//Dorian//AQI//")

source("Web/aqi-watch/R/aqi_convert.R")


# Load history results
setwd("X://Agency_Files//Outcomes//Risk_Eval_Air_Mod//_Air_Risk_Evaluation//Staff Folders//Dorian//AQI//")

history   <- read_csv(paste0("X://Agency_Files//Outcomes//Risk_Eval_Air_Mod//_Air_Risk_Evaluation//Staff Folders//Dorian//AQI//Verification//AQI History//Archive//", Sys.Date()-1, " AQI history.csv"))


# Load yesterday's results
yesterday <- read_csv(paste0("Current forecast//", Sys.Date() - 1, "_AQI_observed", ".csv"))


# Join tables
history   <- left_join(select(history, -observation_recorded), select(yesterday, -date, -air_monitor, -count_ozone_obs, -count_pm25_obs))

history$aqi_max_date <- as.Date(history$aqi_max_date, "%m/%d/%Y")


# Add new value to correct AQI color
history <- history %>%
           rowwise() %>%
           mutate(max_aqi      = max(c(-1, 
                                       conc2aqi(obs_max_ozone_8hr_ppb, "ozone"), 
                                       conc2aqi(obs_pm25_24hr_ugm3, "pm25")), na.rm = T),
                  aqi_yellow   = aqi_yellow + (max_aqi > 50 & max_aqi < 101),
                  aqi_green    = aqi_green  + (max_aqi > -1 & max_aqi < 51),
                  aqi_orange   = aqi_orange + (max_aqi > 100),
                  aqi_max_date = ifelse(!is.na(max_aqi) & (max_aqi > aqi_max), as.character(Sys.Date()-1), as.character(aqi_max_date)),
                  aqi_max      = max(c(aqi_max, max_aqi), na.rm = T))


# Change name of column indicating if observation was recorded
names(history)[grep("aqsid", names(history))] <- "observation_recorded"

# Drop concentration columns
history <- select(history, -max_aqi, -obs_pm25_24hr_ugm3, -obs_max_ozone_8hr_ppb)


# Replace -Inf with NAs
history[history == -Inf] <- NA

# Save table
if(T) {

write_csv(history, 
          "X://Agency_Files//Outcomes//Risk_Eval_Air_Mod//_Air_Risk_Evaluation//Staff Folders//Dorian//AQI//Verification//AQI History//2017 AQI history.csv")

# Archive
write_csv(history, 
          paste0("X://Agency_Files//Outcomes//Risk_Eval_Air_Mod//_Air_Risk_Evaluation//Staff Folders//Dorian//AQI//Verification//AQI History//Archive//", Sys.Date(), " AQI history.csv"))

}


# Select 24 sites
## Drop PM2.5 only sites, and duplicates
history <- filter(history, !short_name %in% c("Marshall2", 
                                              "Fond_Du_Lac2", 
                                              "Voyageurs", 
                                              "Winona_pm", 
                                              "Ramsey_Health", 
                                              "St_Louis_Park", 
                                              "Duluth_WDSE",
                                              #"Cedar_Creek",
                                              "Stanton"))

# Update site names
#write_csv(hist_names, "Verification/AQI History/Names for history charts.csv")
hist_names <- read_csv("Verification/AQI History/Names for history charts.csv")

history    <- left_join(history, hist_names)

# Flip to tall
history <- gather(data = history, key = aqi_color, value = aqi_days, na.rm = FALSE, aqi_yellow, aqi_green, aqi_orange)

# Calculate percent of days for each color
history <- history %>% 
           group_by(hist_name) %>%
           mutate(total_days   = sum(aqi_days),
                  aqi_days_pct = aqi_days / sum(total_days),
                  aqi_label    = ifelse(aqi_days < 100, aqi_days, paste(aqi_days, "days")),
                  aqi_pos      = ifelse(aqi_color == "aqi_green", 110,
                                        ifelse(aqi_color == "aqi_yellow", 4 + 0.3 * aqi_days + max(0, aqi_days[aqi_color == "aqi_orange"], na.rm = T),
                                               4 + 0.3 * aqi_days)))

# Find max for chart scaling
max_aqi_days <- max(history$total_days, na.rm = T) + 15


# Save Max AQI table
max_data <- filter(history, aqi_days > 0, aqi_color == "aqi_green") %>%
            arrange(desc(aqi_color), -aqi_days) %>%
            select(`Air Monitor`, site_catid, aqi_max) %>%
            mutate(aqi_color = aqi2color(aqi_max))

write_csv(max_data, 
          "X://Agency_Files//Outcomes//Risk_Eval_Air_Mod//_Air_Risk_Evaluation//Staff Folders//Dorian//AQI//Verification//AQI History//2017_site_max_aqi.csv")


# Split sites into 4 groups of 6
for(i in 1:4) {
  
  # Select next 5 sites
  sub_data <- filter(history, 
                     aqi_days > 0, 
                     hist_name %in% arrange(filter(history, aqi_color == "aqi_yellow"), -aqi_days)$hist_name[(i*6-5):(i*6)]) %>%
              arrange(desc(aqi_color), -aqi_days)
  
  sub_data$hist_name <- factor(sub_data$hist_name, levels = rev(unique(sub_data$hist_name)))
  
  
  # Plot colors
  plot_colors <- c("#53BF33","#DB6B1A","#FFEE00")[c(T, "aqi_orange" %in% sub_data$aqi_color, "aqi_yellow" %in% sub_data$aqi_color)]
  
  text_colors <- c("white","grey50","grey50")[c(T, "aqi_orange" %in% sub_data$aqi_color, "aqi_yellow" %in% sub_data$aqi_color)]
 
 
  # Adjust low numbers to make room for labels
  sub_data$aqi_days_bump <- sub_data$aqi_days + 4
  
  # Create bar charts
  # Days chart
  day_chart <-
    ggplot(sub_data, aes(hist_name, aqi_days_bump)) +
      geom_bar(stat="identity", aes(fill = aqi_color), position = position_stack(reverse = F), alpha = 0.74) +
      geom_text(size = 3.7, fontface = "bold", 
                aes(label = ifelse(aqi_color %in% c("aqi_green", "aqi_yellow"), aqi_label, ""),
                    y = aqi_pos, color= aqi_color)) +
      coord_flip() +
      theme_ipsum(grid="X", base_size = 10) +
      scale_fill_manual(values  = plot_colors) +
      scale_color_manual(values = text_colors) +
      ylim(c(0, max_aqi_days)) + 
      #scale_x_discrete(labels = percent_format()) +
      guides(fill = F, color = F) +
      labs(x = NULL, y = NULL) + 
      theme(axis.title.x = element_blank(),
            axis.text.x  = element_blank(),
            axis.ticks.x = element_blank(),
            panel.grid.major = element_blank(),
            plot.margin = unit(c(0,0,0,0.5), "lines"))
  
  
  # Save to PNG image
  png(paste0("X:/Agency_Files/Outcomes/Risk_Eval_Air_Mod/_Air_Risk_Evaluation/Staff Folders/Dorian/AQI/Web/aqi-dashboard/images/history", i, ".png"), 
      width = 1300, height = 890, res = 300)

  #grid.arrange(day_chart)
  print(day_chart)
  
  dev.off()
  
  # % chart
  if(F) {
    pct_chart <- 
      ggplot(sub_data, aes(hist_name, aqi_days_pct)) +
      geom_bar(stat="identity", aes(fill = aqi_color), position = position_stack(reverse = T), alpha = 0.74) +
      geom_text(size = 3, aes(label = ifelse(aqi_color == "aqi_green", paste0(sprintf("%.0f", aqi_days_pct*100),"%"),""),
                              y = (1 - 0.52 * aqi_days_pct)), color= "white") +
      coord_flip() +
      theme_ipsum(grid="X") +
      scale_fill_manual(values = plot_colors) +
      #scale_color_manual(values = text_colors) +
      #scale_x_discrete(labels = percent_format()) +
      guides(fill = F, color = F) +
      labs(x = NULL, y = NULL) + 
      theme(axis.title.x = element_blank(),
            axis.text.x  = element_blank(),
            axis.ticks.x = element_blank(),
            panel.grid.major = element_blank(),
            plot.margin = unit(c(0,0,0,0.5), "lines"))
    
    #print(pct_chart)
  } 
  
 
} 


# Combine charts into a single GIF image
img1 <- image_read(paste0("X:/Agency_Files/Outcomes/Risk_Eval_Air_Mod/_Air_Risk_Evaluation/Staff Folders/Dorian/AQI/Web/aqi-dashboard/images/history1.png"))
img2 <- image_read(paste0("X:/Agency_Files/Outcomes/Risk_Eval_Air_Mod/_Air_Risk_Evaluation/Staff Folders/Dorian/AQI/Web/aqi-dashboard/images/history2.png"))
img3 <- image_read(paste0("X:/Agency_Files/Outcomes/Risk_Eval_Air_Mod/_Air_Risk_Evaluation/Staff Folders/Dorian/AQI/Web/aqi-dashboard/images/history3.png"))
img4 <- image_read(paste0("X:/Agency_Files/Outcomes/Risk_Eval_Air_Mod/_Air_Risk_Evaluation/Staff Folders/Dorian/AQI/Web/aqi-dashboard/images/history4.png"))

list(img1, img1, img1, img1, img1, img1, image_morph(c(img1,img2), frames=1), 
     img2, img2, img2, img2, img2, img2, image_morph(c(img2,img3), frames=1),
     img3, img3, img3, img3, img3, img3, image_morph(c(img3,img4), frames=1),
     img4, img4, img4, img4, img4, img4, image_morph(c(img4,img1), frames=1)) %>%
  image_join() %>%
  image_animate(fps=4) %>%
  image_write(paste0("X://Agency_Files//Outcomes//Risk_Eval_Air_Mod//_Air_Risk_Evaluation//Staff Folders//Dorian//AQI//Web//aqi-dashboard//images//history_fade.gif"))


list(img1, img1, img1, 
     img2, img2, img2, 
     img3, img3, img3, 
     img4, img4, img4) %>%
  image_join() %>%
  image_animate(fps=0.5) %>%
  image_write(paste0("X://Agency_Files//Outcomes//Risk_Eval_Air_Mod//_Air_Risk_Evaluation//Staff Folders//Dorian//AQI//Web//aqi-dashboard//images//history.gif"))


##
