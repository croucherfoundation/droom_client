require 'net/http'
require 'uri'
require 'json'
require 'openssl'

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
    uri = URI.parse("#{BASE_URL}/scan-file")
    
    # Configure SSL/HTTP based on environment
    ssl_options = if Rails.env.production? || Rails.env.staging?
                    # Use HTTP (no SSL) for production/staging internal IP
                    { use_ssl: false }
                  else
                    # Use HTTPS for development with external domain
                    { use_ssl: true }
                  end
    
    Net::HTTP.start(uri.host, uri.port, **ssl_options) do |http|
      request = Net::HTTP::Post.new(uri)
      
      # Only include API key in development environment
      if Rails.env.development?
        request['X-API-Key'] = API_KEY
      end
      
      # Create multipart form data
      boundary = "----WebKitFormBoundary#{SecureRandom.hex(16)}"
      request['Content-Type'] = "multipart/form-data; boundary=#{boundary}"
      
      # Read file content
      file_content = File.read(file_path)
      filename = File.basename(file_path)
      
      # Build multipart body
      body = []
      body << "--#{boundary}"
      body << "Content-Disposition: form-data; name=\"file\"; filename=\"#{filename}\""
      body << "Content-Type: application/octet-stream"
      body << ""
      body << file_content
      body << "--#{boundary}--"
      
      request.body = body.join("\r\n")
      
      http.request(request)
    end
  end

  def self.parse_response(response)
    case response.code
    when '200'
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
    when '400'
      error_msg = "Bad request: #{response.body}"
      puts error_msg
      { status: :error, message: error_msg }
    when '401'
      error_msg = "Unauthorized: Invalid API key"
      puts error_msg
      { status: :error, message: error_msg }
    when '413'
      error_msg = "File too large"
      puts error_msg
      { status: :error, message: error_msg }
    else
      error_msg = "HTTP #{response.code}: #{response.body}"
      puts error_msg
      { status: :error, message: error_msg }
    end
  rescue JSON::ParserError => e
    error_msg = "Invalid JSON response: #{e.message}"
    puts error_msg
    { status: :error, message: error_msg }
  end
end