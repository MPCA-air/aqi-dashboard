#! /usr/bin/env Rscript

setwd("X:/Agency_Files/Outcomes/Risk_Eval_Air_Mod/_Air_Risk_Evaluation/Staff folders/Dorian/AQI/Web/aqi-dashboard")

current_hour <- as.numeric(format(Sys.time(), "%H"))

# Load credentials
creds <- read_csv("C:/Users/dkvale/Desktop/credentials.csv")


if(current_hour > 6 & current_hour < 22) {
  
  # Update current AQI map
  print("Updating current AQI map")
  setwd("X:/Agency_Files/Outcomes/Risk_Eval_Air_Mod/_Air_Risk_Evaluation/Staff Folders/Dorian/AQI/Web/aqi-dashboard/R")
  try(source("grab_current_aqi_map.R"))
  
  
  # Update hourly AQI trends
  #print("Updating hourly aqi trends")
  #setwd("X:/Agency_Files/Outcomes/Risk_Eval_Air_Mod/_Air_Risk_Evaluation/Staff Folders/Dorian/AQI/Web/aqi-dashboard/R")
  #try(source("update_aqi_trends.R"))
  
  
  # Update Bloom Sky haze cameras
  #print("Updating haze cameras")
  #setwd("X:/Agency_Files/Outcomes/Risk_Eval_Air_Mod/_Air_Risk_Evaluation/Staff Folders/Dorian/AQI/Web/aqi-dashboard/R")
  #try(source("update_bloom_sky.R"))
  
  
  # Push to GitHub
  git <- 'X: & CD "X:/Agency_Files/Outcomes/Risk_Eval_Air_Mod/_Air_Risk_Evaluation/Staff folders/Dorian/AQI/Web/aqi-dashboard/" & "C:/Users/dkvale/AppData/Local/Programs/Git/bin/git.exe" '
    
  #shell(paste0(git, "add ozone_chart.gif"))
    
  commit <- paste0(git, 'commit -a -m ', '"update aqi charts"')
    
  shell(commit)
    
  shell(paste0(git, "config --global user.name dkvale"))
  shell(paste0(git, "config --global user.email ", creds$email))
  shell(paste0(git, "config credential.helper store"))
    
  push <- paste0(git, "push -f origin master")
    
  shell(push)
  
}