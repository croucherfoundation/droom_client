require 'rake'
Rake.application.init
module EcsSafelist
  def self.get_all_public_ips
    # Skip Redis initialization for Rake tasks
    if defined?(Rake) && Rake.application.top_level_tasks.include?('assets:clean')
      Rails.logger.info "Skipping Redis initialization for rake assets:clean"
      return []
    end

    begin
      redis = Redis.new
      redis.select(0)
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
    rescue Redis::CannotConnectError => e
      Rails.logger.error "Redis connection error: #{e.message}"
      []
    end
  end
end