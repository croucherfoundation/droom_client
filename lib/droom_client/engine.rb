# require 'concerns/droom_authentication'
# require 'concerns/has_droom_user'
# require 'concerns/might_have_droom_user'
# require 'concerns/hk_names'
# require 'concerns/user_administration'

module DroomClient
  class Engine < ::Rails::Engine

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
    end

    config.to_prepare do
      Dir.glob(Rails.root + "app/helpers/*_helper.rb").each do |c|
        require_dependency(c)
      end
    end

  end
end
