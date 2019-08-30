module LocalApi
  extend ActiveSupport::Concern

  included do
    before_action :assert_local_request!
  end

  def assert_local_request!
    raise CanCan::AccessDenied unless local_request?
  end

  def assert_local_request_or_signed_in!
    raise CanCan::AccessDenied unless local_request? || user_signed_in?
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