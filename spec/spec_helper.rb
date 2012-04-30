require 'redis_props'
require 'pry'

module RedisProps
  class Rails
    def self.env
      "test"
    end
  end
end

Redis.current = Redis.new(db: 13)

RSpec.configure do |c|
  c.before(:each) { Redis.current.flushdb }
end
