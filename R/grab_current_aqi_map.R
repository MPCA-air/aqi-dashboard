# Download current AQI map as PNG image

library(webshot)
library(magick)

map_url <- "https://mpca.sonomatechdata.com/reportingarea/contourMap"

file_path <- paste0("X://Agency_Files/Outcomes/",
                    "Risk_Eval_Air_Mod/_Air_Risk_Evaluation/",
                    "Staff folders/Dorian/AQI/Web/aqi-dashboard/",
                    "images/current_map.png")

webshot(map_url, file = file_path, zoom = 2)

map <- image_read(file_path)

map <- image_crop(map, "794x764+598+92")
#map2 <- image_crop(map, "400x428+296+26")

#map

image_write(map, path = file_path, format = "png")

##