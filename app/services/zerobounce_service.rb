require 'zerobounce'

class ZerobounceService
  Zerobounce.config.apikey = ENV.fetch('ZEROBOUNCE_API_KEY', nil)

  attr_reader :record, :column, :email, :valid_column, :checked_at_column, :save_immediate

  def initialize(record:, column: :email, save_immediate: true)
    raise ArgumentError, "Record cannot be nil" if record.nil?

    @record = record
    @save_immediate = save_immediate
    @column = column

    @valid_column = "#{column}_valid"
    @checked_at_column = "#{column}_checked_at"
    @email = record.send(column)
  end

  def call
    return false if email.to_s.strip.empty?
    return false unless record
    return true if recent_check? && !record.send("#{column}_changed?")

    validate_email
  rescue => e
    Rails.logger.error("ZerobounceService error: #{e.message}")
    false
  end

  private

  def recent_check?
    checked_at = record.send(checked_at_column)
    record.send(valid_column) && checked_at.present? && checked_at >= 30.days.ago
  end

  def validate_email
    status = Zerobounce.validate(email)['status'] == 'valid'
    update_status(status)
    status
  end

  def update_status(status)
    record.assign_attributes(valid_column => status, checked_at_column => Time.current)
    record.save if save_immediate
  end
end
