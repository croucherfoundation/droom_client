class Venue < ActiveResource::Base
  include DroomFormatApiResponse
  include DroomActiveResourceConfig

  self.primary_key = 'slug'

  def save
    self.prefix_options[:venue] = self.attributes
    super
  end

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
