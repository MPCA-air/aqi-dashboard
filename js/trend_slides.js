$("#aqi-trends > .slides:gt(0)").hide();

setInterval(function() { 
  $('#aqi-trends > .slides:first')
  .fadeOut(800)
  .next()
  .fadeIn(800)
  .end()
  .appendTo('#aqi-trends');
},  10000);
