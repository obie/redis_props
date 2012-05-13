# RedisProps

A simple way to annotate ActiveRecord objects with properties that are stored in Redis instead
of your relational database.
Perfect for adding attributes to your models that you won't have to worry about querying
or reporting on later. Examples include flags, preferences, etc.

If you provide a default value for a property definition, then RedisProps provides typecasting based on the type
inferred

Properties are lazily loaded when their accessors are invoked, but saved immediately when set. In other words,
don't rely on them to have transactional behavior along with the rest of your ActiveRecord attributes. (However, there
are plans to add a transactional modes soon.)

The current version is extracted from working code in DueProps http://dueprops.com

## Installation

Add this line to your application's Gemfile:

    gem 'redis_props'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redis_props

## Usage

The `RedisProps` module depends on `Redis.current` (provided by the `redis` gem) being set.
Key names and namespaces are generated using a customized version of a 1-file library called `Nest`
hat we bundled into this gem.

To add RedisProps to your models just include `RedisProps` in your ActiveRecord class.

```ruby
class Dog < ActiveRecord::Base
  include RedisProps

  redis_props :has_medical_condition do
    define :fleas, default: false
  end
end

>> dog = Dog.create(name: "Fido")
=> <Dog id: 1, name: "Fido", created_at: "2012-05-13 02:15:35", updated_at: "2012-05-13 02:15:35">

>> dog.has_medical_condition_fleas?
=> false

>> dog.has_medical_condition_fleas = true
=> true

>> dog = Dog.find_by_name("Fido")
=> <Dog id: 1, name: "Fido", created_at: "2012-05-13 02:15:35", updated_at: "2012-05-13 02:15:35">

>> dog.has_medical_condition_fleas?
=> true
```

In addition to the `define` method, you'll get a protected `r` method that returns a namespaced key that
can be used for manual redis operations.

```ruby
>> dog = Dog.create
=> <Dog id: 5, name: nil, created_at: "2012-05-13 02:15:35", updated_at: "2012-05-13 02:15:35">

>> dog.send(:r)
=> "Dog:5"

>> dog.has_medical_condition_fleas = true
=> true

>> dog.send(:r).redis.keys
=> ["Dog:5:has_medical_condition_fleas"]
```

## TODOS
These are ranked in order of very likely to get done soon to less likely to get done soon (or maybe not at all.)

* Add documentation for type inference based on default values
* batch saving of attributes instead of instant
* record locking and transactions


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
