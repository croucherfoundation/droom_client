class Event < ActiveResource::Base
  include DroomFormatApiResponse
  include DroomActiveResourceConfig

  after_create :assign_to_associates

  @associates = []
  attr_accessor :associates

protected

  def assign_to_associates
    associates.each do |ass|
      ass.event = self
    end
  end

end
