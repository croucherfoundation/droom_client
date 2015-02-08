require 'addressable/uri'

module DroomClientHelper

  def droom_url(path, params={})
    uri = Addressable::URI.join(droom_host, path)
    uri.query_values = params if params.any?
    uri.to_s
  end

  def droom_asset_url(path)
    Settings.droom[:asset_path] ||= nil
    Addressable::URI.join(droom_asset_host, Settings.droom.asset_path, path).to_s
  end

  def droom_host
    "#{Settings.droom.protocol}://#{Settings.droom.host}"
  end

  def droom_asset_host
    Settings.droom[:asset_protocol] ||= Settings.droom.protocol
    Settings.droom[:asset_host] ||= Settings.droom.host
    "//#{Settings.droom.asset_host}"
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
      type = thing.class.to_s.downcase.underscore
      classname = type.split('/').last
      locals[classname.to_sym] = thing
      render :partial => "#{type.pluralize}/action_menu", :locals => locals
    end
  end

end
