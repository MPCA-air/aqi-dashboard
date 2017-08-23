#! /usr/bin/env Rscript

setwd("X:/Agency_Files/Outcomes/Risk_Eval_Air_Mod/_Air_Risk_Evaluation/Staff folders/Dorian/AQI/Web/aqi-dashboard")

current_hour <- as.numeric(format(Sys.time(), "%H"))


if(current_hour > 7 & current_hour < 22) {
  
  saveRDS(current_time, "past_update.rdata")
  
  # Update forecast maps
  print("Updating forecast maps")
  setwd("X:/Agency_Files/Outcomes/Risk_Eval_Air_Mod/_Air_Risk_Evaluation/Staff Folders/Dorian/AQI/Web/aqi-dashboard/R")
  try(source("update_forecast_maps.R"))
  
  
  # Update hourly AQI trends
  print("Updating hourly aqi trends")
  setwd("X:/Agency_Files/Outcomes/Risk_Eval_Air_Mod/_Air_Risk_Evaluation/Staff Folders/Dorian/AQI/Web/aqi-dashboard/R")
  try(source("update_aqi_trends.R"))
  
  
  # Update Bloom Sky haze cameras
  print("Updating haze cameras")
  setwd("X:/Agency_Files/Outcomes/Risk_Eval_Air_Mod/_Air_Risk_Evaluation/Staff Folders/Dorian/AQI/Web/aqi-dashboard/R")
  try(source("update_bloom_sky.R"))
  
  
}