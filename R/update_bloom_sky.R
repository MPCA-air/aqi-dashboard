# Bloom Sky
# Get current visibility images from Minnesota cameras
library(dplyr)
library(rvest)

options(stringsAsFactors = FALSE)

setwd("X:/Agency_Files/Outcomes/Risk_Eval_Air_Mod/_Air_Risk_Evaluation/Staff Folders/Dorian/AQI/Web/aqi-dashboard")

# Set path to phantomjs .exe
phantom_path <- "X:/Agency_Files/Outcomes/Risk_Eval_Air_Mod/_Air_Risk_Evaluation/Staff Folders/Dorian/AQI/Web/phantomjs/bin/"

# Load Bloom Sky site list
bloom_sites  <- read.csv("data/Bloom Sky site list.csv", stringsAsFactors = F)

bloom_sites  <- bloom_sites[-c(1:2), ]


# MPCA haze cam links
#grand_img    <- "http://www.mwhazecam.net/CreateMain.aspx?t=main&p=images/photos-main/GRAND.jpg"
#bwca_img     <- "http://www.fsvisimages.com/images/photos-main/bowa1_main.jpg"


# Use phantomjs for scraping site
# Download phantomjs binaries here: http://phantomjs.org/
write_js <- function(file_name = NULL, 
                     site_url  = NULL) {  

  write(sprintf("var url ='%s';
                 var page = new WebPage()
                 var fs = require('fs');
                
                page.open(url, function (status) {
                just_wait();
                });
                
                function just_wait() {
                setTimeout(function() {
                fs.write('bloomsky.html', page.content, 'w');
                phantom.exit();
                }, 2500);
                }", site_url), file_name)
}


get_bloom_img <- function(site_id         = NULL,
                          phantom_js_path = NULL) {  
  print(site_id)
  
  if(!is.null(site_id) & !is.na(site_id) ) {
  
    write_js(file_name = paste0(phantom_js_path, "scrape.js"),
             site_url  = paste0("http://map.bloomsky.com/weather-stations/", site_id))
    
    shell(paste0(substring(phantom_js_path, 1, 2), ' & CD "', phantom_js_path, '" & "phantomjs" scrape.js'))
    
    html_file <- read_html(paste0(phantom_js_path, "/bloomsky.html")) %>% html_nodes("img") %>% html_attr("src")
    
    img_url   <- html_file[grepl(site_id, html_file)]
    
    if(!is.na(img_url)) return(img_url)
  }
  
}

#Test
#stpaul_img <- get_bloom_img(bloom_sites$bloom_id[1], phantom_path)

# Update all Bloom Sky sites
bloom_sites <- bloom_sites %>% 
               rowwise() %>%
               mutate(bloom_img = ifelse(is.na(bloom_id), bloom_img, get_bloom_img(bloom_id, phantom_path)))


# Duplicate St. Paul site to make total divisible by 4
rownames(bloom_sites) <- 1:nrow(bloom_sites)

bloom_sites <- bloom_sites[c(14,15,1:30), ]


# Assign group numbers
bloom_sites$group <- rep(1:8, each = 4)

# Save table
write.csv(bloom_sites, "data/Bloom Sky site list.csv", row.names = F)


# Create time-lapse images


##