class Droom::Folder
  include Her::JsonApi::Model

  use_api DROOM
  collection_path "/api/folders"
  root_element :droom_folder

  class << self

    def children(parent_id)
      get "/api/folders/#{parent_id}/children"
    rescue JSON::ParserError, Her::Errors::ParseError
      nil
    end

    def documents(folder_id)
      get "/api/folders/#{folder_id}/documents"
    rescue JSON::ParserError, Her::Errors::ParseError
      nil
    end

    # including descendants' documents
    def all_documents(folder_id)
      get "/api/folders/#{folder_id}/all_documents"
    rescue JSON::ParserError, Her::Errors::ParseError
      nil
    end

  end

end
