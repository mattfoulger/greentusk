$(function() {
  var mdconverter = new showdown.Converter();
  var editor = $("#editor");
  var preview = $("#preview");
  var exportHTMLbutton = $("#exportHTMLbutton");

  function convertEditorContents(){
    return mdconverter.makeHtml(editor.val());
  }

  function updatePreview(){
    preview.html(convertEditorContents);
  }

  exportHTMLbutton.on('click', function(){
    document.location.href='/html/'+window.btoa(convertEditorContents())
  });

  updatePreview();

  editor.on('keyup', function(){
   updatePreview();
   console.log('keyup updatePreview');
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

  $("#accordion").on('click', 'a', function(e)
  {
    e.stopPropagation();
    e.preventDefault();
    $.get(this.href).then(function(data)
    {
      editor.val(data);
      updatePreview();
    });
    currentNoteGuid = $(this).attr('id');
    currentNoteTitle = $(this).text();
    $(".submenu a.current").removeClass("current");
    $(this).addClass("current");
    return false;
  });

  var currentNoteGuid = "0";
  var currentNoteTitle = "no title";

  $("#newModal").find(".newnoteform").submit(function(e)
  {
    // get the form data
        // there are many ways to get this data using jQuery (you can use the class or id also)
        var formData = {
            'title'              : $("#newModal").find(".titlefield").val(),
            'notebook_guid'      : $("#newModal").find(".notebook_guid_select").val(),
            'content'            : ""
        };

        // process the form
        $.ajax({
            type        : 'POST', // define the type of HTTP verb we want to use (POST for our form)
            url         : '/notes', // the url where we want to POST
            data        : formData, // our data object
            dataType    : 'json', // what type of data do we expect back from the server
                        encode          : true
        })
            // using the done promise callback
            .done(function(data) {
                $("#newModal").modal('hide');
                // log data to the console so we can see
                console.log(data);
                insertNote(data);
                // here we will handle errors and validation messages
            });

        // stop the form from submitting the normal way and refreshing the page
        event.preventDefault();

    console.log(formData)

  });

// FOR SAVE FUNCTION

  $("#savenoteform").submit(function(e)
  {
    
    // get the form data
        // there are many ways to get this data using jQuery (you can use the class or id also)
        var formData = {
            'guid'               : currentNoteGuid,
            'title'              : currentNoteTitle,
            'content'            : editor.val()
        };

        // process the form
        $.ajax({
            type        : 'PUT', // define the type of HTTP verb we want to use (POST for our form)
            url         : '/notes', // the url where we want to POST
            data        : formData, // our data object
            dataType    : 'json', // what type of data do we expect back from the server
                        encode          : true
        })
            // using the done promise callback
            .done(function(data) {
                $("#newModal").modal('hide');
                // log data to the console so we can see
                console.log(data);
                // here we will handle errors and validation messages
            });

        // stop the form from submitting the normal way and refreshing the page
        event.preventDefault();

    console.log('form submission')
  });

// FOR SAVE AS FUNCTION

$("#saveasModal").find(".newnoteform").submit(function(e)
  {
    // get the form data
   
        var formData = {
            'title'              : $("#saveasModal").find(".titlefield").val(),
            'notebook_guid'      : $("#saveasModal").find(".notebook_guid_select").val(),
            'content'            : editor.val()
        };

        // process the form
        $.ajax({
            type        : 'POST', // define the type of HTTP verb we want to use (POST for our form)
            url         : '/notes', // the url where we want to POST
            data        : formData, // our data object
            dataType    : 'json', // what type of data do we expect back from the server
                        encode          : true
        })
            // using the done promise callback
            .done(function(data) {
                $("#saveasModal").modal('hide');
                // log data to the console so we can see
                console.log(data);
                insertNote(data);
                // here we will handle errors and validation messages
            });

        // stop the form from submitting the normal way and refreshing the page
        event.preventDefault();

    console.log(formData)

  });

  $('[type="submit"]').on('click', function () {
                  $('#success').show().delay(5000).fadeOut();
                });

  function insertNote(data) {
    var notebook_guid = data.notebook_guid;
    var title = data.title;
    var guid = data.guid;
    var newnote = "<li><a id='"+guid+"' class='current' href='/notes/"+guid+"'>"+title+"</a></li>";
    $(".submenu a.current").removeClass("current");
    $("#"+notebook_guid).siblings('ul').prepend(newnote);
    
    // // TO DO: open notebook in accordion and scroll to new note
    // $("#"+notebook_guid).dropdown;
    // $("a.current").ScrollTo();
  }

  $(document).ajaxStart(function(){
    console.log('start ajax');
    $(".submenu a").css({'cursor' : 'wait'});
  });
  $(document).ajaxStop(function(){
    console.log('stopped ajax');
    $(".submenu a").css({'cursor' : 'default'});
  });
});
