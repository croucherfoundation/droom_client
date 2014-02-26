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
    "#{Settings.droom.asset_protocol}://#{Settings.droom.asset_host}"
  end
  
  def local_host
    "#{request.protocol}#{request.host}"
  end

end
