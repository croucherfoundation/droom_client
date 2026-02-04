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

    #Archive & Storage Files
    'application/zip',
    'application/x-zip-compressed',
    'application/x-rar-compressed',
    'application/x-tar',
    'application/x-7z-compressed',
    'application/x-gzip',
    'application/x-ole-storage',
    
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
    '.zip',
    '.rar',
    '.tar',
    '.7z',
    '.gz',
    '.tar.gz',
    '.tgz',
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

  ALLOWED_VIDEO_MIME_TYPES = Set.new([
      'video/mp4',
      'video/mpeg',
      'video/ogg',
      'video/webm',
      'video/quicktime', # .mov
      'video/x-msvideo', # .avi
      'video/x-flv',
      'video/x-matroska', # .mkv
      'video/3gpp',
      'video/3gpp2',
      'video/x-ms-wmv' # .wmv
    ]).freeze

  ALLOWED_SPREADSHEET_MIME_TYPES = [
    'application/vnd.ms-excel', # .xls
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', # .xlsx
    'text/csv' # .csv
  ].freeze

  ALLOWED_SUPPORTING_DOCUMENT_TYPES = ["application/pdf", "image/jpeg"].freeze

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

    def allowed_video?(mime_type)
      return false if mime_type.blank?
      ALLOWED_VIDEO_MIME_TYPES.include?(normalize_mime_type(mime_type))
    end

    def allowed_spreadsheet?(mime_type)
      return false if mime_type.blank?
      ALLOWED_SPREADSHEET_MIME_TYPES.include?(normalize_mime_type(mime_type))
    end

    def allowed_supporting_document?(mime_type)
      return false if mime_type.blank?
      ALLOWED_SUPPORTING_DOCUMENT_TYPES.include?(normalize_mime_type(mime_type))
    end

    def allowed_image_document?(mime_type)
      return false if mime_type.blank?
      mime_type.start_with?("image/")
    end

    # Validation with exceptions
    def validate_file!(file_path, mime_type = nil)
      return if allowed_file?(file_path, mime_type)
      
      error_message = security_error_message(file_path, mime_type)
      raise SecurityError, error_message
    end

    # Error message generation
    def security_error_message(file_path, mime_type = nil)
      extension = extract_extension(file_path)
      
      case
      when file_path.blank?
        "path is required"
      when extension.present? && ALLOWED_FILE_EXTENSIONS.include?(extension.downcase)
        "extension '#{extension}' is not allowed."
      when mime_type.present? && !ALLOWED_FILE_MIME_TYPES.include?(normalize_mime_type(mime_type))
        "type '#{mime_type}' is not allowed"
      else
        "upload is not permitted"
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