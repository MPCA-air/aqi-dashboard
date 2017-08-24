$("#aqi-trends > .slides:gt(0)").hide();

setInterval(function() { 
  $('#aqi-trends > .slides:first')
  .fadeOut(700)
  .next()
  .fadeIn(700)
  .end()
  .appendTo('#aqi-trends');
},  11500);
