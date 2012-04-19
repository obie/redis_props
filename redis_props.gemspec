# -*- encoding: utf-8 -*-
require File.expand_path('../lib/redis_props/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "redis_props"
  gem.version       = RedisProps::VERSION
  gem.authors       = ["Obie Fernandez"]
  gem.email         = ["obiefernandez@gmail.com"]
  gem.description   = %q{A simple way to annotate ActiveRecord objects with properties that are stored in Redis.
                         Perfect for adding attributes to your models that you won't have to worry about querying
                         or reporting on later. Examples include flags, preferences, etc.}
  gem.summary       = %q{Add non-relational attributes to your ActiveRecord objects.}
  gem.homepage      = "http://github.com/obie/redis_properties"

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.add_development_dependency "rspec"
  gem.add_development_dependency "activesupport"
  gem.add_development_dependency "sqlite3"
  gem.add_development_dependency "activerecord"
  gem.add_development_dependency "redis-namespace"
  gem.add_development_dependency "pry-nav"

  gem.add_runtime_dependency "activesupport"
  gem.add_runtime_dependency "activerecord"
  gem.add_runtime_dependency "redis"
  gem.add_runtime_dependency "redis-namespace"
end
