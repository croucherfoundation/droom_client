class ConferencePerson
  include Her::JsonApi::Model

  use_api DROOM
  collection_path "/api/conference_people"
  root_element :conference_person
end