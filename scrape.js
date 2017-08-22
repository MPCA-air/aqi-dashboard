var url ='http://map.bloomsky.com/weather-stations/gqBxp6apnJSnmpil';
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
                }
