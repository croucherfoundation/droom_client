module LocalApi
  extend ActiveSupport::Concern

  included do
    before_action :assert_local_request!
  end

  def assert_local_request!
    unless local_request?
      Rails.logger.warn "⚠️ API REQUEST NOT LOCAL: #{request.ip} is not in #{ENV['LOCAL_SUBNET']}"
      raise CanCan::AccessDenied unless local_request?
    end
  end

  def assert_local_request_or_signed_in!
    unless local_request? || user_signed_in?
      Rails.logger.warn "⚠️ NOT SIGNED IN AND API REQUEST NOT LOCAL: #{request.ip} is not in #{ENV['LOCAL_SUBNET']}"
      raise CanCan::AccessDenied
    end
  end

  def local_request?
    if local_subnet_defined?
      permitted_ip_range = IPAddr.new(ENV['LOCAL_SUBNET'])
      permitted_ip_range === IPAddr.new(request.ip)
    else
      false
    end
  end

  def local_subnet_defined?
    ENV['LOCAL_SUBNET'].present?
  end

end