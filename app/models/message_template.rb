class MessageTemplate
  include Her::JsonApi::Model

  use_api DROOM
  collection_path "/api/message_templates"
  root_element :venue
  
end