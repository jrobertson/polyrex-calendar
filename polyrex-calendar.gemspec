Gem::Specification.new do |s|
  s.name = 'polyrex-calendar'
  s.version = '0.7.3'
  s.summary = 'Generates an HTML calendar from a Polyrex document'
  s.authors = ['James Robertson']
  s.files = Dir['lib/polyrex-calendar.rb','stylesheet/*.xsl','stylesheet/*.css']
  s.add_runtime_dependency('polyrex_calendarbase', '~> 0.3', '>=0.3.1')
  s.add_runtime_dependency('weeklyplanner_template', '~> 0.1', '>=0.1.4') 
  s.signing_key = '../privatekeys/polyrex-calendar.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/polyrex-calendar'
  s.required_ruby_version = '>= 2.1.2'
end
