require "minitest/autorun"
require "active_support/all"
require "action_controller"
require "rails"
require "ostruct"
require "logger"
$LOAD_PATH.unshift File.expand_path("../../../lib", __dir__)
require "droom_client/auth_cookie"
require_relative "../../../app/controllers/concerns/droom_authentication"

class AuthCookieTest < Minitest::Test
  class CookieJar < Hash
    attr_reader :written, :deleted

    def []=(name, options)
      @written = options
      super(name, options[:value])
    end

    def delete(name, options = {})
      @deleted = options
      super(name)
    end
  end

  class TestCookie < DroomClient::AuthCookie
    private

    def cookie_name = "test_auth"
    def cookie_domain = ".example.test"
    def auth_secret = "auth-cookie-test-secret"
    def cookie_lifespan = 60
  end

  def setup
    @jar = CookieJar.new
    @cookie = TestCookie.new(@jar)
    @options = { key: "_dashboard_session", domain: nil, secure: false, same_site: :strict }
    @configuration = OpenStruct.new(session_options: @options)
    @resource = OpenStruct.new(unique_session_id: "new-session")
    @original_configuration = Rails.method(:configuration)
    @original_logger = Rails.logger
    Rails.logger = Logger.new(IO::NULL)
    configuration = @configuration
    Rails.define_singleton_method(:configuration) { configuration }
    @original_cookie_new = DroomClient::AuthCookie.method(:new)
    cookie = @cookie
    DroomClient::AuthCookie.define_singleton_method(:new) { |_| cookie }
  end

  def teardown
    Rails.define_singleton_method(:configuration, @original_configuration)
    Rails.logger = @original_logger
    DroomClient::AuthCookie.define_singleton_method(:new, @original_cookie_new)
  end

  def test_setting_cookie_does_not_change_rails_session_configuration
    original = @options.dup

    @cookie.set(@resource)

    assert_equal original, @options
    assert_equal ".example.test", @jar.written[:domain]
    assert_equal "/", @jar.written[:path]
    assert_equal :lax, @jar.written[:same_site]
    assert @jar.written[:secure]
    assert @jar.written[:httponly]
    assert_equal "new-session", @cookie.token
    assert @cookie.fresh?
  end

  def test_deleting_cookie_does_not_change_rails_session_configuration
    original = @options.dup

    @cookie.unset

    assert_equal original, @options
    assert_equal ".example.test", @jar.deleted[:domain]
    assert_equal "/", @jar.deleted[:path]
  end

  def test_expired_cookie_is_cleared_without_authenticating
    @jar["test_auth"] = {
      value: SignedJson::Signer.new("auth-cookie-test-secret").encode(["old-session", 2.hours.ago])
    }

    assert_cookie_rejected
  end

  def test_invalid_signature_is_cleared_without_authenticating
    @jar["test_auth"] = { value: "invalid-cookie" }

    assert_cookie_rejected
  end

  def test_legacy_and_malformed_signed_payloads_do_not_block_sign_in
    [
      ["user-id", "old-session", Time.now.to_s],
      ["old-session", "invalid-date"],
      { "token" => "old-session" },
      nil
    ].each do |payload|
      @jar["test_auth"] = { value: SignedJson::Signer.new("auth-cookie-test-secret").encode(payload) }

      assert_cookie_rejected
    end
  end

  def test_revoked_remote_session_is_cleared
    @cookie.set(@resource)
    controller = controller_for_cookie
    controller.define_singleton_method(:authenticate_with) { |_| nil }

    assert_nil controller.send(:authenticate_from_cookie)
    refute @jar.key?("test_auth")
  end

  def test_valid_cookie_returns_the_authenticated_user
    @cookie.set(@resource)
    controller = controller_for_cookie
    resource = @resource
    controller.define_singleton_method(:authenticate_with) { |_| resource }

    assert_same @resource, controller.send(:authenticate_from_cookie)
    assert @jar.key?("test_auth")
  end

  private

  def controller_for_cookie
    controller = Object.new
    controller.extend(DroomAuthentication)
    controller.define_singleton_method(:cookies) { nil }
    controller
  end

  def assert_cookie_rejected
    controller = controller_for_cookie
    controller.define_singleton_method(:authenticate_with) { |_| raise "Must not authenticate invalid cookie" }

    assert_nil controller.send(:authenticate_from_cookie)
    refute @jar.key?("test_auth")
  end
end
