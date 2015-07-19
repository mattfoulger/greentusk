$(function() {
  var mdconverter = new showdown.Converter();
  var editor = $("#editor");
  var preview = $("#preview");

  var currentNoteGuid = "0";
  var currentNoteTitle = "Untitled note";

  function convertEditorContents(){
    return mdconverter.makeHtml(editor.val());
  }

  function updatePreview(){
    preview.html(convertEditorContents);
  }

  $("#exportHTML").on('click', function(){
    if (editor.val() == "") {
      // error handling
    } else {
      document.location.href='/html/'+window.btoa(currentNoteTitle)+'/'+window.btoa(convertEditorContents())
    }
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

  // load a note when it is clicked in our menu
  $("#accordion").on('click', 'a', function(e) {
    e.stopPropagation();
    e.preventDefault();
    loadNote($(this).attr('id'));
    return false;
  });

  // Load a note
  function loadNote(guid) {
    selectedNote = $("#"+guid);
    // Make a GET request to the server for the href of the
    // link whose id matches the guid of the note.
    // Then populate the editor with the data that the server
    // returns, and update the preview as well.
    $.get(selectedNote.attr("href")).then(function(data)
    {
      editor.val(data);
      updatePreview();
    });
    // Update the variables to keep track of which note is selected
    currentNoteGuid = guid;
    currentNoteTitle = selectedNote.text();
    // Toggle the styles to show the selected note
    $(".submenu a.current").removeClass("current");
    selectedNote.addClass("current");
  }

  // Insert a note into the DOM and load it up using loadNote
  function insertNote(data) {
    var notebook_guid = data.notebook_guid;
    var title = data.title;
    var guid = data.guid;
    var newnote = "<li><a id='"+guid+"' href='/notes/"+guid+"'>"+title+"</a></li>";
    
    $("#"+notebook_guid).siblings('ul').prepend(newnote);
    loadNote(guid);
    // // TO DO: open notebook in accordion and scroll to new note
    // $("#"+notebook_guid).dropdown;
    // $("a.current").ScrollTo();
  }

  $("#newModal").find(".newnoteform").submit(function(e)
  {
    // get the form data
    var formData = {
        'title'              : $("#newModal").find(".titlefield").val(),
        'notebook_guid'      : $("#newModal").find(".notebook_guid_select").val(),
        'content'            : "## New markdown note"
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
            // TODO: handle errors and validation messages
            insertNote(data);
            notification("success", "Your new note, '" + currentNoteTitle + "', has been created.");
        });

    // stop the form from submitting the normal way and refreshing the page
    event.preventDefault();
  });

// FOR SAVE FUNCTION

  $("#savenote").on('click', (function(e) {
    // get the form data
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
            // TODO: handle errors and validation messages
            notification("success", "Your note, '" + currentNoteTitle + "', has been saved.");
        });
    // stop the form from submitting the normal way and refreshing the page
    event.preventDefault();
  }));

// FOR SAVE AS FUNCTION

$("#saveasModal").find(".newnoteform").submit(function(e) {
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
            // TODO: handle errors and validation messages
            insertNote(data);
            notification("success", "Your new note, '" + currentNoteTitle + "', has been created.");
        });
    // stop the form from submitting the normal way and refreshing the page
    event.preventDefault();
  });


  // TODO: create a function for more versatile notifications
  // TODO: call the function from AJAX .done callbacks to display errors or success
  // $('[type="submit"]').on('click', function () {
  //                 $('#success').show().delay(5000).fadeOut();
  //               });

  function notification(type, message) {
    switch (type) {
      case "success":
        toastr.success(message);
        break;
      case "info":
        toastr.info(message);
        break;
      case "error":
        toastr.error(message);
        break;
      case "warning":
        toastr.warning(message);
        break;
    }
  }

// $('#success').show().delay(5000).fadeOut();
  

  $(document).ajaxStart(function(){
    console.log('start ajax');
    $(".submenu a").css({'cursor' : 'wait'});
  });
  $(document).ajaxStop(function(){
    console.log('stopped ajax');
    $(".submenu a").css({'cursor' : 'default'});
  });
});
