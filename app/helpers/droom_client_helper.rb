module DroomClientHelper

  def droom_url(path, params={})
    uri = URI.join(droom_asset_host, path.sub(/^\//, ''))
    uri.query = params.to_query if params.any?
    uri.to_s
  end

  def droom_link_url(path, params={})
    uri = URI.join(droom_asset_host, path.sub(/^\//, ''))
    uri.query = params.to_query if params.any?
    uri.to_s
  end

  def droom_asset_url(path)
    uri = URI.join(droom_asset_host, 'shared_assets/', path.sub(/^\//, ''))
    uri.to_s
  end

  def droom_host
    ENV['DROOM_API_URL']
  end

  def droom_asset_host
    ENV['DROOM_URL']
  end

  def local_host
    "#{request.protocol}#{request.host}"
  end

  def action_menulink(thing, html_options={})
    if can?(:edit, thing)
      classname = thing.class.to_s.underscore.split('/').last
      html_options.reverse_merge!({
        :class => "",
        :data => {:menu => "#{classname}_#{thing.id}"}
      })
      html_options[:class] << " menu"
      link_to t(:edit), "#", html_options
    end
  end

  def action_menu(thing, locals={})
    if can?(:edit, thing)
      type = thing.class.to_s.underscore
      classname = type.split('/').last
      locals[classname.to_sym] = thing
      render :partial => "#{type.pluralize}/action_menu", :locals => locals
    end
  end

  def scholar?
    user_signed_in? && current_user.user_groups&.include?('Scholars')
  end

  def determine_dataroom_url(user)
    return ENV['DROOM_URL'] if user.admin?

    if user.user_groups&.include?('Scholars')
      person = Person.find_by(user_uid: user.uid)
      return scholar_dataroom_or_funding_url(person) if person
    end

    return "#{Settings.home_url}/funding-application" if user.user_groups&.include?('Applicants')

    nil
  end

  private

  def scholar_dataroom_or_funding_url(person)
    person_page = PersonPage.find_by(person_uid: person.id)
    return nil unless person_page

    if person.last_award_year.to_i >= 2021
      "#{Settings.home_url}/dataroom/#{person_page.slug}"
    else
      "#{Settings.home_url}/funding-application"
    end
  end

end
