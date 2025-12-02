module ClientSyncable
  extend ActiveSupport::Concern

  included do
    after_update :capture_client_changes, if: :meaningful_changes?
    
    after_commit :enqueue_client_sync_job,
      unless: -> { SyncGuard.active_for?(self.class.name, id) || client_sync_disabled? }
  end

  # Attributes that should be tracked in the sync
  def client_tracked_attributes
    self.class::CLIENT_TRACKED_ATTRIBUTES
  end

  private

  # Capture the changes we need to sync
  def capture_client_changes
    @client_syncable_changes ||= {}
    current_changes = previous_changes.slice(*client_tracked_attributes)

    @client_syncable_changes.merge!(current_changes) do |key, old_val, new_val|
      [(@client_syncable_changes[key] || [nil])[0], new_val[1]]
    end
  end

  # Enqueue the sync job
  def enqueue_client_sync_job
    return unless @client_syncable_changes&.any?

    changes = @client_syncable_changes
    @client_syncable_changes = nil

    DroomClient::ClientSyncJob.perform_now(self.class.name, id, changes)
  end

  # Check if there are meaningful changes
  def meaningful_changes?
    previous_changes.slice(*client_tracked_attributes).any?
  end

  def client_sync_disabled?
    Thread.current[:client_sync_silenced] == true
  end

  module ClassMethods
    # Silence sync temporarily
    def silence
      Thread.current[:client_sync_silenced] = true
      yield
    ensure
      Thread.current[:client_sync_silenced] = false
    end

    # Each including model must define its target class for sync
    def client_sync_target
      raise NotImplementedError, "Define self.client_sync_target in the including model"
    end
  end
end
