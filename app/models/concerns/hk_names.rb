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

  def name?
    family_name? || given_name?
  end

  # ### Polite informality
  #
  # There are three possible name forms here: Johny Chan, Chan Tai Wan and sometimes Chan Tai Wan, Johnny.
  # It is not possible for us to distinguish them programmatically, but we do know that a given name
  # with a comma includes both chinese and english versions. In that case we favour the english component
  # for informal use, but in every other case we just print `given_name family_name`. This shows a fully
  # Chinese name in the wrong order, but apparently when printed in latin script that's quite acceptable.
  #
  # This also gives sane results in the common but incorrect case where people have given us Johnny Tai Wan.
  #
  def informal_name
    chinese, english = given_name.split(/,\s*/)
    given = english.presence || chinese # nb. if no comma then chinese will hold the whole name
    [given, family_name].join(' ')
  end
  alias :name :informal_name

  # ### Formality
  #
  # For most purposes we can address people using the relatively reliable 'Dr Chan' or 'Mr Smith'.
  #
  def normalized_title
    t = self.title.presence || default_title
    t.gsub('.', '').strip
  end
  
  def default_title
    if respond_to? :gender
      gender == 'f' ? "Ms" : "Mr"
    else
      ""
    end
  end
  
  def title_ordinary?
    ['Mr', 'Ms', 'Mrs', '', nil].include?(title)
  end
  
  def title_if_it_matters
    title unless title_ordinary?
  end

  def formal_name
    if normalized_title.present?
      [normalized_title, family_name].compact.join(' ')
    else
      [given_name, family_name].compact.join(' ')
    end
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
