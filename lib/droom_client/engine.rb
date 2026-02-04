require_relative "../../app/helpers/droom_client_helper"

module DroomClient
  class Engine < ::Rails::Engine

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
    end

    initializer "droom_client.integration" do
      ActiveSupport.on_load :action_controller do
        helper ::DroomClientHelper
      end
    end

  end
end
