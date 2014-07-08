# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'mysql-slowquery-parser'
  spec.version       = '0.0.1'
  spec.authors       = ["studio3104"]
  spec.email         = ["studio3104.com@gmail.com"]
  spec.summary       = %q{MySQL slow query log parser}
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/studio3104/mysql-slowquery-parser'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rake'
end
