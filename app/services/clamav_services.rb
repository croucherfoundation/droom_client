require 'faraday'
require 'json'
require 'stringio'

class ClamavServices
  BASE_URL = if Rails.env.production? || Rails.env.staging?
                'http://172.31.35.113/api/'.freeze
              else
                'https://scan.croucher.org.hk/api/'.freeze
              end
  API_KEY = ENV['CLAMAV_API_KEY'] || ''

  def self.scan_file(file_path)
    raise ArgumentError, 'File path cannot be nil' if file_path.nil?
    raise ArgumentError, 'File does not exist' unless File.exist?(file_path)
    raise ArgumentError, 'API key is required' if API_KEY.blank? && Rails.env.development?

    begin
      response = upload_and_scan(file_path)
      parse_response(response)
    rescue StandardError => e
      puts "An error occurred while scanning the file: #{e.message}"
      { status: :error, message: e.message }
    end
  end

  private

  def self.upload_and_scan(file_path)
    # Configure connection based on environment
    connection = if Rails.env.production? || Rails.env.staging?
                   # Use HTTP for production/staging internal IP
                   Faraday.new(url: BASE_URL) do |f|
                     f.request :multipart
                     f.adapter :net_http
                     f.options.timeout = 240
                     f.options.open_timeout = 69
                   end
                 else
                   # Use HTTPS for development with external domain
                   Faraday.new(url: BASE_URL, ssl: { verify: true }) do |f|
                     f.request :multipart
                     f.adapter :net_http
                     f.options.timeout = 240
                     f.options.open_timeout = 69
                   end
                 end

    # Read file content
    file_content = File.read(file_path)
    filename = File.basename(file_path)

    # Prepare headers
    headers = {}
    headers['X-API-Key'] = API_KEY if Rails.env.development?

    # Create the multipart payload
    payload = {
      file: Faraday::UploadIO.new(StringIO.new(file_content), nil, filename)
    }

    connection.post('scan-file', payload, headers)
  end

  def self.parse_response(response)
    case response.status
    when 200
      result = JSON.parse(response.body)
      scan_result = result['scan_result']
      
      if scan_result['clean']
        puts "File is clean: #{scan_result['message']}"
        { 
          status: :clean, 
          message: scan_result['message'],
          filename: scan_result['filename'],
          scan_time_ms: scan_result['scan_time_ms'],
          file_size_bytes: scan_result['file_size_bytes']
        }
      else
        puts "File is infected: #{scan_result['threat_name'] || 'Unknown threat'}"
        { 
          status: :infected, 
          threat_name: scan_result['threat_name'],
          message: scan_result['message'],
          filename: scan_result['filename'],
          scan_time_ms: scan_result['scan_time_ms'],
          file_size_bytes: scan_result['file_size_bytes']
        }
      end
    when 400
      error_msg = "Bad request: #{response.body}"
      puts error_msg
      { status: :error, message: error_msg }
    when 401
      error_msg = "Unauthorized: Invalid API key"
      puts error_msg
      { status: :error, message: error_msg }
    when 413
      error_msg = "File too large"
      puts error_msg
      { status: :error, message: error_msg }
    else
      error_msg = "HTTP #{response.status}: #{response.body}"
      puts error_msg
      { status: :error, message: error_msg }
    end
  rescue JSON::ParserError => e
    error_msg = "Invalid JSON response: #{e.message}"
    puts error_msg
    { status: :error, message: error_msg }
  end
end