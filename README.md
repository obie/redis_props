# RedisProperties

A simple way to annotate ActiveRecord objects with properties that are stored in Redis.
Perfect for adding attributes to your models that you won't have to worry about querying
or reporting on later. Examples include flags, preferences, etc.

Plan is to include type inference based on default value specified. (Currently implemented for booleans,
which has been our most common use-case up to now.)

Properties are lazily loaded when their accessors are invoked, but saved immediately when set. In other words,
don't rely on them to have transactional behavior along with the rest of your ActiveRecord attributes.

Extracted from working code in DueProps http://dueprops.com

## Installation

Add this line to your application's Gemfile:

    gem 'redis_properties'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redis_properties

## Usage

The `RedisProps` module depends on a `$REDIS_SERVER` variable being set. Keys are prefixed with a namespace
using `Redis::Namespace` and you end up with a `redis` method usable for operations not built-in to the library.

```ruby
class Dog < ActiveRecord::Base
  include RedisProps

  redis_props :has_medical_condition do
    define :fleas, default: false
  end
end

> dog = Dog.create(name: "Fido")

> dog.has_medical_condition_fleas?
false

> dog.has_medical_condition_fleas = true

> dog = Dog.find_by_name("Fido")

> dog.has_medical_condition_fleas?
true
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
