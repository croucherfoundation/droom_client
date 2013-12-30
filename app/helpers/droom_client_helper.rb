module DroomClientHelper

  def droom_url(path)
    URI.join(droom_host, path).to_s
  end

  def droom_asset_url(path)
    URI.join(droom_asset_host, Settings.droom.asset_path, path).to_s
  end

  def droom_host
  "#{Settings.droom.protocol}://#{Settings.droom.host}"
  end

  def droom_asset_host
    "http://#{Settings.droom.asset_host}"
  end

end
