class SyncGuard
  REDIS  = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1"))
  PREFIX = "#{Rails.env}_client_sync_guard_lock".freeze
  TTL    = 5 # seconds

  class << self
    def active_for?(klass, record_id)
      REDIS.exists?(lock_key(klass, record_id))
    end

    def with_record_lock(klass, record_id)
      key = lock_key(klass, record_id)
      locked = REDIS.set(key, "locked", ex: TTL, nx: true)
      unless locked
        Rails.logger.warn("SyncGuard: Lock active for #{klass}(#{record_id}), skipping.")
        return
      end
      yield
    ensure
      REDIS.del(key)
    end

    private

    def lock_key(klass, record_id)
      "#{PREFIX}:#{klass}:#{record_id}"
    end

    def self.silence
      Thread.current[:client_sync_guard_silenced] = true
      yield
    ensure
      Thread.current[:client_sync_guard_silenced] = false
    end

    def client_sync_disabled?
      Thread.current[:client_sync_guard_silenced] == true
    end
  end
end
