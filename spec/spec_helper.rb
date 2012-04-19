require 'redis_props'
require 'pry'

module RedisProps
  class Rails
    def self.env
      "test"
    end
  end
end

$REDIS_SERVER = Redis.new(db: 13)

RSpec.configure do |c|
  c.before(:each) { $REDIS_SERVER.flushdb }
end
