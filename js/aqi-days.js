$("#aqi-days > .day-slides:gt(0)").hide();

setInterval(function() { 
  $('#aqi-days > .day-slides:first')
  .fadeOut(900)
  .next()
  .fadeIn(900)
  .end()
  .appendTo('#aqi-days');
},  9900);
