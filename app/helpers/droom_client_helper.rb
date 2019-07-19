module DroomClientHelper

  def droom_url(path, params={})
    uri = URI.join(droom_host, path)
    uri.query = params.to_query if params.any?
    uri.to_s
  end

  def droom_link_url(path, params={})
    uri = URI.build(host: droom_asset_host, path: path.sub(/^\//, ''), query: params.to_query)
    uri.query = params.to_query if params.any?
    uri.to_s
  end

  def droom_asset_url(path)
    uri = URI.join(droom_asset_host, 'assets/', path.sub(/^\//, ''))
    uri.to_s
  end

  def droom_host
    ENV['DROOM_API_URL'] || "#{Settings.droom.protocol}://#{Settings.droom.host}"
  end

  def droom_asset_host
    ENV['DROOM_URL'] || "//#{Settings.droom.asset_host}" || droom_host
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

end
