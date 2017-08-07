$("#slideshow > div:gt(0)").hide();

setInterval(function() { 
  $('#slideshow > div:first')
    .fadeOut(800)
    .next()
    .fadeIn(800)
    .end()
    .appendTo('#slideshow');
},  4000);