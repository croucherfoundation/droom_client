class Email
  include Her::JsonApi::Model
  use_api DROOM
  collection_path "/api/emails"
end