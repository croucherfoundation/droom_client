# Configure Active Storage tracking
Rails.application.config.after_initialize do
  ActiveSupport.on_load(:active_record) do
    ActiveStorage::Attachment.has_paper_trail(
      on: %i[destroy]
    )

    ActiveStorage::Blob.has_paper_trail(
      on: %i[destroy]
    )
  end
end

Rails.configuration.to_prepare do
  ActiveStorage::Attachment.class_eval do
    before_destroy :purge_attachment

    def purge_attachment
      Rails.logger.info "Purge attachments..."
      record = self.record_type.constantize.find(self.record_id).send(self.name)
      record.purge
    end
  end
end
