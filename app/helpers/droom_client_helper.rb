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
    whitelist_subdomains = ['projectss', 'project', 'scholars', 'scholarss', 'search', 'searchs']
    url = whitelist_subdomains.include?(request.subdomain) ? ENV['DROOM_URL'] : Settings.home_url
    url_name = whitelist_subdomains.include?(request.subdomain) ? 'Go to data room' : 'Go to public site'
  
    return { url: url, text: url_name } if user.admin?
  
    committees = ['Trustees', 'Audit Committee', 'Investment Committee', 'Nomination Committee', 'Staff']
    if user.user_groups&.any? { |group| committees.include?(group) }
      return { url: url, text: url_name }
    end
  
    if defined?(Person)
      person = Person.find_by(user_uid: user.uid)
  
      if person.present? || user.user_groups&.include?('Applicants')
        return { url: "#{Settings.home_url}/funding-application", text: 'Go to data room' }
      end
    end
  
    { url: nil, text: nil }
  end  
end
