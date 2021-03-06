require_relative "../evernote_config"
require 'nokogiri'
require 'base64'


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

  def all_notebooks
    hash = Hash.new
    note_store.listNotebooks(auth_token).each do |notebook|
      hash[notebook.guid] = notebook.name
    end
    hash
  end

  def notes(options = {})
    notebook_guid = options[:notebook_guid]
    tags = options[:tags]
    
    filter = Evernote::EDAM::NoteStore::NoteFilter.new
    filter.notebookGuid = notebook_guid if notebook_guid
    filter.tagGuids = tags if tags

    spec = Evernote::EDAM::NoteStore::NotesMetadataResultSpec.new
    spec.includeTitle = true
    
    notes_list = note_store.findNotesMetadata(auth_token, filter, 0, 100, spec)
    notes_list.notes.reverse
  end

  def note(guid)
    begin
      note_store.getNote(auth_token, guid, true, true, true, true)
    rescue
      return nil
    end
  end

  def check_login
    if auth_token == nil
      redirect '/requesttoken'
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
      # session[:tags][tag_guid] = tag_name
    end
    tag_guid
  end

  # Helper methods for HTML file creation

  def create_file(title, base64)
    converted_string = Base64.decode64(base64)
    converted_string = "<!DOCTYPE html>\n<html>\n<body>\n" + converted_string + "\n</body>\n</html>"
    @new_file = File.open(html_filename(title), "w") { |file| file.write(converted_string) }
    html_filename(title)
  end

  def html_filename(filename)
    filename = Base64.decode64(filename)
    # filename.gsub(/[^\w\s_-]+/, '')
    #         .gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2')
    #         .gsub(/\s+/, '_')
    filename = filename + ".html"
  end


  # def total_note_count
  #   filter = Evernote::EDAM::NoteStore::NoteFilter.new
  #   counts = note_store.findNoteCounts(auth_token, filter, true)
  #   notebooks.inject(0) do |total_count, notebook|
  #     total_count + (counts.notebookCounts[notebook.guid] || 0)
  #   end
  # end


end