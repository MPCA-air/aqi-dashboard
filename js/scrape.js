var page = require('webpage').create();
                   page.open('https://map.bloomsky.com/weather-stations/gqBxp6apnJSnmJm3', function () {
                     console.log(page.content); //page source
                     phantom.exit();
                   });
