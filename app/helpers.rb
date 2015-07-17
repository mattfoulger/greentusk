require_relative "../evernote_config"
require 'nokogiri'


helpers do
  def auth_token
    session[:access_token].token if session[:access_token]
  end

  def client
    EvernoteOAuth::Client.new(token: auth_token, consumer_key:OAUTH_CONSUMER_KEY, consumer_secret:OAUTH_CONSUMER_SECRET, sandbox: SANDBOX)
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