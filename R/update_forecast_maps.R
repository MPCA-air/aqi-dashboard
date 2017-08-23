# Update AQI forecast maps

library(ggplot2)
library(dplyr)
library(readr)
library(leaflet)
library(mapview)
library(magick)


map_grid <- FALSE

if(map_grid) {
  library(gstat)
  library(sp)
  library(rgdal)
  library(rgeos)
  library(maptools)
}
  
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
if(map_grid) {
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
}


# Load MN counties

# Loop through forecast days
for(f_day in 1:2) {
  
  # Select forecast day
  data <- filter(forcs, dayindex == f_day)
  
  # Fill missing Ozone forecast for PM sites
  data <- group_by(data, group) %>%
          mutate(aqi_o3 = ifelse(is.na(aqi_o3), mean(aqi_o3, na.rm=T), aqi_o3)) %>%
          rowwise() %>% 
          mutate(max_aqi = max(aqi_o3, aqi_pm, na.rm = T))
  
  # Random data
  #data$max_aqi <- sample(1:120, nrow(data))
  
  # Set circle size
  data$circle_size <- ifelse(grepl("Metro", data$group) |  
                                 data$group == "MSP", 8, 9.5) 
  
  # Isopleths
  #X     <- cbind(data$long, data$lat)
  #kde2d <- bkde2D(X, bandwidth=c(bw.ucv(X[ ,1]), bw.ucv(X[ ,2])))
  
  if(map_grid) {
  
    names(data)[7:8] <- c("y", "x")
    
    data <- data.frame(data)
    
    coordinates(data) <- ~x + y
    
    # Calculate IDW value at each grid point
    idw    <- idw(formula = max_aqi ~ 1, locations = data, newdata = grd, idp = 1.1, nmax = 2, maxdist = 1000) 
    
    idw_df <- data.frame(idw) 
    
    names(idw_df)[1:3] <- c("long", "lat", "max_aqi")  
    
    
    # Create map 
    data <- idw_df
  }
  
  aqi_colors <- c('#00e400', '#ffff00', '#ff7e00', '#ff0000', '#99004c', '#7e0023')
  
  green_scale <- colorRampPalette(c('#00e400', '#BFF800'))
  
  yellow_scale <- colorRampPalette(c('#ffff00', '#FFDE00'))
  
  #plot(rep(1,5), col = yellow_scale(5), pch = 19, cex = 3)
  
  breaks <- c(0, 50, 100, 150, 200, 300, 700)
  
  scale_breaks <- c(0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 150, 200, 300, 700)
  
  data$aqi_color <- cut(data$max_aqi, 
                        breaks = scale_breaks, 
                        labels = c(green_scale(5), yellow_scale(5), aqi_colors[-(1:2)]),
                        include.lowest = T)
  
  #points(data$long, data$lat, col = data$aqi_color)
  
  # Add popup info
  if(F) {
  data <- mutate(data, 
                 Popup = paste0("<b style='font-size: 160%;'>", 
                                site, "</b>date</br>",
                                "</br> AQI forecast: ", max_aqi,
                                "</br> Parameter: ", ifelse(aqi_o3 >= aqi_pm, "Ozone", "PM2.5")))
  }
  
  data$long <- as.numeric(data$long)
  data$lat  <- as.numeric(data$lat)
  
  m <- leaflet(data, width = '500px', height = '460px') %>%
       setView(lat = 46.33, lng = -94.2, zoom = 6) %>%
       addProviderTiles(providers$Stamen.Watercolor,
                        options = providerTileOptions(opacity = 0.85)) %>%
       addProviderTiles("CartoDB.PositronNoLabels",
                        options = providerTileOptions(opacity = 0.80)) %>%
       addProviderTiles("CartoDB.PositronOnlyLabels")
  
  # Add cities
  m <- m %>% addCircleMarkers(~long, ~lat, 
                              popup       = ~site, #Popup 
                              radius      = ~circle_size, 
                              fillColor   = ~aqi_color,  #~aqi2color(max_aqi),
                              color       = 'gray',
                              weight      = 2, 
                              fillOpacity = 0.99,
                              opacity     = 0.55)
  
  # Print map
  m

## Save to PNG image
img_path <- paste0("X://Agency_Files/Outcomes/",
                   "Risk_Eval_Air_Mod/_Air_Risk_Evaluation/",
                   "Staff folders/Dorian/AQI/Web/aqi-dashboard/",
                   "images/forecast_map_day", f_day, ".png")

mapshot(m, file = img_path)

map_img <- image_read(img_path)

map_img <-  image_crop(map_img, "390x425+86")

# Save cropped image
image_write(map_img, path = img_path, format = "png")



if(map_grid) { 
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
}


# Metro inset map
if(F) {
  metro <- leaflet(data, width = '99%') %>%
           setView(lat = 44.954, lng = -93.26, zoom = 8) %>%
           addProviderTiles("CartoDB.Positron")
  
  metro %>% addCircleMarkers(~long, ~lat, 
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