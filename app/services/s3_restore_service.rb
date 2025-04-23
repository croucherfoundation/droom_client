class S3RestoreService
  attr_reader :s3, :bucket

  def initialize(bucket_name)
    @bucket = bucket_name
    @s3 = initialize_s3_client
  end

  def restore_attachment(attachment_id)
    return false if attachment_id.nil?

    attachment = ActiveStorage::Attachment.find_by(id: attachment_id)
    return false unless attachment&.blob

    restore_file(attachment.blob.key)
  end

  def restore_blob(blob_id)
    return false if blob_id.nil?

    blob = ActiveStorage::Blob.find_by(id: blob_id)
    return false unless blob

    restore_file(blob.key)
  end

  private

  def restore_file(file_path)
    delete_markers = fetch_delete_markers(file_path)
    return false if delete_markers.empty?

    log_restore_attempt(file_path, delete_markers)
    remove_delete_markers(delete_markers)
  end

  def initialize_s3_client
    Aws::S3::Client.new(
      region: ENV['S3_REGION'],
      access_key_id: ENV['S3_KEY'],
      secret_access_key: ENV['S3_SECRET']
    )
  end

  def fetch_delete_markers(file_path)
    response = s3.list_object_versions(
      bucket: bucket,
      prefix: file_path
    )
    response.delete_markers
  end

  def remove_delete_markers(delete_markers)
    delete_markers.each do |marker|
      delete_marker(marker)
    end
  end

  def delete_marker(marker)
    s3.delete_object(
      bucket: bucket,
      key: marker.key,
      version_id: marker.version_id
    )
    true
  rescue Aws::S3::Errors::ServiceError => e
    log_error(e)
    false
  end

  def log_restore_attempt(file_path, delete_markers)
    Rails.logger.info "Attempting to restore file: #{file_path}"
    Rails.logger.info "Found #{delete_markers.count} delete markers"
  end

  def log_error(error)
    Rails.logger.error "Error restoring file: #{error.message}"
  end
end