$("#slideshow2 > div:gt(0)").hide();

setInterval(function() { 
  $('#slideshow2 > div:first')
  .fadeOut(800)
  .next()
  .fadeIn(800)
  .end()
  .appendTo('#slideshow2');
},  4000);