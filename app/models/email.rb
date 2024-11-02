class Email
  include Her::JsonApi::Model
  use_api DROOM
  collection_path "/api/emails"

  def self.all_address_types
    [
      { id: 1, name: "Home" },
      { id: 2, name: "Mobile" },
      { id: 3, name: "Work" },
      { id: 4, name: "Correspondence" },
      { id: 5, name: "Original" }
    ]
  end
end