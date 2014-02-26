module HkNames
  extend ActiveSupport::Concern

  ## Names
  #
  # With Anglo-Chinese Hong Kong names it is difficult to be sure of the right presentation for each individual.
  #
  # We hold the name in three fields: title, given name and family name. People with both a Chinese and an
  # English forename are encouraged to enter their given name in the form Tai Wan, Jimmy. The family_name 
  # should always be a single, usually Chinese, surname: Chan or Smith.
  #
  # When a comma is found in the given name, we assume that they have followed the chinese, english format.
  # If not, we assume the whole name is Chinese.
  #
  # ### Polite informality
  #
  # People with an English forename would normally be addressed as Jimmy Chan. People with only a Chinese
  # forename should be addressed as Chan Tai Wan.
  #
  def informal_name
    # The standard form of the given name is Tai Wan, Ray
    # But some people are known only as Ray.
    chinese, english = given_name.split(/,\s*/)
    parts = chinese.split(/\s+/)

    # Here we can't tell the difference between people with one chinese given name and one anglo given name
    # but the order of names is reversed in the latter case. For now we assume that the presence of a chinese
    # name or two given names indicates that the chinese word ordering should be used.
    unless chinese_name? || parts.length > 1
      english ||= chinese
    end
    if english
      # People with an english name are called Ray Chan, by default
      [english, family_name].join(' ')
    else
      # People without are called Chan Tai Wan
      [family_name, chinese].join(' ')
    end
  end
  alias :name :informal_name

  # ### Formality
  #
  # The family name is held separately because for most purposes we will address people using the relatively 
  # reliable 'Dr Chan' or 'Mr Smith'.
  #
  def normalized_title
    t = self.title
    t = ordinary_title unless t.present?
    t.gsub('.', '').strip
  end
  
  def ordinary_title
    gender == 'f' ? "Ms" : "Mr"
  end
  
  def title_ordinary?
    ['Mr', 'Ms', 'Mrs', '', nil].include?(normalized_title)
  end
  
  def title_if_it_matters
    normalized_title unless title_ordinary?
  end

  def formal_name
    [normalized_title, family_name].compact.join(' ')
  end

  # This is our best shot at a representation of how this person would normally be referred to. It combines
  # the informal name (which includes some logic to show chinese, anglo and mixed names correctly) with the title.
  #
  def colloquial_name
    [title_if_it_matters, informal_name].compact.join(' ')
  end

  # ### Completeness
  #
  # For record-keeping purposes we show the whole name: Chan Tai Wan, Jimmy.
  #
  def whole_name
    [family_name, given_name].compact.join(' ')
  end

  # ### Compatibility
  #
  # An HKID card will normally show only the translitered Chinese name: Chan Tai Wan
  #
  def official_name
    chinese, english = given_name.split(/,\s*/)
    [family_name, chinese].join(' ')
  end

end
