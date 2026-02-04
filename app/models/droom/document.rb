class Droom::Document
  include Her::JsonApi::Model

  use_api DROOM
  collection_path "/api/documents"
  root_element :droom_document

end