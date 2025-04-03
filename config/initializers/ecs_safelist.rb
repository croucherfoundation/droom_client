module EcsSafelist
  def self.get_all_public_ips
    redis = Redis.new
    keys = redis.keys("ecs_safelist:#{Rails.env}:*")
    public_ips = []
    keys.each do |key|
      ips = redis.get(key)
      unless ips.nil?
        ips.split(",").each do |ip|
          public_ips << ip.strip unless ip.strip.blank?
        end
      end
    end
    public_ips.uniq
  end
end