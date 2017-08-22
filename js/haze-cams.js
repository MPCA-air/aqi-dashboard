$("#haze-cams > .haze-slides:gt(0)").hide();

setInterval(function() { 
  $('#haze-cams > .haze-slides:first')
  .fadeOut(1100)
  .next()
  .fadeIn(1100)
  .end()
  .appendTo('#haze-cams');
},  7000);
