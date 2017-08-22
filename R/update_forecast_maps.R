# Update AQI forecast maps

library(ggplot2)
library(dplyr)
library(readr)
library(leaflet)

# Leaflet to image reference: https://stackoverflow.com/questions/31336898/how-to-save-leaflet-in-r-map-as-png-or-jpg-file


# AQI color functions
setwd("X://Agency_Files//Outcomes//Risk_Eval_Air_Mod//_Air_Risk_Evaluation//Staff Folders//Dorian//AQI//")

source("Web/aqi-watch/R/aqi_convert.R")


# Load most recent forecasts
setwd("X://Agency_Files//Outcomes//Risk_Eval_Air_Mod")

forcs <- read_csv("Air_Modeling/AQI_Forecasting/Tree_Data/Forecast/AQI_Solutions/Values/All_Values.csv")


# Load site data
sites <- read_csv("X:/Agency_Files/Outcomes/Risk_Eval_Air_Mod/_Air_Risk_Evaluation/Staff folders/Dorian/AQI/MET data/Monitors and Rep Wx Stations.csv")

names(sites) <- gsub(" ", "_", tolower(names(sites)))

# Switch Voyageurs AQS ID to alt
sites[sites$site_catid == "27-137-9000", "site_catid"] <- sites[sites$site_catid == "27-137-9000", "alt_siteid"]


# Join
forcs <- left_join(forcs, sites)

# Create map for today and tomorrow's forecast
legend_colors <- c('#00e400', '#ffff00', '#ff7e00', '#ff0000', '#99004c', '#7e0023')

breaks <- c(0, 50, 100, 150, 200, 300, 700)

data <- forcs

data$aqi_color <- cut(data$AQI_Value, 
                      breaks = breaks, 
                      labels = legend_colors,
                      include.lowest = T)

data <- mutate(data, 
               Popup = paste0("<b style='font-size: 150%;'>", 
                              `Site Name`, "</b></br>", 
                              #"</br> AQS-ID: ", AqsID,
                              "</br> 1-hr AQI: ", AQI_Value,
                              "</br> Concentration: ", Concentration,
                              "</br> Parameter: ", Parameter,
                              "</br> Sampling Hour: ", Time,
                              "</br> Date: ", Date))

data <- left_join(data, locations[ , -2]) %>% arrange(AQI_Value)

data <- group_by(data, AqsID) %>%
       mutate(circle_scale = round(min(max(AQI_Value ** 0.5, 4.5), 12, na.rm = T), 1))

data$Long <- as.numeric(data$Long)

data$Lat  <- as.numeric(data$Lat)

map <- leaflet(na.omit(data[, c("aqi_color", "Popup", "Lat", "Long", "circle_scale")]), width = '99%') %>%
       setView(lat = 46.33, lng= -95.2, zoom= 6) %>%
       addProviderTiles("CartoDB.Positron") %>%
       addCircleMarkers(~Long, ~Lat, 
                        popup     = ~Popup, 
                        radius    = ~circle_scale, 
                        fillColor = ~aqi_color,
                        color     = 'gray',
                        weight    = 2, 
                        fillOpacity = 0.65,
                        opacity   = 0.5)

map 

##
