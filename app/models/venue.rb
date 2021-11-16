class Venue < ActiveResource::Base
  # include Her::JsonApi::Model

  # use_api DROOM
  # collection_path "/api/venues"
  # root_element :venue
  
  self.site = ENV['DROOM']
  self.include_format_in_path = false

  def associates
    @associates ||= []
  end

  def associates=(these)
    @associates = these
  end

  def self.for_selection
    self.all.map{|venue| [venue.name, venue.slug]}
  end

  def self.new_with_defaults
    self.new({
      name: "",
      address: ""
    })
  end

end
