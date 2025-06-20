class FileSecurityService
  # Security configuration constants
  BLOCKED_MIME_TYPES = [
    # JavaScript and scripting languages
    %r{\Aapplication/(x-javascript|javascript|x-msdownload|x-sh|x-exe|x-dosexec|x-bat|x-csh|x-python|x-perl|x-php|x-ruby|x-shellscript)\z}i,
    %r{\Atext/(javascript|x-python|x-perl|x-php|x-ruby|x-shellscript)\z}i,
    
    # Generic binary/executable types
    %r{\Aapplication/octet-stream\z}i,
    
    # Windows executables and installers
    %r{\Aapplication/(x-msdos-program|x-msdownload|x-winexe|x-msi|vnd\.microsoft\.portable-executable)\z}i,
    
    # Unix/Linux executables and scripts
    %r{\Aapplication/(x-executable|x-sharedlib|x-object|x-archive)\z}i,
    
    # Shell scripts and command files
    %r{\Atext/(x-sh|x-shellscript|x-script\.sh|x-script\.csh|x-script\.ksh|x-script\.zsh)\z}i,
    
    # Mac executables
    %r{\Aapplication/(x-mach-binary|x-apple-diskimage)\z}i,
    
    # Java executables
    %r{\Aapplication/(java|x-java-archive|x-java-jnlp-file)\z}i,
    
    # Other potentially dangerous formats
    %r{\Aapplication/(x-deb|x-rpm|x-tar|x-gtar|x-compress|x-gzip)\z}i,
    
    # Script engines
    %r{\Atext/(x-python|x-python3|x-script\.python)\z}i,
    %r{\Aapplication/(x-powershell|x-ps1)\z}i
  ].freeze

  BLOCKED_EXTENSIONS = /\.(js|exe|sh|bat|py|pl|php|rb|c|cpp|h|java|class|jar|msi|vb|vbs|cmd|scr|ps1|ps2|psc1|psc2|msh|msh1|msh2|mshxml|msh1xml|msh2xml|scf|lnk|inf|reg|app|deb|rpm|dmg|pkg|run|bin|bash|zsh|fish|csh|ksh|com|pif|vbe|jse|wsf|wsh|war|lua)\z/i.freeze

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