Gem::Specification.new do |s|
  s.name = 'polyrex-calendar'
  s.version = '0.3.11'
  s.summary = 'Generates an HTML calendar from a Polyrex document'
  s.authors = ['James Robertson']
  s.files = Dir['lib/**/*']
  s.add_runtime_dependency('polyrex', '~> 0.9', '>=0.9.3')
  s.add_runtime_dependency('nokogiri', '~> 1.6', '>=1.6.2.1') 
  s.add_runtime_dependency('chronic_duration', '~> 0.10', '>=0.10.4') 
  s.add_runtime_dependency('chronic_cron', '~> 0.2', '>=0.2.33')
  s.add_runtime_dependency('rxfhelper', '~> 0.1', '>=0.1.12') 
  s.signing_key = '../privatekeys/polyrex-calendar.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/polyrex-calendar'
  s.required_ruby_version = '>= 2.1.2'
end
