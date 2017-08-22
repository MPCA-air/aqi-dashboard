# Bloom Sky
# Get current visibility images from Minnesota cameras
library(dplyr)
library(rvest)

options(stringsAsFactors = FALSE)

# Set path to phantomjs .exe
phantom_path <- "X:/Agency_Files/Outcomes/Risk_Eval_Air_Mod/_Air_Risk_Evaluation/Staff Folders/Dorian/AQI/Web/phantomjs/bin"

# Load Bloom Sky site list
bloom_sites <- read.csv("data/Bloom Sky site list.csv", stringsAsFactors = F)

#stpaul_url <- "https://map.bloomsky.com/weather-stations/gqBxp6apnJSnmJm3"
#duluth_url <- "http://map.bloomsky.com/weather-stations/gqBxp6apnJSnrpqk"


# Use phantomjs for scraping site
# > phantomjs binaries are here: http://phantomjs.org/
if(FALSE) {
# Write a script phantomjs can process
write(sprintf("var page = require('webpage').create();
                   page.open('%s', function () {
                     console.log(page.content); //page source
                     phantom.exit();
                   });", url), "js\\scrape.js")

}

write_js <- function(site_url  = NULL) {  

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
                }", sitel_url), "scrape.js")
}


get_bloom_img <- function(site_id         = NULL,
                          phantom_js_path = NULL) {  
  
  write_js(site_url = paste0("http://map.bloomsky.com/weather-stations/", site_id))
  
  shell(paste0(substring(phantom_js_path, 1, 2), ' & CD "', phantom_js_path, '" & "phantomjs" scrape.js'))
  
  html_file <- read_html(paste0(phantom_js_path, "/bloomsky.html")) %>% html_nodes("img") %>% html_attr("src")
  
  img_url <- html_file[grepl(site_id, html_file)]
  
  return(img_url)
  
}


stpaul_img <- get_bloom_img(stpaul_url, "js/scrape.js", phantom_path)


# St Paul
write_js(stpaul_url, "js\\scrape.js")
# Run phantomjs to get web page with img link
shell(paste0('X: & CD "', js_path, '" & "../../phantomjs/bin/phantomjs" scrape.js'))

# Use rvest to read html
stpaul <- read_html("js/bloomsky.html") %>% html_nodes("img") %>% html_attr("src")

stpaul_img <- stpaul[grepl("gqBxp6apnJSnmJm3", stpaul)]


# Duluth
write_js(duluth_url, "js\\scrape.js")
shell(paste0('X: & CD "', js_path, '" & "../../phantomjs/bin/phantomjs" scrape.js'))

# Use rvest to read html
duluth <- read_html("js/bloomsky.html") %>% html_nodes("img") %>% html_attr("src")

duluth_img <- duluth[grepl("gqBxp6apnJSnrpqk", duluth)]



##