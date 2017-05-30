window.jazzy = {'docset': false}
if (typeof window.dash != 'undefined') {
  document.documentElement.className += ' dash'
  window.jazzy.docset = true
}
if (navigator.userAgent.match(/xcode/i)) {
  document.documentElement.className += ' xcode'
  window.jazzy.docset = true
}

// On doc load, toggle the URL hash discussion if present
$(document).ready(function() {
  if (!window.jazzy.docset) {
    var linkToHash = $('a[href="' + window.location.hash +'"]');
    linkToHash.trigger("click");
  }
});

// Do some other stuff on window load
$(window).load(function() {
  refreshFixedHeader();
  fillCodeBlocksWithLanguageTag();
  if ((window.location.pathname.indexOf('index.html') != -1) ||
      (window.location.pathname.indexOf('.html') == -1))
    $('head style.nav-group-highlight-style').remove();
  $('li.nav-group-name[data-name="Guides"]').remove();
  var orderedPrefixes = ["TravelKit", "TKPlace", "TKTour", "TKMedium", "TKReference", "TKMap"].reverse();
  $.each(orderedPrefixes, function(i,e){
    var elms = $('li.nav-group-task[data-name*="'+e+'"]').toArray().reverse();
    $.each(elms, function(i,e){
      $(e).parent().prepend(e);
    });
  });
});

// On token click, toggle its discussion and animate token.marginLeft
$(".token").click(function(event) {
  if (window.jazzy.docset) {
    return;
  }
  var link = $(this);
  var linkIcon = link.find('.token-icon');
  var animationDuration = 300;
  var tokenOffset = "0px";
  var original = link.css('marginLeft') == tokenOffset;
  linkIcon.toggleClass('token-icon-minus');
  link.animate({'margin-left':original ? "0px" : tokenOffset}, animationDuration);
  $content = link.parent().parent().next();
  $content.slideToggle(animationDuration);

  // Keeps the document from jumping to the hash.
  var href = $(this).attr('href');
  if (history.pushState) {
    history.pushState({}, '', href);
  } else {
    location.hash = href;
  }
  event.preventDefault();
});

// Dumb down quotes within code blocks that delimit strings instead of quotations.
$("code q").replaceWith(function () {
  return ["\"", $(this).contents(), "\""];
});

// Customisations
function refreshFixedHeader() {
  $('.breadcrumbs').css('top', $('.header-container').height()+'px');
  $('.content-wrapper').css("cssText", "padding-top: "+ ($('.header-container').height() + $('.breadcrumbs').height()) + 'px !important');
}

function fillCodeBlocksWithLanguageTag() {
  $.each($('.highlight.objective_c'), function(i,o){ o.innerHTML = '<div><span class="codeblock-inserted-heading">Objective-C</span></div>'+o.innerHTML });
  $.each($('.highlight.swift'), function(i,o){ o.innerHTML = '<div><span class="codeblock-inserted-heading">Swift</span></div>'+o.innerHTML });
  $.each($('.highlight.json'), function(i,o){ o.innerHTML = '<div><span class="codeblock-inserted-heading">JSON</span></div>'+o.innerHTML });
}

$(window).resize(function() {
  refreshFixedHeader();
});
