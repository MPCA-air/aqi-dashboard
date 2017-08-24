# Update AQI trend charts

library(ggplot2)
library(dplyr)
library(readr)
library(magick)
library(tidyr)

#require(installr) 
#install.ImageMagick()

# AQI color functions
setwd("X://Agency_Files//Outcomes//Risk_Eval_Air_Mod//_Air_Risk_Evaluation//Staff Folders//Dorian//AQI//")

source("Web/aqi-watch/R/aqi_convert.R")

# Load credentials
creds <- read_csv("C:/Users/dkvale/Desktop/credentials.csv")

# Size adjustment
size_adjust <- 0.63


# Current hour
current_hr <- as.numeric(format(Sys.time() - 42 * 60, "%H"))


# Load most recent forecasts from AirNow
aqi_o3 <- readLines(paste0("ftp://", creds$user, ":", creds$pwd, "@ftp.airnowapi.org/ObsFiles/today_ozone.obs"))
aqi_pm <- readLines(paste0("ftp://", creds$user, ":", creds$pwd, "@ftp.airnowapi.org/ObsFiles/today_pmfine.obs"))


# Trim data to hourly observations
aqi_o3 <- aqi_o3[(1+grep("BEGIN_DATA", aqi_o3)[1]):(1+grep("END_DATA", aqi_o3)[1])] 
aqi_pm <- aqi_pm[(1+grep("BEGIN_DATA", aqi_pm)[1]):(1+grep("END_DATA", aqi_pm)[1])]


# Store in data frame
aqi_o3  <- gsub("[|]", ",", aqi_o3)
aqi_pm  <- gsub("[|]", ",", aqi_pm)

aqi_o3 <- read_csv(paste0(aqi_o3, collapse = "\n"), col_names = F)
aqi_pm <- read_csv(paste0(aqi_pm, collapse = "\n"), col_names = F)


# Set names
names(aqi_o3) <- c("site", "aqs_id", 0:(ncol(aqi_o3)-3)) 
names(aqi_pm) <- c("site", "aqs_id", 0:(ncol(aqi_pm)-3)) 


# Add param, date, and units
aqi_o3$param <- "ozone"
aqi_pm$param <- "pm"


# Join parameters
aqi <- bind_rows(aqi_pm, aqi_o3)


# Filter sites
aqi <- filter(aqi, 
              substring(aqs_id, 1,2) %in% "27" | 
                site %in% c("Fargo NW", "LACROSSE DOT"),
              !is.na(as.numeric(`0`)))

unique(aqi$site)

# Limit to 12 observations
start_col <- max(0, current_hr - 11) + 3

aqi <- aqi[ , c(1,2,ncol(aqi), start_col:(start_col + 11))]


# Flip to tall format
aqi <- gather(aqi, key = time, value = aqi, -site, -aqs_id, -param, na.rm = FALSE)


# Replace -999's and extreme values with NAs
aqi <- aqi %>%
       rowwise() %>%
       mutate(aqi = as.numeric(aqi),
              aqi = ifelse(aqi < -99, NA, aqi),
              aqi = ifelse(aqi < 1, 1, aqi),
              aqi = ifelse(aqi > 499, NA, aqi),
              aqi = ifelse(aqi > 300, 300, aqi))


# Add time and row columns
aqi$aqi  <- as.integer(aqi$aqi)

aqi$time <- as.integer(aqi$time)

aqi$row  <- 12


# Background colors
aqi_refs <- data.frame(xstart = c(seq(0,150,50), 200, 300),
                       xend   = c(seq(50,200,50), 300, 500),
                       col    = c("#53BF33", "#F4C60B", "#DB6B1A", "#c81d25", "#52154E", "#4c061d"), 
                       stringsAsFactors = F)
    
aqi_refs$col <- factor(aqi_refs$col, ordered = T, levels = aqi_refs$col)
  

# Drop irregular sites
aqi <- filter(aqi, !site %in% c("Stanton", "Red Lake Nation"))

# Consolidate Minneapolis and Duluth sites
aqi[grepl("Minneap", aqi$site) | grepl("Paul", aqi$site), ]$site <- "Minneapolis"

aqi[grepl("Duluth", aqi$site), ]$site <- "Duluth"

aqi <- group_by(aqi, site, param, time, row) %>%
       summarize(aqi    = round(mean(aqi, na.rm = T)),
                 aqs_id = max(aqs_id, na.rm=T)) %>%
       ungroup()

# Join public site names
pub_names <- read_csv("X://Agency_Files//Outcomes//Risk_Eval_Air_Mod//_Air_Risk_Evaluation//Staff Folders//Dorian//AQI//Verification/AQI History/Names for history charts.csv")

sites_aqs <- read_csv("X:/Agency_Files/Outcomes/Risk_Eval_Air_Mod/_Air_Risk_Evaluation/Staff folders/Dorian/AQI/MET data/Monitors and Rep Wx Stations.csv")

names(sites_aqs) <- gsub(" ", "_", tolower(names(sites_aqs)))

names(sites_aqs)[grepl("site_catid", names(sites_aqs))] <- "aqs_id"

sites_aqs$aqs_id <- gsub("-", "", sites_aqs$aqs_id )

pub_names <- left_join(pub_names, select(sites_aqs, short_name, aqs_id))

aqi <- left_join(aqi, pub_names)


# Update missing public names
aqi[aqi$site == "Voyageurs NP", ]$hist_name <- "Voyageurs NP"
aqi[aqi$site == "Duluth", ]$hist_name <- "Duluth"
aqi[aqi$site == "Minneapolis", ]$hist_name <- "State Fair"


# Group South metro area
aqi[grepl("S-Metro", aqi$hist_name), ]$hist_name <- "South Metro"

aqi <- group_by(aqi, hist_name, param, time, row) %>%
       summarize(aqi    = round(mean(aqi, na.rm = T)),
                 aqs_id = max(aqs_id, na.rm=T)) %>%
       ungroup()



# Save site list
write_csv(aqi[!duplicated(aqi$hist_name), ], "X://Agency_Files//Outcomes//Risk_Eval_Air_Mod//_Air_Risk_Evaluation//Staff Folders//Dorian//AQI//Web//aqi-dashboard//data//aqi_hourly_sites.csv")



# Prep for plot loop
setwd("C:/Users/dkvale/Desktop/aqi/trend_charts/")

par(mar=c(0,0,0,0))

site_x  <- aqi$hist_name[1]

param_x <- aqi$param[1]

start_tm <- Sys.time()

for(site_x in c("State Fair", unique(aqi$hist_name)[!grepl("State Fair", unique(aqi$hist_name))])[c(1,3:5,2,6:9,10:12,14:15)]) {
  
  print(Sys.time() - start_tm)
  
  print(site_x)
  
  aqi_site <- filter(aqi, hist_name == site_x) 
  
  for(param_x in unique(aqi_site$param)) {
    
    # Empty chart folder
    shell("C: & CD C:/Users/dkvale/Desktop/aqi/trend_charts/ & del /F /Q *")
    
    img_count <- 0  
  
  # Select site data  
  aqi2 <- filter(aqi_site, param == param_x) %>%
          arrange(time)
  
  
  # Limit to last 12 hours
  aqi2 <- filter(aqi2, time > max(aqi2$time, na.rm = T) - 12)
  
  
  # Add buffer data to extend plot
  pre_na <- aqi2[1, ] %>% 
            mutate(time = time - 1, aqi  = NA)
  
  post_na <- aqi2[nrow(aqi2), ] %>% 
             mutate(time = time + 1, aqi  = NA)
  
  aqi2 <- bind_rows(pre_na, aqi2, post_na)
  
  aqi2$row <- 0:13
  
  time_labels <- c("", aqi2$time[-c(1, nrow(aqi2))], "")
  
for(i in 2:13) {
      
  aqi_cut <- aqi2[1:i, ]
      
  aqi_last <- aqi2[2:max(c(2, i-1)), ]
      
  aqi_new <- aqi2[i, ]
      
  for(z in seq(1, 37, 2)) {
        
        print(img_count)
    
        img_count <- img_count + 1
        
        p <- ggplot() +
          geom_rect(data = aqi_refs, aes(ymin = xstart, ymax = xend, 
                                         xmin = 0, xmax = 13, 
                                         fill = col), alpha = 0.74) 
        
        # Background line
        p <- p + 
          geom_line(data = aqi2[!is.na(aqi2$aqi), ], aes(x = row, y = aqi), size =1.1*size_adjust, color="grey40", alpha = 0.08) +
          geom_point(data = aqi2[!is.na(aqi2$aqi), ], aes(x = row, y = aqi), color = "grey40",  size = 4*size_adjust, alpha = 0.06)
        
        
        
        # Connecting lines
        if(z < 25 && nrow(aqi_cut) > 1) {
          p <- p + 
            geom_line(data = aqi_last, aes(x = row, y = aqi * .996), size =1.1*size_adjust, color="grey20", alpha = 0.15) +
            geom_line(data = aqi_last, aes(x = row, y = aqi), size =1*size_adjust, color="grey40", alpha = 0.65)
        }  
        
        if(z >= 25 && nrow(aqi_cut) > 1) {
          p <- p + 
            geom_line(data = aqi_cut, aes(x = row, y = aqi * .996), size =1.1*size_adjust, color="grey20", alpha = 0.15) +
            geom_line(data = aqi_cut, aes(x = row, y = aqi), size =1*size_adjust, color="grey40", alpha = 0.65) 
        }  
        
        
        # Previous points
        p <- p + 
          geom_point(data = aqi_last, aes(x = row, y = aqi), color = "grey50", size = 4.5*size_adjust) +
          geom_point(data = aqi_last, aes(x = row, y = aqi), color = "white", size = 4*size_adjust)
        
        # New point
        if(z >= 25) {
          p <- p + 
            geom_point(data = aqi_new, aes(x = row, y = aqi), color = "grey50", size = 4.5*size_adjust, alpha = .8) +
            geom_point(data = aqi_new, aes(x = row, y = aqi), color = "white", size = 4*size_adjust, alpha = .8) 
        }
        
        # Ripple effect
        if(z < 29) p <- p + 
          geom_point(data = aqi_new, aes(x = row, y = aqi), color = "grey50", size = 0.8*z**0.81*size_adjust, alpha = 0.15 + 0.025 * abs(27-z), pch=21) 
        
        # Fade in white circle
        if(z < 25 && z > 9) { 
          p <- p + 
            geom_point(data = aqi_new, aes(x = row, y = aqi), color = "white", size = 0.8*(z-10)**0.54 *size_adjust, alpha = .83 - 0.03 * abs(24-z)) 
        }
        
        
        if(z < 29 && z > 3) { 
          p <- p + 
            geom_label(data    = aqi_new,
                       aes(x = row, y = aqi + 35 - 70 * (aqi > 105), label = aqi), 
                       color   = "grey40", 
                       size    = size_adjust * 4.2 - 0.047 * abs(27-z), 
                       alpha   = .95 - 0.025 * abs(28-z),
                       family  = c("serif", "mono")[2])
        }
        
        if(z >= 29 && z < 37) { 
          p <- p + 
            geom_label(data    = aqi_new,
                       aes(x = row, y = aqi + 35 - 70 * (aqi > 105), label = aqi), 
                       color   = "grey40", 
                       size    = 4.2 * size_adjust, 
                       alpha   = .95,
                       family  = c("serif", "mono")[2])
        }
        
        
        p <- p +
          guides(fill = "none") +
          scale_fill_manual(values = as.character(aqi_refs$col)) +
          labs(x = NULL, y = NULL) + 
          #labs(subtitle = "Air Quality Index") +
          scale_x_continuous(breaks = aqi2$row, labels = time_labels, expand=c(0,0)) + 
          scale_y_continuous(limits=c(0, min(c(seq(150, 200, 50), 300, 500)[c(seq(150, 200, 50), 300, 500) >= max(aqi2$aqi, na.rm=T)])), 
                             expand=c(0,0)) + 
          theme_bw() + 
          theme(panel.border = element_blank(), 
                panel.background = element_blank(),
                panel.grid.minor= element_blank(), 
                panel.grid.major = element_blank(),
                axis.text.y = element_text(size=7.5*size_adjust*1.3),
                axis.text.x = element_text(size=6*size_adjust*1.25),
                plot.subtitle = element_text(size=8.2*size_adjust, color="grey30"),
                axis.ticks = element_line(size = 0.25),
                axis.ticks.length = unit(.04, "cm"))
        
        p
        
        #ggsave(paste0(img_count, ".png"), width=4, height=1.7)
        ggsave(paste0(img_count, ".png"), width=4, height=0.82)
        
      }
      
      if(i == 13) for(y in 1:5) {
        img_count <- img_count + 1
        #ggsave(paste0(img_count, ".png"), width=4, height=1.7)
        ggsave(paste0(img_count, ".png"), width=4, height=0.82) 
      }
      
    }
    
    list.files() %>% 
      .[grepl("png", .)] %>% 
      .[order(as.numeric(sub("([0-9]*).*", "\\1", .)))] %>% 
      image_read() %>%
      image_join() %>%
      image_animate(fps=(20)) %>%
      image_write(paste0("X://Agency_Files//Outcomes//Risk_Eval_Air_Mod//_Air_Risk_Evaluation//Staff Folders//Dorian//AQI//Web//aqi-dashboard//images//", param_x, "_chart_", site_x, ".gif"))
    
  }
  }
