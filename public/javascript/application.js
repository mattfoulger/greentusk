$(function() {
  var mdconverter = new showdown.Converter();
  var editor = $("#editor");
  var preview = $("#preview");

  function updatePreview(){
    preview.html(mdconverter.makeHtml(editor.val()));
  }

  updatePreview();

  editor.on('keyup', function(){
   updatePreview();
  });

  var Accordion = function(el, multiple) {
    this.el = el || {};
    this.multiple = multiple || false;

    // Variables privadas
    var links = this.el.find('.link');
    // Evento
    links.on('click', {el: this.el, multiple: this.multiple}, this.dropdown)
  }

  Accordion.prototype.dropdown = function(e) {
    var $el = e.data.el;
      $this = $(this),
      $next = $this.next();

    $next.slideToggle();
    $this.parent().toggleClass('open');

    if (!e.data.multiple) {
      $el.find('.submenu').not($next).slideUp().parent().removeClass('open');
    };
  } 

  var accordion = new Accordion($('#accordion'), false);

  $("#accordion").on('click', 'a.note-link', function(e)
  {
    e.stopPropagation();
    e.preventDefault();
    $.get(this.href).then(function(data)
    {
      editor.text(data);
      updatePreview();
    });
    return false;
  });

  $(document).ajaxStart(function(){
    console.log('start ajax');
    $(".submenu a").css({'cursor' : 'wait'});
  });
  $(document).ajaxStop(function(){
    console.log('stopped ajax');
    $(".submenu a").css({'cursor' : 'default'});
  });
});
