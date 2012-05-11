require 'logger'
require 'pry'
require 'redis_props'

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

ActiveRecord::Base.logger = Logger.new("test.log")
