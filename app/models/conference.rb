class Conference
  include Her::JsonApi::Model

  use_api DROOM
  collection_path "/api/conferences"
  root_element :conference

end
