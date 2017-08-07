library(dplyr)
library(rvest)

options(stringsAsFactors = FALSE)


# Bloom Sky
# Get current St. Paul visibility image

# Use phantomjs for scraping site
# > phantomjs binaries are here: http://phantomjs.org/
stpaul_url <- "https://map.bloomsky.com/weather-stations/gqBxp6apnJSnmJm3"

duluth_url <- "http://map.bloomsky.com/weather-stations/gqBxp6apnJSnrpqk"

if(FALSE) {
# Write a script phantomjs can process
write(sprintf("var page = require('webpage').create();
                   page.open('%s', function () {
                     console.log(page.content); //page source
                     phantom.exit();
                   });", url), "js\\scrape.js")


write_js <- function(site_url, file_name) {  
write(sprintf("var url ='%s';
               var page = new WebPage()
               var fs = require('fs');
              
              
              page.open(url, function (status) {
              just_wait();
              });
              
              function just_wait() {
              setTimeout(function() {
              fs.write('stpaul.html', page.content, 'w');
              phantom.exit();
              }, 2500);
              }", sitel_url), file_name)
}

write_js(stpaul_url, "js\\scrape_stpaul.js")

write_js(duluth_url, "js\\scrape_duluth.js")
}

folder_path <- "X:/Agency_Files/Outcomes/Risk_Eval_Air_Mod/_Air_Risk_Evaluation/Staff Folders/Dorian/AQI/Web/aqi-dashboard/js"


# St Paul
# Run phantomjs to get web page with img link
shell(paste0('X: & CD "', folder_path, '" & "phantomjs/bin/phantomjs" scrape_duluth.js'))

# Use rvest to read html
stpaul <- read_html("js/stpaul.html") %>% html_nodes("img") %>% html_attr("src")

stpaul_img <- stpaul[grepl("gqBxp6apnJSnmJm3", stpaul)]


# Duluth
shell(paste0('X: & CD "', folder_path, '" & "phantomjs/bin/phantomjs" scrape_duluth.js'))

# Use rvest to read html
duluth <- read_html("js/stpaul2.html") %>% html_nodes("img") %>% html_attr("src")

duluth_img <- duluth[grepl("gqBxp6apnJSnrpqk", duluth)]



##