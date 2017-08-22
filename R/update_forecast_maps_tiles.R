# Update AQI forecast maps

library(ggplot2)
library(dplyr)
library(readr)
library(leaflet)
library(rgdal)
library(rgeos)
library(maptools)
library(mapview)
library(gstat)
library(sp)

# Leaflet to image reference: https://stackoverflow.com/questions/31336898/how-to-save-leaflet-in-r-map-as-png-or-jpg-file


# AQI color functions
setwd("X://Agency_Files//Outcomes//Risk_Eval_Air_Mod//_Air_Risk_Evaluation//Staff Folders//Dorian//AQI//")

source("Web/aqi-watch/R/aqi_convert.R")


# Load most recent forecasts
setwd("X://Agency_Files//Outcomes//Risk_Eval_Air_Mod")

#forcs <- readLines("ftp://ftp.airnowapi.org/ReportingArea/reportingarea.dat")

forcs <- read_csv("Air_Modeling/AQI_Forecasting/Tree_Data/Forecast/AQI_Solutions/Values/All_Values.csv")

names(forcs) <- gsub(" ", "_", tolower(names(forcs)))

names(forcs)[7:8] <- c("lat", "long")

# Select maximum AQI value for each site and day
forcs <- forcs %>% rowwise() %>% mutate(max_aqi = max(c(aqi_o3, aqi_pm), na.rm = T))

# Load site data
sites <- read_csv("X:/Agency_Files/Outcomes/Risk_Eval_Air_Mod/_Air_Risk_Evaluation/Staff folders/Dorian/AQI/MET data/Monitors and Rep Wx Stations.csv")

names(sites) <- gsub(" ", "_", tolower(names(sites)))

names(sites)[grepl("short_name", names(sites))] <- "site"

# Switch Voyageurs AQS ID to alt
sites[sites$site_catid == "27-137-9000", "site_catid"] <- sites[sites$site_catid == "27-137-9000", "alt_siteid"]


# Join site data
forcs <- left_join(forcs, sites)


# Interpolate regional concentrations across Minnesota
data <- forcs

# Create state grid
x_size <- diff(range(data$long))/150 #0.00018
y_size <- diff(range(data$lat))/130  #0.00012

grd <- expand.grid(x = seq(from = range(data$long)[1], to = range(data$long)[2], by = x_size),  
                   y = seq(from = range(data$lat)[1], to = range(data$lat)[2], by = y_size))    

coordinates(grd) <- ~x + y

gridded(grd)     <- TRUE

plot(grd)


# Clip to Minnesota border
if(F) {
  mn_border <- get_state("MN")
  
  in_mn <- ggintersect(mn_border, data)
  
  grd  <- filter(grd, id %in% filter(in_mn, !is.na(id)))
}


# Load MN counties
i=0
# Loop through forecast days
for(i in 1:2) {
  
  # Select forecast day
  data <- filter(forcs, dayindex == i)
  
  # Fill missing Ozone forecast for PM sites
  data <- group_by(data, group) %>%
          mutate(aqi_o3 = ifelse(is.na(aqi_o3), mean(aqi_o3, na.rm=T), aqi_o3)) %>%
          rowwise() %>% 
          mutate(max_aqi = max(aqi_o3, aqi_pm, na.rm = T))
  
  # Set circle size
  data$circ_size <- ifelse(grepl("Metro", data$group) |  
                                 data$group == "MSP", 8, 10) 
  
  # Isopleths
  #X     <- cbind(data$long, data$lat)
  #kde2d <- bkde2D(X, bandwidth=c(bw.ucv(X[ ,1]), bw.ucv(X[ ,2])))
  
  names(data)[7:8] <- c("y", "x")
  
  data <- data.frame(data)
  
  coordinates(data) <- ~x + y
  
  # Calculate IDW value at each grid point
  idw    <- idw(formula = max_aqi ~ 1, locations = data, newdata = grd, idp = 1.1, nmax = 2, maxdist = 1000) 
  
  idw_df <- data.frame(idw) 
  
  names(idw_df)[1:3] <- c("long", "lat", "max_aqi")  
  
  
  # Create map 
  data <- idw_df
  
  aqi_colors <- c('#00e400', '#ffff00', '#ff7e00', '#ff0000', '#99004c', '#7e0023')
  
  breaks <- c(0, 50, 100, 150, 200, 300, 700)
  
  data$aqi_color <- cut(data$max_aqi, 
                        breaks = breaks, 
                        labels = aqi_colors,
                        include.lowest = T)
  
  #points(data$long, data$lat, col = data$aqi_color)
  
  if(F) {
    
  data <- mutate(data, 
                 Popup = paste0("<b style='font-size: 150%;'>", 
                                `Site Name`, "</b></br>", 
                                "</br> Date: ", Date),
                                #"</br> AQS-ID: ", AqsID,
                                "</br> AQI forecast: ", AQI_Value,
                                "</br> Concentration: ", Concentration,
                                "</br> Parameter: ", Parameter,
                                "</br> Sampling Hour: ", Time)
  }
  
  
  data$long <- as.numeric(data$long)
  data$lat  <- as.numeric(data$lat)
  
  m <- leaflet(data, width = '99%') %>%
       setView(lat = 46.33, lng = -95.2, zoom = 6) %>%
       addProviderTiles("CartoDB.Positron")
  
  grd_data <- data


for(i in 1:(length(aqi_colors))) {
  
  data <- filter(grd_data, aqi_color == rev(aqi_colors)[i])
  
  if(nrow(data) > 0) {
  
     m %>% addRectangles(lng1 = data$long - x_size/2, 
                         lng2 = data$long + x_size/2,
                         lat1 = data$lat + y_size/2, 
                         lat2 = data$lat - y_size/2,
                         fillColor   = rev(aqi_colors)[i], 
                         fillOpacity = 0.45,
                         opacity     = 0.95,
                         stroke      = F, 
                         popup       = paste0("<b> ", data$max_aqi, 
                                              '<span style="font-style: italic; color: #7e7e7e;"> AQI</span> </b> ')) 
  
  }
}

# Add cities
m <- m %>% addCircleMarkers(~long, ~lat, 
                            popup       = ~site, 
                            radius      = ~circ_size, 
                            fillColor   = ~aqi2color(max_aqi),
                            color       = 'gray',
                            weight      = 2, 
                            fillOpacity = 0.85,
                            opacity     = 0.38)
  
# Print map
m

## Save to PNG image
mapshot(m, file = paste0("\\\\x1600/vol3/Agency_Files/Outcomes/",
                         "Risk_Eval_Air_Mod/_Air_Risk_Evaluation/",
                         "Staff folders/Dorian/AQI/Web/aqi-dashboard/",
                         "images/forecast_map_day", i, ".png"))

# Metro inset map
if(F) {
  metro <- leaflet(data, width = '99%') %>%
           setView(lat = 44.954, lng = -93.26, zoom = 8) %>%
           addProviderTiles("CartoDB.Positron")
  
  metro %>% 
           addCircleMarkers(~long, ~lat, 
                            popup      = ~site, 
                            radius      = 13, 
                            fillColor   = ~aqi2color(max_aqi),
                            color       = 'gray',
                            weight      = 1.7, 
                            fillOpacity = 0.85,
                            opacity     = 0.38)
}

}
##