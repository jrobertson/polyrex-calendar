Gem::Specification.new do |s|
  s.name = 'polyrex-calendar'
  s.version = '0.1.11'
  s.summary = 'polyrex-calendar'
    s.authors = ['James Robertson']
  s.files = Dir['lib/**/*']
  s.add_dependency('polyrex')
  s.add_dependency('nokogiri') 
  s.signing_key = '../privatekeys/polyrex-calendar.pem'
  s.cert_chain  = ['gem-public_cert.pem']
end
