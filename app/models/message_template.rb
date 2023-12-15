class MessageTemplate
  include Her::JsonApi::Model

  use_api DROOM
  collection_path "/api/message_templates"
  include_root_in_json true
  parse_root_in_json false
  
end