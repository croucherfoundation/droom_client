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