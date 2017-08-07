$("#slide-titles > div:gt(0)").hide();

setInterval(function() { 
  $('#slide-titles > div:first')
  .fadeOut(800)
  .next()
  .fadeIn(800)
  .end()
  .appendTo('#slide-titles');
},  4000);