class Address
  include Her::JsonApi::Model
  use_api DROOM
  collection_path "/api/addresses"

  def self.new_with_defaults(atts={})
    attributes = {
      id: nil,
      address: nil,
      address_type_id: nil,
      _destroy: false
    }.with_indifferent_access.merge(atts)

    self.new(attributes)
  end
end
