class FileSecurityService
  ALLOWED_FILE_MIME_TYPES = Set.new([
    # PDF
    'application/pdf',
    
    # Word documents
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/x-tika-ooxml',
    'application/vnd.oasis.opendocument.text',
    'application/vnd.oasis.opendocument.text-template',
    'application/vnd.oasis.opendocument.text-web',
    'application/vnd.oasis.opendocument.text-master',
    
    # PowerPoint presentations
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    
    # Excel spreadsheets
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'text/csv',
    
    # Text files
    'text/plain',
    'text/rtf',
    
    # Email messages
    'message/rfc822',
    'application/vnd.ms-outlook',
    'application/x-msg',
    'text/x-eml',
    
    # Images
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

  ALLOWED_FILE_EXTENSIONS = Set.new([
    '.pdf',
    '.doc',
    '.docx',
    '.odt',
    '.ott',
    '.docm',
    '.dot',
    '.dotx',
    '.dotm',
    '.ppt',
    '.pptx',
    '.xls',
    '.xlsx',
    '.csv',
    '.txt',
    '.rtf',
    '.eml',
    '.msg',
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.avif',
    '.webp',
    '.svg',
    '.bmp',
    '.tiff',
    '.ico',
    '.heic',
    '.heif'
  ]).freeze
 
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
      
      # Check if extension is in allowed list
      extension = extract_extension(file_path).downcase
      return false unless ALLOWED_FILE_EXTENSIONS.include?(extension)
      
      # If mime_type is provided, check if it's in allowed list
      if mime_type.present?
        normalized_mime = normalize_mime_type(mime_type)
        return false unless ALLOWED_FILE_MIME_TYPES.include?(normalized_mime)
      end
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

    # Error message generation
    def security_error_message(file_path, mime_type = nil)
      extension = extract_extension(file_path)
      
      case
      when file_path.blank?
        "File path is required"
      when extension.present? && !ALLOWED_FILE_EXTENSIONS.include?(extension.downcase)
        "File extension '#{extension}' is not allowed."
      when mime_type.present? && !ALLOWED_FILE_MIME_TYPES.include?(normalize_mime_type(mime_type))
        "File type '#{mime_type}' is not allowed"
      else
        "File upload is not permitted"
      end
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