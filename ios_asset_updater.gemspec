# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'ios-asset-updater'
  s.version     = '0.0.1'
  s.date        = '2020-05-19'
  s.summary     = 'iOS Asset Updater'
  s.description = 'Update iOS Assets in an easy and quick way'
  s.authors     = ['Marcelo Vitoria']
  s.email       = 'contact@marcelovitoria.com'
  s.files       = ['lib/ios_asset_updater.rb']
  s.homepage    =
    'https://rubygems.org/gems/ios-asset-updater'
  s.license     = 'MIT'
  s.add_runtime_dependency 'colorize', '~> 0.8.1'
  s.add_development_dependency 'rubocop', '~> 0.83.0'
end
