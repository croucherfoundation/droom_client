module DroomClient
  class ClientSyncJob < ApplicationJob
    queue_as :default

    def perform(klass_name, record_id, changes)
      klass  = constantize_safely(klass_name)
      record = klass&.find_by(id: record_id)
      return unless record && changes.present?
      
      return if SyncGuard.active_for?(klass_name, record_id)

      SyncGuard.with_record_lock(klass_name, record_id) do
        sync_to_target(record, changes)
      end
    end

    private

    def constantize_safely(class_name)
      class_name.constantize
    rescue NameError
      nil
    end

    def sync_to_target(record, changes)
      return unless should_sync?(record.class)

      target_class = record.class.client_sync_target
      return unless target_class
      
      target_id = record.id.to_s
      
      target = target_class.all.to_a.select do |c|
        
        associated_data = c.associated_with
        
        unless associated_data.is_a?(Hash)
          associated_data = JSON.parse(associated_data) rescue {} if associated_data.is_a?(String) && associated_data.present?
          associated_data ||= {}
        end
        
        supervisor_ids = associated_data.dig("supervisor")
        
        supervisor_ids.is_a?(Array) && supervisor_ids.map(&:to_s).include?(target_id)
        
      end.first

      return unless target 

      record.class.silence do
        apply_changes(target, changes)
      end
    end


    def should_sync?(klass)
      # Supervisor can sync to Contact
      return true if klass.name == "Supervisor"

      # Contact should NOT sync back to supervisor for now
      return false if klass.name == "Contact"

      # other sync paths later
      false
    end

    def apply_changes(target, changes)
      updates_made = false

      changes.each do |attr, (_old, new_val)|
        case attr
        when "name"
          full_name = new_val.to_s.strip
          names = NameSplitter::Splitter.call(full_name)
          Rails.logger.info("NameSplitter Result: #{names.inspect}")
          target.given_name = names.first_name
          Rails.logger.info("#{target.given_name} ---- given_name")
          target.family_name = names.last_name
          Rails.logger.info("#{target.family_name} ---- family_name")
          target.title = names.salutation
          Rails.logger.info("#{target.title} ---- title")
          updates_made = true
          next

        else
          next unless target.respond_to?("#{attr}=")
          next if new_val.blank?
          next if target.public_send(attr) == new_val

          target.public_send("#{attr}=", new_val)
          updates_made = true
        end
      end

      if updates_made
        # The logging of changes works best just before the save.
        Rails.logger.info("Her Changes: #{target.changed_attributes.keys.join(', ')}")
        
        # KEEP this final, single save.
        target.save! 
      end
      
      Rails.logger.info "🔁 Synced → #{target.class}(#{target.id})" if updates_made
    rescue => e
      # Ensure logging handles cases where 'target' might not have an ID (though unlikely here)
      target_info = target ? "#{target.class}(#{target.id})" : target.class.name
      Rails.logger.error "❌ Sync failed for #{target_info}: #{e.message}"
    end

  end
end
