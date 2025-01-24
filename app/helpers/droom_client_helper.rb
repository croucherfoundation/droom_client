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
    whitelist_subdomains = %w[projectss projects scholars scholarss search searchs]
    committees = ['Trustees', 'Audit Committee', 'Investment Committee', 'Nomination Committee', 'Staff']

    # Determine base URL and text based on subdomain
    base_url = whitelist_subdomains.include?(request.subdomain) ? ENV['DROOM_URL'] : Settings.home_url
    base_text = whitelist_subdomains.include?(request.subdomain) ? 'Go to data room' : 'Go to public site'

    # Admin users or committee members
    if user.admin? || user.user_groups&.any? { |group| committees.include?(group) }
      return { url: base_url, text: base_text }
    end

    # Partner admin users
    if defined?(Nominator) && defined?(CswAdmin)
      if (partner_url = partner_admin_url_for_user(user))
        return { url: partner_url, text: 'Go to data room' }
      end
    end

    # Funding applicants or persons linked to the user
    if defined?(Person)
      person = Person.find_by(user_uid: user.uid)
      if person.present? || user.user_groups&.include?('Applicants')
        return { url: "#{Settings.home_url}/funding-application", text: 'Go to data room' }
      end
    end

    # Default case
    { url: nil, text: nil }
  end

  def partner_admin_url_for_user(user)
    subdomain =
      if (nominator = Nominator.find_by(user_uid: user.uid))
        nominator.institution_code
      elsif (csw_admin = CswAdmin.find_by(user_uid: user.uid))
        CswPartner.find(csw_admin.csw_partner_id).code
      end

    return unless subdomain

    subdomain << 's' if Rails.env.staging?
    domain = Rails.env.development? ? 'croucher.localhost' : 'croucher.org.hk'
    URI.join("https://#{subdomain}.#{domain}", '/dashboard').to_s
  end

end
