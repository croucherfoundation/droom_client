class FileSecurityService
  # Security configuration constants
  BLOCKED_MIME_TYPES = [
    %r{\Aapplication/(x-javascript|javascript|x-msdownload|x-sh|x-exe|x-dosexec|x-bat|x-csh|x-python|x-perl|x-php|x-ruby|x-shellscript)\z}i,
    %r{\Atext/(javascript|x-python|x-perl|x-php|x-ruby|x-shellscript)\z}i,
    %r{\Aapplication/octet-stream\z}i
  ].freeze

  BLOCKED_EXTENSIONS = /\.(js|exe|sh|bat|py|pl|php|rb|c|cpp|h|java|class|jar|msi|vb|vbs|cmd|scr|ps1)\z/i.freeze

  ALLOWED_IMAGE_MIME_TYPES = Set.new([
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/gif',
    'image/avif',
    'image/webp',
    'image/svg+xml',
    'image/bmp',
    'image/tiff',
    'image/x-icon',
    'image/heic',
    'image/heif'
  ]).freeze

  class << self
    # Main validation methods
    def allowed_file?(file_path, mime_type = nil)
      return false if file_path.blank?
      return false if blocked_extension?(file_path)
      return false if mime_type.present? && blocked_mime_type?(mime_type)
      true
    end

    def allowed_image?(mime_type)
      return false if mime_type.blank?
      ALLOWED_IMAGE_MIME_TYPES.include?(normalize_mime_type(mime_type))
    end

    def allowed_pdf?(mime_type)
      return false if mime_type.blank?
      normalize_mime_type(mime_type) == 'application/pdf'
    end

    # Validation with exceptions
    def validate_file!(file_path, mime_type = nil)
      return if allowed_file?(file_path, mime_type)
      
      error_message = security_error_message(file_path, mime_type)
      raise SecurityError, error_message
    end

    def validate_image!(file_path, mime_type)
      return if allowed_image?(mime_type)
      
      raise SecurityError, "Image type not allowed: #{extract_extension(file_path)} (#{mime_type})"
    end

    # Security checking methods
    def blocked_extension?(file_path)
      return false if file_path.blank?
      file_path.match?(BLOCKED_EXTENSIONS)
    end

    def blocked_mime_type?(mime_type)
      return false if mime_type.blank?
      normalized_type = normalize_mime_type(mime_type)
      BLOCKED_MIME_TYPES.any? { |pattern| normalized_type.match?(pattern) }
    end

    # Error message generation
    def security_error_message(file_path, mime_type = nil)
      case
      when blocked_extension?(file_path)
        "extension '#{extract_extension(file_path)}' is not allowed"
      when mime_type.present? && blocked_mime_type?(mime_type)
        "type '#{mime_type}' is not allowed"
      else
        "File upload is not permitted"
      end
    end

    # File type detection
    def file_type(mime_type)
      return :unknown if mime_type.blank?
      
      case normalize_mime_type(mime_type)
      when *ALLOWED_IMAGE_MIME_TYPES
        :image
      else
        :other
      end
    end

    # Utility methods for validation results
    def validation_result(file_path, mime_type = nil)
      {
        allowed: allowed_file?(file_path, mime_type),
        file_type: file_type(mime_type),
        blocked_extension: blocked_extension?(file_path),
        blocked_mime_type: mime_type.present? && blocked_mime_type?(mime_type),
        error_message: allowed_file?(file_path, mime_type) ? nil : security_error_message(file_path, mime_type)
      }
    end

    private

    def normalize_mime_type(mime_type)
      mime_type.to_s.downcase.strip
    end

    def extract_extension(file_path)
      return '' if file_path.blank?
      File.extname(file_path.to_s)
    end
  end
end