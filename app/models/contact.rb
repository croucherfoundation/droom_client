class Contact
  include Her::JsonApi::Model

  use_api Client

  collection_path "/api/contacts"
  resource_path   "/api/contacts/:id"

  attributes :given_name, :family_name, :email, :address, :title
end
