class Event
  include PaginatedHer::Model

  use_api DROOM
  collection_path "/api/events"
  root_element :event
  request_new_object_on_build true

  after_create :assign_to_associates
  after_save :decache

  @associates = []
  attr_accessor :associates

protected
  
  def assign_to_associates
    associates.each do |ass|
      ass.event = self
    end
  end
  
  def decache
    $cache.flush_all if $cache
  end

end
