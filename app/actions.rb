##
# Copyright 2012 Evernote Corporation. All rights reserved.
##
require 'shotgun'
require 'sinatra'
enable :sessions
require 'nokogiri'


# Load our dependencies and configuration settings
# $LOAD_PATH.push(File.expand_path(File.dirname(__FILE__)))
require_relative "../evernote_config"

##
# Verify that you have obtained an Evernote API key
##
before do
  if OAUTH_CONSUMER_KEY.empty? || OAUTH_CONSUMER_SECRET.empty?
    halt '<span style="color:red">Before using this sample code you must edit evernote_config.rb and replace OAUTH_CONSUMER_KEY and OAUTH_CONSUMER_SECRET with the values that you received from Evernote. If you do not have an API key, you can request one from <a href="http://dev.evernote.com/documentation/cloud/">dev.evernote.com/documentation/cloud/</a>.</span>'
  end
end

helpers do
  def auth_token
    session[:access_token].token if session[:access_token]
  end

  def client
    @client ||= EvernoteOAuth::Client.new(token: auth_token, consumer_key:OAUTH_CONSUMER_KEY, consumer_secret:OAUTH_CONSUMER_SECRET, sandbox: SANDBOX)
  end

  def user_store
    @user_store ||= client.user_store
  end

  def note_store
    @note_store ||= client.note_store
  end

  def en_user
    user_store.getUser(auth_token)
  end

  def notebooks
    @notebooks ||= note_store.listNotebooks(auth_token)
  end

  def notes(options = {})
    notebook_guid = options[:notebook_guid]
    tags = options[:tags]
    
    filter = Evernote::EDAM::NoteStore::NoteFilter.new
    filter.notebookGuid = notebook_guid if notebook_guid
    filter.tagGuids = tags if tags

    spec = Evernote::EDAM::NoteStore::NotesMetadataResultSpec.new
    spec.includeTitle = true
    note_store.findNotesMetadata(auth_token, filter, 0, 100, spec)
  end

  def note(guid)
    begin
      note_store.getNote(auth_token, guid, true, true, true, true)
    rescue
      return nil
    end
  end

  def format_content(string)
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">\n<en-note>" + string + "</en-note>"
  end

  def strip_content(string)
    xml_doc = Nokogiri::XML(string)
    xml_doc.at_css("en-note").content
  end

  def all_tags
    hash = Hash.new
    note_store.listTags.each do |tag|
      hash[tag.guid] = tag.name
    end
    hash
  end

  def find_tag(tag_name)
    all_tags.key(tag_name)
  end

  def create_tag(tag_name)
    tag_guid = find_tag(tag_name)
    if tag_guid == nil
      tag = Evernote::EDAM::Type::Tag.new
      tag.name = tag_name
      created_tag = note_store.createTag(auth_token, tag)
      tag_guid = created_tag.guid
      session[:tags][tag_guid] = tag_name
    end
    tag_guid
  end

  # def total_note_count
  #   filter = Evernote::EDAM::NoteStore::NoteFilter.new
  #   counts = note_store.findNoteCounts(auth_token, filter, true)
  #   notebooks.inject(0) do |total_count, notebook|
  #     total_count + (counts.notebookCounts[notebook.guid] || 0)
  #   end
  # end
end

##
# Index page
##
get '/' do
  if session[:access_token]
    redirect '/notes'
  else
    erb :index
  end
end

##
# Reset the session 
##
get '/reset' do
  session.clear
  redirect '/'
end

##
# Obtain temporary credentials
##
get '/requesttoken' do
  callback_url = request.url.chomp("requesttoken").concat("callback")
  begin
    session[:request_token] = client.request_token(:oauth_callback => callback_url)
    redirect '/authorize'
  rescue => e
    @last_error = "Error obtaining temporary credentials: #{e.message}"
    erb :'errors/oauth_error'
  end
end

##
# Redirect the user to Evernote for authoriation
##
get '/authorize' do
  if session[:request_token]
    redirect session[:request_token].authorize_url
  else
    # You shouldn't be invoking this if you don't have a request token
    @last_error = "Request token not set."
    erb :'errors/oauth_error'
  end
end

##
# Receive callback from the Evernote authorization page
##
get '/callback' do
  unless params['oauth_verifier'] || session['request_token']
    @last_error = "Content owner did not authorize the temporary credentials"
    halt erb :'errors/oauth_error'
  end
  session[:oauth_verifier] = params['oauth_verifier']
  begin
    session[:access_token] = session[:request_token].get_access_token(:oauth_verifier => session[:oauth_verifier])
    redirect '/notes'
  rescue
    @last_error = 'Error extracting access token'
    erb :'errors/oauth_error'
  end
end

get '/notes' do
  notebook_guid = params['notebook_guid']
  if tags = params['tags']
    tags = tags.split(',')
  end
  @notes = notes(notebook_guid: notebook_guid, tags: tags)
  erb :'/notes/index'
end

get '/notes/new' do
  erb :'notes/new'
end

get '/notes/:guid' do
  if @note = note(params[:guid])
    erb :'notes/show'
  else
    erb :'errors/no_note_error'
  end 
end

get '/notes/:guid/edit' do
  @note = note(params[:guid])
  erb :'notes/edit'
end


post '/notes' do
  new_note = Evernote::EDAM::Type::Note.new
  new_note.title = params[:title]
  new_note.notebookGuid = params[:notebook_guid]
  new_note.tagNames = ["markit"]
  new_note.content = format_content("")
  created_note = note_store.createNote(auth_token, new_note)
  redirect '/notes'
end

put '/notes' do
  edit_note = Evernote::EDAM::Type::Note.new
  edit_note.guid = params[:guid]
  edit_note.title = params[:title]
  edit_note.notebookGuid = params[:notebook_guid]
  # edit_note.tagNames = [params[:tags]]
  edit_note.content = format_content(params[:content])
  binding.pry
  updated_note = note_store.updateNote(auth_token, edit_note)
  redirect '/notes'
end




