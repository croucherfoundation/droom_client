require 'zerobounce'

class ZerobounceService
  Zerobounce.config.apikey = ENV.fetch('ZEROBOUNCE_API_KEY', nil)

  def initialize
  end

  def self.valid_email?(email)
    validate_email(email)['status'] == 'valid'
  end

  def self.validate_email(email)
    raise ArgumentError, "Email is required" if email.to_s.strip.empty?
    Zerobounce.validate(email)
  end

  def self.valid_emails?(emails)
    return false unless valid_batch_response?(emails)

    emails_status_valid?(emails)
  end

  def self.validate_batch(emails)
    raise ArgumentError, "Emails array is required" unless emails.is_a?(Array) && emails.any?
    Zerobounce.validate_batch(emails)
  end

  private

  def valid_batch_response?(emails)
    response = validate_batch(emails)
    response.all? { |r| r.is_a?(Hash) && r.key?('status') }
  end

  def emails_status_valid?(emails)
    response = validate_batch(emails)
    response.all? { |r| r['status'] == 'valid' }
  end
end
