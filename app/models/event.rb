class Event < ActiveResource::Base
  # include Her::JsonApi::Model

  # use_api DROOM
  # collection_path "/api/events"
  # root_element :event
  # request_new_object_on_build true

  # after_create :assign_to_associates
  
  self.site = ENV['DROOM']
  self.include_format_in_path = false

  @associates = []
  attr_accessor :associates

protected
  
  def assign_to_associates
    associates.each do |ass|
      ass.event = self
    end
  end
  
end
