Gem::Specification.new do |s|
  s.name = 'polyrex-calendar'
  s.version = '0.1.22'
  s.summary = 'polyrex-calendar'
  s.authors = ['James Robertson']
  s.files = Dir['lib/**/*']
  s.add_dependency('polyrex')
  s.add_dependency('nokogiri') 
  s.add_dependency('chronic_duration') 
  s.signing_key = '../privatekeys/polyrex-calendar.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/polyrex-calendar'
end
