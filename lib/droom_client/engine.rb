require 'concerns/droom_authentication'
require 'concerns/has_droom_user'
require 'concerns/hk_names'
require 'concerns/user_administration'

module DroomClient
  class Engine < ::Rails::Engine

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
    end
    
    initializer "droom_client.integration" do
      ActiveSupport.on_load :action_controller do
        helper DroomClientHelper
      end
    end

  end
end
