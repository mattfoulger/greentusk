##
# Copyright 2012 Evernote Corporation. All rights reserved.
##
require 'shotgun'
require 'sinatra'
require 'byebug'
require_relative "../evernote_config"
require_relative 'helpers'


before "/notes" do
  redirect '/' unless session[:access_token]
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
    if(request.xhr?)
      content_type :json
      return strip_content(@note.content).to_json
    end
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
  new_note.tagNames = ["markdown"]
  new_note.content = format_content("")
  created_note = note_store.createNote(auth_token, new_note)
  unless (request.xhr?)
    redirect '/editor'
  end
  # TODO: error message handling
  # content_type :json
  hash = {guid: created_note.guid, title: created_note.title, notebook_guid: created_note.notebookGuid}
  hash.to_json
end

put '/notes' do
  # check if note exists first
  # if note()

  edit_note = Evernote::EDAM::Type::Note.new
  edit_note.guid = params[:guid]
  edit_note.title = params[:title]
  edit_note.notebookGuid = params[:notebook_guid]
  # edit_note.tagNames = [params[:tags]]
  edit_note.content = format_content(params[:content])
  updated_note = note_store.updateNote(auth_token, edit_note)
  # redirect '/notes'
end

get '/editor' do
  erb :'editor'
end




