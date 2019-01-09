$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "droom_client/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "droom_client"
  s.version     = DroomClient::VERSION
  s.authors     = ["William Ross"]
  s.email       = ["will@spanner.org"]
  s.homepage    = "https://github.com/spanner/droom_client"
  s.summary     = "Holds in one place all the gubbins necessary to act as the client of a data room."
  s.description = "For now just a convenience and a maintenance simplifier."

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails"
  s.add_dependency "responders"
  s.add_dependency "addressable"
  s.add_dependency "her"
  s.add_dependency "faraday"
  s.add_dependency "faraday_middleware"
  s.add_dependency "request_store"
  s.add_dependency "signed_json"

  s.add_development_dependency "sqlite3"
end
