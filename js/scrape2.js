var url ='https://map.bloomsky.com/weather-stations/gqBxp6apnJSnmJm3';
               var page = new WebPage()
               var fs = require('fs');
              
              
              page.open(url, function (status) {
              just_wait();
              });
              
              function just_wait() {
              setTimeout(function() {
              fs.write('stpaul2.html', page.content, 'w');
              phantom.exit();
              }, 2500);
              }
