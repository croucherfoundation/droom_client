class Address
  include Her::JsonApi::Model
  use_api DROOM
  collection_path "/api/addresses"
end