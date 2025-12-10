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
      
      target = nil
      person_uid = nil

      if record.is_a?(Stakeholder) 
        stakeholder_id = record.id.to_s 
        
        target = target_class.all.to_a.find do |contact|
          associated_stakeholder_ids = find_associated_ids(contact, "stakeholder")
          associated_stakeholder_ids.include?(stakeholder_id)
        end
        
        unless target
          Rails.logger.warn("Stakeholder sync: Contact not found for Stakeholder ID: #{stakeholder_id}")
        end

      elsif record.is_a?(Actor)
        actor_id = record.id.to_s
        
        target = target_class.all.to_a.find do |contact|
          associated_actor_ids = find_associated_ids(contact, "actor")
          associated_actor_ids.include?(actor_id)
        end

        unless target
          Rails.logger.warn("Actor sync: Contact not found for Actor ID: #{actor_id}")
        end

      elsif record.is_a?(Application)
        application_id = record.id.to_s
        
        target = target_class.all.to_a.find do |contact|
          associated_application_ids = find_associated_ids(contact, "application")
          associated_application_ids.include?(application_id)
        end

        unless target
          Rails.logger.warn("Application sync: Contact not found for Application ID: #{application_id}")
        end

      elsif record.is_a?(Grantor)
        grantor_id = record.id.to_s
        
        target = target_class.all.to_a.find do |contact|
          associated_grantor_ids = find_associated_ids(contact, "grantor")
          associated_grantor_ids.include?(grantor_id)
        end

        unless target
          Rails.logger.warn("Application sync: Contact not found for Grantor ID: #{grantor_id}")
        end

      elsif record.is_a?(Interviewer)
        interviewer_id = record.id.to_s
        
        target = target_class.all.to_a.find do |contact|
          associated_interviewer_ids = find_associated_ids(contact, "interviewer")
          associated_interviewer_ids.include?(interviewer_id)
        end

        unless target
          Rails.logger.warn("Application sync: Contact not found for Interviewer ID: #{interviewer_id}")
        end

      elsif record.is_a?(Reviewer)
        reviewer_id = record.id.to_s
        
        target = target_class.all.to_a.find do |contact|
          associated_reviewer_ids = find_associated_ids(contact, "reviewer")
          associated_reviewer_ids.include?(reviewer_id)
        end

        unless target
          Rails.logger.warn("Application sync: Contact not found for Reviewer ID: #{reviewer_id}")
        end

      elsif record.is_a?(Speaker)
        speaker_id = record.id.to_s
        
        target = target_class.all.to_a.find do |contact|
          associated_speaker_ids = find_associated_ids(contact, "speaker")
          associated_speaker_ids.include?(speaker_id)
        end

        unless target
          Rails.logger.warn("Application sync: Contact not found for Speaker ID: #{speaker_id}")
        end

      elsif record.is_a?(Supervisor)
        supervisor_id = record.id.to_s
        target = target_class.all.to_a.find do |contact|
          associated_supervisor_ids = find_associated_ids(contact, "supervisor")
          associated_supervisor_ids.include?(supervisor_id)
        end

        unless target
          Rails.logger.warn("Supervisor sync: Contact not found for Supervisor ID: #{supervisor_id}")
        end
      
      elsif record.is_a?(Person)
        person_uid = record.uid.to_s 
        
        target = target_class.all.to_a.find do |contact|
          associated_person_uids = find_associated_ids(contact, "person")
          associated_person_uids.include?(person_uid)
        end

        unless target
          Rails.logger.warn("Person sync: Contact not found for Person UID: #{person_uid}")
        end

      
      end

      return unless target 

      record.class.silence do
        apply_changes(target, changes)
      end
    end


    def should_sync?(klass)
      return true if klass.name.in?(["Supervisor",  "Stakeholder", "Person", "Actor", "Application", "Grantor", "Interviewer", "Reviewer", "Speaker"]) 

      return false if klass.name == "Contact"

      false
    end

    def apply_changes(target, changes)
      # updates_made = false

      changes.each do |attr, (_old, new_val)|
        case attr
        when "name"
          full_name = new_val.to_s.strip
          names = NameSplitter::Splitter.call(full_name)
          target.given_name = names.first_name
          target.family_name = names.last_name
          target.title = names.salutation
          next

        else
          next unless target.respond_to?("#{attr}=")
          next if new_val.blank?
          next if target.public_send(attr) == new_val

          target.public_send("#{attr}=", new_val)
          # updates_made = true
        end
      end

      # if updates_made
      if target.changed?
        Rails.logger.info("Her Changes: #{target.changed_attributes.keys.join(', ')}")
        
        target.save! 
      end
      
      Rails.logger.info "🔁 Synced → #{target.class}(#{target.id})" if target.changed?
    rescue => e
      # Ensure logging handles cases where 'target' might not have an ID (though unlikely here)
      target_info = target ? "#{target.class}(#{target.id})" : target.class.name
      Rails.logger.error "❌ Sync failed for #{target_info}: #{e.message}"
    end

    # helper method for associated_with
    def find_associated_ids(contact, key)
      associated_data = parse_associated_data(contact)
      ids = associated_data.dig(key)
      ids.is_a?(Array) ? ids.map(&:to_s) : []
    end

    def parse_associated_data(contact)
      associated_data = contact.associated_with
      
      unless associated_data.is_a?(Hash)
        associated_data = JSON.parse(associated_data) rescue {} if associated_data.is_a?(String) && associated_data.present?
        associated_data ||= {}
      end
      associated_data
    end

  end
end