$("#city-titles > div:gt(0)").hide();

setInterval(function() { 
  $('#city-titles > div:first')
  .fadeOut(600)
  .next()
  .fadeIn(600)
  .end()
  .appendTo('#city-titles');
},  10000);

$("#o3-trends > div:gt(0)").hide();

setInterval(function() { 
  $('#o3-trends > div:first')
    .fadeOut(800)
    .next()
    .fadeIn(800)
    .end()
    .appendTo('#o3-trends');
  },  10000);

$("#pm-trends > .slides:gt(0)").hide();

setInterval(function() { 
  $('#pm-trends > .slides:first')
  .fadeOut(800)
  .next()
  .fadeIn(800)
  .end()
  .appendTo('#pm-trends');
},  10000);


$("#aqi-trends > .slides:gt(0)").hide();

setInterval(function() { 
  $('#aqi-trends > .slides:first')
  .fadeOut(800)
  .next()
  .fadeIn(800)
  .end()
  .appendTo('#aqi-trends');
},  10000);
