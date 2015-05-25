Gem::Specification.new do |s|
  s.name = 'polyrex-calendar'
  s.version = '0.6.0'
  s.summary = 'Generates an HTML calendar from a Polyrex document'
  s.authors = ['James Robertson']
  s.files = Dir['lib/*.rb','stylesheet/*']
  s.add_runtime_dependency('polyrex_calendarbase', '~> 0.2', '>=0.2.0') 
  s.signing_key = '../privatekeys/polyrex-calendar.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/polyrex-calendar'
  s.required_ruby_version = '>= 2.1.2'
end
